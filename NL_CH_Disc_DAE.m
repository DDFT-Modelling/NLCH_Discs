function Rho_t = NL_CH_Disc_DAE(phi_ic,  aDisc, Diff, Ind,  Conv, Conv_D, eta, TimeLine)
    % Solves the Nonlocal Cahn–Hilliard equation with a source 
    % No flux boundary conditions are enforcing using own DAE

    %% Scalar functions
    % F  = @(s) (1+s) .* log(1+s) + (1-s) .* log(1-s);      % Logarithmic potential
    dF = @(s) log(1+s) - log(1-s);                          % Derivative of logarithmic potential
    ddF = @(s) 2 ./ ( 1 - s.^2 );
    Q  = @(s) tanh(0.5 * s);                                % Inverse of dF
    dQ = @(s) 0.5 * sech(0.5 * s).^2;

    %% Retrieve differential operators in space
    grad  = Diff.grad;       div = Diff.div;
    bound = Ind.bound;    normal = Ind.normal;
    Lap    = Diff.Lap;      % Already in Cartesian form
    N = aDisc.M;
    N_bound = size(aDisc.Ind.normal,1);
    % Scale convolutions if needed
    Conv   = eta * Conv;
    Conv_D = eta * Conv_D;

    %% Select submatrices and invert A at boundary indices
    % This is A:
    normal_grad = normal * grad;
    % normal works well in the box, but for the disc this is not well
    % defined: unique(range(normal)) is just a vector of ones
    % So here's the issue: the normal is not defined. There are only
    % sum(nonzeros(normal)) = aDisc.M ones stored
    %
    % Unit outward normals from Cartesian boundary coords
    ptsCart = GetCartPts(aDisc);
    rn = hypot(ptsCart.y1_kv(bound), ptsCart.y2_kv(bound));             % radius
    nx = ptsCart.y1_kv(bound) ./ rn;        % robust normalize
    ny = ptsCart.y2_kv(bound) ./ rn;
    Nx = spdiags(nx, 0, N_bound, N_bound);
    Ny = spdiags(ny, 0, N_bound, N_bound);
    % Boundary projector: E_b u = u|_boundary
    ib = (1:aDisc.M)';
    E_b = sparse(1:N_bound, ib(bound), 1, N_bound, aDisc.M);
    normal_op = [Nx * E_b,  Ny * E_b];
    normal_grad = normal_op * grad;
    % However, we don't need this: In polar coordinates, the normal
    % derivative is equal to ∂r at the boundary points:
    %Dr_b = Diff.Dy1(bound,:);
    normal_grad = Diff.Dy1(bound,:);


    % Multiplying A times the discretisation of the convolution, we obtain B
    B_No_Flux = normal_grad * (Conv + diag( Conv_D )  );
    % We can see that |B|_2 < 1 (40: 0.0929) via norm(B_No_Flux)
    %norm(B_No_Flux)
    
    % Obtain the inverse of A at the boundary:
    A_bound_inv = normal_grad(:,bound)^-1;
    % --------------- ** Before noticing the normal issue ** --------------
    % Here's an issue:  
    % A_bound = normal_grad(:,bound); is diagonally dominant except at two 
    % points: (~0,1) & (~0,-1)
    %
    % plot( abs( ( diag(A_bound) ) ))
    % hold on
    % plot(sum( abs(A_bound - diag( diag(A_bound) ) ), 1 ))
    % plot(sum( abs(A_bound - diag( diag(A_bound) ) ), 2 ))
    % 
    % v = nan(aDisc.M,1);
    % v(bound) = diag( A_bound );
    % trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, v )
    % --------------- ** After noticing the normal issue ** --------------
    % cond(A_bound) ~ 1 with A_bound strictly diagonally dominant

    % To find C just multiply the previous two matrices at the indices of the boundary
    C_bound = A_bound_inv * B_No_Flux(:,bound);
    % --------------- ** Before noticing the normal issue ** --------------
    % We find |C|_2 ≥ 1 in disc: 7e+6
    % --------------- ** After noticing the normal issue ** --------------
    % We find |C|_2 < 1
    norm(C_bound)
    
    %% Auxiliary functions for fixed point
    R   = @(u,d)     Q(C_bound * u + d);
    NR  = @(u,d) u - Q(C_bound * u + d);
    dNR = @(u,d) eye(N_bound) - diag( dQ(C_bound * u + d) ) * C_bound;

    function dNR_k = dNR_blocks(u,d,k)
        z = C_bound * u + d;           % n×k
        J_cell = cell(1,k);
        for i = 1:k
            J_cell{i} = speye(N_bound) - diag( dQ( z(:,i) ) ) * C_bound;
        end
        dNR_k = blkdiag(J_cell{:});    % size (n*m) × (n*m)
    end


    %% Solve the PDE, the RHS of which is given below
    % There is no need to define a mass matrix to enforce BC

    
    Tmax = 1; %10.0; %TimeLine.Pts.y(2);
    %Tmax = 8;

    %opts = odeset('RelTol',10^-4,'AbsTol',10^-4,'Stats','on', 'Jacobian', @JacobiFun,'Mass',diag(mM));
    opts = odeset('RelTol',3e-7,'AbsTol',1e-7,'Stats','on','InitialStep',1e-3, 'MaxStep',Tmax * 0.9);
    opts.Jacobian = @JacobiFun;
    opts.Vectorized = 'on';
    opts.InitialStep = 1e-3;

    dy0 = Lap * (dF(phi_ic) - eta * (Conv*phi_ic + Conv_D .* phi_ic));
    opts.InitialSlope = dy0(~bound);
    
    %d = ode(ODEFcn=@rhs);          d.InitialTime = 0.0;              d.InitialValue = phi_ic(~bound);
    %d.RelativeTolerance = 1e-7;         d.Solver = "cvodesstiff";    %d.Jacobian = @JacobiFun;

    FP_opts = optimoptions('fsolve','Display','off', 'Algorithm','trust-region-dogleg','SpecifyObjectiveGradient', true);
    FP_opts.OptimalityTolerance = 1e-9;
    FP_opts.FunctionTolerance = 1e-9;
    %FP_opts.Display = 'iter';

    charCount = 0;
    tic
    %[~,Phi_t] = ode45(@rhs, 0:TimeLine.yMax/100:TimeLine.yMax, phi_ic(~bound), opts);
    %[~,Phi_t] = ode15s(@rhs, 0:Tmax/99:Tmax, phi_ic(~bound), opts);
    [~,Phi_t] = ode15s(@rhs, TimeLine.Pts.y, phi_ic(~bound), opts);
    %      20 [T=0.12] (F)                      [T = 1]
    % ode15s - 4.8s (807)                        F(0.129)
    % ode45  - 5.1s (305)                        F
    % ode23  - 3.4s (11)   <-  7.2 (15)          F
    % ode78  - 6.0s (6)                          
    % ode89  - 11.s (420) x                      
    % ode113 - 3.9s (1320) <-  3.9 (683)         F
    % ode23t - 7.4s (1152)                      
    % ode23tb - 31.7s (5002) x
    
    % In 20x20 we can run up to T = 0.124. Then the problem becomes too
    % steep. The best solver under this regime is ode113.


    % Sundials (4xslow for easy problem)
    %sol = solve(d,0,Tmax);
    %fh = solutionFcn(d,0,Tmax);
    %Phi_t = fh(0:Tmax/99:Tmax)'; %sol.Solution'; 
    
    % Euler
    %Phi_t = phi_ic(~bound);
    %Phi_t = Phi_t' + Tmax * rhs(0,Phi_t);
    toc

    %   rhs(1e-15, 0.5*ones(N-N_bound,1));      % A wee test that takes 0.047151 s

    %% Now process the solution for it to also contain the domain
    %Rho_t = zeros(1,N);     % rn let's just interpolate once
    % 
    d_bound = A_bound_inv * ( B_No_Flux(:,~bound) * Phi_t' - normal_grad(:,~bound) * dF(Phi_t')  );
    % Find a fixed point
    %rho_bound = R(R(R(zeros(N_bound,1), d_bound), d_bound), d_bound);
    %sprintf('%.2e', norm( rho_bound - R(rho_bound, d_bound), 'fro') )
    rho_bound = zeros(size(d_bound));
    for i = 1:size(d_bound,2)
        d = d_bound(:,i);
        Fixed_Point = @(u) deal(NR(u,d), dNR(u,d));
        x_0 = zeros(size(d));
        x_0 = R(R(R( x_0, d), d), d);
        rho_bound(:,i) = fsolve(Fixed_Point, x_0, FP_opts);
    end


    %Fixed_Point = @(u) deal(NR(u,d_bound), dNR(u,d_bound));             % Run just this one every time to set the parameter
    % rho_bound = fsolve(Fixed_Point, zeros(size(d_bound)), ...
    %                            optimoptions('fsolve', 'Display', 'none','Algorithm','trust-region','SpecifyObjectiveGradient', true));
    Rho_t = zeros(size(d_bound,2), N);
    Rho_t(:,bound)  = rho_bound';
    Rho_t(:,~bound) = Phi_t;



    

    %% Define ODE in time
    function dydt = rhs(t,rho_inner)
        
        % Print current time
        % str = sprintf('%.5e ', t);
        % charCount = charCount + length(str);
        % if charCount >= 139
        %     fprintf('\n');
        %     charCount = 0;
        % end
        % fprintf('%.5e ', t)


        %rho_inner = clip(rho_inner,-1+1e-9, 1-1e-9);

        %% Interior-to-boundary
        % Compute constant vector
        d_bound = A_bound_inv * ( B_No_Flux(:,~bound) * rho_inner - ...
                                   normal_grad(:,~bound) * dF(rho_inner) );
        %size(d_bound)

        % Compute u at bound
        if size(d_bound,2) == 1
            Fixed_Point = @(u) deal(NR(u,d_bound), dNR(u,d_bound));             % Run just this one every time to set the parameter
            x_0 = zeros(size(d_bound));
            x_0 = R(R(R( x_0, d_bound), d_bound), d_bound);
            rho_bound = x_0;
            %rho_bound = fsolve(Fixed_Point, x_0, FP_opts);                       % Better than using just 0 vector in disc
        elseif size(d_bound,2) > 1
            % Fixed_Point = @(u) deal(NR(u,d_bound), dNR_blocks(u,d_bound, size(d_bound,2)));        % This is possible with infinite memory
            rho_bound = zeros(size(d_bound));
            for i = 1:size(d_bound,2)
                d = d_bound(:,i);
                Fixed_Point = @(u) deal(NR(u,d), dNR(u,d));
                x_0 = zeros(size(d));
                rho_bound(:,i) = fsolve(Fixed_Point, x_0, FP_opts);
            end
        end
        %rho_bound = clip(rho_bound,-1+1e-9, 1-1e-9);
        
        
        %
        %plot(rho_bound)
        
        % This was discussed before the fix:
        % Question: Does it work if I directly apply a fixed point
        % iteration?
        % x_0 = zeros(N_bound, size(rho_inner,2));         % Initial point
        % rho_bound = R(R(R( x_0, d_bound), d_bound), d_bound);
        % if norm( rho_bound - R(rho_bound, d_bound), 'fro' ) > 1e-10
        %     rho_bound = R(R(R( rho_bound, d_bound), d_bound), d_bound);
        %     norm( rho_bound - R(rho_bound, d_bound), 'fro' )
        % end
        % It does not for disc, R is not a contraction here!
        

        %% Consolidate full domain information
        % This changes to vectorise code
        rho = zeros(N,size(rho_bound,2));               % [Was (N,1) before vectorisation]
        rho(bound,:)  = rho_bound;                      % [Remove ,: for unvectorised]
        rho(~bound,:) = rho_inner;                      % [Remove ,: for unvectorised]

        %% Compute dynamics
    
        % Compute mu and its Laplacian
        mu = getPotential(rho);
        dydt = Lap * mu;
    
        % no-flux BCs: gives that j.n = 0 on boundary
        % We don't need this extra operator:    Solved using DAE and discarded at the end
        % dydt(bound,:) = normal_grad * mu;        % [Remove ,: for unvectorised]

        %% Project to interior of domain
        dydt = dydt(~bound,:);                          % [Remove ,: for unvectorised]
    end

    function mu = getPotential(phi)
        % the potential is the difference between F' and the nonlocal term
        z = phi;
        % z = clip(phi, -1.0 + 1e-9, 1.0 - 1e-9);
        mu = dF(z) - eta * (Conv * phi + Conv_D .* phi);
    end

    %% Jacobian: Not really useful

    function drhs = JacobiFun(t,rho_inner)
        %% Interior-to-boundary
        % Compute constant vector
        d_bound = A_bound_inv * ( B_No_Flux(:,~bound) * rho_inner - ...
                                   normal_grad(:,~bound) * dF(rho_inner) );
        % Fixed point
        x_0 = zeros(N_bound, 1);         % Initial point
        rho_bound = R(R(R( x_0, d_bound), d_bound), d_bound);
        if norm( rho_bound - R(rho_bound, d_bound), 'fro' ) > 1e-10
            rho_bound = R(R(rho_bound, d_bound), d_bound);
        end
        %% Consolidate full domain information
        rho = zeros(N,1);
        rho(bound)  = rho_bound;
        rho(~bound) = rho_inner;
        
        %% Full Jacobian
        % Spatial part
        z = rho;
        %z = clip(phi, -1.0 + 1e-9, 1.0 - 1e-9);

        Jmu = scalarOperator(ddF(z) - Conv_D) - Conv;
        drhs = Lap * Jmu;
        drhs = drhs(~bound,~bound);
        % Boundary:     We don't need this for the inner points
        %drhs(bound,:) = normal_grad * Jmu;
    end
    function S = scalarOperator(s)
        S = spdiags( s,0,N,N );
    end

end
% Life lesson «If you have a code that works already: don't touch it.»