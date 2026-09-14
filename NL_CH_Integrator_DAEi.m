function Phi_t = NL_CH_Integrator_DAEi(phi_ic, aDisc, Diff, Ind, Conv, Conv_D, dF, ddF, TimeLine, eta)

% It moves from 0 but only marginally. Seems I will have to use the fixed
% point method.

    grad   = Diff.grad;  
    div    = Diff.div;
    bound  = Ind.bound;
    normal = Ind.normal;
    Lap    = Diff.Lap;      % Already in Cartesian form
    N = aDisc.M;

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
    % However, we don't need this: In polar coordinates, the normal
    % derivative is equal to ∂r at the boundary points:
    Dr_b = Diff.Dy1(bound,:);


    % Define residual function for ode15i
    function F = residualFun(t, phi, dphi)
        % chemical potential
        mu = dF(phi) - eta * (Conv * phi + Conv_D .* phi);
        % Obtain Laplacian of mu
        d2mu = Lap * mu;
        %d2mu = div * grad * mu;          % If used also uncomment 47 & 67

        % Interior equations
        F = dphi - d2mu;

        % Boundary equations: gives that j.n = mu.n on boundary
        F(bound,:) = Dr_b * mu;
    end

    % Initial guess for consistent initial conditions
    %dphi_ic = div * grad* (dF(phi_ic) - eta * (Conv*phi_ic + Conv_D .* phi_ic));        % guess zero time derivative
    dphi_ic = Lap * (dF(phi_ic) - eta * (Conv*phi_ic + Conv_D .* phi_ic));

    % Make them consistent with constraints
    [phi_0, dphi_0] = decic(@residualFun, TimeLine.yMin, phi_ic, [], dphi_ic, []);

    % Solve
    opts = odeset('RelTol',3e-11,'AbsTol',1e-11, ...
                  'Stats','on','Jacobian',@JacobiFun, 'Vectorized','on');
    opts.MaxStep = 0.01;

    tic
    %sol = ode15i(@residualFun, TimeLine.Pts.y, phi_0, dphi_0, opts);
    [~,Phi_t] = ode15i(@residualFun, TimeLine.Pts.y, phi_0, dphi_0, opts);
    toc

    % Jacobian of residual (optional, helps performance)
    function [J_y, J_yp] = JacobiFun(t, phi, dphi)
        % dF/dphi part
        Jmu = scalarOperator(ddF(phi) - eta * Conv_D) - eta * Conv;

        % Residual is dphi - ∆mu, so wrt phi:
        %J_y = -div * grad * Jmu;
        J_y = -(Lap * Jmu);

        % Boundary rows
        J_y(bound,:) = Dr_b * Jmu;

        % Jacobian of dphi
        %mM = ones(N,1);
        %mM(bound) = 0;
        %J_yp = scalarOperator(mM);       % 1 on interior, 0 on boundary
        J_yp = scalarOperator(double(~bound));
    end


    function S = scalarOperator(s)
        S = spdiags( s,0,N,N );
    end

end
