%% Example of the NLCH with singular potentials

%%  Load box and convolution structures
% Load a SK: 20 × 20 box with 𝜀 = 10^-3
load('Singular_Kernel_Disc_20.mat', 'Newtonians')
%Newtonians

% Retrieve box and number of collocation points
[N1, N2] = deal(Newtonians.N, Newtonians.N);
epsilon  = Newtonians.eps;          % This is ε

geom = struct('N', [Newtonians.N Newtonians.N], 'R', 1.0, 'Origin', [0 0]);
aDisc = Disc(geom);

% For the selected box and value of  we select a convolution matrix based on a subdivision factor:
Newtonians.Level.Available          % Check available matrices
% Select convolution matrix
if N1 == 20
    Conv = Newtonians.Level.n4;         % Name format: 'n' + factor
elseif N1 == 40
    Conv = Newtonians.Level.n2;
elseif N1 == 60
    Conv = Newtonians.Level.n2;
end
% Retrieve additional data
Conv_D = Newtonians.NG;

% Define additional structures in the disc for defining the differential equation:
% Points, differentiation matrices, integration vector, and indices
% giving masks for the boundary
[Pts,Diff,Int,Ind] = aDisc.ComputeAll();
bound = Ind.bound;    normal = Ind.normal;
r = aDisc.Pts.y1_kv;
theta = aDisc.Pts.y2_kv;
safe_r = r ./ (r.^2 + (r==0));
nx = aDisc.M;
% Fix gradient vector (see Comparing_Normals.m)
Dx = spdiags(cos(theta), 0, nx,nx) * aDisc.Diff.Dy1 - spdiags(safe_r .* sin(theta), 0, nx,nx) * aDisc.Diff.Dy2;
Dy = spdiags(sin(theta), 0, nx,nx) * aDisc.Diff.Dy1 + spdiags(safe_r .* cos(theta), 0, nx,nx) * aDisc.Diff.Dy2;
grad = [Dx; Dy];
%div = [Dx Dy];
div = [ spdiags(safe_r,0,nx,nx) * ( aDisc.Diff.Dy1 * spdiags(r,0,nx,nx) * spdiags(cos(theta),0,nx,nx) ...
                              + aDisc.Diff.Dy2 * spdiags(-sin(theta),0,nx,nx) ), ...
        spdiags(safe_r,0,nx,nx) * ( aDisc.Diff.Dy1 * spdiags(r,0,nx,nx) * spdiags(sin(theta),0,nx,nx) ...
                              + aDisc.Diff.Dy2 * spdiags( cos(theta),0,nx,nx) ) ];

% Replace in-built operators
Diff.grad = grad;       Diff.div = div;
Lap_Space = Diff.Lap;

% compute the interpolation matrix from the box points to a uniform
% grid [only for plotting]
Interp = aDisc.ComputeInterpolationMatrix((-1:0.02:1)',(-1:0.02:1)',true,true);
% If that does not work, we can use pointwise coordinates
ptsCart = GetCartPts(aDisc);
tri = delaunay(ptsCart.y1_kv,ptsCart.y2_kv);

% Potential and derivatives
F  = @(s) (1+s) .* log(1+s) + (1-s) .* log(1-s);
dF = @(s) log(1+s) - log(1-s);
ddF = @(s) 2 ./ ( 1 - s.^2 );

% Test derivatives_ ∂/∂x x ≈ 1
%aDisc.plot( Dx * (r.*cos(theta)) );

%% Create a time interval
tMax = 2.0; % Usually T = 5
n_t  = 100;   % often 100
% Set up a time line where we are currently at 
ge.yMin  = 0.0;    ge.yMax = tMax;    ge.N = n_t;
TimeLine = SpectralLine(ge);
outTimes = TimeLine.Pts.y;

%% Define initial condition
%Y1 = 0.5 * sin( 3 * pi * Pts.y1_kv) .* cos( 3 * pi * Pts.y2_kv) + 0.25;
%Y2 = max( abs(Pts.y1_kv - 0.5), abs(Pts.y2_kv-0.5));         % l_\infty norm
%Y1(Y2 > 0.36) = 0.0;
Y1 = 0.5 * sin( 3 * pi * ptsCart.y1_kv) .* cos( 3 * pi * ptsCart.y2_kv) + 0.25;
Y2 = max( abs(ptsCart.y1_kv - 0.5), abs(ptsCart.y2_kv-0.5));
Y1(r > 0.36) = 0.0;

h_a = 0.5;
Molly  = @(y1,y2) fillmissing( (y1.^2 + y2.^2  < 1.0 ) .* exp( -1.0./( 1 - (y1.^2 + y2.^2 ) ) ) , 'Constant', 0);
Molly_a = @(y1,y2) h_a.^(-2) * Molly(y1/h_a, y2/h_a);
H_a = aDisc.ComputeConvolutionMatrix(Molly_a,true);
phi_ic = 40 * (H_a * Y1);
aDisc.plot(phi_ic);

%% Modify kernel? (optional)
ConvL = Conv + (0.02) * H_a;


%% Solve equation
% Select a kernel scaling
eta = -30;
% Now solve
Phi_t = NL_CH_Integrator_Simple(phi_ic,  aDisc, Diff, Ind,  ConvL, Conv_D, dF, ddF, TimeLine, eta, 1 );
Phi_T = Phi_t(end,:)';

% Compute energy
Energy = (Int * F(Phi_t)') - 0.5 * eta * Int * ( (ConvL * Phi_t' + Conv_D .* Phi_t') .* Phi_t');
% Compute approximation of C_* and \delta
C_Val_Approx = dF(Phi_t(end,:)') - eta * (ConvL * Phi_t(end,:)' + Conv_D .* Phi_t(end,:)');
%aBox.plot(C_Val_Approx);
Int * (C_Val_Approx)                % Approx C_*
1-max( abs(Phi_t(end,:)),[],'all')  % Approx \delta

% Visualise
%aDisc.plot(Phi_T);
plot(TimeLine.Pts.y, Energy)
% Animation
plots_in_disc(Phi_t, aDisc, outTimes, 'MWE.gif', '$\rho(x;t)$')