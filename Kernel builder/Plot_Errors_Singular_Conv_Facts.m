function Plot_Errors_Singular_Conv_Facts(Nx, Ny, Abs_a, col, Factors, store)

    colores = [255, 200, 87; 186, 45, 11; 86, 22, 67]/255;
    %[186, 45, 11; 0, 105, 137; 255, 200, 87]/255; %; 46, 196, 182; 86, 22, 67]/255;
    N = Nx * Ny;
    de = size(Abs_a,1);

    % Define a colour gradient
    colour_A = [255, 225, 168]/255;
    colour_B = [114, 61, 70]/255;
    GRADIENT_flexible = @(n,nn) interp1([1/nn 1],[colour_A;colour_B],n/nn);
    G_colours = GRADIENT_flexible((1:de),de);
    


    %% First plot: swarms of each error set 
    %%%%%%%%%%%
    figure(2)
    a(1) = plot(nan, nan, 'LineWidth', 2, 'LineStyle', '-', 'Color', 'black', 'DisplayName', 'Median'); hold on
    a(2) = plot(nan, nan, 'LineWidth', 2, 'LineStyle', ':', 'Color', 'black', 'DisplayName', 'Mode');
    a(3) = plot(nan, nan, 'LineWidth', 1, 'LineStyle', '--', 'Color', 'black', 'DisplayName', 'Mean');
    % 10 points
    swarmchart(1.0*ones(N,1), Abs_a{1,col}, 5, G_colours(1,:), 'XJitterWidth', 0.4)
    line([1-0.15,1+0.15],[median(Abs_a{1,col}),median(Abs_a{1,col})], 'LineWidth', 2, 'LineStyle', '-', 'Color', 'black') % colores( mod(1+4,5) + 1,:))
    line([1-0.15,1+0.15],[mode(Abs_a{1,col}),mode(Abs_a{1,col})], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'black') % colores( mod(1+4,5) + 1,:))
    line([1-0.15,1+0.15],[mean(Abs_a{1,col}),mean(Abs_a{1,col})], 'LineWidth', 1, 'LineStyle', '--', 'Color', 'black') % colores( mod(1+4,5) + 1,:))
    yscale log
    hold on
    for i = 2:de
        loc = (i+1)/2;
        swarmchart(loc*ones(N,1), Abs_a{i,col}, 10, G_colours(i,:), 'XJitterWidth', 0.4)
        line([loc-0.15,loc+0.15],[median(Abs_a{i,col}),median(Abs_a{i,col})], 'LineWidth', 2, 'LineStyle', '-', 'Color', 'black')
        line([loc-0.15,loc+0.15],[mode(Abs_a{i,col}),mode(Abs_a{i,col})], 'LineWidth', 2, 'LineStyle', ':', 'Color', 'black')
        line([loc-0.15,loc+0.15],[mean(Abs_a{i,col}),mean(Abs_a{i,col})], 'LineWidth', 1, 'LineStyle', '--', 'Color', 'black')
    end
    xlim([0.75,(de+1)/2 + 0.25]);
    
    MinMax = [1e+10,0];
    for i = 1:de
        [mina, maxa] = bounds(Abs_a{i,col}(Abs_a{i,col}>0),'all');
        if mina < MinMax(1)
            MinMax(1) = mina;
        end
        if maxa > MinMax(2)
            MinMax(2) = maxa;
        end
    end
    %ylim(MinMax .* [0.9, 1.1] );
    ylim(MinMax .* [0.65, 1.5] );
    % Add vertical lines as separators between classes
    %xline( 0.5*(2 + 2.5) ,'-.');


    % Additional decoration
    lgd = legend(a, 'Interpreter','latex','Location','northeast');
    title(lgd,'Descriptors','Interpreter','latex')
    % 
    % 
    % 
    xticks([1, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0 ]) %, 4.5])
    % 
    divisions = {};
    for i = 1:de
        divisions{i} = strcat( num2str(Nx), num2str(Factors( i ),'/%d'));
    end
    if Nx == 20
        divisions{1} = '20/0.5';
    end

    %xlabelArray = [ divisions; {'10^{-2}','10^{-2}', '10^{-5}', '10^{-5}'} ];  
    xlabelArray = [ divisions; {' ', ' ', ' ', '10^{-3}',  ' ', ' ', ' '} ]; 
    xtickLabels = strtrim(sprintf('%s\\newline %s\n', xlabelArray{:}));
    %xtickLabels = divisions;
    % 
    % %xticklabels({'A','B','C','D','E',  'A','B','C','D','E',  'A','B','C','D','E',  'A','B','C','D','E'})
    % %xticklabels({10, 10, 10, 10, 10,  20, 20, 20, 20, 20,  30, 30, 30, 30, 30,  40, 40, 40, 40, 40})
    xticklabels(xtickLabels)
    %xticklabels(divisions)
    set(gca, 'FontName', 'CMR10', 'TickLabelInterpreter','latex')
    xlabel('Grid resolution and detail factor','Interpreter','latex')
    ylabel('Absolute errors','Interpreter','latex')
    set(gca, 'YTick', 10.^(-20:1:-1)) %set(gca, 'YTick', logspace(-18,-1, 18))

    if store
        file_name = strcat('Test_Singular_Convolution_Fixed_Swarm[', num2str(Nx), ',', num2str(Factors,'%d,'), num2str(col), '].pdf');
        exportgraphics(figure(2), file_name, 'BackgroundColor','none','ContentType','vector')
    end
    hold off

end