fig = figure('Name', '500', 'Position', [500 282 900 230]);
hold on
set(fig, 'WindowStyle', 'normal');


% Setup
Tile = tiledlayout(1,5,'TileSpacing','compact', 'Padding','compact');

% Axes
for i = 1:5
    h_S(i) = nexttile;
end

% Initial plot
axes(h_S(1))
aDisc.plot(phi_ic,{});
xlabel('$x_1$'); ylabel('$x_2$'); caxis([-1,1])
title('$t=0$','Interpreter','latex');    shading interp

set(h_S(1),'fontsize',6,'linewidth',0.1);

%h_S(1).CameraPosition = [0.5 0.5 30];
h_S(1).CameraPosition = [0 0 30];

set(h_S(1), 'TickLabelInterpreter', 'latex');
set(gca,'color','none')
xticks([-1,0,1]);    yticks([-0.5,0,0.5]);
yticklabels(strrep(yticklabels,'-','$-$'));
xticklabels(strrep(xticklabels,'-','$-$'));

% Interpolate solution at specified times
%TimesEval = [0,0.0025,0.125,0.5,10/4]*4;      % Test A
TimesEval = [0, 0.1, 1, 10,100];      % Test B
%TimesEval = [0,0.001, 0.0025, 0.005, 1]*10;      % Test C

for i = 2:5
    t = TimesEval(i);
    IP = TimeLine.ComputeInterpolationMatrixPhys(t).InterPol;
    rho_t = (IP * Phi_to)';
    
    % Add panels
    axes(h_S(i))
    aDisc.plot(rho_t,{});
    xlabel('$x_1$'); ylabel('');
    
    zlim([-1-4e-1,1+1e-1]); clim([-1.0,1.0]);    shading interp
    title(['$t$ = ' num2str(TimesEval(i))],'Interpreter','latex')

    set(h_S(i),'fontsize',6,'linewidth',0.1,'yticklabel',[]);
    xticklabels(strrep(xticklabels,'-','$-$'));

    h_S(i).CameraPosition = [0 0 30];
    set(h_S(i), 'TickLabelInterpreter', 'latex');
    set(gca,'color','none')
end

% Add additional comments
set(h_S(5),'YAxisLocation', 'right')

axes(h_S(5));    ylabel('$\rho(x;t)$');

colormap bone

fontsize(11,"points")


set(fig, 'Position', [500 282 900 230])
% This is the command I used before R2025b, since it rendered the image
% well, but that doesn't take place anymore.
% exportgraphics(fig, Out_Name, 'BackgroundColor','none','ContentType','image', 'Resolution', 300)
% % we repeat bc in 2025b something weird is happening
% exportgraphics(fig, Out_Name, 'BackgroundColor','none','ContentType','image', 'Resolution', 1200)

exportHybridFigure(fig, 'low.png', Out_Name, 400);


