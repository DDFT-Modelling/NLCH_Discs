%% Test CircularSegment
% Define a speudospectral mesh for space
geom.N(1)= 40;    geom.N(2) = 40;    geom.R = 2;

% The direction of the segment depends on the sign of the apotheme:
% a positive sign gives an upper segment
% a negative sign gives a lower segment
% no sign gives a line at the origin

% Upper
geom.d = 1.0;

CS = CircularSegment(geom);
CS.PlotGridLines;
ptsCart = GetCartPts(CS);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
int = CS.ComputeIntegrationVector;
hold on

% Lower
geom.d = -1.5;

CS = CircularSegment(geom);
CS.PlotGridLines;
ptsCart = GetCartPts(CS);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');
int = CS.ComputeIntegrationVector;

% If d and R coincide, the segment reduces to a point
geom.R = 0.5;    geom.d = 0.5;
CS = CircularSegment(geom);
ptsCart = GetCartPts(CS);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

% If d is 0, a line segment of radius R is generated
geom.R = 1.5;    geom.d = 0;
CS = CircularSegment(geom);
ptsCart = GetCartPts(CS);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

hold off