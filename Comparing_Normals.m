% Example of normals

disc.R  = 2;
disc.N  = [40,40];
aDisc                 = Disc(disc);
[Pts,Diff,Int,Ind] = aDisc.ComputeAll();    
Interp  = aDisc.ComputeInterpolationMatrix((0:0.02:1)',(0:0.02:1)',true,true);

% boundary indices
bound = Ind.bound;

% Fix differential operators
r = aDisc.Pts.y1_kv;
theta = aDisc.Pts.y2_kv;
safe_r = r ./ (r.^2 + (r==0));
nx = aDisc.M;
Dx = spdiags(cos(theta), 0, nx,nx) * aDisc.Diff.Dy1 - spdiags(safe_r .* sin(theta), 0, nx,nx) * aDisc.Diff.Dy2;
Dy = spdiags(sin(theta), 0, nx,nx) * aDisc.Diff.Dy1 + spdiags(safe_r .* cos(theta), 0, nx,nx) * aDisc.Diff.Dy2;
grad = [Dx; Dy];
% Polar divergence: 
% ∇·w = (1/r)∂_r(r w_r) + (1/r)∂_θ w_θ
%     = (1/r)[ ∂_r (r cos(θ) ) - ∂_θ ( sin(θ) ), ∂_r (r sin(θ)) + ∂_θ ( cos(θ) ) ]    <- We need to
% understand this in terms of differential forms https://math.stackexchange.com/questions/3044642/divergence-in-polar-coordinates
% However, analytically, this should coincide with [Dx Dy]
%div = [Dx Dy];
div = [ spdiags(safe_r,0,nx,nx) * ( aDisc.Diff.Dy1 * spdiags(r,0,nx,nx) * spdiags(cos(theta),0,nx,nx) ...
                                  + aDisc.Diff.Dy2 * spdiags(-sin(theta),0,nx,nx) ), ...
        spdiags(safe_r,0,nx,nx) * ( aDisc.Diff.Dy1 * spdiags(r,0,nx,nx) * spdiags(sin(theta),0,nx,nx) ...
                                  + aDisc.Diff.Dy2 * spdiags( cos(theta),0,nx,nx) ) ];

% Unit outward normals from Cartesian boundary coords
N_bound = size(aDisc.Ind.normal,1);
ptsCart = GetCartPts(aDisc);
x = ptsCart.y1_kv;
y = ptsCart.y2_kv;
rn = hypot(x(bound), y(bound));             % radius
nx = x(bound) ./ rn;        % robust normalize
ny = y(bound) ./ rn;
Nx = spdiags(nx, 0, N_bound, N_bound);
Ny = spdiags(ny, 0, N_bound, N_bound);
% Boundary projector: E_b u = u|_boundary
ib = (1:aDisc.M)';
E_b = sparse(1:N_bound, ib(bound), 1, N_bound, aDisc.M);
normal = [Nx * E_b,  Ny * E_b];

%% Compare normal derivatives
% An easy, radially symmetric function
u = r.^2;                        % Exact ∂u/∂n = (2x,2y) • (x/R,y/R) = 2R = 4
dndu_polar     = Ind.normal * (Diff.grad * u);
dndu_cartesian = normal * (grad * u);

figure(1)
plot( abs(dndu_polar - 2*disc.R), 'DisplayName', '$\left| \texttt{normal} \cdot \texttt{grad} (u) - 2R \right|$')
hold on
plot( abs(dndu_cartesian - 2*disc.R), 'DisplayName', '$\left| \frac{\partial}{\partial n} u - 2R \right|$')
legend('show', 'Interpreter', 'latex');
norm(dndu_polar - dndu_cartesian)

%%
% A non radially symmetric function
u = r.^2 + x;                    % Exact ∂u/∂n = (1+2x,2y) • (x/R,y/R) = (x + 2R^2)/R
dndu_polar     = Ind.normal * (Diff.grad * u);
dndu_cartesian = normal * (grad * u);

figure(2)
plot( abs(dndu_polar - (x(bound)/disc.R + 2 * disc.R) ), 'DisplayName', '$\left| \texttt{normal} \cdot \texttt{grad} (u) -  \frac{x + 2R^2}{R} \right|$')
hold on
plot( abs(dndu_cartesian - (x(bound)/disc.R + 2 * disc.R) ), 'DisplayName', '$\left| \frac{\partial}{\partial n} u - \frac{x + 2R^2}{R} \right|$')
legend('show', 'Interpreter', 'latex');
norm(dndu_polar - dndu_cartesian)

%% What's up?
% It turns out that ∂/∂n = ∂r (can be analytically proved) so this hides
% underneath some truths about what is going on.

norm( normal * grad(:,bound) - Ind.normal * Diff.grad(:,bound), 2)