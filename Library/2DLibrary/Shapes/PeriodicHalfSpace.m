classdef PeriodicHalfSpace < SpectralFourier

    properties       
        % y1 spectral inf, y2 periodic
        y1Min = 0    % bottom of half space
        y2Min, y2Max % periodic box bounds
        L1 % stretching parameter for half infinite domain
        L2 % length of periodic domain
    end
    
    methods        
        function this = PeriodicHalfSpace(Geometry)
            this@SpectralFourier(Geometry.N(1),Geometry.N(2));
                        
            this.y1Min = Geometry.y1Min;
            
            this.y2Min = Geometry.y2Min;
            this.y2Max = Geometry.y2Max;
            
            this.L1 = Geometry.L1;
            this.L2 = this.y2Max - this.y2Min;
            
            InitializationPts(this);      
            this.polar = 'cart';
        end                         
    
        % overridden from SpectralFourier to deal with infinite entries in
        % the integration vector
        function int = ComputeIntegrationVector(this)
            int = ComputeIntegrationVector@SpectralFourier(this);
            int(~isfinite(int)) = 0; % deal with points at \pm \infty
            this.Int = int;
        end
        
    end
    
    methods (Access = public)
        
        function [y1,dy1,dx,ddx,dddx,ddddx] = PhysSpace1(this,x1)
            [y1,dy1,dx,ddx,dddx,ddddx] = QuotientMap(x1,this.L1,this.y1Min,inf);
        end
        function x1 = CompSpace1(this,y1)
            x1  = InvQuotientMap(y1,this.L1,this.y1Min,inf);
        end               
        function [y2,dy2,dx,ddx,dddx,ddddx] = PhysSpace2(this,x2)    
            [y2,dy2,dx,ddx,dddx,ddddx] = LinearMap01(x2,this.y2Min,this.y2Max);
        end
        function x2 = CompSpace2(this,y2)                        
            x2 = (y2-this.y2Min)/(this.y2Max-this.y2Min);   
        end        
        
    end
end