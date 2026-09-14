# `fix_matlab_pdf.py`

## Purpose

`fix_matlab_pdf.py` repairs a specific class of PDFs produced by the raw MATLAB/Qt PDF exporter.

The target files are PDFs like `A_Solution_PS.pdf`, where MATLAB stores a raster layer inside a **Type-1 coloured tiling pattern** and then paints that pattern into the page while leaving axes, text, ticks, labels, and other annotations as vector graphics.

Some PDF consumers mishandle that structure when the PDF is embedded and scaled, which can make the raster layer appear at the wrong size while the vector layer remains correctly positioned.

The script replaces the problematic pattern fill with a normal direct image draw while preserving MATLAB's original embedded image and vector content.

It can also optionally remove MATLAB's separate opaque white page background.

---

## Version

Current script version:

```text
raw-matlab-v3
```

Check the installed copy with:

```bash
python fix_matlab_pdf.py --version
```

Expected output:

```text
fix_matlab_pdf.py raw-matlab-v3
```

---

## Dependency

The script requires [PyMuPDF](https://pymupdf.readthedocs.io/), imported in Python as `fitz`.

Install it with:

```bash
python -m pip install pymupdf
```

No external PDF command-line utilities are required.

---

# What problem does it repair?

The raw MATLAB/Qt exporter can generate a page with a structure conceptually like this:

```text
PDF page
│
├── opaque white page background
│
├── Type-1 tiling pattern
│      └── raster image XObject
│
├── vector axes
├── vector ticks
├── vector text
├── vector labels
└── other vector graphics
```

The raster itself is valid. The troublesome part is the way it is painted.

A typical MATLAB pattern resource looks like:

```text
/Pattern /PatN
    ↓
Type-1 coloured tiling pattern
    ↓
pattern stream:
    <matrix> cm
    /ImN Do
```

The page then selects the pattern and fills a path:

```pdf
/PCSp cs
/PatN scn

... construct path ...

f*
```

Some PDF rendering paths do not handle this nested transformation correctly when the entire PDF is embedded and scaled.

The result can look like:

- vector axes at the correct size;
- raster panels magnified or displaced;
- raster regions spilling into neighbouring subplot areas.

---

# What the script changes

The script does **not** rasterise the whole page.

It also does **not** decode and recompress the embedded image.

Instead, it reuses the exact image XObject already stored in the PDF.

Conceptually, this:

```text
construct MATLAB raster boundary
        ↓
select tiling pattern
        ↓
fill path with pattern
```

is converted into:

```text
construct the same raster boundary
        ↓
turn that path into a clipping path
        ↓
draw the original embedded image directly
```

For a fill using the even-odd rule:

```pdf
f*
```

the replacement is equivalent to:

```pdf
W* n
q
a b c d e f cm
/MatlabFix0 Do
Q
```

For a normal fill:

```pdf
f
```

the clipping operation becomes:

```pdf
W n
```

The direct image matrix is computed from MATLAB's original PDF transformations, so the image is placed at the same location and scale intended by MATLAB.

---

# Important design goals

The script is deliberately conservative.

It is intended for the raw MATLAB/Qt structure represented by files such as `E3_Solution_PS.pdf`. It is **not** intended as a general-purpose PDF repair utility.

The main safety principles are:

1. **Structural detection rather than filename detection.**  
   A file is repaired only when its internal PDF structure matches the expected MATLAB pattern arrangement.

2. **No image recompression.**  
   The existing PDF image XObject is referenced directly.

3. **Vector content is retained.**  
   Axes, labels, text, ticks, and other vector objects are not rasterised.

4. **The original fill path is retained as a clip.**  
   This preserves the region MATLAB intended the raster to occupy.

5. **Ambiguous structures are rejected.**  
   If a pattern is used multiple times or unexpected operators occur before the fill, the script refuses that candidate.

6. **By default, the original file is not overwritten.**  
   A new `_fixed.pdf` copy is created.

7. **In-place mode creates a backup.**

8. **A render comparison is performed by default.**  
   The repaired page is rendered and compared against the original before the result is accepted.

---

# Basic usage

## Inspect a single PDF

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf \
    --check-only \
    --diagnose
```

No file is modified.

---

## Repair a single PDF

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf
```

By default this creates:

```text
E3_Solution_PS_fixed.pdf
```

The original remains untouched.

---

## Scan a directory

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --check-only
```

Only PDFs immediately inside the directory are scanned.

---

## Scan a directory recursively

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --check-only
```

or equivalently:

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    -r \
    --check-only
```

---

## Diagnose every candidate

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --check-only \
    --diagnose
```

This is the recommended first command for a new collection of MATLAB PDFs.

It reports either a match or the reason a candidate was rejected.

---

## Repair all matching files recursively

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive
```

Matching files produce `_fixed.pdf` copies.

Non-matching files are left untouched.

---

# Removing MATLAB's white background

MATLAB may first paint a page-sized opaque white rectangle before drawing the actual figure.

The script can remove this separate backdrop with:

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf \
    --remove-white-background
```

For a directory:

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --remove-white-background
```

The operation targets MATLAB's separate full-page white fill.

It does **not** remove white pixels contained inside the raster image itself.

Conceptually:

```pdf
1 1 1 scn
... page-sized path ...
f*
```

becomes:

```pdf
1 1 1 scn
... page-sized path ...
n
```

`n` terminates the path without painting it.

This can make the otherwise empty page area transparent.

---

# In-place mode

To replace the original matching PDFs:

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --in-place
```

The original is backed up before replacement.

For example:

```text
E3_Solution_PS.pdf
E3_Solution_PS.pdf.bak
```

If `.bak` already exists, the script uses numbered backups:

```text
E3_Solution_PS.pdf.bak1
E3_Solution_PS.pdf.bak2
...
```

To combine in-place replacement with white-background removal:

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --in-place \
    --remove-white-background
```

---

# Output directory

Instead of placing repaired files beside the originals, an output directory can be specified:

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --output-dir Fixed_PDFs
```

The destination filename still uses the configured suffix.

`--output-dir` and `--in-place` cannot be used together.

---

# Output suffix

The default suffix is:

```text
_fixed
```

Therefore:

```text
E3_Solution_PS.pdf
```

becomes:

```text
E3_Solution_PS_fixed.pdf
```

A custom suffix can be supplied:

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf \
    --suffix "_repaired"
```

which produces:

```text
E3_Solution_PS_repaired.pdf
```

---

# Wildcards and multiple inputs

The script accepts multiple files, directories, and simple wildcard-like paths.

Examples:

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf E6_Solution_PS.pdf
```

```bash
python fix_matlab_pdf.py "Graphics/CH_Gallery/E*_Solution_PS.pdf"
```

```bash
python fix_matlab_pdf.py FolderA FolderB Figure1.pdf
```

Wildcard expansion is handled internally when necessary, so quoted wildcard expressions can be used.

---

# Verification

By default, every repaired page is rendered both:

- before repair;
- after repair.

The pixel data is then compared.

This is intended to catch accidental changes to the visible figure.

The default verification resolution is:

```text
144 dpi
```

and the default per-channel tolerance is:

```text
0
```

A tolerance of zero means the rendered pixel arrays must match exactly.

---

## Change verification DPI

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf \
    --verify-dpi 200
```

Higher DPI provides a stricter and more expensive check.

---

## Allow a small pixel tolerance

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf \
    --tolerance 1
```

The value is a per-channel difference from `0` to `255`.

The default is:

```text
0
```

---

## Disable verification

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --no-verify
```

This may make a large batch run faster, but verification is recommended unless there is a specific reason to disable it.

---

# Diagnostic modes

## `--check-only`

Detect matching structures without writing output:

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf \
    --check-only
```

Example style of output:

```text
FOUND E3_Solution_PS.pdf: 1 repairable raw MATLAB pattern fill(s)
```

or:

```text
OK    some_other_file.pdf: 0 repairable raw MATLAB pattern fill(s)
```

---

## `--verbose`

Show details for successful matches:

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf \
    --check-only \
    --verbose
```

Details can include:

- page number;
- pattern resource name;
- pattern object xref;
- image resource name;
- image object xref;
- fill operator;
- page coverage;
- calculated local image matrix.

---

## `--diagnose`

Show both matches and rejection reasons:

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --check-only \
    --diagnose
```

This is useful when MATLAB produces a slightly different raw PDF structure.

Possible diagnostic messages include:

```text
page has no /Pattern resource
```

```text
not a Type-1 tiling pattern
```

```text
pattern is not coloured (/PaintType 1)
```

```text
pattern stream is not 'matrix cm /Image Do'
```

```text
pattern has no /XObject dictionary
```

```text
/ImageName does not point to an image XObject
```

```text
pattern is selected 2 times; refusing ambiguous page
```

```text
no f/f* operation follows the pattern selection
```

```text
unexpected operator before pattern fill: ...
```

```text
current transformation matrix is singular
```

```text
pattern fill covers only ...% of the page
```

---

# Minimum coverage threshold

To avoid modifying small decorative patterns, the script requires the pattern-fill path to cover a minimum fraction of the page.

The default is:

```text
0.50
```

or 50% of the page.

Change it with:

```bash
python fix_matlab_pdf.py E3_Solution_PS.pdf \
    --min-cover 0.40
```

Valid values are between:

```text
0.0
```

and:

```text
1.0
```

Lowering this threshold makes the detector less conservative.

---

# Files skipped automatically

During recursive or directory processing, the collector skips files whose names already end in:

```text
_fixed.pdf
```

or:

```text
.pdf.bak
```

This prevents the script from repeatedly processing its own standard output files and backups.

---

# Password-protected PDFs

Encrypted or password-protected PDFs are skipped.

The script reports:

```text
SKIP  filename.pdf: encrypted/password-protected
```

---

# Structural detection in detail

A repairable pattern must satisfy several conditions.

## 1. The page must have an indirect `/Resources` object

The script reads the page object and finds:

```pdf
/Resources N 0 R
```

It intentionally expects the raw MATLAB variant to store page resources indirectly.

---

## 2. The resources must contain `/Pattern`

The script extracts the page's `/Pattern` dictionary and examines its entries.

For example:

```pdf
/Pattern <<
    /Pat9 9 0 R
>>
```

---

## 3. The pattern must be a Type-1 coloured tiling pattern

The referenced object must contain:

```pdf
/PatternType 1
```

and:

```pdf
/PaintType 1
```

Other pattern types are rejected.

---

## 4. The pattern stream must be simple

The script deliberately accepts a narrow pattern-stream structure:

```pdf
a b c d e f cm
/ImN Do
```

with optional surrounding:

```pdf
q
...
Q
```

This means the pattern is essentially just a transformed image draw.

A more complex pattern stream is rejected rather than guessed at.

---

## 5. The XObject must be an image

The pattern's `/XObject` dictionary is inspected.

The referenced object must have:

```pdf
/Subtype /Image
```

The original image object is reused in the repaired page.

---

## 6. The page must select the pattern with `scn`

The content stream is searched for:

```pdf
/PatN scn
```

The detector currently requires exactly one use of that pattern in the relevant content stream.

Multiple uses are considered ambiguous and are rejected.

---

## 7. A fill must follow the pattern selection

The next relevant painting operation must be:

```pdf
f
```

or:

```pdf
f*
```

Only colour/graphics-state commands and path construction are allowed between the pattern selection and the fill.

Unexpected drawing, text, transformation, image, or graphics-stack operations cause the candidate to be rejected.

---

## 8. The current transformation matrix is reconstructed

Before the pattern paint, the script tracks:

```pdf
q
Q
cm
```

operations to reconstruct the current transformation matrix, or CTM.

This is important because raw MATLAB output may establish page transformations before selecting the raster pattern.

---

## 9. The direct image matrix is derived

The pattern itself contains two transformations:

1. the pattern `/Matrix`;
2. the image matrix inside the pattern stream.

The script composes these into the intended page-space image transformation.

It then converts that transformation into the local coordinate system active at the exact point where the pattern is painted.

This gives the matrix inserted into:

```pdf
a b c d e f cm
/Image Do
```

---

## 10. The pattern-fill path must be sufficiently large

The path between pattern selection and `f`/`f*` is examined.

The script currently recognizes path points made with:

```pdf
m
l
```

and rectangles made with:

```pdf
re
```

It transforms those points into page coordinates and calculates a bounding box.

The candidate must satisfy `--min-cover`.

---

# Repair process in detail

For every accepted pattern:

1. The page's existing embedded image XObject is identified.
2. A unique page-level XObject resource name is created, for example:

   ```text
   /MatlabFix0
   ```

3. That name is added to the page `/XObject` resource dictionary and points to the **existing** image object.
4. The existing raster fill path is left in the content stream.
5. The original `f` or `f*` operator is replaced by:
   - `W n` for `f`;
   - `W* n` for `f*`.
6. A local transformation matrix is applied.
7. The original image XObject is drawn directly.
8. The graphics state is restored.
9. The document is saved to a temporary PDF.
10. The original and repaired pages are rendered and compared.
11. Only after successful verification is the temporary output promoted to the final destination.

---

# Why use a clipping path?

The raster region does not have to be assumed to be a simple rectangle.

MATLAB already constructed the path it wanted to fill.

The repair reuses that exact path as a clip:

```text
original path
     ↓
clip
     ↓
direct image draw
```

This is safer than independently recreating the region based only on width and height.

---

# Why the image quality is preserved

The script does not perform:

```text
PDF image
    ↓
decode to pixels
    ↓
encode as JPEG/PNG
    ↓
insert new image
```

Instead, the page resource dictionary is made to reference the same existing image PDF object.

Conceptually:

```text
pattern
   └── original image object #7
```

becomes:

```text
page
   └── /MatlabFix0 -> original image object #7
```

Therefore the image stream itself is not recompressed by the repair logic.

---

# White-background removal in detail

White-background removal is optional and only considered on pages already identified for raster repair.

The script looks before the first pattern use for a sequence beginning with RGB white:

```pdf
1 1 1 scn
```

followed by a path and an `f` or `f*`.

The path must cover at least:

```text
97%
```

of the page.

Unexpected paint, image, text, transformation, or graphics-stack operators between the white colour selection and the fill cause the candidate to be ignored.

If accepted, only the fill operator is replaced with:

```pdf
n
```

The rest of the page stream is left in place.

---

# Function reference

## `_fmt(x)`

Formats floating-point numbers for insertion into PDF content streams.

Very small values are normalized to zero.

---

## `_matrix_compose(outer, inner)`

Composes two six-element PDF affine matrices:

```text
[a b c d e f]
```

and returns:

```text
outer(inner(point))
```

---

## `_matrix_inverse(m)`

Computes the inverse of a six-element affine matrix.

Returns `None` for a singular matrix.

---

## `_transform(m, x, y)`

Applies a PDF affine matrix to a point.

---

## `_parse_array(text, n)`

Extracts a PDF numeric array and returns exactly `n` floating-point values.

---

## `_balanced_dict_after(text, key)`

Locates the nested `<< ... >>` dictionary immediately following a named PDF dictionary key.

It performs manual nesting-depth tracking rather than assuming dictionaries contain no nested dictionaries.

---

## `_dict_bounds_after(text, key)`

Like `_balanced_dict_after`, but returns the character positions delimiting the dictionary.

This is used when inserting an XObject resource.

---

## `_resource_xref(doc, page)`

Finds the indirect object referenced by the page's `/Resources` entry.

Returns its xref number.

---

## `_pattern_resources(doc, page)`

Reads the page resource dictionary and returns all `/Pattern` resource names and xrefs.

Also returns a diagnostic reason if pattern resources cannot be found.

---

## `_parse_pattern(doc, name, xref)`

Determines whether a pattern matches the target raw MATLAB structure.

It verifies:

- stream object;
- `/PatternType 1`;
- `/PaintType 1`;
- parseable optional `/Matrix`;
- simple `matrix cm /Image Do` pattern stream;
- image resource exists;
- XObject is `/Subtype /Image`.

On success, it returns a `PatternInfo` object.

---

## `_ctm_at(content, pos)`

Reconstructs the PDF current transformation matrix before a given position in the content stream.

The deliberately narrow interpreter tracks:

- `q`;
- `Q`;
- `cm`.

---

## `_path_bbox(segment, ctm)`

Estimates the bounding box of a path segment using:

- `m`;
- `l`;
- `re`.

Points are transformed using the current transformation matrix.

---

## `_coverage_of_bbox(page, bbox_pdf)`

Converts a PDF-coordinate bounding box through PyMuPDF's page transformation and calculates what fraction of the visible page it covers.

---

## `_content_streams(doc, page)`

Returns the page content streams as:

```text
(xref, bytes)
```

pairs.

Unreadable streams are ignored.

---

## `_find_pattern_fill_in_stream(...)`

Looks for the actual use of a parsed pattern in a page content stream.

It:

- finds `/PatN scn`;
- requires one unambiguous use;
- finds the next `f` or `f*`;
- rejects unexpected intervening operators;
- reconstructs the current transformation matrix;
- derives the local direct-image matrix;
- determines path coverage;
- returns a `Repair` description.

---

## `find_repairs(doc, min_cover, diagnose=False)`

Scans every page and every page pattern resource.

Returns:

```python
(repairs, diagnostic_notes)
```

Each accepted pattern produces a `Repair` instance.

---

## `_find_white_fill(...)`

Searches before the first raster-pattern use for MATLAB's large opaque white backdrop.

The candidate must cover at least 97% of the page.

Returns a `WhiteFill` object when found.

---

## `_ensure_page_xobject(...)`

Adds a new name to the page `/XObject` dictionary that points to MATLAB's existing image object.

It does not create a replacement image stream.

---

## `_unique_xobject_name(...)`

Finds a free resource name of the form:

```text
MatlabFix0
MatlabFix1
MatlabFix2
...
```

---

## `_apply_repairs(doc, repairs, remove_white)`

Performs the actual content-stream modification.

For each repair, it:

- adds an image resource alias;
- converts the original fill path into a clip;
- inserts a direct image draw;
- optionally neutralizes the white backdrop.

Replacements are applied from the end of each content stream toward the beginning so earlier byte offsets remain valid.

Returns:

```python
(patterns_fixed, white_fills_removed)
```

---

## `_pix(doc, pno, dpi, alpha=False)`

Renders a page with PyMuPDF and returns:

```python
(width, height, number_of_channels, pixel_bytes)
```

Used by verification.

---

## `_verify(original, fixed, pages, dpi, tolerance)`

Renders the selected pages from the original and repaired PDFs and compares them.

With:

```text
--tolerance 0
```

the pixel byte arrays must be identical.

---

## `collect_inputs(items, recursive)`

Expands:

- explicit PDF files;
- directories;
- simple wildcard-like paths.

It removes duplicates and skips the script's standard `_fixed.pdf` and `.pdf.bak` outputs.

---

## `output_path_for(src, output_dir, suffix)`

Constructs the copied-output destination.

---

## `process_one(...)`

Runs the complete process for one PDF:

1. open;
2. reject encrypted documents;
3. detect repairs;
4. optionally report only;
5. modify;
6. save temporary file;
7. verify;
8. create backup when necessary;
9. move the verified result into place;
10. report the outcome.

Errors are caught and reported without intentionally replacing the original file.

---

## `build_parser()`

Defines the command-line interface.

---

## `main(argv=None)`

Validates arguments, collects PDFs, processes them sequentially, and prints the final summary.

---

# Command-line options

| Option | Meaning |
|---|---|
| `paths` | One or more PDF files, wildcard-like paths, or directories |
| `-r`, `--recursive` | Recurse through directories |
| `--check-only` | Detect only; do not write files |
| `--diagnose` | Explain why patterns match or are rejected |
| `-v`, `--verbose` | Show details for successful matches |
| `--remove-white-background` | Remove MATLAB's separate page-sized white backdrop |
| `--min-cover FLOAT` | Minimum page fraction covered by raster fill; default `0.50` |
| `--suffix TEXT` | Output suffix; default `_fixed` |
| `--output-dir PATH` | Put copied outputs in this directory |
| `--in-place` | Replace matching originals and create `.bak` backups |
| `--no-verify` | Disable render verification |
| `--verify-dpi FLOAT` | Verification render DPI; default `144` |
| `--tolerance INT` | Allowed per-channel render difference, `0–255`; default `0` |
| `--version` | Print script version |

---

# Recommended workflow for a large MATLAB figure collection

## Step 1 — diagnose first

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --check-only \
    --diagnose
```

Confirm that known affected files such as `E3_Solution_PS.pdf` and `E6_Solution_PS.pdf` are reported as matches.

---

## Step 2 — create repaired copies

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive
```

Compile the LaTeX document using the repaired copies and inspect the result.

---

## Step 3 — optionally test transparent backgrounds

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --remove-white-background
```

Check any figures whose surrounding page/background is not white.

---

## Step 4 — switch to in-place operation if desired

After confirming the results:

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --in-place \
    --remove-white-background
```

The `.bak` copies provide a rollback path.

---

# Example batch output

A successful diagnostic may look like:

```text
FOUND /path/E3_Solution_PS.pdf: 1 repairable raw MATLAB pattern fill(s)
      page 1: /Pat9 xref=9 -> /Im7 image xref=7:
      MATCH; paint=f*; coverage=93.8%;
      local-matrix=[900 0 0 -210 2 212]
```

A non-matching PDF may look like:

```text
OK    /path/other_figure.pdf: 0 repairable raw MATLAB pattern fill(s)
      page 1: page has no /Pattern resource
```

At the end of `--check-only` mode:

```text
Found N repairable pattern fill(s) in M of K PDF(s).
```

After a repair run:

```text
Repaired N pattern fill(s) in M of K PDF(s).
```

---

# What the script intentionally does not do

The script does not attempt to:

- repair arbitrary PDF tiling patterns;
- rewrite all MATLAB PDFs;
- detect figures based only on MATLAB metadata;
- rasterise vector text or axes;
- recreate the raster from screenshots;
- recompress the original image;
- remove white pixels from the raster itself;
- interpret arbitrary PDF graphics programs;
- repair password-protected PDFs;
- silently guess when a pattern is structurally ambiguous.

These restrictions are intentional.

---

# Known structural assumptions

The detector is tailored to the raw MATLAB/Qt PDF layout represented by the target sample.

In particular, it assumes:

- page `/Resources` is an indirect object;
- the problematic raster is represented as a page `/Pattern` resource;
- the pattern is `/PatternType 1`;
- the pattern is `/PaintType 1`;
- the pattern stream is essentially one transformed image draw;
- the page selects it with `/PatternName scn`;
- a simple path is then painted with `f` or `f*`;
- the relevant pre-fill transformation can be reconstructed from `q`, `Q`, and `cm`;
- the clipping path can be bounded from `m`, `l`, and/or `re` operations.

If MATLAB changes its exporter again, `--diagnose` is intended to reveal which assumption no longer holds.

---

# Limitations

## Verification and transparency

Normal repair verification renders with an opaque RGB output.

When the optional white backdrop is removed, a page can gain transparency even though its appearance over a white background is unchanged.

The current verification routine compares RGB renders rather than alpha channels.

---

## Narrow PDF parser

The script does not implement the complete PDF graphics language.

Its parsers are purpose-built for the target MATLAB structure.

This is an intentional safety choice.

---

## Coverage is based on a bounding box

The coverage guard uses the bounding box of the detected path rather than calculating the exact filled path area.

This is sufficient for the large raster-region geometry targeted by the script but should not be treated as a general PDF area calculation.

---

## Resource structure

The current implementation expects the page `/Resources` entry to reference an indirect object.

A different MATLAB exporter layout using an inline resource dictionary will be rejected.

---

# Troubleshooting

## `Found 0 repairable pattern(s)`

Run:

```bash
python fix_matlab_pdf.py problem.pdf \
    --check-only \
    --diagnose
```

The rejection reason is more useful than lowering thresholds blindly.

---

## `page has no /Pattern resource`

The file does not expose the target raster as a page pattern resource.

It may:

- have been processed by another PDF application;
- have been exported using a different MATLAB path;
- already have been normalized;
- simply not contain this pathology.

---

## `pattern stream is not 'matrix cm /Image Do'`

The pattern contains more graphics instructions than the current conservative parser accepts.

This should be treated as a new structural variant rather than automatically forcing a repair.

---

## `pattern is selected ... times; refusing ambiguous page`

The same pattern is used more than once.

The script currently refuses to infer which use should be rewritten.

---

## `pattern fill covers only ...%`

The candidate pattern is smaller than `--min-cover`.

If inspection confirms that it is genuinely the problematic MATLAB raster, the threshold can be lowered, for example:

```bash
--min-cover 0.30
```

Do this deliberately rather than making a very low threshold the default.

---

## `verification failed`

The temporary repaired PDF is discarded and the original is left untouched.

Possible next steps:

1. rerun with `--diagnose`;
2. inspect the particular page;
3. try a higher `--verify-dpi` for investigation;
4. use a small `--tolerance` only if the difference is known to come from renderer nondeterminism.

`--no-verify` should not be the first response to an unexplained verification failure.

---

# Suggested LaTeX use after repair

The repaired PDF can be included normally:

```latex
\includegraphics[scale=0.5]{Graphics/CH_Gallery/E3_Solution_PS_fixed.pdf}
```

or by explicit width:

```latex
\includegraphics[width=0.75\textwidth]
    {Graphics/CH_Gallery/E3_Solution_PS_fixed.pdf}
```

The purpose of the repair is to make the raster behave like a normal image XObject under PDF embedding/scaling while retaining the vector annotations.

---

# Safety summary

The safest batch workflow is:

```bash
# 1. Inspect
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --check-only \
    --diagnose

# 2. Create copies
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive

# 3. Compile and visually inspect the LaTeX document

# 4. Only then, if desired, operate in place
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --in-place
```

For transparent page backgrounds:

```bash
python fix_matlab_pdf.py Graphics/CH_Gallery \
    --recursive \
    --in-place \
    --remove-white-background
```

---

# Summary

`fix_matlab_pdf.py` is a targeted normalizer for raw MATLAB/Qt PDFs whose raster layer is painted through a Type-1 tiling pattern.

Its core strategy is:

```text
find raw MATLAB pattern
        ↓
identify its existing image XObject
        ↓
find the exact page fill that paints the pattern
        ↓
reuse the fill path as a clip
        ↓
draw the existing image directly
        ↓
optionally remove MATLAB's white backdrop
        ↓
save to a temporary PDF
        ↓
render-compare original and repaired pages
        ↓
keep the result only if verification succeeds
```

The script is designed to preserve the original figure appearance and vector content while replacing the PDF construct responsible for the scaling/rendering problem.
