%% Test Intersect disc disc
% Define a speudospectral mesh for space
geom.N(1)= 10;    geom.N(2) = 10;
geom.R = 2.0;
geom.Origin = [-0.5,1.0];

% First circle
D_1 = Disc(geom);
D_1.PlotGridLines;
%ptsCart = GetCartPts(D_1);
%s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

% Second circle
%geom.Origin = [2.5,1.5];
%geom.Origin = [4.0,0.0];
geom.Origin = [-3.0,3.5];    geom.R = 1.0;          D_2 = Disc(geom);
geom.Origin = [-0.5,3.5];    geom.R = 1.0;          D_2 = Disc(geom);
geom.Origin = [-2.0,0.5];    geom.R = 1.0;          D_2 = Disc(geom); % C
geom.Origin = [-2.7,0.0];    geom.R = 1.0;          D_2 = Disc(geom); % C
geom.Origin = [-0.5,-1.6];   geom.R = 1.0;          D_2 = Disc(geom); % C
geom.Origin = [ 1.0,-1.0];   geom.R = 1.0;          D_2 = Disc(geom); % C
geom.Origin = [-2.0,1.5];    geom.R = sqrt(1.5);    D_2 = Disc(geom); % C
geom.Origin = [1,1];    geom.R = 1.7;    D_2 = Disc(geom);

D_2.PlotGridLines;

% Intersection
[area,complement] = Intersect_Disc_Disc(D_1,D_2);

ptsCart = GetCartPts(area);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

ptsCart = GetCartPts(complement);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');

% Move second circle around
Shapes(1).Shape = D_2;
D2 = ArbitraryIntersection(Shapes);

D2.ReflectPtsYAxis;
ptsCart = GetCartPts(D2);
s = scatter(ptsCart.y1_kv, ptsCart.y2_kv, 'filled');