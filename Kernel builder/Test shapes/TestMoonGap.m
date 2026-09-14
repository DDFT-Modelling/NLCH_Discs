%% Test MoonGap
% Define a speudospectral mesh for space
geom.N(1)= 40;    geom.N(2) = 40;

% Upper shard not fully contained
geom.R_1 = 4.0;    geom.R_2 = 1.7;    geom.d = 4.4;    geom.s = -1;

% Not fully contained and before centre
MG = MoonGap(geom);
MG.PlotGridLines;
ptsCart = GetCartPts(MG);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
%int = MG.ComputeIntegrationVector;

% Top at border
geom.d = 3.7;
MG = MoonGap(geom);
MG.PlotGridLines;
ptsCart = GetCartPts(MG);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
%int = MG.ComputeIntegrationVector;

% Top past border before centre
geom.d = 2.5;
MG = MoonGap(geom);
MG.PlotGridLines;
ptsCart = GetCartPts(MG);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

% Centred circle
geom.d = 0.0;    geom.s = 1.0;
MG = MoonGap(geom);
MG.PlotGridLines;
ptsCart = GetCartPts(MG);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

% After centre
geom.d = 2.0;    geom.s = 1.0;
MG = MoonGap(geom);
MG.PlotGridLines;
ptsCart = GetCartPts(MG);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

% Generate an error at right intersection
geom.R_2 = 2.0;
MG = MoonGap(geom);