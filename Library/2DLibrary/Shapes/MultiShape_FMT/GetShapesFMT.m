function [shapes,geomFMT,shapesPlot] = GetShapesFMT(Geometry)
    % Automatically create the MultiShape given the FMTShape

    if(strcmp(Geometry.FMTShape,'HalfSpace'))

        % get parameters and remove the unnecessary ones from the geometry
        R = Geometry.R;
        Geometry = rmfield(Geometry,'R');
        Geometry = rmfield(Geometry,'FMTShape');

        % Note that Geometry.y2Min is the positions of the wall
        
        % this is the domain on which the density is non-zero
        geomFMT = Geometry;
        geomFMT.y2Min = Geometry.y2Min + R;

        % these give the extended domain (up to the walls), split
        % at the line where the averaged densities are only
        % continuous, not smooth
        geomMain = Geometry;
        geomMain.y2Min = Geometry.y2Min + 2*R;

        geomBottom = Geometry;
        geomBottom.y2Min = Geometry.y2Min;
        geomBottom.y2Max = Geometry.y2Min + 2*R;                

        % construct the shapes
        shapes(1).shape = 'HalfSpace';
        shapes(1).geom = geomMain;
        shapes(2).shape = 'InfCapillary';
        shapes(2).geom = geomBottom;
        
        % these give the parts of the extended domain (up to the walls), split
        % at the lines where the density jumps; it is zero in the two edge
        % strips.  This is used for plotting

        geomBottomPlot = Geometry;
        geomBottomPlot.y2Min = Geometry.y2Min;
        geomBottomPlot.y2Max = Geometry.y2Min + R;                

        % construct the shapes
        shapesPlot(1).shape = 'InfCapillary';
        shapesPlot(1).geom = geomBottomPlot;

        
    elseif(strcmp(Geometry.FMTShape,'PeriodicHalfSpace'))

        % get parameters and remove the unnecessary ones from the geometry
        R = Geometry.R;
        Geometry = rmfield(Geometry,'R');
        Geometry = rmfield(Geometry,'FMTShape');
        
        % Note that Geometry.y1Min is the position of the wall
        
        % this is the domain on which the density is non-zero
        geomFMT = Geometry;
        geomFMT.y1Min = Geometry.y1Min + R;

        % these give the extended domain (up to the walls), split
        % at the line where the averaged densities are only
        % continuous, not smooth
        geomMain = Geometry;
        geomMain.y1Min = Geometry.y1Min + 2*R;
        
        geomLeft = Geometry;
        geomLeft = rmfield(geomLeft,'L1');
        geomLeft.y1Min = Geometry.y1Min;
        geomLeft.y1Max = Geometry.y1Min + 2*R;
        
        % construct the shapes
        shapes(1).shape = 'PeriodicHalfSpace';
        shapes(1).geom = geomMain;
        shapes(2).shape = 'PeriodicBox';
        shapes(2).geom = geomLeft;
        
        % these give the parts of the extended domain (up to the walls), split
        % at the lines where the density jumps; it is zero in the two edge
        % strips.  This is used for plotting

        geomLeftPlot = Geometry;
        geomLeftPlot = rmfield(geomLeftPlot,'L1');
        geomLeftPlot.y1Min = Geometry.y1Min;
        geomLeftPlot.y1Max = Geometry.y1Min + R;                

        % construct the shapes
        shapesPlot(1).shape = 'PeriodicBox';
        shapesPlot(1).geom = geomLeftPlot;
        
        
    elseif(strcmp(Geometry.FMTShape,'InfCapillary'))

        % get parameters and remove the unnecessary ones from the geometry
        R = Geometry.R;
        Geometry = rmfield(Geometry,'R');
        Geometry = rmfield(Geometry,'FMTShape');

        % Note that Geometry.y2Min and Geometry.y2Max are the positions of
        % the walls
        
        % this is the domain on which the density is non-zero
        geomFMT = Geometry;
        geomFMT.y2Min = Geometry.y2Min + R;
        geomFMT.y2Max = Geometry.y2Max - R;

        % these give the extended domain (up to the walls), split
        % at the lines where the averaged densities are only
        % continuous, not smooth
        geomMain = Geometry;
        geomMain.y2Min = Geometry.y2Min + 2*R;
        geomMain.y2Max = Geometry.y2Max - 2*R;

        geomTop = Geometry;
        geomTop.y2Min = Geometry.y2Max - 2*R;
        geomTop.y2Max = Geometry.y2Max;                

        geomBottom = Geometry;
        geomBottom.y2Min = Geometry.y2Min;
        geomBottom.y2Max = Geometry.y2Min + 2*R;                

        % construct the shapes
        % ordering to match InfCapillary_FMT
        shapes(1).shape = 'InfCapillary';
        shapes(1).geom = geomBottom;
        shapes(2).shape = 'InfCapillary';
        shapes(2).geom = geomMain;
        shapes(3).shape = 'InfCapillary';
        shapes(3).geom = geomTop;
        
        % these give the parts of the extended domain (up to the walls), split
        % at the lines where the density jumps; it is zero in the two edge
        % strips.  This is used for plotting

        geomTopPlot = Geometry;
        geomTopPlot.y2Min = Geometry.y2Max - R;
        geomTopPlot.y2Max = Geometry.y2Max;                

        geomBottomPlot = Geometry;
        geomBottomPlot.y2Min = Geometry.y2Min;
        geomBottomPlot.y2Max = Geometry.y2Min + R;                

        % construct the shapes
        shapesPlot(1).shape = 'InfCapillary';
        shapesPlot(1).geom = geomTopPlot;
        shapesPlot(2).shape = 'InfCapillary';
        shapesPlot(2).geom = geomBottomPlot;

    elseif(strcmp(Geometry.FMTShape,'PeriodicBox'))

        % get parameters and remove the unnecessary ones from the geometry
        R = Geometry.R;
        Geometry = rmfield(Geometry,'R');
        Geometry = rmfield(Geometry,'FMTShape');
        
        % Note that Geometry.y1Min and Geometry.y1Max are the positions of the wall
        
        % this is the domain on which the density is non-zero
        geomFMT = Geometry;
        geomFMT.y1Min = Geometry.y1Min + R;
        geomFMT.y1Max = Geometry.y1Max - R;

        % these give the extended domain (up to the walls), split
        % at the line where the averaged densities are only
        % continuous, not smooth
        geomMain = Geometry;
        geomMain.y1Min = Geometry.y1Min + 2*R;
        geomMain.y1Max = Geometry.y1Max - 2*R;
        
        geomLeft = Geometry;
        geomLeft.y1Min = Geometry.y1Min;
        geomLeft.y1Max = Geometry.y1Min + 2*R;

        geomRight = Geometry;
        geomRight.y1Min = Geometry.y1Max - 2*R;
        geomRight.y1Max = Geometry.y1Max;
        
        % construct the shapes
        shapes(1).shape = 'PeriodicBox';
        shapes(1).geom = geomMain;
        shapes(2).shape = 'PeriodicBox';
        shapes(2).geom = geomLeft;
        shapes(3).shape = 'PeriodicBox';
        shapes(3).geom = geomRight;
       
        % these give the parts of the extended domain (up to the walls), split
        % at the lines where the density jumps; it is zero in the two edge
        % strips.  This is used for plotting

        geomLeftPlot = Geometry;
        geomLeftPlot.y1Min = Geometry.y1Min;
        geomLeftPlot.y1Max = Geometry.y1Min + R;                

        geomRightPlot = Geometry;
        geomRightPlot.y1Min = Geometry.y1Max - R;
        geomRightPlot.y1Max = Geometry.y1Max;                
        
        % construct the shapes
        shapesPlot(1).shape = 'PeriodicBox';
        shapesPlot(1).geom = geomLeftPlot;
        shapesPlot(2).shape = 'PeriodicBox';
        shapesPlot(2).geom = geomRightPlot;
        
        
    else
        error('MultiShape_FMT:UnknownFMTShape',...
              'Error. Unknown FMTShape for MultiShape_FMT')
    end

end
