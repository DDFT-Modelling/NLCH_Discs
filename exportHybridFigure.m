function exportHybridFigure(fig, rasterFile, finalFile, rasterDPI)
% exportHybridFigure  Export a figure with raster graphics + vector text
%
%   exportHybridFigure(fig, rasterFile, finalFile, rasterDPI)
%
%   fig        - handle to the original figure
%   rasterFile - filename for raster image (e.g., 'plot_raster.png')
%   finalFile  - filename for final vector file (e.g., 'plot_hybrid.pdf')
%   rasterDPI  - resolution for raster export (e.g., 300)

if nargin < 4
    rasterDPI = 300;
end

%% 1. Store original text handles and properties
textObjs   = findall(fig, 'Type', 'text');
axesObjs   = findall(fig, 'Type', 'axes');
tickLabels = struct('X', {get(axesObjs, 'XTickLabel')}, ...
                    'Y', {get(axesObjs, 'YTickLabel')}, ...
                    'Z', {get(axesObjs, 'ZTickLabel')});
legendObjs = findall(fig, 'Type', 'Legend');
legendLabels = {get(legendObjs, 'String')};
colorbarObjs = findall(fig, 'Tag', 'Colorbar');
cbLabels = struct('Ticks', {get(colorbarObjs, 'Ticks')}, ...
                  'TickLabels', {get(colorbarObjs, 'TickLabels')}, ...
                  'Label', {get(colorbarObjs, 'Label')}, ...
                  'Title', {get(colorbarObjs, 'Title')});

annoTxtBoxes = findall(fig, 'Type', 'textboxshape');

% UI text controls (rare in plots)
uiTxt = findall(fig, 'Style', 'text');

%% 2. Hide all text
set(textObjs, 'Visible', 'off');
for ax = axesObjs'
    set(ax, 'XTickLabel', [], 'YTickLabel', [], 'ZTickLabel', []);
end

for i = 1:numel(legendObjs)
    % Keep the original strings
    legendObjs(i).String = legendLabels{i};
    
    % Change the text color to white
    legendObjs(i).TextColor = [1 1 1];  % RGB for white
end

for cb = colorbarObjs'
    set(cb, 'Visible', 'off');
end

set(annoTxtBoxes, 'Visible', 'off');
set(uiTxt, 'Visible', 'off');

%% 3. Save raster image
print(fig, rasterFile, '-dpng', sprintf('-r%d', rasterDPI));

%% 4. Restore text in original figure
set(textObjs, 'Visible', 'on');
if numel(axesObjs)>1
    for i = 1:numel(axesObjs)
        set(axesObjs(i), 'XTickLabel', tickLabels.X{i}, ...
            'YTickLabel', tickLabels.Y{i}, ...
            'ZTickLabel', tickLabels.Z{i});
    end
else
    set(axesObjs, 'XTickLabel', tickLabels.X, ...
            'YTickLabel', tickLabels.Y, ...
            'ZTickLabel', tickLabels.Z);
end

for i = 1:numel(legendObjs)
    % Keep the original strings
    legendObjs(i).String = legendLabels{i};
    
    % Change the text color to white
    legendObjs(i).TextColor = [0 0 0];  % RGB for white
end

for cb = colorbarObjs'
    set(cb, 'Visible', 'on');
end

set(annoTxtBoxes, 'Visible', 'on');
set(uiTxt, 'Visible', 'on');

%% 5. Create new figure with same inner size
outerPos = get(fig, 'Position');
innerPos = get(fig, 'InnerPosition');
figUnits = get(fig, 'Units');

fig2 = figure('Units', figUnits, 'Position', outerPos);
set(fig2, 'InnerPosition', innerPos);

% Axes that fill the entire inner area
ax1 = axes('Parent', fig2, 'Units', 'normalized', 'Position', [0 0 1 1]);

% Show raster without resizing figure
imshow(rasterFile, 'Parent', ax1, ...
       'InitialMagnification', 'fit', ...
       'Border', 'tight');

%% 6. Copy text objects from original figure to top axes

% for ax = flipud(axesObjs(:)')  % preserve order
%     ax.Units = 'normalized';
%     newAx = copyobj(ax, fig2);
% 
%     % Hide layout-affecting objects instead of deleting them
%     set(findobj(newAx, 'Type', 'legend'),   'Visible', 'off');
%     set(findobj(newAx, 'Type', 'colorbar'), 'Visible', 'off');
% 
%     % Remove everything except text objects
%     delete(findall(newAx, '-not', 'Type', 'text', '-and', '-not', 'Type', 'axes'));
%     set(newAx, 'Color', 'none');
%     set(newAx, 'GridLineStyle', 'none', ...
%                'MinorGridLineStyle', 'none', ...
%                'Box', 'off');
% 
%     % Bring to top
%     uistack(newAx, 'top');
% end

for ax = flipud(axesObjs(:)')  % preserve order
    ax.Units = 'normalized';
    newAx = copyobj(ax, fig2);

    % --- Freeze current limits ---
    xl = xlim(newAx);
    yl = ylim(newAx);
    zl = zlim(newAx);

    delete(findall(newAx, '-not', 'Type', 'text', '-and', '-not', 'Type', 'axes'));

    set(newAx, 'XLim', xl, 'YLim', yl, 'ZLim', zl, ...
        'XLimMode', 'manual', ...
        'YLimMode', 'manual', ...
        'ZLimMode', 'manual');


    % Style tweaks
    set(newAx, 'Color', 'none', ...
               'GridLineStyle', 'none', ...
               'MinorGridLineStyle', 'none', ...
               'Box', 'off');

    uistack(newAx, 'top');
end



for i = 1:numel(legendObjs)
    lg = legendObjs(i);
    props = get(lg);

    % Legend position in normalized figure coords
    lgPos = props.Position;
    nEntries = numel(props.String);
    nCols = props.NumColumns;
    nRows = ceil(nEntries / nCols);

    % Rough spacing (you can refine this)
    colWidth = lgPos(3) / nCols;
    rowHeight = lgPos(4) / nRows;

    entry = 1;
    for r = 1:nRows
        for c = 1:nCols
            if entry > nEntries, break; end
            % Position text to the right of the marker
            x = lgPos(1) + (c-1)*colWidth + 0.38*colWidth;
            y = lgPos(2) + lgPos(4) - r*rowHeight - 0.78*rowHeight;

            annotation(fig2, 'textbox', [x y 0.1 0.1], ...
                'String', props.String{entry}, ...
                'FontSize', props.FontSize, ...
                'FontName', props.FontName, ...
                'FontWeight', props.FontWeight, ...
                'Interpreter', props.Interpreter, ...
                'Color', props.TextColor, ...
                'EdgeColor', 'none', ...
                'BackgroundColor', 'none', ...
                'FitBoxToText', 'on', ...
                'VerticalAlignment', 'middle');
            entry = entry + 1;
        end
    end
end



for cb = flipud(colorbarObjs(:)')  % preserve order
    parentAx = cb.Axes;

    % Copy both axes and colorbar together
    newObjs = copyobj([parentAx, cb], fig2);

    % Identify which is which
    newAx = newObjs(1);
    newCb = newObjs(2);

    cmap = colormap(cb.Axes);  % get colormap from original
        colormap(newCb.Axes, cmap)

    % Also strip everything except text from the copied axes
    % --- Freeze current limits ---
    xl = xlim(newAx);
    yl = ylim(newAx);
    zl = zlim(newAx);

    delete(findall(newAx, '-not', 'Type', 'text', '-and', '-not', 'Type', 'axes'));

    set(newAx, 'XLim', xl, 'YLim', yl, 'ZLim', zl, ...
        'XLimMode', 'manual', ...
        'YLimMode', 'manual', ...
        'ZLimMode', 'manual');
    set(newAx, 'Color', 'none', ...
               'GridLineStyle', 'none', ...
               'MinorGridLineStyle', 'none', ...
               'Box', 'off');
end


% Copy annotation text boxes
for k = 1:numel(annoTxtBoxes)
    props = get(annoTxtBoxes(k));
    annotation(fig2, 'textbox', props.Position, ...
        'String', props.String, ...
        'FontSize', props.FontSize, ...
        'FontName', props.FontName, ...
        'FontWeight', props.FontWeight, ...
        'HorizontalAlignment', props.HorizontalAlignment, ...
        'VerticalAlignment', props.VerticalAlignment, ...
        'Rotation', props.Rotation, ...
        'Interpreter', props.Interpreter, ...
        'Color', props.Color, ...
        'EdgeColor', props.EdgeColor, ...
        'LineWidth', props.LineWidth, ...
        'BackgroundColor', props.BackgroundColor);
end

%% 7. Export final hybrid figure

exportgraphics(fig2, finalFile, 'ContentType', 'vector');
fprintf('Raster image saved to %s\n', rasterFile);
fprintf('Hybrid figure saved to %s\n', finalFile);

end