%% Test Shardlet
% Define a speudospectral mesh for space
geom.N(1)= 40;    geom.N(2) = 40;

% Upper shard not fully contained
geom.R_1 = 5.0;    geom.R_2 = 3.0;    geom.d = 2.5;    geom.s = 1;

SL = Shardlet(geom);
SL.PlotGridLines;
ptsCart = GetCartPts(SL);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
int = SL.ComputeIntegrationVector;

% Oposing side
geom.R_1 = 5.0;    geom.R_2 = 3.0;    geom.d = 2.5;    geom.s = -1;
SL = Shardlet(geom);
SL.PlotGridLines;
ptsCart = GetCartPts(SL);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
int = SL.ComputeIntegrationVector;

% Lower shard intersecting at one point
geom.R_1 = 4.0;    geom.R_2 = 1.0;    geom.d = 3.0;    geom.s = -1;
SL = Shardlet(geom);
SL.PlotGridLines;
ptsCart = GetCartPts(SL);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
int = SL.ComputeIntegrationVector;

