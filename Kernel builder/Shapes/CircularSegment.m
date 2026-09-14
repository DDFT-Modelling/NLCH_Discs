 classdef CircularSegment < M1SpectralSpectral
    properties 
        R    % Radius of disc
        d    % Apothem of the segment
        s    % Sense: +1 Upper, -1 Lower segment (assumes alignment)
    end
    
    methods
        function this = CircularSegment(Geometry)
            %% Basic setup
            this@M1SpectralSpectral(Geometry.N(1),Geometry.N(2));
            
            this.R = Geometry.R;             % Radius of disc
            this.d = abs(Geometry.d);        % Apothem
            this.s = sign(Geometry.d);       % Direction of segment
            
            if(isfield(Geometry,'Origin'))              
                this.Origin = Geometry.Origin;
            end

            %% Check if intersection exists
            if abs(this.d) > this.R
                exc = MException('CircularSegment:Existence','Impossible shape.');
                throw(exc);
            end

            %% Initialise class
            InitializationPts(this);            
            
            this.polar = 'cart';
        end        
        %***************************************************************
        %   Mapping functions:
        %***************************************************************             
        function [y1_kv,y2_kv,J] = PhysSpace(this,x1,x2)        
            
            % Vertical coordinates of left side of segment
            [y2_kv, dy2dx2] = LinearMap(x2, this.s * this.d, this.s * this.R);

            % Horizontal coordinates
            left  = -sqrt( clip(this.R^2 - y2_kv.^2, 0, this.R^2) );
            right = -left;

            % Make a spectral line
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
        
        
        % Compute area inside vertilune
        function [int,area] = ComputeIntegrationVector(this)
            int = ComputeIntegrationVector@M1SpectralSpectral(this);
            
            % Check Accuracy: compute area
            % 1. Find central angle
            theta = 2 * acos( this.d / this.R );
            % 2. Compute value
            area = 0.5 * this.R^2 * (theta - sin(theta));
            
            % Check
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