%% Errors for different values of ε and factors (grids in MS) employing moongaps
% Warning: If you run the following code from scratch, it will take a
% couple of hours to finish. Average and total computing times are reported
% for each experiment.

% Extremely recomend to store working space: 'autosave(10,'workspace.mat')'
% Command to be stopped with 'autosave stop' followed by 'autosave delete'

options = struct('Partition', 'MoonGap', 'display', false);
%options = struct('Partition', 'VertiLune', 'display', false);

Range_Epsilons = [logspace(-7,-2, 12), logspace(-2,-1, 8)*5.85/2.01];
%% ----------------------------------------- n = 10, n_i in [10 ... 80] ----------------------------------------- %
factors = [1,2,4,6,8,10,16];

i = 1;
for a = factors %  3h 41 min    1.58 min
    j = 1;
    %          Time         Mean 
    %   1    26.91 s       1.35 s
    %   2     1.69 min     5.06 s
    %   4     6.65 min    19.95 s
    %   6    15.29 min    45.86 s
    %   8    29.82 min     1.49 min
    %  10    45.11 min     2.26 min
    %  16     2h 2 min     6.10 min

    for e = Range_Epsilons
        tic;
        [D_A, MS, errors, Conv, correction] = Singular_Kernel_Conv_Disc(e, 10, 10, a, options);
        T(i,j) = toc;  % pair 1: toc
        
        Abs_10_10{i,j} = errors;
        Cor_10_10{i,j} = correction;
    
        j = j + 1;
    end
    if i == 1
        [sum(T(i,:)), mean(T(i,:))]
    else
        [sum(T(i,:))/60, mean(T(i,:))]
    end
    i = i+1;
end
[sum(T(:)), mean(T(:))]

save('Abs_10_10.mat', 'Abs_10_10');
save('Cor_10_10.mat', 'Cor_10_10');
%load('Data for plots/Abs_10_10.mat')
%load('Data for plots/Cor_10_10.mat')

% Plot error swamp values for eps approx 1e-3
Plot_Errors_Singular_Conv_Facts(10, 10, Abs_10_10, 10, factors, true)

%% ----------------------------------------- n = 20, n_i in [10 ... 80]/2 ----------------------------------------- %
%[logspace(-7,-1, 100)*5.85/2.01, linspace(0.585/2,0.585,100)];   %logspace(-10,-1, 100)*5.85; %linspace(1e-10,0.585,200);
factors = [0.5,1,2,3,4,5,8];

i = 1;
for a = factors %  28h 57 min    12.41 min
    j = 1;
    %          Time         Mean 
    %   1     4.25 min    12.75 s
    %   2    14.85 min    44.54 s
    %   4    57.06 min     2.85 min
    %   6   128.34 min     5.97 min
    %   8   226.95 min    11.34 min
    %  10   5 h 57 min    17.82 min
    %  16  15 h 49 min    47.47 min

    for e = Range_Epsilons
        tic;
        [D_A, MS, errors, Conv, correction] = Singular_Kernel_Conv_Disc(e, 20, 20, a, options);
        T(i,j) = toc;  % pair 1: toc
        
        Abs_20_20{i,j} = errors;
        Cor_20_20{i,j} = correction;
    
        j = j + 1;
    end
    if i == 1
        [sum(T(i,:)), mean(T(i,:))]
    else
        [sum(T(i,:))/60, mean(T(i,:))]
    end
    i = i+1;
end
[sum(T(:))/3600, mean(T(:))]

save('Abs_20_20.mat', 'Abs_20_20');
save('Cor_20_20.mat', 'Cor_20_20');
%load('Data for plots/Abs_20_20.mat')
%load('Data for plots/Cor_20_20.mat')

% Plot error swamp values for eps approx 1e-3
Plot_Errors_Singular_Conv_Facts(20, 20, Abs_20_20, 10, factors, true)
close all

%% Plot max errors n = 10

% Obtain max error for each series
All_Errs = zeros([length(factors), length(Range_Epsilons) ]);
for i = 1:length(factors)
    All_Errs(i,:) = max([Abs_10_10{i,:}], [], 1);
end
save('All_Errs_10.mat', 'All_Errs');
%load('All_Errs_10.mat')
[MinA, MaxA] = bounds(All_Errs, 'all');

% Obtain truncation error
ptsCart = GetCartPts(D_A);
Exact_v = 0.25 * (ptsCart.y1_kv.^2 + ptsCart.y2_kv.^2 - 1.0);

% Colour selection
colour_A = [255, 225, 168]/255;
colour_B = [114, 61, 70]/255;
GRADIENT_flexible = @(n,nn) interp1([1/nn 1],[colour_A;colour_B],n/nn);
G_colours = GRADIENT_flexible((1:7),7);

% Plot things
figure(1)
plot(Range_Epsilons, All_Errs', 'LineWidth',2);    hold on
yscale log
xscale log
ylim([MinA, MaxA].* [0.9, 1.1] );
xlim([Range_Epsilons(1), Range_Epsilons(end)]);
colororder(G_colours)
set(gca, 'FontName', 'CMR10', 'TickLabelInterpreter','latex')
xlabel('Neighbourhood radius $\varepsilon$','Interpreter','latex')
ylabel('Absolute errors','Interpreter','latex')
set(gca, 'YTick', 10.^(-20:1:0))

% Truncation error
Bound_G = @(x) 0.25 * x.^2 .* abs( 1.0 - log(x.^2) );
plot(Range_Epsilons, Bound_G(Range_Epsilons), 'black','LineWidth',2,'LineStyle','--')

% Add some nice lines
for i = [1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1]
    if i < 1e+2
        plot([Range_Epsilons(1),i],[Bound_G(i),Bound_G(i)], 'Color', [1,1,1]/1.5);
    end
    plot([i,i], [MinA, Bound_G(i)], 'Color', [1,1,1]/1.5);
end

lgd = legend({'1','2','4','6','8', '10','16'},'Location','SouthWest');
lgd.Title.String = 'Factors';
ylim([9.9e-6,0.1])

exportgraphics(figure(1), 'Errors_Factor[10].pdf', 'BackgroundColor','none', 'ContentType', 'vector', 'Resolution', 300);
hold off



% Dividing the factor 2 steps:
% All_Errs(1,[1,2,3,5])./All_Errs(1,[2,3,5,7])
% > 23.3098   21.3960   21.0828   21.7605
% So each factor of 2 is around 20 times more accurate!

%% Plot max errors n = 20
% Obtain max error for each series
All_Errs_20 = zeros([length(factors), length(Range_Epsilons) ]);
for i = 1:length(factors)
    All_Errs_20(i,:) = max([Abs_20_20{i,:}], [], 1);
end
save('All_Errs_20.mat', 'All_Errs_20');
%load('All_Errs_20.mat');
[MinA_20, MaxA_20] = bounds(All_Errs_20, 'all');

% Colour selection
colour_A = [255, 225, 168]/255;
colour_B = [114, 61, 70]/255;
GRADIENT_flexible = @(n,nn) interp1([1/nn 1],[colour_A;colour_B],n/nn);
G_colours = GRADIENT_flexible((1:7),7);

% Plot things
figure(1)
plot(Range_Epsilons, All_Errs_20', 'LineWidth',2);    hold on
yscale log
xscale log
ylim([MinA_20, MaxA_20].* [0.9, 1.1] );
xlim([Range_Epsilons(1), Range_Epsilons(end)]);
colororder(G_colours)
set(gca, 'FontName', 'CMR10',  'TickLabelInterpreter','latex')
xlabel('Neighbourhood radius $\varepsilon$','Interpreter','latex')
ylabel('Absolute errors','Interpreter','latex')
set(gca, 'YTick', 10.^(-20:1:0))

% Truncation error
Bound_G = @(x) 0.25 * x.^2 .* abs( 1.0 - log(x.^2) );
plot(Range_Epsilons, Bound_G(Range_Epsilons), 'black','LineWidth',2,'LineStyle','--')

% Add some nice lines
for i = [1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1]
    if i < 1e+2
        plot([Range_Epsilons(1),i],[Bound_G(i),Bound_G(i)], 'Color', [1,1,1]/1.5);
    end
    plot([i,i], [MinA_20, Bound_G(i)], 'Color', [1,1,1]/1.5);
end

lgd = legend({'1/2','1','2','3','4','5','8'},'Location','SouthWest');
lgd.Title.String = 'Factors';
ylim([9.9e-6,0.1])

exportgraphics(figure(1), 'Errors_Factor[20].pdf', 'BackgroundColor','none', 'ContentType', 'vector', 'Resolution', 300);
hold off




%% Error accumulates at the origin and near the boundary
% n = 20
ptsCart = GetCartPts(D_A);

col = 20-6;
figure(3)
hold on
for i = 1:7
    plot(sqrt(ptsCart.y1_kv.^2 + ptsCart.y2_kv.^2), Cor_20_20{i,col}, 'LineWidth',2)
end
colororder(G_colours)

[MinA, MaxA] = deal( min(Cor_20_20{1,10}), max(Cor_20_20{7,col}) );
%ylim([MinA, MaxA].* [1.1, 0.9] );

%% Visualise approximate correction factor


tri = delaunay(ptsCart.y1_kv,ptsCart.y2_kv);
%trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, Abs_20_20{5,10})
trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, -Cor_20_20{5,10})

[MinA, MaxA] = bounds(-Cor_20_20{5,10});
zlim([MinA, MaxA].* [0.9, 1.05] );

shading interp
colormap bone
%colorbar
%view(3)            % 3D view
set(gca, 'FontName', 'CMR10', 'TickLabelInterpreter','latex')

hXL = xlabel('$x_1$','Interpreter','latex');
hXL.Position=hXL.Position+[0.5 0 0];

hYL = ylabel('$x_2$','Interpreter','latex');
hYL.Position=hYL.Position+[0 0.5 0];
zscale log
zlabel('Correction term')

title('Factor $\alpha =4$, neighbourhood radius $\varepsilon \approx 10^{-3}$','Interpreter','latex')
exportgraphics(figure(1), 'Correction_[20,4,1e-3].pdf', 'BackgroundColor','none', 'ContentType', 'vector', 'Resolution', 300);



% % 3d
% %surfaceArray = findobj(gca, 'Type', 'Surface');
% surfaceArray = findobj(gca,'Type','Patch');
% % Initialize combined vertices and faces
% allVertices = [];
% allFaces = [];
% faceOffset = 0; % Keeps track of vertex indexing for faces
% % Loop through each surface and combine the data
% for i = 1:length(surfaceArray)
%     % Extract X, Y, Z data
%     X_all = get(surfaceArray(i), 'XData');
%     Y_all = get(surfaceArray(i), 'YData');
%     Z_all = get(surfaceArray(i), 'ZData');
%     % Convert to patch data (triangles)
%     data = surf2patch(X_all, Y_all, Z_all, 'triangles');
%     % Extract vertices and faces
%     vertices = data.vertices;
%     faces = data.faces;
%     % Adjust face indices for the combined vertices
%     faces = faces + faceOffset;
%     % Append to the combined lists
%     allVertices = [allVertices; vertices];
%     allFaces = [allFaces; faces];
%     % Update face offset
%     faceOffset = faceOffset + size(vertices, 1);
% end
% stlwrite('Chapeau.stl', allFaces, allVertices);


%%
%% --------------------- Store struct with outputs ---------------------- %
%% 10 x 10 disc
tic
[D_A, MS, errors, Conv, correction] = Singular_Kernel_Conv_Disc(1e-3, 10, 10, 8, options);
toc
% 16 s

% Display correction factor
ptsCart = GetCartPts(D_A);
tri = delaunay(ptsCart.y1_kv,ptsCart.y2_kv);
trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, correction )

% 10 - 8: 1e-3
epsilon = 1e-3;
Newtonians = struct();
Newtonians.eps = epsilon;   % This is ε
Newtonians.disc = D_A;      % This is the domain

% Numerical integrals
Newtonians.NI = Conv * ones([10^2,1]);                                 % is the convolution outside [0,1]^2 ∩ N(ε)
Newtonians.NJ = 0.25 * (ptsCart.y1_kv.^2 + ptsCart.y2_kv.^2 - 1.0);    % is the convolution B[0;1] (symbolic)
Newtonians.NG = correction';                                           % is the convolution in N(ε), this is `smaller`: NJ - NI
Newtonians.N = 10;      % Number of points per dimension

% Now we add a substruct
Newtonians.Level = {};
Newtonians.Level.Available = [8];     % Number of subdivisions per dimension
% Store Convolution matrices
Newtonians.Level.n8  = Conv;

% Update: Newtonian paper arXiv.2512.17734, there is an exact correction
% Add exact kernel values at diagonal
a = vecnorm([ptsCart.y1_kv, ptsCart.y2_kv], 2, 2);        % Radial parts of points for E_ε
E_eps = Conv_Disc_Intersection(a, Newtonians.eps, false); % ε is still computable for double arithmetic
Newtonians.NG = E_eps;


% Store kernel
save('Singular_Kernel_Disc_10.mat', 'Newtonians');
disp('Contents of Singular_Kernel_Disc_10.mat:')
whos('-file', 'Singular_Kernel_Disc_10.mat')

clear('Newtonians')
%load('Singular_Kernel_Disc_10.mat', 'Newtonians')

%% 20 x 20 disc
tic
[D_A, MS, errors, Conv, correction] = Singular_Kernel_Conv_Disc(1e-3, 20, 20, 4, options);
toc
% 11 min 29 s

% Display correction factor
ptsCart = GetCartPts(D_A);
tri = delaunay(ptsCart.y1_kv,ptsCart.y2_kv);
trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, correction )

% 20 - 4: 1e-3
epsilon = 1e-3;
Newtonians = struct();
Newtonians.eps = epsilon;   % This is ε
Newtonians.disc = D_A;      % This is the domain
Newtonians.tag = 'MoonGap';

% Numerical integrals
Newtonians.NI = Conv * ones([20^2,1]);                                 % is the convolution outside [0,1]^2 ∩ N(ε)
Newtonians.NJ = 0.25 * (ptsCart.y1_kv.^2 + ptsCart.y2_kv.^2 - 1.0);    % is the convolution B[0;1] (symbolic)
Newtonians.NG = correction';                                           % is the convolution in N(ε), this is `smaller`: NJ - NI
Newtonians.N = 20;      % Number of points per dimension

% Now we add a substruct
Newtonians.Level = {};
Newtonians.Level.Available = [4];     % Number of subdivisions per dimension
% Store Convolution matrices
Newtonians.Level.n4  = Conv;

% Update: Newtonian paper arXiv.2512.17734, there is an exact correction
% Add exact kernel values at diagonal
a = vecnorm([ptsCart.y1_kv, ptsCart.y2_kv], 2, 2);        % Radial parts of points for E_ε
E_eps = Conv_Disc_Intersection(a, Newtonians.eps, false); % ε is still computable for double arithmetic
Newtonians.NG = E_eps;


% Store kernel
save('Singular_Kernel_Disc_20.mat', 'Newtonians');
disp('Contents of Singular_Kernel_Disc_20.mat:')
whos('-file', 'Singular_Kernel_Disc_20.mat')

clear('Newtonians')
%% 40 x 40 disc
tic
[D_A, MS, errors, Conv, correction] = Singular_Kernel_Conv_Disc(1e-3, 40, 40, 2, options);
toc
% 6 h 38 min 29 s (23909.141871)

% Display correction factor
ptsCart = GetCartPts(D_A);
tri = delaunay(ptsCart.y1_kv,ptsCart.y2_kv);
trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, correction )

% 40 2: 1e-3
epsilon = 1e-3;
Newtonians = struct();
Newtonians.eps = epsilon;   % This is ε
Newtonians.disc = D_A;      % This is the domain
Newtonians.tag = 'MoonGap';

% Numerical integrals
Newtonians.NI = Conv * ones([40^2,1]);                                 % is the convolution outside [0,1]^2 ∩ N(ε)
Newtonians.NJ = 0.25 * (ptsCart.y1_kv.^2 + ptsCart.y2_kv.^2 - 1.0);    % is the convolution B[0;1] (symbolic)
Newtonians.NG = correction';                                           % is the convolution in N(ε), this is `smaller`: NJ - NI
Newtonians.N = 40;      % Number of points per dimension

% Now we add a substruct
Newtonians.Level = {};
Newtonians.Level.Available = [2];     % Number of subdivisions per dimension
% Store Convolution matrices
Newtonians.Level.n2  = Conv;

% Update: Newtonian paper arXiv.2512.17734, there is an exact correction
% Add exact kernel values at diagonal
a = vecnorm([ptsCart.y1_kv, ptsCart.y2_kv], 2, 2);        % Radial parts of points for E_ε
E_eps = Conv_Disc_Intersection(a, Newtonians.eps, false); % ε is still computable for double arithmetic
Newtonians.NG = E_eps;

% Store kernel
save('Singular_Kernel_Disc_40.mat', 'Newtonians');
disp('Contents of Singular_Kernel_Disc_40.mat:')
whos('-file', 'Singular_Kernel_Disc_40.mat')

clear('Newtonians')
%% 60 x 60 disc
tic
[D_A, MS, errors, Conv, correction] = Singular_Kernel_Conv_Disc(1e-3, 60, 60, 1.5, options);
toc
% 3 days 7 h 13 min 47 s (285226.841611)

% Display correction factor
ptsCart = GetCartPts(D_A);
tri = delaunay(ptsCart.y1_kv,ptsCart.y2_kv);
trisurf(tri, ptsCart.y1_kv,ptsCart.y2_kv, correction )

% 40 2: 1e-3
epsilon = 1e-3;
Newtonians = struct();
Newtonians.eps = epsilon;   % This is ε
Newtonians.disc = D_A;      % This is the domain
Newtonians.tag = 'MoonGap';

% Numerical integrals
Newtonians.NI = Conv * ones([60^2,1]);                                 % is the convolution outside [0,1]^2 ∩ N(ε)
Newtonians.NJ = 0.25 * (ptsCart.y1_kv.^2 + ptsCart.y2_kv.^2 - 1.0);    % is the convolution B[0;1] (symbolic)
Newtonians.NG = correction';                                           % is the convolution in N(ε), this is `smaller`: NJ - NI
Newtonians.N = 60;      % Number of points per dimension

% Now we add a substruct
Newtonians.Level = {};
Newtonians.Level.Available = [1.5];     % Number of subdivisions per dimension
% Store Convolution matrices
Newtonians.Level.n2  = Conv;

% Update: Newtonian paper arXiv.2512.17734, there is an exact correction
% Add exact kernel values at diagonal
a = vecnorm([ptsCart.y1_kv, ptsCart.y2_kv], 2, 2);        % Radial parts of points for E_ε
E_eps = Conv_Disc_Intersection(a, Newtonians.eps, false); % ε is still computable for double arithmetic
Newtonians.NG = E_eps;


% Store kernel
save('Singular_Kernel_Disc_60.mat', 'Newtonians');
disp('Contents of Singular_Kernel_Disc_60.mat:')
whos('-file', 'Singular_Kernel_Disc_60.mat')

clear('Newtonians')


%% 3D fun
% figure(1)
% [MX, MY] = meshgrid( linspace(0,1,100), linspace(0,1,100) );
% s = surf(MX, MY, rescale(-Newtonians.Level.n10, 0,1),'FaceAlpha',0.2 );
% s.EdgeColor = 'none';
% stlwrite('test.stl',MX,MY,rescale(-Newtonians.Level.n10, 0,1),'mode','ascii')