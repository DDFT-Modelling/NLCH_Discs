function SD_Shapes = Set_Difference_Discs(disc_1, disc_2, N, option)
%% ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– %%
%
%             Compute the set difference disc_1 \ disc_2
%
%% ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– %%
    arguments
        disc_1  Disc                                                                   % Closed ball B(O_1; R_1)
        disc_2  Disc                                                                   % Closed ball B(O_2; R_2)
        N (1,2) double = [max(disc_1.N1, disc_2.N1), max(disc_1.N2, disc_2.N2)]        % Number of points in subshapes
        option struct = struct('Partition', 'MoonGap', 'display', false)               % Partition method
    end
    
    %Initialization
    R_1 = disc_1.R;    Origin_1 = disc_1.Origin;
    R_2 = disc_2.R;    Origin_2 = disc_2.Origin;

    % Validation
    if (R_1 < R_2)
        % This is just an implementation issue. Could be extended in the
        % future.
        exc = MException('Set_Difference_Discs:Implementation','First disc should be larger than second disc.');
        throw(exc);
    end

    
    validPartitions = ["MoonGap", "VertiLune"];
    if ~ismember(option.Partition, validPartitions)
        warning('Invalid partition option "%s". Falling back to default: "MoonGap".', option.Partition);
        option.Partition = 'MoonGap';
    end
    %fprintf('Partition method: %s \n', option.Partition)

    % Signed coordinate distances:
    dx = Origin_2(1) - Origin_1(1);    dy = Origin_2(2) - Origin_1(2);
    % Euclidean distance
    d = sqrt( dx^2 + dy^2 );
    % Compute angle raised from O_1 to O_2
    theta = atan2(dy,dx);

    % Choose a coordinate shift
    shift = Origin_1;

    %% Compute intersection
    %% ————————————————————————————————————————————————————————————————— %%
    % First we determine if any patological cases arise: 
    % (1) Empty sets
    % (2) One-point sets
    % (3) O_1 is contained in O_2

    % Empty cases:
    % - If shapes overlap and have the same size
    % - If distance is infinity
    % In such cases: return empty set.
    check = ( d < 1e-17 && abs(R_1 - R_2) < 1e-17 )  ||  (d==inf);
    if check
        SD_Shapes = ArbitraryIntersection();
        cprintf('String', 'Empty set.\n')
    end
    
    % One point sets:
    % Return the same disc. A warning can be given.
    check = ( abs(d - (R_1 + R_2) ) < 1e-17 );
    if check
        % Compute point of intersection:
        x_I = Origin_1(1) + R_1 * dx /d;
        y_I = Origin_1(2) + R_1 * dy /d;

        SD_Shapes = disc_1;
        message = sprintf('One point intersection at [%.2f, %.2f].\n', x_I, y_I);
        cprintf('String', message)
    end

    % O_1 is contained in O_2: Empty set
    check = ( R_2 > R_1 ) && (d + R_1 < R_2);
    if check
        SD_Shapes = ArbitraryIntersection();
        cprintf('String', 'Empty set.\n')
    end

    %% ————————————————————————————————————————————————————————————————— %%
    % Any other instance must intersect a set of nonempty interior
    check = (d < R_1 + R_2);
    if check
        % Preprocess shapes to have additional properties (rotation & shift)
        % [No need: radial symmetry allows us to assume new coordinate system]
        %
        % Aux_Shapes(1).Shape = disc_1;
        % D_1 = ArbitraryIntersection(Aux_Shapes);
        % Aux_Shapes(1).Shape = disc_2;
        % D_2 = ArbitraryIntersection(Aux_Shapes);
        if option.display 
            disc_1.PlotGridLines;
            disc_2.PlotGridLines;
        end
        % 
        % % Shift and rotate to deal with discs not centred at [0,0] and [d,0]
        % D_1.ShiftPts(-shift);
        % D_2.ShiftPts(-shift);        D_2.RotatePts(pi-theta);
        % 
        % ptsCart = GetCartPts(D_1);
        % s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
        % ptsCart = GetCartPts(D_2);
        % s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
        % hold on

        % We assume that D_2 is always on the left of D_1. The code above
        % allows for it
        %check(1) = ( d^2 + R_2^2 >= R_1^2 );  % Centre is not contained
        %check(2) = (d < R_1);                 % Centre is contained
        check(1) = true;                      % Area before top is contained (has to happen)
        check(2) = (d^2 + R_2^2 < R_1^2);     % Top is fully contained
        check(3) = (d < R_1 - R_2);           % Fully contained

        Position = max(find(check));

        % Generate shapes according to position
        switch Position
            %% Inclusion up to top
            case 1
                % Number of shapes depends on partition method
                if option.Partition == "MoonGap"
                    % One shape - Simple MoonGaps
                    geom.N = N;    geom.R_1 = R_1;    geom.R_2 = R_2;    geom.d = d;    geom.s = -1;
                    MG = MoonGap(geom);
                    
                    %MG.PlotGridLines;
                    %ptsCart = GetCartPts(MG);
                    %s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
                    Pre_Shapes(1).Shape = MG;
                elseif option.Partition == "VertiLune"
                    % Three shapes - 1 VertiLune + 2 CircularSegments
                    geom = struct('N', N, 'R_l', R_2, 'R_r', R_1, 'd', d);
                    VL = VertiLune(geom);
                    % Vertilune assumes everything is centred on the left
                    % circle at the origin
                    VL.Origin = [-d,0];
                    Pre_Shapes(1).Shape = VL;

                    % Apothem is given by VertiLune
                    geom = struct('N', N, 'R', R_1, 'd', VL.y_I);
                    Pre_Shapes(2).Shape = CircularSegment(geom);    % top
                    geom.d = -VL.y_I;
                    Pre_Shapes(3).Shape = CircularSegment(geom);    % bottom

                end
            %% Top included but not compactly contained
            case 2
                if option.Partition == "MoonGap"
                    % Three shapes - 1 MoonGap + 2 LuneShards
                    geom.N = N;    geom.R_1 = R_1;    geom.R_2 = R_2;    geom.d = d;    geom.s = -1;
                    Pre_Shapes(1).Shape = MoonGap(geom);      % MoonGap
                    Pre_Shapes(3).Shape = LuneShard(geom);    % Lower LuneShard
                    geom.s = 1;
                    Pre_Shapes(2).Shape = LuneShard(geom);    % Upper LuneShard

                elseif option.Partition == "VertiLune"
                    % Five shapes - 1 VertiLune + 2 CircularSegments + 2 Shardlets
                    geom = struct('N', N, 'R_l', R_2, 'R_r', R_1, 'd', d);
                    VL = VertiLune(geom);
                    VL.Origin = [-d,0];
                    Pre_Shapes(1).Shape = VL;

                    % Apothem is given by VertiLune
                    geom = struct('N', N, 'R', R_1, 'd', VL.y_I);
                    Pre_Shapes(2).Shape = CircularSegment(geom);    % top
                    geom.d = -VL.y_I;
                    Pre_Shapes(3).Shape = CircularSegment(geom);    % bottom

                    % Bits missing
                    geom = struct('N', N, 'R_1', R_1, 'R_2', R_2, 'd', d, 's', 1);
                    Pre_Shapes(4).Shape = Shardlet(geom);    % top shardlet
                    geom.s = -1;
                    Pre_Shapes(5).Shape = Shardlet(geom);    % bottom shardlet
                end
            %% Fully contained disc
            otherwise
                if option.Partition == "MoonGap"
                    % Two shapes - Two MoonGaps (one rotated)
                    geom.N = N;    geom.R_1 = R_1;    geom.R_2 = R_2;    geom.d = d;    geom.s = -1;
                    Pre_Shapes(1).Shape = MoonGap(geom);      % MoonGap
                    geom.N = N;    geom.R_1 = R_1;    geom.R_2 = R_2;    geom.d = d;    geom.s = 1;
                    Aux_Shapes(1).Shape = MoonGap(geom);      % MoonGap
                    ToFlip = ArbitraryIntersection(Aux_Shapes);
                    ToFlip.ReflectPtsYAxis;
                    Pre_Shapes(2).Shape = ToFlip;

                elseif option.Partition == "VertiLune"
                    % Four shapes - 2 VertiLunes + 2 CircularSegments
                    geom = struct('N', N, 'R_l', R_2, 'R_r', R_1, 'd', d);
                    VL = VertiLune(geom);
                    VL.Origin = [-d,0];
                    Pre_Shapes(1).Shape = VL;

                    % Apothem is given by VertiLune
                    geom = struct('N', N, 'R', R_1, 'd', VL.y_I);
                    Pre_Shapes(2).Shape = CircularSegment(geom);    % top
                    geom.d = -VL.y_I;
                    Pre_Shapes(3).Shape = CircularSegment(geom);    % bottom

                    % We need to rotate the other VertiLune
                    geom = struct('N', N, 'R_l', R_2, 'R_r', R_1, 'd', d, 's', -1);
                    VL = VertiLune(geom);
                    Pre_Shapes(4).Shape = VL;
                end
        end
        
        % Now return to original coordinate system
        ToProcess = ArbitraryIntersection(Pre_Shapes);
        ToProcess.RotatePts(theta-pi);
        ToProcess.ShiftPts(shift);

        if option.display 
            ptsCart = GetCartPts(ToProcess);
            s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
        end

        SD_Shapes = ToProcess;

    end
    

end