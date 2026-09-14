 classdef LuneShard < M1SpectralSpectral
    properties 
        R_1         % Radius of large disc
        R_2         % Radius of small disc
        d           % Distance between centres
        s           % Sense: +1 Upper, -1 Lower segment (assumes alignment)
    end
    
    methods
        function this = LuneShard(Geometry)
            %% Basic setup
            this@M1SpectralSpectral(Geometry.N(1),Geometry.N(2));
            
            this.R_1 = Geometry.R_1;      % Radius of large disc
            this.R_2 = Geometry.R_2;      % Radius of small disc
            this.d   = Geometry.d;        % Distance between disc
            this.s   = Geometry.s;        % Sense
            
            if(isfield(Geometry,'Origin'))
                this.Origin = Geometry.Origin;
            end

            %% Check if shape exists
            check(1) = (this.d < this.R_1);                      % Centre is contained
            check(2) = ((this.d + this.R_2)^2 >= this.R_1^2);    % Intersection exists
            check(3) = (this.d^2 + this.R_2^2 < this.R_1^2);     % Top is contained
            if ~all(check)
                exc = MException('Shardlet:Existence','Impossible shape.');
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
            
            % Find coordinates of mid point
            x_H_right = -this.d;            y_H_right = this.s * this.R_2;
            % Find coordinates of top and bottom
            x_H_left = -this.d;
            y_H_left = this.s * sqrt( clip(this.R_1^2 - x_H_left^2, 0, Inf) );

            % Find nontrivial intersection between discs
            if abs(this.d + this.R_2 - this.R_1) < 1e-17
                % Leftmost part is contained
                x_I = -this.R_1;
                y_I = 0.0;
            else
                x_I = 0.5 * ( this.R_2^2 - this.R_1^2 - this.d^2 ) / this.d;
                y_I = this.s * sqrt( this.R_1^2 - x_I^2 );
            end


            % Vertical coordinates of left side of segment
            if this.s > 0
                [y2_kv, dy2dx2] = LinearMap(x2, y_I, y_H_left);
            else
                [y2_kv, dy2dx2] = LinearMap(x2, y_H_left, y_I);
            end

            % Horizontal coordinates
            left  = -sqrt( clip(this.R_1^2 - y2_kv.^2, 0, this.R_1^2) );
            % ** Right part contains an edge and an arc **
            if this.s > 0
                Y_1 = y2_kv(y2_kv <  y_H_right);
                Y_2 = y2_kv(y2_kv >= y_H_right);
                X_1 = -this.d - sqrt( clip(this.R_2^2 - Y_1.^2, 0, this.R_2^2) );
                X_2 = zeros(size(Y_2));     X_2(:) = x_H_right;

                right = zeros(size(y2_kv));
                right(y2_kv <  y_H_right) = X_1;
                right(y2_kv >= y_H_right) = X_2;

            else
                Y_1 = y2_kv(y2_kv >= y_H_right);
                Y_2 = y2_kv(y2_kv <  y_H_right);

                X_1 = -this.d - sqrt( clip(this.R_2^2 - Y_1.^2, 0, this.R_2^2) );
                X_2 = zeros(size(Y_2));     X_2(:) = x_H_right;

                right = zeros(size(y2_kv));
                right(y2_kv >= y_H_right) = X_1;
                right(y2_kv <  y_H_right) = X_2;
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
            exc = MException('Shardlet:CompSpace','not yet implemented');
            throw(exc);
        end            
        
        
        % Compute area inside vertilune
        function [int,area] = ComputeIntegrationVector(this)
            int = ComputeIntegrationVector@M1SpectralSpectral(this);
            
            % Check Accuracy: Not implemented
            area = sum(int);
        end
            
    end
end