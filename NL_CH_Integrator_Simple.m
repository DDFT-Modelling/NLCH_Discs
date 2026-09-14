function Phi_t = NL_CH_Integrator_Simple(phi_ic,  aDisc, Diff, Ind,  Conv, Conv_D, dF, ddF, TimeLine, eta, idTmin )

% Check initial time
if nargin <= 10
  idTmin = 1;
end

    % Retrieve differential operators in space
    grad  = Diff.grad;       div = Diff.div;
    bound = Ind.bound;      % Also works with Ind.outR 
    normal = Ind.normal;    % Same as Ind.normalOutR
    Lap    = Diff.Lap;      % Already in Cartesian form
    N = aDisc.M;
    %y1 = aBox.Pts.y1_kv;
    %y2 = aBox.Pts.y2_kv;

    % Unit outward normals from Cartesian boundary coords
    N_bound = size(aDisc.Ind.normal,1);
    ptsCart = GetCartPts(aDisc);
    % Pointwise normals as operators for each dimension
    Nx = spdiags( ptsCart.y1_kv(bound) / aDisc.R, 0, N_bound, N_bound);
    Ny = spdiags( ptsCart.y2_kv(bound) / aDisc.R, 0, N_bound, N_bound);
    % Boundary projector: E_b u = u|_boundary
    ib = (1:aDisc.M)';
    E_b = sparse(1:N_bound, ib(bound), 1, N_bound, aDisc.M);
    normal = [Nx * E_b,  Ny * E_b];
    % However, we don't need this: In polar coordinates, the normal
    % derivative is equal to ∂r at the boundary points:
    Dr_b = Diff.Dy1(bound,:);
    

    % solve the PDE, the RHS of which is given below
    % note that setting the mass matrix on the boundary allows us to solve
    % algebraic constraints (i.e., the no-flux BC) there.
    
    mM        = ones([N,1]);
    mM(bound) = 0;
    
    % Error using daeic12:      Need a better guess y0 for consistent initial conditions. [when using Jac or tight tol]

    
    %opts = odeset('RelTol',10^-4,'AbsTol',10^-4,'Stats','on', 'Jacobian', @JacobiFun,'Mass',diag(mM));
    %opts = odeset('RelTol',10^-9,'AbsTol',10^-9,'Stats','on', 'Mass',diag(mM),'Vectorized','on');
    opts = odeset('RelTol',3e-11,'AbsTol',1e-11, ...
                  'Stats','on',   ...
                  'Mass',diag(mM),'MStateDependence','none', 'MassSingular','yes', ...      % Additional options save a bit of time
                  'Vectorized','on', ...        % Reduced computation times 10 fold
                  'BDF','on' );                 % Had more successful steps when on, I will consider it again later  
    %                  'InitialSlope', dy0, ...      % daeic12 was struggling with this, which makes sense for time 0
    %dy0 = rhs(Tmin,phi_ic);
    %opts.InitialSlope = dy0;
    %aBox.plot(dy0);
    opts.InitialStep = 1e-4;          % Can help sometimes (e.g., 20 - eta = 100)
    opts.Jacobian = @JacobiFun;
    %opts.MaxStep = 0.0001;
    % Chapeau
    %opts.MaxStep = 0.001; % 101714 evals in (60, 50) at 2319s
    %opts.MaxStep = 0.02; % 11859 for 370s in (60, 50), and works at (60,-10)
    %opts.MaxStep = 0.01; %
    % Sombrero
    %opts.MaxStep = 0.005; % (20,100)
    %opts.MaxStep = 0.01;  % (20,~)

    tic
    %[~,Phi_t] = ode15s(@rhs, TimeLine.Pts.y(2:end), phi_ic, opts);
    %[~,Phi_t] = ode15s(@rhs, Tmin:h:Tmax, phi_ic, opts);
    [~,Phi_t] = ode15s(@rhs, TimeLine.Pts.y(idTmin:end), phi_ic, opts);
    %[~,Phi_t] = ode15s(@rhs, idTmin, phi_ic, opts);
    %Phi_t = ode15s(@rhs, TimeLine.Pts.y, phi_ic, opts);                  % Solution struct
    toc
   

    % Define ODE in time
    function dydt = rhs(t,phi)
        % Compute the first derivative of mu and apply nonlocal operator
        mu = getPotential(phi);
        % Obtain Laplacian of mu
        dydt = Lap * mu;
        %dydt = div * grad * mu;            % If used also uncomment 102
    
        % no-flux BCs: gives that j.n = mu.n on boundary
        dydt(bound,:) = Dr_b * mu;
    end

    function mu = getPotential(phi)
        % the potential is the difference between F' and the nonlocal term
        %
        % Approximate derivative: [n]
        z = phi;
        % z = clip(phi, -1.0 + 1e-9, 1.0 - 1e-9);

        mu = dF(z) - eta * (Conv * phi + Conv_D .* phi);
        %mu = 0*dF(z) - eta * (phi);
    end

    function drhs = JacobiFun(t,phi)
        % Spatial part
        Jmu = scalarOperator( ddF(phi) - eta * Conv_D) - eta * Conv;
        drhs = (Lap * Jmu);
        %drhs = (div * grad * Jmu);
        % Boundary
        %drhs(bound,:) = normal * grad * Jmu;
        drhs(bound,:) = Dr_b * Jmu;
    end

    function S = scalarOperator(s)
        S = spdiags( s,0,N,N );
    end

end
% Life lesson «If you have a code that works already: don't touch it.»


