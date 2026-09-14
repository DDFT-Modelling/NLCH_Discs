%%
% Define a speudospectral mesh for space
geom.N(1)= 40;    geom.N(2) = 40;    geom.R = 2;    geom.d = sqrt(2)*2+1; % add 1 to show wedge
Moon_Shape = Moon(geom);
Moon_Shape.PlotGridLines;

ptsCart = GetCartPts(Moon_Shape);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
%Moon_Shape.PlotGrid;
%s = scatter(Moon_Shape.Pts.y1_kv, imag(Moon_Shape.Pts.y2_kv), 'filled')

%%
Moon_Sliced = MoonSlice(geom);
Moon_Sliced.PlotGridLines;

ptsCart = GetCartPts(Moon_Sliced);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

%%
% Since Moon can give a wedge, maybe MoonSlice gives a better shape.
% However, that shape is based on two circles having the same radius. So
% let's introduce a new shape for two different circles.
%geom.R_l = 1.7;    geom.R_r = 0.5;    geom.d = 1.0;

% Nonempty intersection
geom.R_l = 1.0;    geom.R_r = 1.3;    geom.d = 1.8;
%geom.d = 0;   % Even works in this case
% Right disc contains left disc
%geom.R_l = 0.8;    geom.R_r = 3.0;
% Left disc contains right disc
%geom.R_l = 3.5;    geom.R_r = 0.6;

VertiLuna = VertiLune(geom);
VertiLuna.PlotGridLines;
ptsCart = GetCartPts(VertiLuna);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
