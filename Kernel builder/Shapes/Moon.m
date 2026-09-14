 classdef Moon < Polar_M1SpectralSpectral
    properties 
        R
        d
    end
    
    methods
        function this = Moon(Geometry)
            
            this@Polar_M1SpectralSpectral(Geometry.N(1),Geometry.N(2));
                        
            this.R    = Geometry.R;
            this.d    = Geometry.d;

            if this.d > 2*this.R
                exc = MException('Moon:Intersection','Shapes do not overlap.');
                throw(exc);
            end

            InitializationPts(this);  
            if(isfield(Geometry,'Origin'))
                this.Origin = Geometry.Origin;                    
            end
            
        end        
        %***************************************************************
        %   Mapping functions:
        %***************************************************************             
        function [y1_kv,y2_kv,J,dH1,dH2] = PhysSpace(this,x1,x2)        
            % inputs are already kron products
            
            % linear in theta
            xIntersect = this.d/2; % discs are are at (0,0) and (0,d)
            theta = asin(xIntersect/this.R); % theta at 'top' of triangle
            %% Angle should be tested
            % theta > pi/4:         Wedge 
            % theta in (0,pi/4):    Crescent moon   d <= R * sqrt(2)
            % theta = 0:            Circle implemented as half circle

            %% Build wedge or crescent moon
            % Angle at origin
            y2_kv   = LinearMap(x2,-pi/2+theta,pi/2-theta);

            % 'Inner' edge radius
            RIn = this.R*ones(size(x1));  
            
            % Compute ROut by using law of cosines
            ROut = this.d * cos(y2_kv) + sqrt( clip( this.R^2 - this.d^2 * sin(y2_kv).^2, 0.0, Inf) );
            % The other point of intersection has a - instead before sqrt

            % standard Chebyshev map from RIn to ROut; different for
            % different theta = y2
            y1_kv   = LinearMap(x1,RIn,ROut);
            
            if(nargout >= 3)
                J        = zeros(this.M,2,2);
                J(:,1,1) = (ROut - RIn)/2;                
                J(:,2,2) = (pi-2*theta)/2;
            end

            if(nargout >= 4)
                dH1        = zeros(this.M,2,2);                 
            end

            if(nargout >= 4)
                dH2        = zeros(this.M,2,2);            
            end

        end
        
        function [x1,x2] = CompSpace(this,y1,y2)
            exc = MException('Moon:CompSpace','not yet implemented');
            throw(exc);
        end
        
        function [int,area] = ComputeIntegrationVector(this)
            int = ComputeIntegrationVector@Polar_M1SpectralSpectral(this);
            
            %Check Accuracy 
            % compute area of removed segments
            th   = 2*acos((this.d/2)/this.R);
            areaRemoved = 2 * this.R^2/2*(th-sin(th));
            areaTotal = pi*this.R^2;
            area = areaTotal - areaRemoved;
            
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