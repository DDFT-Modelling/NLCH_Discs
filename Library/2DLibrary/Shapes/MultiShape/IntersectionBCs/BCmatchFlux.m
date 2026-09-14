    function [BC,mask] = BCmatchFlux(data,Intersections,iShape,jShape)
        
        lenx = data.lenx;
        flux = data.flux;
        mult = data.mult;

        lenf = length(flux(1,:));
        vecf = (lenf == 1);

        IB = eye(lenx); 
        BC = zeros(size(IB));
        
        Iij = Intersections(iShape,jShape);
        Iji = Intersections(jShape,iShape);
        
        multij = scalarOperator(mult(Iij.PtsMask));
        multji = scalarOperator(mult(Iji.PtsMask));
        
        lres = multij*Iij.Normal*flux; % s x 1
        rres = multji*Iji.Normal*flux; % s x 1 

        if (vecf)
            ltemp = zeros(size(BC(Iij.PtsMask,:)));
            rtemp = zeros(size(BC(Iji.PtsMask,:)));

            ltemp(:,Iij.PtsMask) = scalarOperator(lres);
            rtemp(:,Iji.PtsMask) = scalarOperator(rres);
        else
            ltemp = lres;
            rtemp = rres;
        end

        if(~isempty(Iij.PtsMask))
            if(~Iij.Flip)
                BC(Iji.PtsMask,:) = ltemp + rtemp;
            else
                BC(Iji.PtsMask,:) = flipud(ltemp) + rtemp;
            end
        end

        mask = (Iij.PtsMask | Iji.PtsMask);

    end