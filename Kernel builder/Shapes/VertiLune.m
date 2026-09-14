 classdef VertiLune < M1SpectralSpectral
    properties 
        R_l         % Radius of left disc
        R_r         % Radius of right disc
        d           % Distance between centres
        s           % Sense: +1 Right -1 Left (right can only exist if l_c_r)
        x_I         % horizontal coordinate of intersection
        y_I         % vertical coordinate of intersection
        MaxAngle    % Maximum angle from origin to intersection
    end
    
    methods
        function this = VertiLune(Geometry)
            %% Basic setup
            this@M1SpectralSpectral(Geometry.N(1),Geometry.N(2));
            
            this.R_l = Geometry.R_l;      % Radius of left disc
            this.R_r = Geometry.R_r;      % Radius of right disc
            this.d   = Geometry.d;        % Distance between discs
            
            if(isfield(Geometry,'Origin'))              
                this.Origin = Geometry.Origin;
            end
            if(~isfield(Geometry,'s'))
                Geometry.s = 1;
            end
            this.s = Geometry.s;

            %% Check if intersection exists
            if this.d > this.R_l + this.R_r
                exc = MException('VertiLune:Intersection','Shapes do not overlap.');
                throw(exc);
            end

            %% Identify one of the following two cases:
            % A: Disc_r and Disc_l do not fully intersect
            % B: One disc contains the other

            r_c_l = (this.d + this.R_l <= this.R_r);    % r contains l
            l_c_r = (this.d + this.R_r <= this.R_l);    % l contains r

            %% Case A:
            if ~r_c_l && ~l_c_r
                % (x_I,y_I) is the upper intersection or division point 
                % Determine largest angle in triangle (x_I,y_I), (0,0), (d,0)
                MaxAngle = acos( (this.R_l^2 + this.d^2 - this.R_r^2)/(2 * this.R_l * this.d) );
                % If MaxAngle > pi/2, we only include the right vertilune 
                if this.d < 1e-17
                    MaxAngle = pi/2;
                end
                MaxAngle = clip(MaxAngle, 0.0, pi/2);
                this.MaxAngle = MaxAngle;
    
                % Intersection no longer happens at the midpoint of [0,d]
                % Define 'intersect': 
                %   If MaxAngle <= pi/2: Upper intersect
                %   If MaxAngle >  pi/2: Right vertilune
                this.x_I = this.R_l * cos(MaxAngle);
                this.y_I = this.R_l * sin(MaxAngle);
            end
            %% Case B:
            % Left contains right
            if l_c_r
                % Max angle is pi/2
                this.MaxAngle = pi/2;
                % Intersection occurs at top of right circle
                this.x_I = this.d;
                this.y_I = this.R_r;
            end
            % Right contains left
            if r_c_l
                % Max angle is pi/2
                this.MaxAngle = pi/2;
                % Intersection occurs at top of left circle
                this.x_I = 0.0;
                this.y_I = this.R_l;
            end


            %% Initialise class
            InitializationPts(this);            
            
            this.polar = 'cart';
        end        
        %***************************************************************
        %   Mapping functions:
        %***************************************************************             
        function [y1_kv,y2_kv,J] = PhysSpace(this,x1,x2)        
            
            % Verify cases for computation
            r_c_l = (this.d + this.R_l <= this.R_r);    % r contains l
            l_c_r = (this.d + this.R_r <= this.R_l);    % l contains r

            % Vertical coordinates of left side
            [y2_kv, dy2dx2] = LinearMap(x2,-this.y_I,this.y_I);

            % *** The following works for r_c_l and partial intersect **
            if (r_c_l || (~r_c_l && ~l_c_r)) || this.s > 0
                % Horizontal coordinates
                left = sqrt( clip(this.R_l^2 - y2_kv.^2,0,Inf) );
                
                % Find horizontal coordinates on right side
                right = this.d + sqrt( clip(this.R_r^2 - y2_kv.^2,0,Inf) );
            end
            % *** l_c_r just inverts the roles ***
            if (l_c_r || this.s < 0)
                % Horizontal coordinates
                left = this.s * sqrt( clip(this.R_r^2 - y2_kv.^2,0,Inf) );
                % Find horizontal coordinates on right side
                right = this.s * this.d + this.s * sqrt( clip(this.R_l^2 - y2_kv.^2,0,Inf) );
            end

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
            % Verify cases for computation
            r_c_l = (this.d + this.R_l <= this.R_r);    % r contains l
            l_c_r = (this.d + this.R_r <= this.R_l);    % l contains r


            % 1. Left half circle or sector
            if ~r_c_l && ~l_c_r
                % Sector
                phi = 2 * asin(this.y_I / this.R_l);    % Two lenghts
                A_S1 = 0.5 * this.R_l^2 * (phi - sin(phi));
            end
            if r_c_l
                A_S1 = 0.5 * pi * this.R_l^2;
            end
            if l_c_r
                A_S1 = 0.5 * pi * this.R_r^2;
            end

            % 2. Rectangle
            if r_c_l || (~r_c_l & ~l_c_r)
                a = this.d + sqrt( clip(this.R_r^2 - this.y_I^2, 0.0, Inf) );
            end
            if l_c_r
                a = sqrt( clip(this.R_l^2 - this.y_I^2, 0.0, Inf) );
            end
            A_R = 2 * this.y_I * abs(a - this.x_I);

            % 3. Right sector
            if r_c_l || (~r_c_l & ~l_c_r)
                phi = 2 * asin(this.y_I / this.R_r);
                A_S2 = 0.5 * this.R_r^2 * (phi - sin(phi));
            end
            if l_c_r
                phi = 2 * asin(this.y_I / this.R_l);
                A_S2 = 0.5 * this.R_l^2 * (phi - sin(phi));
            end

            %display([A_R, A_S1, A_S2])
            % 4. Compute final value
            area = (A_R - A_S1) + A_S2;
            
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