classdef PeriodicBox < SpectralFourier

    properties        
        y1Min = 0
        y2Min = 0
        y1Max,y2Max  
        L2
    end
    
    methods        
        function this = PeriodicBox(Geometry)
           this@SpectralFourier(Geometry.N(1),Geometry.N(2));
                        
            if(isfield(Geometry,'L1'))
                if(isfield(Geometry,'Origin'))
                    this.y1Min = Geometry.Origin(1);
                    this.y2Min = Geometry.Origin(2);
                end
                this.y1Max      = this.y1Min + Geometry.L1; 
                this.y2Max      = this.y2Min + Geometry.L2;            
            else
                this.y1Min = Geometry.y1Min;
                this.y1Max = Geometry.y1Max;                
                this.y2Min = Geometry.y2Min;
                this.y2Max = Geometry.y2Max;
            end
            
            this.L2 = this.y2Max - this.y2Min;
            
            InitializationPts(this);      
            this.polar = 'cart';
        end                         
   
     
        function M_conv = ComputeConvolutionMatrix_Pointwise(this,f,shapeParams)
            % Convolution \int_D(x) f(x-y)g(y) dy
            % Here D(x) is the intersection of the subshape defined in
            % shapeParams with the box

            disp('Computing Convolution matrices...'); 
                                       
            if(nargin(f)==1)
                useDistance = true;
            else
                useDistance = false;
            end

            if(isfield(shapeParams,'shape'))
                subshapeFn = str2func(shapeParams.shape);
                
                % Disc, which will need to be decomposed into segments,
                % triangles and boxes; NT is the number of points for the
                % triangle
                if(strcmp(shapeParams.shape,'Disc'))
                    if(~isfield(shapeParams,'NT'))
                        shapeParams.NT = shapeParams.N;
                    end
                end
                
            else
                % whole box
                M_conv = ComputeConvolutionMatrix(this,f);
                return;
                                
            end
                
            Pts = this.Pts;
            
            if(useDistance)
                fPTemp = f(GetDistance(this,Pts.y1_kv,Pts.y2_kv));
            else
                fPTemp = f(Pts.y1_kv,Pts.y2_kv);
            end
            
            fDim = size(fPTemp,2);
            
            N1  = this.N1;  N2  = this.N2;
            N1N2 = N1*N2;
            M_conv = zeros(N1*N2,N1*N2,fDim);
            
            wb = waitbar(0,'Computing Convolution Matrices');
            
            y1 = Pts.y1_kv;
            y2 = Pts.y2_kv;
            
            for i=1:N1N2
                
                waitbar(i/N1N2,wb);

                % set up the subshape and intersect it with the box
                
                % can modify disc by specifying the origin
                % need to shift y1/2/Min/Max for box
                geom = ShiftGeometryOrigin(shapeParams,[y1(i);y2(i)]);
                    
                subshapeFull = subshapeFn(geom);
                subShape = Intersect(this,subshapeFull);

                % determine the points in the intersected domain
                subConvShapePts = subShape.pts;
                
                % the interpolation onto D(x) from the full domain
                IP_i     = SubShapePts(this,subConvShapePts);
                
                % the integration weights for the subshape
                Int_i    = subShape.int;
                
                % f(x-y)
                dy1 = y1(i) - subShape.pts.y1_kv;
                dy2 = y2(i) - subShape.pts.y2_kv;
                
                if(useDistance)
                    fP = f(GetDistance(this,dy1,dy2));
                else
                    fP = f(GetDistance1(this,dy1),GetDistance2(this,dy2));
                end

                for iF = 1:fDim
                    M_conv(i,:,iF) = (Int_i.*fP(:,iF)')*IP_i;
                end

            end

            M_conv(isnan(M_conv)) = 0;
                
            disp('...done.');
            
            close(wb);
            
        end % convolution               

       
        function M_IntConv = ComputeIntegrationConvolutionMatrix(this,fInt,fConv,shapeParams)
            
            if(nargin<4)
                shapeParams = struct;
            end
            
            % Weighted integration in y1 (spectral)
            
            % set up spectral line
            geom1.N = this.N1;
            geom1.yMin = this.y1Min;
            geom1.yMax = this.y1Max;
            sLine = SpectralLine(geom1);

            % compute integration weights
            Int1 = sLine.ComputeIntegrationVector;
            ws = sLine.Pts.y;
            gLine = fInt(ws);
            I1Line = Int1.* gLine';
            I1Rep = repmat(I1Line,[this.N1,1]);
            I1 = sparse(kron(I1Rep,eye(this.N2)));
            
            % Convolution in y2 (Fourier)
            
            % set up Fourier line
            geom2.N = this.N2;
            geom2.yMin = this.y2Min;
            geom2.yMax = this.y2Max;
            fLine = FourierLine(geom2);

            % compute convolution (which requires the integration vector)
            fLine.ComputeIntegrationVector;
            % format: C2 = fLine.ComputeConvolutionMatrix(this,f,shapeParams,parent)
            C2Line = fLine.ComputeConvolutionMatrix(fConv,shapeParams);
            C2 = sparse(kron(eye(this.N1),C2Line));
            
            % Full integral
            M_IntConv = C2*I1;
        end


        function [M_ConvConv,C1,C2,C1Line,C2Line] = ComputeConvolutionConvolutionMatrix(this,f1,f2,shapeParams1,shapeParams2)
            
            
            % Convolution in y1 (spectral) with cutoff
            
            % set up spectral line
            geom1.N = this.N1;
            geom1.yMin = this.y1Min;
            geom1.yMax = this.y1Max;
            sLine = SpectralLine(geom1);

            % compute convolution in y1
            sLine.ComputeIntegrationVector;
            C1Line = sLine.ComputeConvolutionMatrix_Pointwise(f1,shapeParams1);
            C1 = sparse(kron(C1Line,eye(this.N2)));
            
            % Convolution in y2 (Fourier)
            
            % set up Fourier line
            geom2.N = this.N2;
            geom2.yMin = this.y2Min;
            geom2.yMax = this.y2Max;
            fLine = FourierLine(geom2);

            % compute convolution (which requires the integration vector)
            fLine.ComputeIntegrationVector;
            C2Line = fLine.ComputeConvolutionMatrix(f2,shapeParams2);
            C2 = sparse(kron(eye(this.N1),C2Line));
            
            % Full convolution
            M_ConvConv = C1*C2;
        end


        function [Int1,Int2] = Compute1DIntegrationMatrices(this)

            % Spectral integration
            geom1.N = this.N1;
            geom1.yMin = this.y1Min;
            geom1.yMax = this.y1Max;
            sLine = SpectralLine(geom1);
            I1 = sLine.ComputeIntegrationVector;
            Int1 = sparse(kron(I1,eye(this.N2)));
            
            % Fourier integration
            geom2.N = this.N2;
            geom2.yMin = this.y2Min;
            geom2.yMax = this.y2Max;
            fLine = FourierLine(geom2);
            I2 = fLine.ComputeIntegrationVector;
            Int2 = sparse(kron(eye(this.N1),I2));
        end
        
        function [M_conv_1D,M_conv] = ComputeConvolutionMatrix_1D_1(this,f,shapeParams)
      
            if(nargin<2)
                shapeParams = struct;
            end

            % Create line that corresponds to the y1 line
            geom1.N = this.N1;
            geom1.yMin = this.y1Min;
            geom1.yMax = this.y1Max;
            y1Line = SpectralLine(geom1);
            
            % Compute 1D convolution
            y1Line.ComputeIntegrationVector;
            
            % this will default to y1Line.ComputeConvolutionMatrix if
            % there's no shapeParams
            M_conv_1D = y1Line.ComputeConvolutionMatrix_Pointwise(f,shapeParams);
            
            % Copy for each y2
            M_conv = sparse(kron(M_conv_1D,eye(this.N2)));
            
        end

        function [M_conv_1D,M_conv] = ComputeConvolutionMatrix_1D_2(this,f,shapeParams)

            if(nargin<2)
                shapeParams = struct;
            end

            % Create line that corresponds to the y2 line
            geom2.N = this.N2;
            geom2.yMin = this.y2Min;
            geom2.yMax = this.y2Max;
            y2Line = FourierLine(geom2);
            
            % Compute 1D convolution
            y2Line.ComputeIntegrationVector;
            % no pointwise option as it's not needed for periodic
            M_conv_1D = y2Line.ComputeConvolutionMatrix(f,shapeParams);
            
            % Copy for each y1
            M_conv = sparse(kron(eye(this.N1),M_conv_1D));
            
        end
        
    end
    
    methods (Access = public)
        function [y1,dy1,dx,ddx,dddx,ddddx] = PhysSpace1(this,x1)            
            [y1,dy1,dx,ddx,dddx,ddddx] = LinearMap(x1,this.y1Min,this.y1Max);
        end
        function xf = CompSpace1(this,y1)
            xf  = InvLinearMap(y1,this.y1Min,this.y1Max);
        end       
        
        function [th,dth,dx,ddx,dddx,ddddx] = PhysSpace2(this,x2)    
            [th,dth,dx,ddx,dddx,ddddx] = LinearMap01(x2,this.y2Min,this.y2Max);
        end
        function x2 = CompSpace2(this,y2)                        
            x2 = (y2-this.y2Min)/(this.y2Max-this.y2Min);   
        end        
        
    end
end