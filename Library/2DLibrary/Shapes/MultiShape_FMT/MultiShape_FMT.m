classdef MultiShape_FMT < MultiShape
    
    properties (Access = public)
        
        FMTShape;
        MSPlot;
        
    end
    
    methods
                
        %------------------------------------------------------------------
        % Create a MultiShape_FMT including
        % - FMTShape, which is the physical domain where the density is
        % non-zero
        % - this, which is the full domain, split along the lines where the
        % averaged densities are non-smooth, i.e., where the area
        % intersects witht the boundaries
        %------------------------------------------------------------------
        
        function this = MultiShape_FMT(Geometry,GeometryPlot)   
            
            [shapes,geomFMT,shapesPlot] = GetShapesFMT(Geometry);
            
            % create the multishape for computing FMT
            this@MultiShape(shapes);

            % create the shape where the density is non-zero
            FMTShape = str2func(Geometry.FMTShape);
            this.FMTShape = FMTShape(geomFMT);
                        
            if(nargin==1)

                GeometryPlot.N = [40;40];
                Pts = this.FMTShape.Pts;
                GeometryPlot.y1Min = min(Pts.y1_kv(isfinite(Pts.y1_kv)));
                GeometryPlot.y1Max = max(Pts.y1_kv(isfinite(Pts.y1_kv)));
                GeometryPlot.y2Min = min(Pts.y2_kv(isfinite(Pts.y2_kv)));
                GeometryPlot.y2Max = max(Pts.y2_kv(isfinite(Pts.y2_kv)));
                
            end
                        
            this.FMTShape.ComputeAll(GeometryPlot);            
            
            % create the multishape for plotting, including a region where
            % the density is zero
            this.MSPlot = MultiShape(shapesPlot);
            
        end
        
        %------------------------------------------------------------------
        % Convolution matrix with a finitely-supported kernel with a set of
        % weights
        % Relies on the shapes having this functionality already
        %------------------------------------------------------------------

        function M_conv = ComputeConvolutionFiniteSupport(this,area,weights,pts)
            % * area - object of a class with two methods 
            %          (1) [int,A] = ComputeIntegrationVector() and
            %          (2) pts = GetCartPts(), with pts = struct(y1_kv,y2_kv)
            % * weights - a cell with a list of functions which get a structure with 
            %         two arrays [y1_kv,y2_kv] as input and returns one
            %         array of same size. 
            %         Note it automatically prepends a weight of 1 to the
            %         list
            % * pts - structure with 'y1_kv','y2_kv','y1','y2'. 
            
            nPts = length(pts.y1_kv); % number of points to compute at
            nWeights = numel(weights);
            
            M_conv = zeros(nPts,this.M,nWeights+1); % include 1 in weights
            
            for iW = 1:nWeights
                weightFns(iW).fn = str2func(weights{iW}); %#ok
            end

            
            totalComps = this.nShapes*nPts;
            updateCount = 0;
            updateThreshold = floor(totalComps/20);
            lineLength = 0;
            tStart = clock;
            
            
            for iShape = 1:this.nShapes
                mask = this.Shapes(iShape).PtsMask;
                shape = this.Shapes(iShape).Shape;

                for iPt = 1:nPts
                    
                    updateCount = updateCount + 1;

                    if(updateCount>=updateThreshold)
                        updateCount = 0;
                        tTaken = etime(clock,tStart);
                        thisComp = (iShape-1)*nPts + iPt;
                        tLeft  = (totalComps - thisComp)/thisComp*tTaken;
                        tEst   = addtodate(now,round(tLeft),'second');
                        tString    = datestr(tEst);
                        message  = ['ComputeConvolutionFiniteSupport ' ...
                                     num2str(thisComp) '/' num2str(totalComps) '; ' ...
                                     'Est. finish ' tString];

                        fprintf(repmat('\b',1,lineLength));
                        lineLength = fprintf(1, message);
                    end                            
                    
                    area.Origin = [pts.y1_kv(iPt);pts.y2_kv(iPt)];
                    
                    if(isfinite(area.Origin))
                        subShape = Intersect(shape,area);

                        % the interpolation onto subshape from the full domain
                        IP_i     = shape.SubShapePts(subShape.pts);

                        % deal with empty intersections
                        if(~isempty(IP_i))

                            % the integration weights for the subshape
                            Int_i    = subShape.int;

                            M_conv(iPt,mask,1) = Int_i*IP_i; % weight of 1

                            for iW = 1:nWeights
                                W = weightFns(iW).fn(subShape.ptsPolLoc);
                                M_conv(iPt,mask,iW+1) = (Int_i.*W')*IP_i;
                            end

                        end
                    end
                    
                end

            end
            
            fprintf(1,'\n\n');
                                
        end

        
        function M_conv = ComputeConvolutionFiniteSupportFMTShape(this,area,weights,pts)
            % * area - object of a class with two methods 
            %          (1) [int,A] = ComputeIntegrationVector() and
            %          (2) pts = GetCartPts(), with pts = struct(y1_kv,y2_kv)
            % * weights - a cell with a list of functions which get a structure with 
            %         two arrays [y1_kv,y2_kv] as input and returns one
            %         array of same size. 
            %         Note it automatically prepends a weight of 1 to the
            %         list
            % * pts - structure with 'y1_kv','y2_kv','y1','y2'. 
                        
            nPts = length(pts.y1_kv); % number of points to compute at
            nWeights = numel(weights);
            
            M_conv = zeros(nPts,this.FMTShape.M,nWeights+1); % include 1 in weights
            
            for iW = 1:nWeights
                weightFns(iW).fn = str2func(weights{iW}); %#ok
            end

            updateCount = 0;
            updateThreshold = floor(nPts/20);
            lineLength = 0;
            tStart = clock;
            
            for iPt = 1:nPts
                
                updateCount = updateCount + 1;

                if(updateCount>=updateThreshold)
                    updateCount = 0;
                    tTaken = etime(clock,tStart);
                    tLeft  = (nPts - iPt)/iPt*tTaken;
                    tEst   = addtodate(now,round(tLeft),'second');
                    tString    = datestr(tEst);
                    message  = ['ComputeConvolutionFiniteSupportFMTShape ' ...
                                 num2str(iPt) '/' num2str(nPts) '; ' ...
                                 'Est. finish ' tString];

                    fprintf(repmat('\b',1,lineLength));
                    lineLength = fprintf(1, message);
                end         
                
                area.Origin = [pts.y1_kv(iPt);pts.y2_kv(iPt)];
                
                if(isfinite(area.Origin))
                    subShape = Intersect(this.FMTShape,area);

                    % the interpolation onto subshape from the full domain
                    IP_i     = this.FMTShape.SubShapePts(subShape.pts);

                    % deal with empty intersections
                    if(~isempty(IP_i))

                        % the integration weights for the subshape
                        Int_i    = subShape.int;

                        M_conv(iPt,:,1) = Int_i*IP_i; % weight of 1

                        for iW = 1:nWeights
                            W = weightFns(iW).fn(subShape.ptsPolLoc);
                            M_conv(iPt,:,iW+1) = (Int_i.*W')*IP_i;
                        end
                    end
                    
                end

            end
            fprintf(1,'\n');
                                
        end
        
        
%         function M_conv = ComputeConvolutionFiniteSupport_Old(this,area,weights,pts)
%             % * area - object of a class with two methods 
%             %          (1) [int,A] = ComputeIntegrationVector() and
%             %          (2) pts = GetCartPts(), with pts = struct(y1_kv,y2_kv)
%             % * weights - a cell with a list of functions which get a structure with 
%             %         two arrays [y1_kv,y2_kv] as input and returns one
%             %         array of same size. 
%             %         Note it automatically prepends a weight of 1 to the
%             %         list
%             % * pts - structure with 'y1_kv','y2_kv','y1','y2'. 
%             
%             M_conv = zeros(length(pts.y1_kv),this.M,length(weights)+1);
%             
%             for iShape = 1:this.nShapes
%                 mask = this.Shapes(iShape).PtsMask;
%                 Shape = this.Shapes(iShape).Shape;
%                 M_conv(:,mask,:) = ...
%                     Shape.ComputeConvolutionFiniteSupport(area,weights,pts);
%             end
%             
%         end
        
        
%         function [AD,AAD] = GetAverageDensities(this,area,weights)
%             [AD,AAD] = GetAverageDensities_New(this,area,weights);
%         end
%         
%         function [AD,AAD] = GetAverageDensities_Old(this,area,weights)
%             %
%             % 
%             % This function is designed to compute the averaged densities and the
%             % functional derivates of the free energy in for Fundamental Measure Theory (FMT).
%             % With AD, it computes the convolution of a function defined on FTMShape,
%             % with a list of weight functions of finite support. 
%             % The support of the resulting function is a shape, which goes
%             % beyond FMTShape.  Additionally, the averaged densities are
%             % not smooth on the boundary of FMTShape inside this larger
%             % domain.  Hence it is split up into a MultiShape, with the
%             % averaged densities being smooth on each Shape.
%             % With AAD, the convolution of a function defined on this
%             % extended MultiShape is computed with the same list of weight functions defined in the input,
%             % with the result specified on the points of FMTShape.
%             %
%             % Input
%             %
%             % * area - structure with two methods 
%             %          (1) [int,A] = ComputeIntegrationVector() and
%             %          (2) pts = GetCartPts(), with pts = struct(y1_kv,y2_kv)
%             % * weights - a cell with a list of functions which get a structure with 
%             %         two arrays [y1_kv,y2_kv] as input and returns one
%             %         array of same size. 
%             %
%             % Output
%             %
%             % Both AD and AAD are operators for the following convolution:
%             %
%             % $$X_{i,:,k}\cdot \rho = \int_{A}  \rho({\bf r}_i+{\bf r}')w_k({\bf r}') d{\bf r}'$$
%             %
%             % * AD   : $A = area.GetCartPts() \cap this.FMTShape.GetCartPts()$, 
%             %          and ${\bf r}_i \in this.GetCartPts()$ (average density)
%             %
%             % * AAD  : $A = area.GetCartPts() \cap this.GetCartPts()$, 
%             %          and ${\bf r}_i \in this.FMTShape.GetCartPts()$
%             %          (average the average densities to compute free energy)
%             %            
%             
%             % average density on all MS points computed from density on the
%             % points of the FMT shape
%             
%             
%             % need to fiddle the points a bit so that
%             % FMTShape.ComputeConvolutionFiniteSupport works
%             if( isa(this.FMTShape,'InfCapillary') || isa(this.FMTShape,'HalfSpace') )
%                 thisPts = this.Pts;
%                 y2 = [];
%                 for iShape = 1:this.nShapes
%                     y2 = [y2;this.Shapes(iShape).Shape.Pts.y2];
%                 end
%                 thisPts.y1 = this.Shapes(1).Shape.Pts.y1;
%                 thisPts.y2 = y2;
%             elseif( isa(this.FMTShape,'PeriodicInfBox') )
%                 thisPts = this.Pts;
%                 y1 = [];
%                 for iShape = 1:this.nShapes
%                     y1 = [y1;this.Shapes(iShape).Shape.Pts.y1];
%                 end
%                 thisPts.y1 = y1;
%                 thisPts.y2 = this.Shapes(1).Shape.Pts.y2;
%             end
% 
%                 
%             AD   = this.FMTShape.ComputeConvolutionFiniteSupport(area,weights,thisPts);  
% 
%             % average of averaged densities (specified on the MS points and
%             % outputted on the FMTShape points)
%             AAD  = this.ComputeConvolutionFiniteSupport_Old(area,weights,this.FMTShape.Pts);
%         end

        
        function [AD,AAD] = GetAverageDensities(this,area,weights)
            %
            % 
            % This function is designed to compute the averaged densities and the
            % functional derivates of the free energy in for Fundamental Measure Theory (FMT).
            % With AD, it computes the convolution of a function defined on FTMShape,
            % with a list of weight functions of finite support. 
            % The support of the resulting function is a shape, which goes
            % beyond FMTShape.  Additionally, the averaged densities are
            % not smooth on the boundary of FMTShape inside this larger
            % domain.  Hence it is split up into a MultiShape, with the
            % averaged densities being smooth on each Shape.
            % With AAD, the convolution of a function defined on this
            % extended MultiShape is computed with the same list of weight functions defined in the input,
            % with the result specified on the points of FMTShape.
            %
            % Input
            %
            % * area - structure with two methods 
            %          (1) [int,A] = ComputeIntegrationVector() and
            %          (2) pts = GetCartPts(), with pts = struct(y1_kv,y2_kv)
            % * weights - a cell with a list of functions which get a structure with 
            %         two arrays [y1_kv,y2_kv] as input and returns one
            %         array of same size. 
            %
            % Output
            %
            % Both AD and AAD are operators for the following convolution:
            %
            % $$X_{i,:,k}\cdot \rho = \int_{A}  \rho({\bf r}_i+{\bf r}')w_k({\bf r}') d{\bf r}'$$
            %
            % * AD   : $A = area.GetCartPts() \cap this.FMTShape.GetCartPts()$, 
            %          and ${\bf r}_i \in this.GetCartPts()$ (average density)
            %
            % * AAD  : $A = area.GetCartPts() \cap this.GetCartPts()$, 
            %          and ${\bf r}_i \in this.FMTShape.GetCartPts()$
            %          (average the average densities to compute free energy)
            %            
            
            % average density on all MS points computed from density on the
            % points of the FMT shape
                            
            AD   = this.ComputeConvolutionFiniteSupportFMTShape(area,weights,this.Pts);  

            % average of averaged densities (specified on the MS points and
            % outputted on the FMTShape points)
            AAD  = this.ComputeConvolutionFiniteSupport(area,weights,this.FMTShape.Pts);
        end
        
        
        %------------------------------------------------------------------
        % Plotting including the excluded volume region
        %------------------------------------------------------------------
        
        function PlotFMT(this,V,opts,optsDetail)
            if(nargin<4)
                optsDetail = [];
            end
            if(nargin<3)
                opts = {};
            end
            
            optsDetail.sigma = false;
            optsDetail.edgecolor = 'none';
            
            this.FMTShape.plot(V,opts,optsDetail);
        end

        function PlotGridFMT(this)
            this.FMTShape.PlotGrid;
        end
        
        function PlotWithExcludedVolume(this,V,opts,optsDetail)
            % rho should be specified on FMTShape
            % This automatically plots zeros elsewhere
            
            if(nargin<3)
                opts = {};
            end
            if(nargin<4)
                optsDetail = [];
            end
            
            optsDetail.sigma = false;
            optsDetail.edgecolor = 'none';

            this.FMTShape.plot(V,opts,optsDetail);
            hold on
            this.MSPlot.Plot(zeros(size(this.MSPlot.Pts.y1_kv)),opts,optsDetail);
            
            if(isfield(optsDetail,'y1Lim'))
                xlim(optsDetail.y1Lim);
            end

            if(isfield(optsDetail,'y2Lim'))
                xlim(optsDetail.y2Lim);
            end
                        
        end
        
    end
    
end