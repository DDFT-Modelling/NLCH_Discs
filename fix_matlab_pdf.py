#!/usr/bin/env python3
"""fix_matlab_pdf.py — repair raw MATLAB/Qt raster-pattern PDFs.

Target structure
----------------
This script intentionally targets the *raw* MATLAB/Qt PDF structure seen in
E3_Solution_PS.pdf (MATLAB R2025b / Qt exporter):

    page Resources
      /Pattern /PatN -> Type-1 coloured tiling pattern
    pattern stream
      <image transform> cm
      /ImN Do
    page content
      /PCSp cs /PatN scn
      <path>
      f*                 # paint raster via tiling pattern

Some PDF consumers mishandle that tiling pattern when the PDF is embedded and
scaled (notably in some LaTeX/PDF viewing paths), making the raster appear at
the wrong scale while vector axes/text remain correct.

The repair keeps MATLAB's existing image XObject and replaces only the pattern
fill operation with a direct image draw at the *same point in the content
stream*. The original fill path is reused as a clipping path. No image is
re-encoded and vector content is left in place.

Optionally, --remove-white-background removes MATLAB's separate page-sized
opaque white fill. This does not alter white pixels that are actually inside
the raster image.

Dependency
----------
    python -m pip install pymupdf

Typical use
-----------
    # Diagnose without writing anything
    python fix_matlab_pdf.py Graphics/CH_Gallery --recursive --check-only --diagnose

    # Write *_fixed.pdf copies
    python fix_matlab_pdf.py Graphics/CH_Gallery --recursive

    # Same, and remove MATLAB's page-sized white backdrop
    python fix_matlab_pdf.py Graphics/CH_Gallery --recursive --remove-white-background

    # Replace originals, keeping .bak files
    python fix_matlab_pdf.py Graphics/CH_Gallery --recursive --in-place --remove-white-background
    
    # One file
    python fix_matlab_pdf.py E6_Solution_PS.pdf --remove-white-background --in-place

Version: raw-matlab-v3 (2026-08-19)
"""

from __future__ import annotations

import argparse
import math
import re
import shutil
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

try:
    import fitz  # PyMuPDF
except ImportError:
    print("ERROR: PyMuPDF is required. Install with: python -m pip install pymupdf", file=sys.stderr)
    raise SystemExit(2)

VERSION = "raw-matlab-v3"
NUM = rb"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?"
NUM_S = r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?"
NAME_RE = rb"[^\s/<>{}\[\]()]+"

# The pattern stream used by MATLAB is essentially:
#   1350 0 0 -315 0 315 cm
#   /Im7 Do
PATTERN_STREAM_RE = re.compile(
    rb"^\s*(?:q\s+)?"
    rb"(" + NUM + rb")\s+(" + NUM + rb")\s+(" + NUM + rb")\s+"
    rb"(" + NUM + rb")\s+(" + NUM + rb")\s+(" + NUM + rb")\s+cm\s+"
    rb"/(" + NAME_RE + rb")\s+Do\s*(?:Q\s*)?$",
    re.S,
)

# Graphics-state operations needed before the pattern paint. MATLAB puts the
# problematic fill very near the start, before text strings, so this is a
# deliberately narrow parser rather than a general PDF interpreter.
GS_RE = re.compile(
    rb"(?P<cm>(?<!\S)(" + NUM + rb")\s+(" + NUM + rb")\s+(" + NUM + rb")\s+"
    rb"(" + NUM + rb")\s+(" + NUM + rb")\s+(" + NUM + rb")\s+cm(?!\S))"
    rb"|(?P<q>(?<!\S)q(?!\S))|(?P<Q>(?<!\S)Q(?!\S))"
)

FILL_RE = re.compile(rb"(?<!\S)(f\*|f)(?!\S)")
PATH_POINT_RE = re.compile(
    rb"(" + NUM + rb")\s+(" + NUM + rb")\s+(m|l)(?=\s|$)"
)
RECT_RE = re.compile(
    rb"(" + NUM + rb")\s+(" + NUM + rb")\s+(" + NUM + rb")\s+(" + NUM + rb")\s+re(?=\s|$)"
)


@dataclass(frozen=True)
class PatternInfo:
    name: str
    xref: int
    image_name: str
    image_xref: int
    pattern_matrix: tuple[float, float, float, float, float, float]
    inner_matrix: tuple[float, float, float, float, float, float]
    direct_page_matrix: tuple[float, float, float, float, float, float]


@dataclass(frozen=True)
class Repair:
    page_number: int
    content_xref: int
    pattern: PatternInfo
    scn_start: int
    fill_start: int
    fill_end: int
    fill_op: str
    current_ctm: tuple[float, float, float, float, float, float]
    local_image_matrix: tuple[float, float, float, float, float, float]
    page_rect: tuple[float, float, float, float]
    coverage: float


@dataclass(frozen=True)
class WhiteFill:
    page_number: int
    content_xref: int
    fill_start: int
    fill_end: int
    coverage: float


def _fmt(x: float) -> str:
    if abs(x) < 5e-12:
        x = 0.0
    return f"{x:.10g}"


def _matrix_compose(outer: Sequence[float], inner: Sequence[float]) -> tuple[float, ...]:
    """Return outer(inner(point)) for PDF affine matrices [a b c d e f]."""
    a, b, c, d, e, f = outer
    A, B, C, D, E, F = inner
    return (
        a*A + c*B,
        b*A + d*B,
        a*C + c*D,
        b*C + d*D,
        a*E + c*F + e,
        b*E + d*F + f,
    )


def _matrix_inverse(m: Sequence[float]) -> tuple[float, ...] | None:
    a, b, c, d, e, f = m
    det = a*d - b*c
    if abs(det) < 1e-14:
        return None
    return (
        d/det,
        -b/det,
        -c/det,
        a/det,
        (c*f - d*e)/det,
        (b*e - a*f)/det,
    )


def _transform(m: Sequence[float], x: float, y: float) -> tuple[float, float]:
    a, b, c, d, e, f = m
    return a*x + c*y + e, b*x + d*y + f


def _parse_array(text: str, n: int) -> tuple[float, ...] | None:
    m = re.search(r"\[([^\]]+)\]", text, re.S)
    if not m:
        return None
    try:
        vals = tuple(float(v) for v in re.findall(NUM_S, m.group(1)))
    except ValueError:
        return None
    return vals if len(vals) == n else None


def _balanced_dict_after(text: str, key: str) -> str | None:
    """Return the <<...>> dictionary immediately following /key, balancing nesting."""
    m = re.search(r"/" + re.escape(key) + r"\s*<<", text)
    if not m:
        return None
    start = text.find("<<", m.start())
    depth = 0
    i = start
    while i < len(text) - 1:
        pair = text[i:i+2]
        if pair == "<<":
            depth += 1
            i += 2
            continue
        if pair == ">>":
            depth -= 1
            i += 2
            if depth == 0:
                return text[start:i]
            continue
        i += 1
    return None


def _dict_bounds_after(text: str, key: str) -> tuple[int, int] | None:
    m = re.search(r"/" + re.escape(key) + r"\s*<<", text)
    if not m:
        return None
    start = text.find("<<", m.start())
    depth = 0
    i = start
    while i < len(text) - 1:
        pair = text[i:i+2]
        if pair == "<<":
            depth += 1
            i += 2
        elif pair == ">>":
            depth -= 1
            i += 2
            if depth == 0:
                return start, i
        else:
            i += 1
    return None


def _resource_xref(doc: fitz.Document, page: fitz.Page) -> int | None:
    pobj = doc.xref_object(page.xref, compressed=False)
    m = re.search(r"/Resources\s+(\d+)\s+\d+\s+R", pobj)
    return int(m.group(1)) if m else None


def _pattern_resources(doc: fitz.Document, page: fitz.Page) -> tuple[dict[str, int], str]:
    rx = _resource_xref(doc, page)
    if rx is None:
        return {}, "page /Resources is not an indirect object"
    robj = doc.xref_object(rx, compressed=False)
    p_dict = _balanced_dict_after(robj, "Pattern")
    if p_dict is None:
        return {}, "page has no /Pattern resource"
    pairs = re.findall(r"/([^\s/<>{}\[\]()]+)\s+(\d+)\s+\d+\s+R", p_dict)
    return {name: int(xref) for name, xref in pairs}, ""


def _parse_pattern(doc: fitz.Document, name: str, xref: int) -> tuple[PatternInfo | None, str]:
    if not doc.xref_is_stream(xref):
        return None, "pattern object is not a stream"
    obj = doc.xref_object(xref, compressed=False)
    if not re.search(r"/PatternType\s+1(?:\D|$)", obj):
        return None, "not a Type-1 tiling pattern"
    if not re.search(r"/PaintType\s+1(?:\D|$)", obj):
        return None, "pattern is not coloured (/PaintType 1)"

    mm = re.search(r"/Matrix\s*(\[[^\]]+\])", obj, re.S)
    if mm:
        pm = _parse_array(mm.group(1), 6)
        if pm is None:
            return None, "could not parse pattern /Matrix"
    else:
        pm = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)

    pstream = doc.xref_stream(xref)
    sm = PATTERN_STREAM_RE.fullmatch(pstream)
    if not sm:
        return None, "pattern stream is not 'matrix cm /Image Do'"
    inner = tuple(float(sm.group(i)) for i in range(1, 7))
    image_name = sm.group(7).decode("latin1")

    xdict = _balanced_dict_after(obj, "XObject")
    if not xdict:
        return None, "pattern has no /XObject dictionary"
    im = re.search(r"/" + re.escape(image_name) + r"\s+(\d+)\s+\d+\s+R", xdict)
    if not im:
        return None, f"/{image_name} is not an indirect XObject"
    image_xref = int(im.group(1))
    iobj = doc.xref_object(image_xref, compressed=False)
    if not re.search(r"/Subtype\s*/Image(?:\s|/|>>)", iobj):
        return None, f"/{image_name} does not point to an image XObject"

    direct = _matrix_compose(pm, inner)
    return PatternInfo(name, xref, image_name, image_xref, tuple(pm), tuple(inner), tuple(direct)), ""


def _ctm_at(content: bytes, pos: int) -> tuple[float, ...]:
    """Track q/Q/cm in content[0:pos]. Sufficient for MATLAB's early raster fill."""
    ident = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
    ctm: tuple[float, ...] = ident
    stack: list[tuple[float, ...]] = []
    for m in GS_RE.finditer(content, 0, pos):
        if m.group("q") is not None:
            stack.append(ctm)
        elif m.group("Q") is not None:
            ctm = stack.pop() if stack else ident
        else:
            # With our affine convention, coordinates after a later cm first see
            # that local transform and then the previous CTM: C_new = C_old o M.
            vals = tuple(float(m.group(i)) for i in range(2, 8))
            ctm = _matrix_compose(ctm, vals)
    return ctm


def _path_bbox(segment: bytes, ctm: Sequence[float]) -> tuple[float, float, float, float] | None:
    pts: list[tuple[float, float]] = []
    for m in PATH_POINT_RE.finditer(segment):
        pts.append(_transform(ctm, float(m.group(1)), float(m.group(2))))
    for m in RECT_RE.finditer(segment):
        x, y, w, h = map(float, m.groups())
        pts.extend([
            _transform(ctm, x, y), _transform(ctm, x+w, y),
            _transform(ctm, x, y+h), _transform(ctm, x+w, y+h),
        ])
    if not pts:
        return None
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def _coverage_of_bbox(page: fitz.Page, bbox_pdf: Sequence[float]) -> float:
    x0, y0, x1, y1 = bbox_pdf
    # bbox_pdf is already in default PDF page coordinates. Convert its corners
    # through PyMuPDF's page transform, then intersect with page.rect.
    tm = page.transformation_matrix
    pts = [fitz.Point(x0, y0)*tm, fitz.Point(x0, y1)*tm,
           fitz.Point(x1, y0)*tm, fitz.Point(x1, y1)*tm]
    r = fitz.Rect(min(p.x for p in pts), min(p.y for p in pts),
                  max(p.x for p in pts), max(p.y for p in pts))
    inter = r & page.rect
    return max(0.0, inter.get_area()) / max(page.rect.get_area(), 1e-12)


def _content_streams(doc: fitz.Document, page: fitz.Page) -> list[tuple[int, bytes]]:
    out: list[tuple[int, bytes]] = []
    for xref in page.get_contents():
        try:
            out.append((xref, doc.xref_stream(xref)))
        except Exception:
            pass
    return out


def _find_pattern_fill_in_stream(
    page: fitz.Page,
    xref: int,
    content: bytes,
    pat: PatternInfo,
    min_cover: float,
) -> tuple[Repair | None, str]:
    token = re.compile(rb"/" + re.escape(pat.name.encode("latin1")) + rb"\s+scn\b")
    uses = list(token.finditer(content))
    if not uses:
        return None, "pattern resource is not selected with scn in this stream"
    if len(uses) != 1:
        return None, f"pattern is selected {len(uses)} times; refusing ambiguous page"

    sel = uses[0]
    # Find the next fill. Raw MATLAB has /GSa gs + a simple path + h + f*.
    fill = FILL_RE.search(content, sel.end())
    if not fill:
        return None, "no f/f* operation follows the pattern selection"
    between = content[sel.end():fill.start()]

    # Refuse if another painting/transform/text/image operator intervenes. The
    # allowed material is colors/gs and path construction only.
    disallowed = re.search(
        rb"(?<!\S)(?:S|s|B\*?|b\*?|n|Do|BT|ET|cm|q|Q)(?!\S)", between
    )
    if disallowed:
        return None, f"unexpected operator before pattern fill: {disallowed.group(0).decode('latin1')}"

    ctm = _ctm_at(content, sel.start())
    inv = _matrix_inverse(ctm)
    if inv is None:
        return None, "current transformation matrix is singular"
    local = _matrix_compose(inv, pat.direct_page_matrix)

    # Direct image transform should be non-degenerate. Rotation/shear are fine:
    # we inject a raw PDF cm rather than relying on page.insert_image().
    if abs(local[0]*local[3] - local[1]*local[2]) < 1e-12:
        return None, "computed direct-image transform is singular"

    # The existing fill path is our clip. Require it to cover a meaningful part
    # of the page so decorative patterns are not touched accidentally.
    bbox = _path_bbox(between, ctm)
    if bbox is None:
        return None, "could not find a path between pattern selection and fill"
    coverage = _coverage_of_bbox(page, bbox)
    if coverage < min_cover:
        return None, f"pattern fill covers only {coverage*100:.1f}% of the page (< {min_cover*100:.1f}%)"

    # Report the image's page-space unit-square bounding rectangle.
    corners = [_transform(pat.direct_page_matrix, 0, 0),
               _transform(pat.direct_page_matrix, 1, 0),
               _transform(pat.direct_page_matrix, 0, 1),
               _transform(pat.direct_page_matrix, 1, 1)]
    page_rect = (min(x for x, _ in corners), min(y for _, y in corners),
                 max(x for x, _ in corners), max(y for _, y in corners))

    return Repair(
        page_number=page.number,
        content_xref=xref,
        pattern=pat,
        scn_start=sel.start(),
        fill_start=fill.start(),
        fill_end=fill.end(),
        fill_op=fill.group(1).decode("latin1"),
        current_ctm=tuple(ctm),
        local_image_matrix=tuple(local),
        page_rect=tuple(page_rect),
        coverage=coverage,
    ), ""


def find_repairs(doc: fitz.Document, min_cover: float, diagnose: bool = False) -> tuple[list[Repair], list[str]]:
    repairs: list[Repair] = []
    notes: list[str] = []

    for pno in range(doc.page_count):
        page = doc[pno]
        resources, why = _pattern_resources(doc, page)
        if not resources:
            if diagnose:
                notes.append(f"      page {pno+1}: {why}")
            continue

        streams = _content_streams(doc, page)
        for name, pxref in resources.items():
            pat, reason = _parse_pattern(doc, name, pxref)
            if pat is None:
                if diagnose:
                    notes.append(f"      page {pno+1}: /{name} xref={pxref}: reject - {reason}")
                continue

            found: Repair | None = None
            reasons: list[str] = []
            for cxref, content in streams:
                r, reason = _find_pattern_fill_in_stream(page, cxref, content, pat, min_cover)
                if r is not None:
                    found = r
                    break
                reasons.append(reason)

            if found is not None:
                repairs.append(found)
                if diagnose:
                    m = " ".join(_fmt(v) for v in found.local_image_matrix)
                    notes.append(
                        f"      page {pno+1}: /{name} xref={pxref} -> /{pat.image_name} "
                        f"image xref={pat.image_xref}: MATCH; paint={found.fill_op}; "
                        f"coverage={found.coverage*100:.1f}%; local-matrix=[{m}]"
                    )
            elif diagnose:
                reason = next((r for r in reasons if "not selected" not in r), reasons[0] if reasons else "no content stream")
                notes.append(f"      page {pno+1}: /{name} xref={pxref}: reject - {reason}")

    return repairs, notes


def _find_white_fill(page: fitz.Page, xref: int, content: bytes, before: int, min_cover: float = 0.97) -> WhiteFill | None:
    prefix = content[:before]
    # Raw MATLAB's page backdrop is RGB white: /CSp cs 1 1 1 scn ... f*
    white = list(re.finditer(rb"(?<!\S)1\s+1\s+1\s+scn(?!\S)", prefix))
    for w in reversed(white):
        fill = FILL_RE.search(prefix, w.end())
        if not fill:
            continue
        segment = prefix[w.end():fill.start()]
        # Refuse if anything paints, changes CTM, enters text, etc. before this fill.
        if re.search(rb"(?<!\S)(?:S|s|B\*?|b\*?|n|Do|BT|ET|cm|q|Q)(?!\S)", segment):
            continue
        ctm = _ctm_at(content, w.start())
        bbox = _path_bbox(segment, ctm)
        if bbox is None:
            continue
        cov = _coverage_of_bbox(page, bbox)
        if cov >= min_cover:
            return WhiteFill(page.number, xref, fill.start(), fill.end(), cov)
    return None


def _ensure_page_xobject(doc: fitz.Document, page: fitz.Page, name: str, image_xref: int) -> None:
    rx = _resource_xref(doc, page)
    if rx is None:
        raise RuntimeError("page /Resources is not an indirect object; unsupported raw MATLAB variant")
    obj = doc.xref_object(rx, compressed=False)

    # If already present, keep it.
    if re.search(r"/" + re.escape(name) + r"\s+" + str(image_xref) + r"\s+\d+\s+R", obj):
        return

    bounds = _dict_bounds_after(obj, "XObject")
    entry = f"\n      /{name} {image_xref} 0 R"
    if bounds is not None:
        start, end = bounds
        # Insert immediately before this XObject dictionary's closing >>.
        insert_at = end - 2
        new_obj = obj[:insert_at] + entry + "\n    " + obj[insert_at:]
    else:
        # Add /XObject to the outer resource dictionary before its final >>.
        insert_at = obj.rfind(">>")
        if insert_at < 0:
            raise RuntimeError("could not locate end of page resource dictionary")
        new_obj = obj[:insert_at] + f"\n  /XObject << /{name} {image_xref} 0 R >>\n" + obj[insert_at:]
    doc.update_object(rx, new_obj)


def _unique_xobject_name(doc: fitz.Document, page: fitz.Page, base: str = "MatlabFix") -> str:
    rx = _resource_xref(doc, page)
    obj = doc.xref_object(rx, compressed=False) if rx is not None else ""
    i = 0
    while re.search(r"/" + re.escape(f"{base}{i}") + r"(?:\s|/|<)", obj):
        i += 1
    return f"{base}{i}"


def _apply_repairs(doc: fitz.Document, repairs: list[Repair], remove_white: bool) -> tuple[int, int]:
    """Modify content streams in place. Returns (patterns_fixed, white_fills_removed)."""
    by_stream: dict[tuple[int, int], list[tuple[int, int, bytes]]] = {}
    white_count = 0

    # Add image resource names and schedule replacements.
    for r in repairs:
        page = doc[r.page_number]
        xname = _unique_xobject_name(doc, page)
        _ensure_page_xobject(doc, page, xname, r.pattern.image_xref)
        a,b,c,d,e,f = r.local_image_matrix
        clipop = "W*" if r.fill_op == "f*" else "W"
        repl = (
            f"{clipop} n\n"
            f"q\n{_fmt(a)} {_fmt(b)} {_fmt(c)} {_fmt(d)} {_fmt(e)} {_fmt(f)} cm\n"
            f"/{xname} Do\nQ"
        ).encode("ascii")
        by_stream.setdefault((r.page_number, r.content_xref), []).append((r.fill_start, r.fill_end, repl))

    if remove_white:
        # At most one backdrop per repaired page / content stream, before its first pattern use.
        for r in repairs:
            key = (r.page_number, r.content_xref)
            page = doc[r.page_number]
            content = doc.xref_stream(r.content_xref)
            wf = _find_white_fill(page, r.content_xref, content, before=r.scn_start)
            if wf is not None:
                # Avoid duplicates when multiple patterns share a stream.
                existing = by_stream.setdefault(key, [])
                if not any(s == wf.fill_start and e == wf.fill_end for s,e,_ in existing):
                    existing.append((wf.fill_start, wf.fill_end, b"n"))
                    white_count += 1

    for (_, xref), replacements in by_stream.items():
        data = doc.xref_stream(xref)
        for start, end, repl in sorted(replacements, key=lambda t: t[0], reverse=True):
            data = data[:start] + repl + data[end:]
        doc.update_stream(xref, data)

    return len(repairs), white_count


def _pix(doc: fitz.Document, pno: int, dpi: float, alpha: bool = False) -> tuple[int,int,int,bytes]:
    z = dpi / 72.0
    p = doc[pno].get_pixmap(matrix=fitz.Matrix(z,z), alpha=alpha)
    return p.width, p.height, p.n, bytes(p.samples)


def _verify(original: Path, fixed: Path, pages: Iterable[int], dpi: float, tolerance: int) -> tuple[bool,str]:
    with fitz.open(original) as a, fitz.open(fixed) as b:
        for pno in sorted(set(pages)):
            pa = _pix(a,pno,dpi,False); pb = _pix(b,pno,dpi,False)
            if pa[:3] != pb[:3]:
                return False, f"page {pno+1}: rendered dimensions differ"
            if tolerance == 0:
                if pa[3] != pb[3]:
                    return False, f"page {pno+1}: rendered pixels differ"
            else:
                if any(abs(x-y) > tolerance for x,y in zip(pa[3],pb[3])):
                    return False, f"page {pno+1}: pixel difference exceeds tolerance {tolerance}"
    return True, "render verified"


def collect_inputs(items: Sequence[str], recursive: bool) -> list[Path]:
    out: list[Path] = []
    seen: set[Path] = set()
    for raw in items:
        p = Path(raw).expanduser()
        candidates: Iterable[Path]
        if p.is_dir():
            candidates = p.rglob("*.pdf") if recursive else p.glob("*.pdf")
        elif p.is_file():
            candidates = [p]
        else:
            # Basic shell-independent wildcard support.
            parent = p.parent if str(p.parent) else Path(".")
            candidates = parent.glob(p.name)
        for q in candidates:
            if q.is_file() and q.suffix.lower() == ".pdf":
                q = q.resolve()
                # Don't recursively reprocess our own outputs/backups by default.
                if q.name.endswith("_fixed.pdf") or q.name.endswith(".pdf.bak"):
                    continue
                if q not in seen:
                    seen.add(q); out.append(q)
    return sorted(out)


def output_path_for(src: Path, output_dir: Path | None, suffix: str) -> Path:
    name = src.stem + suffix + src.suffix
    return (output_dir / name) if output_dir else src.with_name(name)


def process_one(
    src: Path,
    *,
    check_only: bool,
    diagnose: bool,
    min_cover: float,
    remove_white: bool,
    in_place: bool,
    output_dir: Path | None,
    suffix: str,
    verify: bool,
    verify_dpi: float,
    tolerance: int,
    verbose: bool,
) -> tuple[str,int]:
    try:
        doc = fitz.open(src)
    except Exception as e:
        return f"ERROR {src}: {e}", 0

    try:
        if doc.needs_pass:
            return f"SKIP  {src}: encrypted/password-protected", 0
        repairs, notes = find_repairs(doc, min_cover=min_cover, diagnose=diagnose)
        if not repairs:
            msg = f"OK    {src}: 0 repairable raw MATLAB pattern fill(s)"
            if notes:
                msg += "\n" + "\n".join(notes)
            return msg, 0

        details = notes if diagnose else []
        if verbose and not diagnose:
            for r in repairs:
                m = " ".join(_fmt(v) for v in r.local_image_matrix)
                details.append(
                    f"      page {r.page_number+1}: /{r.pattern.name} xref={r.pattern.xref} "
                    f"-> /{r.pattern.image_name} image xref={r.pattern.image_xref}; "
                    f"paint={r.fill_op}; coverage={r.coverage*100:.1f}%; local-matrix=[{m}]"
                )
        head = f"FOUND {src}: {len(repairs)} repairable raw MATLAB pattern fill(s)"
        if check_only:
            return head + (("\n" + "\n".join(details)) if details else ""), len(repairs)

        if in_place:
            dst = src
            temp_dir = src.parent
        else:
            dst = output_path_for(src, output_dir, suffix)
            dst.parent.mkdir(parents=True, exist_ok=True)
            temp_dir = dst.parent

        fixed_count, white_count = _apply_repairs(doc, repairs, remove_white)
        fd, tmpname = tempfile.mkstemp(prefix=f".{src.stem}.matlabfix.", suffix=".pdf", dir=temp_dir)
        Path(tmpname).unlink(missing_ok=True)
        tmp = Path(tmpname)
        try:
            doc.save(tmp, garbage=4, deflate=True, clean=False)
            doc.close()

            if verify:
                ok, why = _verify(src, tmp, [r.page_number for r in repairs], verify_dpi, tolerance)
                if not ok:
                    tmp.unlink(missing_ok=True)
                    return f"ERROR {src}: repair created but verification failed ({why}); original untouched", 0
            else:
                why = "verification disabled"

            if in_place:
                bak = src.with_name(src.name + ".bak")
                if bak.exists():
                    # Never silently overwrite an existing backup.
                    i = 1
                    while src.with_name(src.name + f".bak{i}").exists():
                        i += 1
                    bak = src.with_name(src.name + f".bak{i}")
                shutil.copy2(src, bak)
                tmp.replace(src)
                extra = f"; backup={bak.name}"
            else:
                tmp.replace(dst)
                extra = ""

            wb = f"; removed {white_count} white backdrop fill(s)" if remove_white else ""
            msg = f"FIXED {src}: {fixed_count} pattern fill(s){wb}; {why}{extra}"
            if not in_place:
                msg += f"\n      -> {dst}"
            if details:
                msg += "\n" + "\n".join(details)
            return msg, fixed_count
        finally:
            try:
                doc.close()
            except Exception:
                pass
            tmp.unlink(missing_ok=True)
    except Exception as e:
        try:
            doc.close()
        except Exception:
            pass
        return f"ERROR {src}: {type(e).__name__}: {e}", 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Repair raw MATLAB/Qt PDFs that paint a raster image through a Type-1 tiling pattern.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("paths", nargs="+", help="PDF files, wildcard-like paths, or directories")
    p.add_argument("-r", "--recursive", action="store_true", help="recurse into directories")
    p.add_argument("--check-only", action="store_true", help="detect only; write nothing")
    p.add_argument("--diagnose", action="store_true", help="show why each page pattern matches or is rejected")
    p.add_argument("-v", "--verbose", action="store_true", help="show details for matches")
    p.add_argument("--remove-white-background", action="store_true",
                   help="remove MATLAB's separate page-sized opaque white backdrop")
    p.add_argument("--min-cover", type=float, default=0.50,
                   help="minimum page fraction covered by raster fill (default: 0.50)")
    p.add_argument("--suffix", default="_fixed", help="suffix for copied outputs (default: _fixed)")
    p.add_argument("--output-dir", type=Path, help="directory for copied outputs")
    p.add_argument("--in-place", action="store_true", help="replace matching originals and create .bak backups")
    p.add_argument("--no-verify", action="store_true", help="skip before/after render comparison")
    p.add_argument("--verify-dpi", type=float, default=144.0, help="verification render DPI (default: 144)")
    p.add_argument("--tolerance", type=int, default=0, help="allowed per-channel verification difference (default: 0)")
    p.add_argument("--version", action="version", version=f"%(prog)s {VERSION}")
    return p


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.in_place and args.output_dir is not None:
        print("ERROR: --in-place and --output-dir cannot be used together", file=sys.stderr)
        return 2
    if not (0.0 <= args.min_cover <= 1.0):
        print("ERROR: --min-cover must be between 0 and 1", file=sys.stderr)
        return 2
    if not (0 <= args.tolerance <= 255):
        print("ERROR: --tolerance must be between 0 and 255", file=sys.stderr)
        return 2

    files = collect_inputs(args.paths, args.recursive)
    if not files:
        print("No PDF files found.", file=sys.stderr)
        return 2

    matched_files = 0
    total_repairs = 0
    for src in files:
        msg, count = process_one(
            src,
            check_only=args.check_only,
            diagnose=args.diagnose,
            min_cover=args.min_cover,
            remove_white=args.remove_white_background,
            in_place=args.in_place,
            output_dir=args.output_dir,
            suffix=args.suffix,
            verify=not args.no_verify,
            verify_dpi=args.verify_dpi,
            tolerance=args.tolerance,
            verbose=args.verbose,
        )
        print(msg)
        if count:
            matched_files += 1
            total_repairs += count

    if args.check_only:
        print(f"\nFound {total_repairs} repairable pattern fill(s) in {matched_files} of {len(files)} PDF(s).")
    else:
        print(f"\nRepaired {total_repairs} pattern fill(s) in {matched_files} of {len(files)} PDF(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
