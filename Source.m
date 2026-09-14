%% Load data
load('Singular_Kernel_Disc_20.mat', 'Newtonians')
%Newtonians

% Retrieve box and number of collocation points
aDisc     = Newtonians.disc;          % This is the domain
[N1, N2] = deal(aDisc.N1, aDisc.N2);
epsilon  = Newtonians.eps;          % This is ε

geom = struct('N', aDisc.NT, 'R', aDisc.R, 'Origin', aDisc.Origin);
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

% Define additional structures in the box for defining the differential equation:
% Points, differentiation matrices, integration vector, and indices
% giving masks for the boundary
[Pts,Diff,Int,Ind] = aDisc.ComputeAll();    
%grad  = Diff.grad;       div = Diff.div;
bound = Ind.bound;    %normal = Ind.normal;
r = aDisc.Pts.y1_kv;
theta = aDisc.Pts.y2_kv;
safe_r = r ./ (r.^2 + (r==0));
nx = aDisc.M;
Dx = spdiags(cos(theta), 0, nx,nx) * aDisc.Diff.Dy1 - spdiags(safe_r .* sin(theta), 0, nx,nx) * aDisc.Diff.Dy2;
Dy = spdiags(sin(theta), 0, nx,nx) * aDisc.Diff.Dy1 + spdiags(safe_r .* cos(theta), 0, nx,nx) * aDisc.Diff.Dy2;
grad = [Dx; Dy];
%div = [Dx Dy];
div = [ spdiags(safe_r,0,nx,nx) * ( aDisc.Diff.Dy1 * spdiags(r,0,nx,nx) * spdiags(cos(theta),0,nx,nx) ...
                              + aDisc.Diff.Dy2 * spdiags(-sin(theta),0,nx,nx) ), ...
        spdiags(safe_r,0,nx,nx) * ( aDisc.Diff.Dy1 * spdiags(r,0,nx,nx) * spdiags(sin(theta),0,nx,nx) ...
                              + aDisc.Diff.Dy2 * spdiags( cos(theta),0,nx,nx) ) ];

Diff.grad = grad;       Diff.div = div;
Lap_Space = Diff.Lap;

% Unit outward normals from Cartesian boundary coords
N_bound = size(aDisc.Ind.normal,1);
ptsCart = GetCartPts(aDisc);
rn = hypot(ptsCart.y1_kv(bound), ptsCart.y2_kv(bound));             % radius
nx = ptsCart.y1_kv(bound) ./ rn;        % robust normalize
ny = ptsCart.y2_kv(bound) ./ rn;
Nx = spdiags(nx, 0, N_bound, N_bound);
Ny = spdiags(ny, 0, N_bound, N_bound);
% Boundary projector: E_b u = u|_boundary
ib = (1:aDisc.M)';
E_b = sparse(1:N_bound, ib(bound), 1, N_bound, aDisc.M);
normal = [Nx * E_b,  Ny * E_b];


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

%% Setup
colores = [255, 200, 87; 186, 45, 11; 86, 22, 67]/255;

% Time interval
tMax = 0.5; %2e-2;  % 10
n_t  = 100;   % 100 or 400 for T = 100
% Set up a time line where we are currently at 
ge.yMin  = 0.0;    ge.yMax = tMax;    ge.N = n_t;
TimeLine = SpectralLine(ge);
outTimes = TimeLine.Pts.y;
TimeLine.ComputeDifferentiationMatrix;



%% Exact solution
u = 0.125 * (1 - cos( exp(2 - TimeLine.Pts.y))) * cos(4*r)';
% Generate a bump
u_t  = @(t)  0.125 * (1 - cos( exp(2 - t))) * cos(4*r);
du_t = @(t) -0.125 * exp(2 - t) * sin( exp(2 - t)) * cos(4*r);
% No bump, just exponential decrease
u_t  = @(t)  0.125 * exp(-t) * cos(4*r.^2);
du_t = @(t) -0.125 * exp(-t) * cos(4*r.^2);

% Initial condition 
phi_ic = u_t(0);
%aDisc.plot(phi_ic);

eta = 1;
% Manufacture source inside the domain
S_t = @(t) ( du_t(t) ...
            - div * ( grad * ...
                           ( dF(u_t(t)) - eta*(Conv*u_t(t) + Conv_D.*u_t(t)) ) ...
               ) );
% Manufacture boundary data
B_t = @(t) ( -normal * grad * ( dF(u_t(t)) - eta*(Conv*u_t(t) + Conv_D.*u_t(t)) ) );

%% Compute solution or try
Phi_to = NL_CH_Source(phi_ic,  aDisc, Diff, Ind,  Conv, Conv_D, dF, ddF, TimeLine, eta, S_t, B_t, du_t );
Out_Name = strcat(['Source_eta=',int2str(eta), '.gif']);
plots_in_disc(Phi_to, aDisc, outTimes, Out_Name, '$\rho(x;t)$')