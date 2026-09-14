function [D_A, MS, errors, Conv, correction] = Singular_Kernel_Conv_Disc(epsilon, Nx, Ny, fact, option)
% Convolution weight with multishapes defined over disc set difference.
% We create the following number of MS for each case:
%       Type       VertiLune    MoonGap
%   Before top:       3 MS       1 MS
%   Top +~full:       5 MS       3 MS
%   f+Embedded:       4 MS       2 MS
    
    arguments
        epsilon double = 1e-3                                               % Radius of neighbourhood
        Nx      double = 10                                                 % Radial collocation grid
        Ny      double = 10                                                 % Angular collocation grid
        fact    double = 1                                                  % Refinement factor of sub domain division
        option  struct = struct('Partition', 'MoonGap', 'display', false)   % Partition method
    end
    
    %----------------------------------------------------------------------
    % Set up standard disc to do the full computation on
    %----------------------------------------------------------------------
    
    g_1 = struct('N', [Nx,Ny], 'R', 1.0, 'Origin', [0.0,0.0]);             % Set up of unit ball
    D_A = Disc(g_1);

    % epsilon cannot be larger than radius
    if epsilon > g_1.R
        epsilon = 0.1 * g_1.R;
    end
    % Valid partition method
    validPartitions = ["MoonGap", "VertiLune"];
    if ~ismember(option.Partition, validPartitions)
        warning('Invalid partition option "%s". Falling back to default: "MoonGap".', option.Partition);
        option.Partition = 'MoonGap';
    end
    %fprintf('Partition method: %s \n', option.Partition)

    % Define convolution kernel
    Kernel = @(y1,y2) 0.25 * log(y1.^2 + y2.^2)/pi;    % One operation less to worry about
    
    % Get cartesian description of disc
    ptsCart = GetCartPts(D_A);

    y1_kv = ptsCart.y1_kv;
    y2_kv = ptsCart.y2_kv;
    Points = [y1_kv, y2_kv];
    
    if option.display
        s = scatter(y1_kv, y2_kv, 'filled');
    end
    

    
    % Convolve a function
    test_1 = @(y1,y2) ones(size(y1));
    conv_1 = @(y1,y2) 0.25 * ( y1.^2 + y2.^2 - 1.0 );    % Exact convolution is known: check jupyter notebook

    %Vals = Kernel(y1_kv, y2_kv);
    %Vals(isinf(Vals) | isnan(Vals)) = -2;    % A small value is required
    %aBox.plot(Vals,{})

    
    % Evaluate function
    fBox = test_1(y1_kv, y2_kv);
    % There might be a way to evaluate the convolution at the test function
    Ione = conv_1(y1_kv, y2_kv);
    
    %----------------------------------------------------------------------
    % Set up epsilon disc (centred at the origin)
    %----------------------------------------------------------------------
    
    g_eps = struct('N', [Nx,Ny], 'R', epsilon, 'Origin', [0.0,0.0]);
    
    %----------------------------------------------------------------------
    % Find the intersection with the epsBox centred at one point
    %----------------------------------------------------------------------

    errors  = zeros(Nx*Ny, 1);     % We are going to store the errors
    experiment = zeros(Nx*Ny, 1);  % How well are we approximating the full integral without adding the bits?
    Conv = zeros(Nx*Ny ,Nx*Ny);    % Store convolution matrix as well
    
    %----------------------------------------------------------------------
    % - loop over all of the points in aBox
    % - Compute the set difference with a small disc
    % - Construct MS 
    % - Use the MS to construct the interpolation
    % - Construct a convolution matrix on aBox
    %----------------------------------------------------------------------
    [nx, ny] = deal( round(fact*Nx), round(fact*Ny) );        % # of divisions in subshapes
    %%
    for i = 1:(Nx * Ny)
        % Define point
        [y1, y2] = deal(y1_kv(i), y2_kv(i));
        % centre disc at [y1;y2];
        g_eps.Origin = [y1;y2];
        D_e = Disc(g_eps);
        
        % Visualise disc centred at (y_1,y_2) across grid
        if option.display
            hold on
            D_e.PlotGrid;
            pause(0.01)
            clf
        end

        % --------------------------------------------------------------
        % --------------------------------------------------------------
        % Compute set difference of main disc and the small disc
        MS = Set_Difference_Discs(D_A, D_e, [nx, ny], struct('Partition', option.Partition, 'display', false));
        % --------------------------------------------------------------
        % --------------------------------------------------------------

        % Plot multishapes
        if option.display
            hold on
            MS.PlotGrid;
            pause(0.2)
        end

        
        %%clf(figure(1))

        
        % Extract Integration weights and Interpolation
        Int = MS.Int;

        %% ---------------------------------------------------------------
        % Test MS
        % ---------------------------------------------------------------
        % Build interpolator from original disc to MS
        Interp = D_A.InterpolationMatrix_Pointwise(MS.Pts.y1_kv, MS.Pts.y2_kv);
        % Evaluate kernel outside the point (y1,y2)
        K_diff_x = Kernel(y1 - MS.Pts.y1_kv, y2 - MS.Pts.y2_kv);
        % Convolution weights to act on f
        Conv(i,:) = (Int .* K_diff_x') * Interp;

        %% Time for some numerical experiments

        % K⦿ ★ f at point i = ★ at MS ❍
        % Compute ★ at MS
        Conv_MS = Conv(i,:) * fBox;

        % Compare
        errors(i) = abs(Ione(i) - Conv_MS);
        correction(i) = Ione(i) - Conv_MS;

        %% Note:
        % It seems that relative errors are quite bad, since the exact
        % integrals are always below 1
        %errors(i) = abs(t_Full(i,:) - (Conv_capBox + Conv_MS)) ./ max(abs(t_Full(i,:)), 1e-6);
        
        % plot( errors ./ (abs(t_Full) + 1e-1 ))
        % aBox.plot( errors(:, logical([1 0 1]) ) ./ max( abs(t_Full(:, logical([1 0 1]) ) ), 1e-5) );
        % aBox.plot( errors ./ max( abs(t_Full), 1e-5) );
    end
    
    
    
end