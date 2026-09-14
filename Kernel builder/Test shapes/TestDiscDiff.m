%% Test Disc difference
option.display = true;
option.Partition = 'MoonGap';

N = 10;
%% MoonGap
% 1
g_1 = struct('N', [10,10], 'R', 2.0, 'Origin', [-0.5,1.0]);
g_2 = struct('N', [10,10], 'R', 1.0, 'Origin', [-3.0,1.5]);
D_1 = Disc(g_1);
D_2 = Disc(g_2);
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 2
hold on
O = [4,3];
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0;    D_1 = Disc(g_1);
g_2.Origin = [-0.5,3.5]+O;     g_2.R = 1.0;    D_2 = Disc(g_2);
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 3
O = [5,-1];
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0*0.8;    D_1 = Disc(g_1);
g_2.Origin = [-2.0,0.5]+O;    g_2.R = 1.0*0.8;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 4
O = [10,1];
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0*1.25;    D_1 = Disc(g_1);
g_2.Origin = [-2.7,0.0]+O;    g_2.R = 1.0*1.25;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 5
O = [10,-4];
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0*0.6;    D_1 = Disc(g_1);
g_2.Origin = [0.0,1.0]+O;    g_2.R = 1.0*0.6;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 6
O = [6,-4];
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0*0.5;    D_1 = Disc(g_1);
g_2.Origin = [0.0,0.5]+O;    g_2.R = 1.0*0.5;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 7
O = [1.5,-4];
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0;    D_1 = Disc(g_1);
g_2.Origin = [-2.0,1.5]+O;    g_2.R = sqrt(1.5);          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 8
O = [-1.5,5];
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0;    D_1 = Disc(g_1);
g_2.Origin = [1,1]+O;    g_2.R = 1.7;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);


%% VertiLunes
option.Partition = 'VertiLune';
L = [-20,0];
% 1
g_1 = struct('N', [10,10], 'R', 2.0, 'Origin', [-0.5,1.0]+L);
g_2 = struct('N', [10,10], 'R', 1.0, 'Origin', [-3.0,1.5]+L);
D_1 = Disc(g_1);
D_2 = Disc(g_2);
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 2
hold on
O = [4,3] + L;
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0;    D_1 = Disc(g_1);
g_2.Origin = [-0.5,3.5]+O;     g_2.R = 1.0;    D_2 = Disc(g_2);
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 3
O = [5,-1] + L;
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0*0.8;    D_1 = Disc(g_1);
g_2.Origin = [-2.0,0.5]+O;    g_2.R = 1.0*0.8;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 4
O = [10,1] + L;
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0*1.25;    D_1 = Disc(g_1);
g_2.Origin = [-2.7,0.0]+O;    g_2.R = 1.0*1.25;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 5
O = [10,-4] + L;
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0*0.6;    D_1 = Disc(g_1);
g_2.Origin = [0.0,1.0]+O;    g_2.R = 1.0*0.6;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 6
O = [6,-4] + L;
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0*0.5;    D_1 = Disc(g_1);
g_2.Origin = [0.0,0.5]+O;    g_2.R = 1.0*0.5;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 7
O = [1.5,-4] + L;
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0;    D_1 = Disc(g_1);
g_2.Origin = [-2.0,1.5]+O;    g_2.R = sqrt(1.5);          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);
% 8
O = [-1.5,5] + L;
g_1.Origin = [-0.5,1.0]+O;     g_1.R = 2.0;    D_1 = Disc(g_1);
g_2.Origin = [1,1]+O;    g_2.R = 1.7;          D_2 = Disc(g_2); % C
Set_Difference_Discs(D_1, D_2, [N,N], option);