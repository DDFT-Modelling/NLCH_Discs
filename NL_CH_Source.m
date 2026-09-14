function Phi_t = NL_CH_Source(phi_ic,  aDisc, Diff, Ind,  Conv, Conv_D, dF, ddF, TimeLine, eta, S,B, du )

    % Retrieve differential operators in space
    grad  = Diff.grad;       div = Diff.div;
    bound = Ind.bound;    normal = Ind.normal;
    N = size(Conv,1);  Lap_Space = Diff.Lap;

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
    

    % solve the PDE, the RHS of which is given below
    % note that setting the mass matrix on the boundary allows us to solve
    % algebraic constraints (i.e., the no-flux BC) there.
    mM        = ones([N,1]);
    mM(bound) = 0;
    
    opts = odeset('RelTol',1e-9,'AbsTol',1e-9, ...
                  'Stats','on',   ...
                  'Mass',diag(mM),'MStateDependence','none', 'MassSingular','yes', ...      % Additional options save a bit of time
                  'InitialStep',1e-4, ...       % Allowed to solve the 40 case with more accuracy
                  'Vectorized','on', ...        % Reduced computation times 10 fold
                  'BDF','on' );                 % Had more successful steps when on, I will consider it again later  
    %                  'InitialSlope', dy0, ...      % daeic12 was struggling with this, which makes sense for time 0
    %dy0 = rhs(Tmin,phi_ic);
    opts.InitialSlope = du(0);
    %opts.InitialStep = 1e-8;  % Doesn't really do much
    %opts.NormControl = 'on';  % Finds error first
    %opts.MaxStep = 1e-5; % Cannot be less than 1e-5
    %opts.MaxOrder = 3;   % Impacts performance badly for values ≤ 3
    %aBox.plot(dy0);
    opts.Jacobian = @JacobiFun;
    
    tic
    [~,Phi_t] = ode15s(@rhs, TimeLine.Pts.y, phi_ic, opts);
    toc
   

    % Define ODE in time
    function dydt = rhs(t,phi)
        % Compute the first derivative of mu and apply nonlocal operator
        flux = getFlux(phi);
        % Obtain Laplacian of mu and add the source term
        dydt = div * flux + S(t);
    
        % no-flux BCs: gives that j.n = mu.n on boundary
        dydt(bound,:) = normal * flux + B(t);
    end

    function f = getFlux(phi)
        % the flux is the derivative of the difference between F' and the
        % nonlocality

        f1 = dF(phi) - eta * (Conv * phi + Conv_D .* phi);
        f  = grad * f1;
    end

    function drhs = JacobiFun(t,phi)
        % Spatial part
        Jmu = scalarOperator( ddF(phi) - eta * Conv_D) - eta * Conv;
        drhs = (div * grad * Jmu);
        % Boundary
        drhs(bound,:) = normal * grad * Jmu;
    end

    function S = scalarOperator(s)
        S = spdiags( s,0,N,N );
    end

end
% Life lesson «If you have a code that works already: don't touch it.»


