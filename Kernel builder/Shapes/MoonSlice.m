 classdef MoonSlice < M1SpectralSpectral
    properties 
        R
        d
    end
    
    methods
        function this = MoonSlice(Geometry)
            this@M1SpectralSpectral(Geometry.N(1),Geometry.N(2));
            
            this.R = Geometry.R;
            this.d = Geometry.d;
            
            if(isfield(Geometry,'Origin'))              
                this.Origin = Geometry.Origin;
            end
                        
            InitializationPts(this);            
            
            this.polar = 'cart';
        end        
        %***************************************************************
        %   Mapping functions:
        %***************************************************************             
        function [y1_kv,y2_kv,J] = PhysSpace(this,x1,x2)        
                       
            xIntersect = this.d/2;
            yIntersect = sqrt(this.R^2 - xIntersect^2);
                        
            [y2_kv,dy2dx2] =  LinearMap(x2,-yIntersect,yIntersect);            
            
            left = sqrt(this.R^2-y2_kv.^2);
            right = left + this.d;
            
            [y1_kv,dy1dx1] =  LinearMap(x1,left,right);

            if(nargout >= 3)
                J        = zeros(this.M,2,2);
                J(:,1,1) = dy1dx1;
                J(:,2,2) = dy2dx2;
            end

        end
        
        function [x1,x2] = CompSpace(this,y1,y2)
            exc = MException('MoonSlice:CompSpace','not yet implemented');
            throw(exc);
        end            
        
        
        function [int,area] = ComputeIntegrationVector(this)
            int = ComputeIntegrationVector@M1SpectralSpectral(this);
            
            %Check Accuracy 
            % compute area of removed segments on left
            th   = 2*acos((this.d/2)/this.R);
            areaRemovedLeft = 2 * this.R^2/2*(th-sin(th));
            % compute area of removed segments on top and bottom
            xIntersect = this.d/2;
            yIntersect = sqrt(this.R^2 - xIntersect^2);
            th   = 2*acos(yIntersect/this.R);
            areaRemovedTB = 2 * this.R^2/2*(th-sin(th));
            
            areaTotal = pi*this.R^2;
            area = areaTotal - areaRemovedLeft - areaRemovedTB;
            
            if(nargout < 2)
                if(area == 0)
                    disp(['Moon: Area is zero, Absolute error is: ',...
                                        num2str(area-sum(this.Int))]);
                else
                    disp(['Moon: Error of integration of area (ratio): ',...
                                        num2str(1-sum(this.Int)/area)]);
                end
            end
    
            
        end
            
    end
end