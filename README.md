
[![Hippocratic License HL3-BDS-CL-FFD-LAW-MEDIA-MIL-SV](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-BDS-CL-FFD-LAW-MEDIA-MIL-SV&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/bds-cl-ffd-law-media-mil-sv.html)

# NLCH
Extension for the Nonlocal Cahn–Hilliard Equation with singular potentials: Disc
---

### How do I run tests? ###
 
1. Please run [`AddPaths.m`](AddPaths.m) in the main folder. 
2. Run [`Run_Example.m`](Run_Example.m) for a minimal working example. The solution is depicted in [`MWE.gif`](MWE.gif).
3. Run any main Matlab file in this folder or any of the following:

	* [`Kernel builder`](Kernel%20builder): Code for building spectral element approximation of the Newtonian Kernel. A general-purpose constructor is included in [`Singular_Kernel_Conv_Disc.m`](Kernel%20builder/Singular_Kernel_Conv_Disc.m).

		* [`Shapes`](Kernel%20builder/Shapes): Code for multishape construction and evaluation. The multishape constructor offers two options: `moongap` and `vertilune`. We suggest `moongap`, which provides a minimal partition with smaller, more consistent errors. Each constructor key determines the behaviour of [`Set_Difference_Discs.m`](Kernel%20builder/Shapes/Set_Difference_Discs.m), which relies on the constructors [`MoonGap.m`](Kernel%20builder/Shapes/MoonGap.m) and `LuneShard` or [`Vertilune.m`](Kernel%20builder/Shapes/VertiLune.m), `Shardlet` and `CircularSegment`.
	
			Kernels are corrected in the diagonal employing the exact computation from [`arXiv.2512.17734`](https://arxiv.org/abs/2512.17734), see also the sister repository [`DiscConv`](https://github.com/DDFT-Modelling/DiscConv).

		* [`Generate_60x60.m`](Kernel%20builder/Generate_60x60.m) runs a minimal working example to assemble a kernel object.

	* [`Compressed Kernels`](Compressed%20Kernels): Kernels for $N\in \\{40,50\\}$ that are split into several files due to GitHub's file-size limit.

4. (Optional) If the code requires a kernel that has been split into several files (e.g., `Singular_Kernel_Disc_60_[split_1].mat`), then rebuild it using the code available in [File_Splitter.m](Kernel%20builder/File_Splitter.m).


![Guide of decomposition methods for discs](/Graphical%20decompositions/Decomposing%20Discs.png)

# Files in this folder

A gallery of examples is presented and based on the following scripts:

* [`Compact`](Compact.m): Solves the problem on the unit disc for different scalings. The initial condition is a bowler or a sombrero. An animation is produced using [`plots_in_disc.m`](plots_in_disc.m) and plots for selected times are produced using [`plot_panels.m`](plot_panels.m). The outputs are presented for $N \in \{20,40,60\}$ in [`Galleries_Sombrero`](Galleries_Sombrero/) and [`Galleries_Bowler`](Galleries_Bowler/).

* [`NL_CH_Integrator_Simple.m`](NL_CH_Integrator_Simple.m): Solves the NLCH system using Matlab's own DAE solver for Neumann data. The file includes some suggested ODE configurations. These configurations depend on the MATLAB version since MathWorks modifies its solvers periodically. 
* [`NL_CH_Integrator_DAEi.m`](NL_CH_Integrator_DAEi.m): Solves the NLCH system with a DAEi solver for Neumann data (takes longer times).
* [`NL_CH_Disc_DAE.m`](NL_CH_DAE.m): Solves the NLCH system with a DAE solver for Neumann data (good for small times).


An additional example is tested in [`Source.m`](Source.m), where the equation is tested with a source as in [`NL_CH_Source.m`](NL_CH_Source.m).


---
## Additional files

* [`Comparing_Normals.m`](Comparing_Normals.m) compares different approaches of computing the normal derivative of a function. The original pseudospectral base package provides discretisations for $(\partial_r, \partial_\theta)$ as a gradient operator instead of the cartesian $(\partial_x, \partial_y)$, for which the actual gradient needs to be re-assembled. Similarly, we re-assemble the divergence operator employing a differential forms identity that, although it is analytically identical to the cartesian divergence, provides better approximation errors.

* [`plots_in_disc.m`](plots_in_box.m) returns an animation of a spatio–temporal density.
* [`plot_panels.m`](plot_panels.m) generates density plots.




## Additional GeoGebra files and Python code

The folder [`Graphical decompositions`](Graphical%20decompositions) contains

- Three GeoGebra files that display how to compute several angles required for a VertiLune and a Wedge decomposition, and an interactive construction for the regions required to compute the integral $\mathtt{G}_\varepsilon$.
- A portable vector format file of the diagram that describes how the decompositions take place.
- [`1 - Domain - Spectral Cell.ipynb`](Graphical%20decompositions/1%20-%20Domain%20-%20Spectral%20Cell.ipynb) represents the two-dimensional function that maps the unit box to a cornered cell/bulged square. This is further described in Appendix A of the original manuscript.
- [`2 - Disc Integral.ipynb`](Graphical%20decompositions/2%20-%20Disc%20Integral.ipynb) contains three alternative computations of the integral $I(x) = \int\limits_{ B(0,1) } K(x-y) \,\mathrm{d}y$. Error codes are provided along the first derivation.



---
### Requirements (Matlab versions)

The code was tested using Matlab R2023b, R2024a, and R2025b. The fastest kernel creation times (to date) can be achieved in R2023b.

---

### About `MultiShape`

`MultiShape` is a library developed by Ben Goddard, Rory Mills-Williams, John Pearson, and Jonna Roden. It builds spectral element methods based on the `2DChebClass` library. The baseline package can be found in the public repository [`MultiShape`](https://bitbucket.org/bdgoddard/multishapepublic/src/master/). A detailed presentation can be found in **[1]**.


---

### About `2DChebClass`


`2DChebClass` is a library developed by Andreas Nold and Ben Goddard. It can be used to solve a wide range of (integro-)differential systems in various 1D and 2D geometries. The baseline package can be found in the public repository [`2DChebClass`](https://github.com/NoldAndreas/2DChebClass). A detailed presentation can be found in **[2]**.

---

**[1]** Jonna C. Roden, Rory D. Mills-Williams, John W. Pearson, and Benjamin D. Goddard, 2024 "MultiShape: a spectral element method, with applications to Dynamical Density Functional Theory and PDE-constrained optimization." _IMA Journal of Numerical Analysis,_ drae066. Links: [ArXiv](https://arxiv.org/abs/2207.05589), [IMA JNA](https://doi.org/10.1093/imanum/drae066)


**[2]** Andreas Nold, Benjamin D. Goddard, Peter Yatsyshin, Nikos Savva & Serafim Kalliadasis, 2017 "Pseudospectral methods for density functional theory in bounded and unbounded domains." _Journal of Computational Physics, Elsevier, 334, 639–664. Links: [ArXiv](https://arxiv.org/abs/1701.06182), [J Comp Phys](https://doi.org/10.1016/j.jcp.2016.12.023)
