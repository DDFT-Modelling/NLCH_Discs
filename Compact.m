%% Study of scalings of K
% Initial condition given by a function of compact support

%% Load data
load('Singular_Kernel_Disc_60.mat', 'Newtonians')
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

% Define additional structures in the disc for defining the differential equation:
% Points, differentiation matrices, integration vector, and indices
% giving masks for the boundary
[Pts,Diff,Int,Ind] = aDisc.ComputeAll();    
%grad  = Diff.grad;       div = Diff.div;
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

%% Setup
colores = [255, 200, 87; 186, 45, 11; 86, 22, 67]/255;

% Time interval
tMax = 100;  % 10
n_t  = 400;   % 100 or 400 for T = 100
% Set up a time line where we are currently at 
ge.yMin  = 0.0;    ge.yMax = tMax;    ge.N = n_t;
TimeLine = SpectralLine(ge);
outTimes = TimeLine.Pts.y;
TimeLine.ComputeDifferentiationMatrix;
% Also get a timeline for equilibria
%TimeLong = SpectralLine(struct('yMin', 0.0, 'yMax', 100, 'N', 20));

% Initial condition 
% (C) for box
Y1 = 0.5 * sin( 3 * pi * Pts.y1_kv) .* cos( 3 * pi * Pts.y2_kv) + 0.25;
Y2 = max( abs(Pts.y1_kv - 0.5), abs(Pts.y2_kv-0.5));         % l_\infty norm
Y1(Y2 > 0.36) = 0.0;
% Hat
Gau = @(x,y,a) exp(-( x.^2 + y.^2 - a ).^2 / 0.05^2);
Hat = @(x,y) sqrt( clip(1.0 - x.^2 - y.^2, 0.0, 1.0) ) + 0.5 * ( Gau(x,y,1) + Gau(x,y,-1) - 1.0);
Y1 = Hat(ptsCart.y1_kv,ptsCart.y2_kv);

Y1 = 0.5 * Gau(0.5*ptsCart.y1_kv,0.5*ptsCart.y2_kv, 0) - 0.1;             % (Sombrero)
%s = trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, Y1 ) % Range as it is: [-0.2, 0.5]
%s.EdgeColor = 'none';

phi_ic = Y1;
%aDisc.plot(phi_ic);



%% Solve equation iteratively
Ens  = struct('A',[], 'B',[], 'C',[], 'D',[]);
CRs  = struct('A',[], 'B',[], 'C',[], 'D',[]);
etas = [100, 50, -10, -20];
Fields = fieldnames(Ens);
%
%% ——————————————————————————————————————————————————————————————————— %
% Times for Y1 = Hat(ptsCart.y1_kv,ptsCart.y2_kv);
% odeDAE only works up to T ≤ 4.6e-3
% 
%  M | eta   | ode15s | ode15i |
% |--|-------|--------|--------|
%    | 100   |    8   |   71   | ± 1 in exact
% 20 |  50   |    3   |   13   |
%    | -10   |    .7  |    2   |
%    | -20   |    3   |    8   |
% |--|-------|--------|--------|
%    | 100   |   298  | 29298  |
% 40 |  50   |    53  |   472  |
%    | -10   |    17  |    52  |
%    | -20   |    60  |   229  |
% |--|-------|--------|--------|
%    | 100   |   783  |  1887* | * MaxStep = 0.01
% 60 |  50   |   341  |  1211**|
%    | -10   |   124  |   303  |
%    | -20   |   381  |   963  |
%
%plot([8,3,1,3,298,53,17,60,783,341,124,381])
%plot([71,13,2,8, 29298, 472,52,229]) (gives approx a factor of 3~7)
%
% ——————————————————————————————————————————————————————————————————— %
% Times for Y1 = 0.5 * Gau(0.5*ptsCart.y1_kv,0.5*ptsCart.y2_kv, 0) - 0.1;
% 
%  M | eta   | ode15s | ode15i |
% |--|-------|--------|--------|
%    | 100   |    1*  |   12   |
% 20 |  50   |    4*  |    8   |
%    | -10   |    5*  |    2   |
%    | -20   |    5*  |    6   |
% |--|-------|--------|--------|
%    | 100   |    79* |   278* |
% 40 |  50   |    67* |   193* |
%    | -10   |    50* |   111* |
%    | -20   |    70* |   192* |
% |--|-------|--------|--------|
%    | 100   |   480* |  1839* | * MaxStep = 0.01
% 60 |  50   |   359* |  1266* |
%    | -10   |   250* |   661* |
%    | -20   |   318* |  1246* |
% ——————————————————————————————————————————————————————————————————— %
% Iterate over each field
for i = 1:numel(Fields)
    eta = etas(i);
    % Solve equation to equilibria

    % Solve equation using ode15s
    Phi_to = NL_CH_Integrator_Simple(phi_ic,  aDisc, Diff, Ind,  Conv, Conv_D, dF, ddF, TimeLine, eta, 1 );
    Phi_T = Phi_to(end,:)';
    %Phi_at_t = deval(Phi_to, TimeLine.Pts.y)';
    % In 60 - eta = -20, it works to stop at t = 5.9159 (indx 30) and restart: Different
    % equilibria are reached but this method is consistent with lower dims
    % indx 8 also works

    % Solve equation using ode15i
    %Phi_to = NL_CH_Integrator_DAEi(phi_ic, aDisc, Diff, Ind, Conv, Conv_D, dF, ddF, TimeLine, eta);
    %Phi_T = Phi_to(end,:)';

    % Solve using own DAE: Only use to for very small times.
    %Phi_to = NL_CH_Disc_DAE( phi_ic,  aDisc, Diff, Ind,  Conv, Conv_D, eta, TimeLine);
    %Phi_T = Phi_to(end,:)';

    % norm( normal * grad * (dF(Phi_to(end,:)') - eta * ( Conv * Phi_to(end,:)' + Conv_D .*Phi_to(end,:)') ) )
    

    % Energy
    Energy = (Int * F(Phi_to)') - 0.5 * eta * Int * ( (Conv * Phi_to' + Conv_D .* Phi_to') .* Phi_to');
    %plot(TimeLine.Pts.y, Energy)
    Ens.(Fields{i}) = Energy;

    % Plot solution as an animation
    Out_Name = strcat(['C_eta=',int2str(eta), '.gif']);
    plots_in_disc(Phi_to, aDisc, outTimes, Out_Name, '$\rho(x;t)$')

    % Equilibria
    C_Val_Approx = dF(Phi_T) - eta * (Conv * Phi_T + Conv_D .* Phi_T);
    %aDisc.plot(C_Val_Approx);
    max(C_Val_Approx) - (max(C_Val_Approx) + min(C_Val_Approx))/2

    % Convergence rate: Lemma 2.7 on the L^2 norm
    CR = (Int * (Phi_to - Phi_T')'.^2).^0.5;
    CRs.(Fields{i}) = CR;

    % Modify plot_panels for this:
    Out_Name = strcat(['C',int2str(i), '_Solution_eta=',int2str(eta), '.pdf']);
    plot_panels
end

%% Plot struct
%% Plotting: up to a limited time for graphical purposes

% Colour selection
colour_A = [255, 225, 168]/255;
colour_B = [114, 61, 70]/255;
GRADIENT_flexible = @(n,nn) interp1([1/nn 1],[colour_A;colour_B],n/nn);
G_colours = GRADIENT_flexible((1:7),7);

fig = figure(201);
set(fig, 'WindowStyle', 'normal');
set(fig, 'Units','normalized', 'Position',[0.6 0.8 0.4 0.5])
%set(fig, 'Units','normalized', 'Position',[0.2 0.2 0.4 0.5])

% Plot for each field in struct
Lstyles = {'-','--','-.','-','--','-.','-'};
for i = 1:numel(Fields)
    eta = etas(i);
    if eta > 0
        eta_string = strcat(['$+',int2str(eta), '$']);
    else
        eta_string = strcat(['$',int2str(eta), '$']);
    end

    %t_times = 0:50/200:50;
    t_times = 0:20/200:20;
    y_smooth = interp1(outTimes,Ens.(Fields{i}), t_times,'makima');
    %y_smooth = interp1( outTimes(setdiff(1:end,8)), Ens.(Fields{i})(setdiff(1:end,8)), t_times,'makima'); % remove a tiny artifact
    plot(t_times, y_smooth, 'LineWidth', 1.5, ...
                        'LineStyle', Lstyles{i}, 'DisplayName', eta_string )
    hold on
end

colororder(G_colours)

xlabel('$t$','Interpreter','latex'); 
ylabel( '$\mathcal{E}_\eta(t)$', 'Interpreter','latex');
fontsize(16, "points")
%set(gca, 'XScale', 'log')
lgd = legend('show', 'Interpreter', 'latex', 'Location','northeast');
title(lgd, 'Scaling $\eta$', 'Interpreter', 'latex'); % Title for the legend


set(gca, 'FontName', 'CMR10','TickLabelInterpreter', 'latex');
yticklabels(strrep(yticklabels,'-','$-$'));
xticklabels(strrep(xticklabels,'-','$-$'));

exportgraphics(figure(201), strcat(['NLCH_Energy_',int2str(N1), '.pdf']), 'BackgroundColor','none', 'ContentType', 'vector', 'Resolution', 300)
hold off

%% Plot convergence

fig = figure(301);
set(fig, 'WindowStyle', 'normal');
set(fig, 'Units','normalized', 'Position',[0.2 0.2 0.4 0.5])

% Plot for each field in struct
Lstyles = {'-','--','-.','-','--','-.','-'};
for i = 1:numel(Fields)
    eta = etas(i);
    t_times = 0:50/200:100;
    plot(t_times, interp1(outTimes,CRs.(Fields{i}), t_times,'makima'), 'LineWidth', 1.5, ...
                        'LineStyle', Lstyles{i}, 'DisplayName', strcat(['$',int2str(eta), '$']) )
    hold on
end

colororder(G_colours)

xlabel('$t$','Interpreter','latex'); 
ylabel( '$\| \rho - \rho_\infty\|_{L^2}$', 'Interpreter','latex');
fontsize(16, "points")
%set(gca, 'XScale', 'log')
lgd = legend('show', 'Interpreter', 'latex', 'Location','northeast');
title(lgd, 'Scaling $\eta$', 'Interpreter', 'latex'); % Title for the legend


set(gca, 'FontName', 'CMR10','TickLabelInterpreter', 'latex');
yscale log


% For each CR, we need a curve such that in log scale 
% CR(t) ≤ log(C) - a log(1+t) / 2(1-2a) with C > 0, a in (0,1/2), and t ≥ 1
% in other words, this can be casted as CR(t) ≤ p_1 + p_2 log(1+t)
% Let's pose the following LP:
%
% min_{p} e_T
%  s.t.   Y_t ≤ p_1 - p_2 X_t,   e_T = Y_T - (p_1 - p_2 X_T) + std(Y_T(-5))
%         p_1 ∈ ℝ, p_2 ∈ [0,∞) 
%
% The terminal constraint is artificial and is there just to force the
% model to have a negative slope

% % Prepare variables
% X_t = log(TimeLine.Pts.y(1:end-1) + 1.0);
% Y_t = log(CR(1:end-1));
% % LP constraints: Ax ≤ b
% CR_A = [-ones(size(X_t)), X_t, zeros(size(X_t))];   % size: [N x 3]
% CR_b = -Y_t;
% % Objective
% CR_c = [0, 0, 1];
% % Solve LP
% [p_opt, fval, exitflag] = linprog(CR_c, CR_A, CR_b, [1, -X_t(end), 1], Y_t(end) + std(Y_t(end-5:end)), [-Inf, 0, 0], [], optimoptions('linprog','Display','iter'));
% % 
% %plot(TimeLine.Pts.y, CR)
% %hold on
% p_opt
% The result is often too big... there might be a better way to get this.


exportgraphics(figure(301), strcat(['NLCH_Convergence_',int2str(N1), '.pdf']), 'BackgroundColor','none', 'ContentType', 'vector', 'Resolution', 300)
hold off


%% Additional plots (optional): These plots can be added to the for loop above to obtain the gallery for this example
%plots_in_box(Phi_to, aBox, outTimes,'A_eta=-1.gif', '$\rho(x;t)$')
% Integrate
Mass_Time = Int * Phi_to';
plot(outTimes, Mass_Time, 'LineWidth', 1.5, 'Color', colores(1,:), 'LineStyle', '-', 'Marker','x')


%%
