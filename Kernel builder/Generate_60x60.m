%% Errors for different values of ε and factors (grids in MS) for maximal sensible subdivision

options = struct('Partition', 'MoonGap', 'display', false);

%% 60 x 60 disc
n = 60;
tic
[D_A, MS, errors, Conv, correction] = Singular_Kernel_Conv_Disc(1e-3, n, n, 1.5, options);
toc
% 3 days 7 h 13 min 47 s (285226.841611)

% Display correction factor
ptsCart = GetCartPts(D_A);
tri = delaunay(ptsCart.y1_kv,ptsCart.y2_kv);
trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, correction )

% 40 2: 1e-3
epsilon = 1e-3;
Newtonians = struct();
Newtonians.eps = epsilon;   % This is ε
Newtonians.disc = D_A;      % This is the domain
Newtonians.tag = 'MoonGap';

% Numerical integrals
Newtonians.NI = Conv * ones([n^2,1]);                                  % is the convolution outside [0,1]^2 ∩ N(ε)
Newtonians.NJ = 0.25 * (ptsCart.y1_kv.^2 + ptsCart.y2_kv.^2 - 1.0);    % is the convolution B[0;1] (symbolic)
Newtonians.NG = correction';                                           % is the convolution in N(ε), this is `smaller`: NJ - NI
Newtonians.N = n;                                                      % Number of points per dimension

% Now we add a substruct
Newtonians.Level = {};
Newtonians.Level.Available = [1.5];     % Number of subdivisions per dimension
% Store Convolution matrices
Newtonians.Level.n2  = Conv;

% Update: Newtonian paper arXiv.2512.17734, there is an exact correction
% Add exact kernel values at diagonal
a = vecnorm([ptsCart.y1_kv, ptsCart.y2_kv], 2, 2);        % Radial parts of points for E_ε
E_eps = Conv_Disc_Intersection(a, Newtonians.eps, false); % ε is still computable for double arithmetic
Newtonians.NG = E_eps;


% Store kernel
save('Singular_Kernel_Disc_60.mat', 'Newtonians');
disp('Contents of Singular_Kernel_Disc_60.mat:')
whos('-file', 'Singular_Kernel_Disc_60.mat')

clear('Newtonians')
%load('Singular_Kernel_Disc_60.mat', 'Newtonians')

