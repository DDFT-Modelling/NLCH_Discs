function E = Conv_Disc_Intersection(a, epsilon, asymp)
% E = E_np(a, epsilon, asymp)
% Stable E(a; ε) for small ε, with a in [0,+∞).
%
% a       : scalar or array (double)
% epsilon : scalar, typically epsilon < 0.5
% asymp   : logical, if true use asymptotic expansion in the
%           transition region (recommended for epsilon < 1e-6)
%
% NOTE: Uses polylog(2, z) -> requires Symbolic Math Toolbox.
%       If you don't have it, replace Li_2() with your own
%       numerical dilogarithm implementation.

    if nargin < 3
        asymp = false;
    end

    a       = double(a);
    epsilon = double(epsilon);

    if numel(epsilon) ~= 1
        error('epsilon must be a scalar.');
    end

    th = 1e-13;        % threshold for "equality"

    % --- Masks for the three regions -------------------------------------
    maskL = (a <= 1.0 - epsilon);   % a ≤ 1 - ε
    maskR = (a >= 1.0 + epsilon);   % a ≥ 1 + ε
    maskM = ~(maskL | maskR);       % 1 - ε < a < 1 + ε

    E = zeros(size(a));             % already covers maskR

    % --- Left region: a ≤ 1 - ε -----------------------------------------
    if any(maskL(:))
        E(maskL) = epsilon^2 .* (log(epsilon^2) - 1.0);
    end

    % --- Transition region: 1 - ε < a < 1 + ε ---------------------------
    if any(maskM(:))
        a_mid = a(maskM);

        if asymp
            % Map a ∈ (1-ε, 1+ε) to λ ∈ (0, 1)
            lam = (a_mid - (1.0 - epsilon)) ./ (2.0 * epsilon);

            % Approximate angle φ(λ)
            phi = acos(1.0 - 2.0 .* lam) ...
                + sqrt(lam .* abs(1.0 - lam)) .* ...
                  (epsilon + 0.75 * (1.0 - 2.0 .* lam) * epsilon^2);

            % Leading term
            Emid = (pi - phi) .* epsilon^2 .* (log(epsilon^2) - 1.0) / pi;

            % Branch masks in λ
            lamL = lam < 0.5;       % corresponding to a < 1
            lamR = lam > 0.5;       % corresponding to a > 1

            % --- a < 1 branch -------------------------------------------
            lamL_vals = lam(lamL);
            h1 = 0.25 * (1.0 - 2.0 .* lamL_vals) .* ...
                     sqrt(lamL_vals .* (1.0 - lamL_vals)) / pi;
            h2 = 0.25 * (1.0 - 2.0 .* lamL_vals) .* ...
                 ( (1.0 - 2.0 .* lamL_vals) .* acos(1.0 - 2.0 .* lamL_vals) ...
                   - 3.0 * sqrt(lamL_vals .* (1.0 - lamL_vals)) ) / pi;

            FcorrL = h1 .* (2.0 * epsilon^2 * log(epsilon)) ...
                   + h2 .* (epsilon^2);

            Emid(lamL) = Emid(lamL) + 8.0 .* FcorrL;

            % --- a = 1 branch -------------------------------------------
            lam1 = abs(lam - 0.5) <= th;
            if any(lam1)
                F1 = ( 6.0 * epsilon^3 * log(epsilon) ...
                       - 5.0 * epsilon^3 ) / (18.0 * pi);
                Emid(lam1) = F1;
            end

            % --- a > 1 branch -------------------------------------------
            lamU = 1.0 - lam(lamR);    % symmetry
            h1 = 0.25 * (1.0 - 2.0 .* lamU) .* ...
                     sqrt(lamU .* (1.0 - lamU)) / pi;
            h2 = 0.25 * (1.0 - 2.0 .* lamU) .* ...
                 ( (1.0 - 2.0 .* lamU) .* acos(1.0 - 2.0 .* lamU) ...
                   - 3.0 * sqrt(lamU .* (1.0 - lamU)) ) / pi;

            FcorrR = h1 .* (2.0 * epsilon^2 * log(epsilon)) ...
                   + h2 .* (epsilon^2);

            Emid(lamR) = Emid(lamR) + 8.0 .* FcorrR;
        else
            % Exact formulas via F_np / φ_from_np
            nMid = numel(a_mid);
            Emid = zeros(size(a_mid));
            for k = 1:nMid
                ak  = a_mid(k);
                phi = phi_from_np(ak, epsilon);
                Emid(k) = (pi - phi) * epsilon^2 * (log(epsilon^2) - 1.0) / pi;
                Emid(k) = Emid(k) + 8.0 * F_np(ak, epsilon);
            end
        end

        E(maskM) = Emid;
    end

    % --- Final scaling ---------------------------------------------------
    E = 0.25 * E;
end


% ========================================================================
% Helper functions (local to this file)
% ========================================================================

function val = isclose(x, y, th)
    % Rough equivalent of numpy.isclose for scalars
    val = abs(x - y) <= th + th * abs(y);
end


function s_out = s_np(a, theta)
    th = 1e-13;

    % Stable computation of s(theta)
    sin_t = sin(theta);
    cos_t = cos(theta);

    if theta == 0.0
        sin_t = 0.0; cos_t = 1.0;
    elseif 2.0 * theta == pi
        sin_t = 1.0; cos_t = 0.0;
    elseif 2.0 * theta == 3.0 * pi
        sin_t = -1.0; cos_t = 0.0;
    elseif theta == pi
        sin_t = 0.0; cos_t = -1.0;
    elseif theta == 2.0 * pi
        sin_t = 0.0; cos_t = 1.0;
    elseif (sin(theta) * a == 1.0) && (a > 1.0)
        if cos_t < 0.0
            sin_t = 1.0 / a;
            cos_t = -sqrt(a * a - 1.0) / a;   % π - α
        else
            sin_t = 1.0 / a;
            cos_t =  sqrt(a * a - 1.0) / a;   % α
        end
    elseif (sin(theta) * a == -1.0) && (a > 1.0)
        sin_t = -1.0 / a;
        cos_t =  sqrt(a * a - 1.0) / a;       % 2π - α
    end

    R = 1.0 - (a * a) * (sin_t * sin_t);
    if (abs(sin(theta)) * a == 1.0) && (a > 1.0)
        R = 0.0;
    end

    if R < -th
        s_out = 0.0;
        return;
    end

    if abs(R) <= th
        s_out = -a * cos_t;
    else
        s_out = -a * cos_t + sqrt(R);
    end

    if a == 1.0
        if cos_t >= 0.0
            s_out = 0.0;
        else
            s_out = -2.0 * cos_t;
        end
    end
end


function phi = phi_from_np(a, epsilon)
    th = 1e-13;

    c = 1.0 - a * a - epsilon * epsilon;
    c = c / (2.0 * a * epsilon);

    if a == 1.0 - epsilon          % cos φ = 1
        phi = 0.0;
    elseif a == 1.0 + epsilon      % cos φ = -1
        phi = pi;
    elseif isclose(a * a, 1.0 + epsilon * epsilon, th)
        % cos φ = -ε/sqrt(1 + ε^2)
        phi = atan(epsilon) + 0.5 * pi;
    elseif isclose(a * a, 1.0 - epsilon * epsilon, th)
        % cos φ = 0
        phi = 0.5 * pi;
    elseif a == 1.0                % cos φ = -ε/2
        phi = acos(-0.5 * epsilon);
    else
        phi = acos(c);
    end
end


function phi = Phi_np(a, theta)
    % Variable transformation
    s_theta = s_np(a, theta);
    L_theta = (s_theta * s_theta - 1.0 - a * a) / (2.0 * a);   % [-1,1]
    if a == 1.0
        L_theta = 0.5 * s_theta * s_theta - 1.0;
    end
    phi = 0.5 * acos(L_theta);                                 % [0, π/2]
end


function T = F_np(a, epsilon)
    th = 1e-13;

    % Variable transformation
    theta = phi_from_np(a, epsilon);
    phi   = Phi_np(a, theta);

    if a > 1.0
        % α activates
        alpha = asin(1.0 / a);

        % Exact evaluation at breaking point
        if isclose(a * a, 1.0 + epsilon * epsilon, th)
            phi   = 0.5 * (pi - atan(epsilon));
            alpha = 0.5 * pi - atan(epsilon);
        end

        % Auxiliary angle = Φ(α)
        omega = 0.25 * (2.0 * alpha + pi);
    end

    % Functional evaluation
    if isclose(a, 1.0 - epsilon, th)
        % At interval extremes, the mass is zero
        T = 0.0;
    elseif (a > 1.0 - epsilon) && (a < 1.0)
        % One continuous interval of existence
        T = G_np(a, phi) - (1.0 - a * a) * pi;
    elseif isclose(a, 1.0, th)
        % One functional evaluation
        T = G_np(1.0, Phi_np(1.0, phi_from_np(1.0, epsilon)));
    elseif (a > 1.0) && (a * a < 1.0 + epsilon * epsilon)
        % Two intervals of existence and correct branch selection
        T = G_np(a, phi) - 2.0 * G_np(a, omega) - 2.0 * pi * log(a);
    elseif (a * a >= 1.0 + epsilon * epsilon)
        % One interval of continuity, no α involved
        phi = Phi_np(a, theta + pi);
        if isclose(a * a, 1.0 + epsilon * epsilon, th)
            phi = 0.5 * (pi - atan(epsilon));
        end
        % Principal boundary value: 2 Im Li_2(a+0i) = -2π log(a)
        T = -2.0 * pi * log(a) - G_np(a, phi);
        if isclose(a, 1.0 + epsilon, th)
            % Φ(φ+π) = π/2 and integral cancels out in the right branch
            T = 0.0;
        end
    else
        T = 0.0;
    end

    % Scale
    T = T / (pi * 8.0);
end


function G = G_np(a, phi)
    th = 1e-13;

    % Angular quantities
    cosphi  = cos(phi);
    cos2phi = cos(2.0 * phi);
    sin2phi = sin(2.0 * phi);

    if isclose(2.0 * phi, pi, th)
        cosphi  = 0.0;
        cos2phi = -1.0;
        sin2phi = 0.0;
    end
    if isclose(phi, 0.0, th)
        cosphi  = 1.0;
        cos2phi = 1.0;
        sin2phi = 0.0;
    end

    % --- Special cases ---------------------------------------------------
    % G(1; φ)
    if isclose(a, 1.0, th)
        if isclose(cosphi, 0.0, th)
            G = 0.0;
            return;
        else
            z = -exp(2i * phi);
            G = 2.0 * imag(Li_2(z)) ...
              + 2.0 * (1.0 - log(2.0 * abs(cosphi))) * sin2phi;
            return;
        end
    end

    % G(a; 0)
    if isclose(phi, 0.0, th)
        G = 0.0;
        return;
    end

    % G(a; (2α+π)/2 )
    if a > 1.0
        alpha = asin(1.0 / a);
        % Exact case: 4φ == 2α + π
        if isclose(4.0 * phi, 2.0 * alpha + pi, th)
            % Dilog term
            z   = -a * exp(2i * phi);
            T1  = 2.0 * imag(Li_2(z));
            % Angular term
            T2  = (1.0 - a * a) * alpha;
            % Log term
            T3  = (2.0 - log(a * a - 1.0)) * sqrt(a * a - 1.0);
            G   = T1 + T2 + T3;
            return;
        end
    end

    % --- General case ----------------------------------------------------
    z   = -a * exp(2i * phi);
    T1  = 2.0 * imag(Li_2(z));

    ang = angle(1.0 - z);
    T2  = (1.0 - a * a) * (2.0 * phi - ang);

    % Stable log term: 1 + a^2 + 2 a cos 2φ
    l_a = (a - 1.0)^2 + 4.0 * a * (cosphi * cosphi);
    T3  = a * (2.0 - log(l_a)) * sin2phi;
    if isclose(sin2phi, 0.0, th)
        T3 = 0.0;
    end

    G = T1 + T2 + T3;
end


function y = Li_2(z)
    % Dilogarithm Li_2(z) via polylog(2,z).
    % Requires Symbolic Math Toolbox.
    y = double(polylog(2, z));
end
