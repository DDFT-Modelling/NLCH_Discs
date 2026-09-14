 classdef MoonGap < M1SpectralSpectral
    properties 
        R_1         % Radius of first disc O_1
        R_2         % Radius of second disc O_2
        d           % Distance between centres [0 for centred discs]
        s           % Sense: -1 if centre is left from the origin or +1 otherwise

        x_I         % horizontal coordinate of upper intersection
        y_I         % vertical coordinate of upper intersection
        Edge        % Existence of straight vertial edge
    end
    % We assume that O_2 is smaller than O_1. This function will compute
    % the MoonGap on the right until (d+R_2,0) touches the border of O_1.
    % This limits the functionality of this class for O_2 to have more than
    % one shared point with O_2 on its right side.
    
    methods
        function this = MoonGap(Geometry)
            %% Basic setup
            this@M1SpectralSpectral(Geometry.N(1),Geometry.N(2));
            
            this.R_1 = Geometry.R_1;      % Radius of O_1 (large)
            this.R_2 = Geometry.R_2;      % Radius of O_2 (small)
            this.d   = Geometry.d;        % Distance between discs
            this.s   = Geometry.s;        % Sense
            
            if(isfield(Geometry,'Origin'))              
                this.Origin = Geometry.Origin;
            end

            %% Check if intersection exists
            if this.d + this.s * this.R_2 >= this.R_1
                exc = MException('MoonGap:Intersection','Shapes do not overlap or empty region on the right.');
                throw(exc);
            end

            %% Identify one of the following two cases:
            % A: Top of O_2 is outside of O_1 (or at its intersection)
            % B: Top of O_2 is strictly contained inside O_2

            case_A = ( this.d^2 + this.R_2^2 >= this.R_1^2 );    % Region can only be generated in the case s = -1!
            case_B = ~case_A;

            %% Case A:
            if case_A
                % (x_I,y_I) is the upper intersection
                this.x_I  = clip(0.5 * ( this.R_2^2 - this.R_1^2 - this.d^2 ) / this.d, -this.R_1, 0);
                this.y_I  = sqrt( this.R_1^2 - this.x_I^2 );
                this.Edge = false;
            end
            %% Case B:
            if case_B
                % (x_I,y_I) is just the top of O_2
                this.x_I  = this.s * this.d;
                this.y_I  = this.R_2;
                this.Edge = true;
            end


            %% Initialise class
            InitializationPts(this);            
            
            this.polar = 'cart';
        end        
        %***************************************************************
        %   Mapping functions:
        %***************************************************************             
        function [y1_kv,y2_kv,J] = PhysSpace(this,x1,x2)

            % Vertical coordinates of left side: Two cases
            if this.s < 0
                % (1) all of O_1 
                [y2_kv, dy2dx2] = LinearMap(x2,-this.R_1,this.R_1);
            else
                % (2) Vertical points after centre
                y_r = sqrt( this.R_1^2 - this.x_I^2 );
                [y2_kv, dy2dx2] = LinearMap(x2,-y_r,y_r);
            end

            % The existence of an edge determines left
            % First, we split y2_kv into three sets
            Y_1 = y2_kv(y2_kv > this.y_I);
            Y_2 = y2_kv( (y2_kv >= -this.y_I) & (y2_kv <= this.y_I));
            Y_3 = y2_kv(y2_kv < -this.y_I);

            % Mid part belongs to O_2
            X_2 = this.s*this.d + sqrt( this.R_2^2 - Y_2.^2 );

            % ** Edge: two vertical sets, three partial arcs **
            if this.Edge
                % Y_1 can be split into two sets depending on the
                % additional point
                y_U = sqrt( clip(this.R_1^2 - this.x_I^2, 0.0, this.R_1^2 ) );

                % Just two vertical sides:
                if abs(y_U - this.R_1) < 1e-17
                    X_1 = zeros(size(Y_1));    X_3 = zeros(size(Y_3));
                    X_1(:) = this.x_I;        X_3(:) = this.x_I;
                else
                    % Top arc and vertical line
                    Y_1a = Y_1(Y_1 >  y_U);
                    Y_1b = Y_1(Y_1 <= y_U);
                    X_1a = -sqrt( this.R_1^2 - Y_1a.^2 );
                    X_1b = zeros(size(Y_1b));
                    X_1b(:) = this.x_I;

                    X_1 = zeros(size(Y_1));
                    X_1(Y_1 >  y_U) = X_1a;    X_1(Y_1 <= y_U) = X_1b;

                    % Bottom vertical line and arc
                    Y_3a = Y_3(Y_3 >= -y_U);
                    Y_3b = Y_3(Y_3 <  -y_U);
                    X_3a = zeros(size(Y_3a));
                    X_3a(:) = this.x_I;
                    X_3b = -sqrt( this.R_1^2 - Y_3b.^2 );
                    
                    X_3 = zeros(size(Y_3));
                    X_3(Y_3 >= -y_U) = X_3a;    X_3(Y_3 < -y_U) = X_3b;
                end
                
            end
            % ** No edge: everything is part of an arc **
            if ~this.Edge
                X_1 = -sqrt( this.R_1^2 - Y_1.^2 );
                X_3 = -sqrt( this.R_1^2 - Y_3.^2 );
            end

            % Collect parts
            left = zeros(size(y2_kv));  % Preallocate
            left(y2_kv > this.y_I) = X_1;
            left((y2_kv >= -this.y_I) & (y2_kv <= this.y_I)) = X_2;
            left(y2_kv < -this.y_I) = X_3;

            % The right coordinates are just the right projection on O_1
            right = sqrt( clip(this.R_1^2 - y2_kv.^2, 0, Inf) );

            
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
            if ~this.Edge
                % Circular segment subtracted from disc
                theta = 2.0 * asin( this.y_I / this.R_2 );
                A_sg = 0.5 * this.R_2^2 * (theta - sin(theta));
                A_O1 = pi * this.R_1^2;
                area = A_O1 - A_sg;
            end
            if this.Edge
                % Half disc subtracted from circular segment or complement
                A_hd = 0.5 * pi * this.R_1^2;    % half disc
                % Find coordinate of intersection in O_1
                y_U = this.s * sqrt( clip(this.R_1^2 - this.x_I, 0.0, this.R_1^2) );
                % Angle of segment
                theta = 2.0 * asin( y_U / this.R_1 );
                % If s = -1: complement of segment
                % if s =  1: segment
                A_SG = 0.5 * this.R_1^2 * (theta - sin(theta));
                if this.s < 0
                    A_SG = pi * this.R_1^2 - A_SG;
                end
                area = A_SG - A_hd;
            end
            
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