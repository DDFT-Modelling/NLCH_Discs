# Approximating the singular kernel

We compute the action of the Newtonian kernel as

$$
\begin{align}
	[K \ast \rho] (x) &= \int\limits_{ \Omega } K(x-y) \rho(y) \ \mathrm{d}y
	\approx \int\limits_{ \Omega \setminus B_2 (x;\varepsilon) } K(x-y) \rho(y) \ \mathrm{d}y + \rho(x) \int\limits_{ B_2 (x;\varepsilon) } K(x-y) \ \mathrm{d}y  = \mathbb{M} \rho + \rho \circ \mathtt{G}_\varepsilon.
\end{align}
$$

---
## Main files

* [`Conv_Disc_Intersection.m`](Conv_Disc_Intersection.m) computes $\mathtt{G}_\varepsilon$. Based on the code for [`arXiv.2512.17734`](https://arxiv.org/abs/2512.17734), see also the sister repository [`DiscConv`](https://github.com/DDFT-Modelling/DiscConv).

* [`Singular_Kernel_Conv_Disc.m`](Singular_Kernel_Conv_Disc.m) computes $\mathbb{M}$ and $\mathtt{G}_\varepsilon$ using two possible partitions of the domain $B_2(0;1)$ at each pseudospectral collocation point. The function takes (at most) four arguments: the neighbourhood radius $\varepsilon$, number of collocation points in the first direction $N_x$, number of collocation points in the second direction $N_y$, resolution factor $\alpha$, and the partition option (`moongap` or `vertilune`).

* [`Errors_SingularConv.m`](Errors_SingularConv.m) performs several error tests against many choices of $(\varepsilon,N_x,N_y,\alpha)$. The data for these plots is available at [`Data for plots`](Data%20for%20plots). It includes subroutines to:
	1. Compute and plot the maximum error of the approximation of $K \ast 1$, see examples [`Errors_Factor[10].pdf`](Errors_Resolution/Errors_Factor[10].pdf) and [`Errors_Factor[20].pdf`](Errors_Resolution/Errors_Factor[20].pdf).
	2. Plot swarm plots comparing the approximation errors against different resolution factors $\alpha$, see for example [`Test_Singular_Convolution_Fixed_Swarm[10,1,2,4,6,8,10,16,10].pdf`](Errors_Resolution/Test_Singular_Convolution_Fixed_Swarm[10,1,2,4,6,8,10,16,10].pdf). 
	3. Store a kernel for a given pair of dimensions $(N_x, N_y)$, a fixed radius $\varepsilon > 0$, and one factor $\alpha$ in a structured object. For example, [`Singular_Kernels_Disc_10.mat`](Singular_Kernels_Disc_10.mat) contains the fields:

		a. `I`, `J`, and `G` which are used to evaluate $\mathtt{G}_\varepsilon$.

		b. `NI`, `NJ`, and `NG` which are the numerical evaluations of the functions above at the collocation ponts.

		c. `eps` is the value of $\varepsilon$.

		d. `disc` is a `2DChebClass` disc object with pseudospectral collocation points.

		e. `N`$=(N_x,N_y)$ is the number of collocation points for each direction.

		f. `Level` is a structure that provides, for each factor $\alpha$, the approximation of $\mathbb{M}$.

		g. `tag` identifies the type of partition method used to approximate the kernel; e.g., `MoonGap`.

	4. Plot errors over domain as intensity values at each collocation point, see for example [`Test_Singular_Convolution_Domain[10,1,0.01].pdf`](Errors_Domain/Test_Singular_Convolution_Domain[10,1,0.01].pdf) and [`Test_Singular_Convolution_Domain[10,10,0.01].pdf`](Errors_Domain/Test_Singular_Convolution_Domain[10,10,0.01].pdf).
	5. Plot approximate angles that are generated from each corner of the neighbourhood $B(x;\varepsilon) \cap \Omega$ for $\varepsilon \ll 1$, see for example [`Test_Angles[20].pdf`](Angles/Test_Angles[20].pdf) and [`Test_Angles[100].pdf`](Angles/Test_Angles[100].pdf).

	The same tests were carried out for `VertiLune` and results are included in [`VertiLune Stats`](VertiLune%20Stats).

	

* [`Generate_60x60.m`](Generate_60x60.m) a very condensed version of the previous code that only computes and stores the kernel for $\varepsilon = 10^{-5}$, $N=60$ and one factor.


Note: Kernel files might have to be split (due to file-size limitations in GitHub).

---

## Supplementary folders and files

* [`Plot_Errors_Singular_Conv_Facts.m`](Plot_Errors_Singular_Conv_Facts.m) plots a swarm plot comparing the errors for different resolution factors $\alpha$.

* [`File_Splitter.m`](File_Splitter.m) code for splitting a file into two parts or recombining both files.

* [`Shapes`](Shapes): Code for multishape construction and evaluation. 

* [`Test shapes`](Test%20shapes): Code testing the multishapes. Basic spectral integration is performed to check partitions. 

* [`Data for plots`](Data%20for%20plots): `mat` files produced by [`Errors_SingularConv.m`](Errors_SingularConv.m) to build the plots in [`Errors_Resolution`](Errors_Resolution).


