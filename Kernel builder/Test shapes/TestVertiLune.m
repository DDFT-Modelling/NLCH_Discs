%% Test VertiLune
% Define a speudospectral mesh for space
geom.N(1)= 40;    geom.N(2) = 40;

% Since Moon can give a wedge, maybe MoonSlice gives a better shape.
% However, that shape is based on two circles having the same radius. So
% let's introduce a new shape for two different circles.
%geom.R_l = 1.7;    geom.R_r = 0.5;    geom.d = 1.0;

% Nonempty intersection
geom.R_l = 1.0;    geom.R_r = 1.3;    geom.d = 1.8;

VertiLuna = VertiLune(geom);
VertiLuna.PlotGridLines;
ptsCart = GetCartPts(VertiLuna);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
int = VertiLuna.ComputeIntegrationVector;

%geom.d = 0;   % Even works in this case
% Right disc contains left disc
geom.R_l = 0.8;    geom.R_r = 3.0;

VertiLuna = VertiLune(geom);
VertiLuna.PlotGridLines;
ptsCart = GetCartPts(VertiLuna);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
int = VertiLuna.ComputeIntegrationVector;

% Left disc contains right disc
geom.R_l = 3.5;    geom.R_r = 0.6;
VertiLuna = VertiLune(geom);
VertiLuna.PlotGridLines;
ptsCart = GetCartPts(VertiLuna);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
int = VertiLuna.ComputeIntegrationVector;

