    function [BC,mask] = BCnoFluxNK(data,Intersections,iShape,jShape)

        lenx = data.lenx;
        flux = data.flux;
        mult = data.mult;

        IB = eye(lenx); 
        BC = zeros(size(IB));
        
        Iij = Intersections(iShape,jShape);
        Iji = Intersections(jShape,iShape);
        
        multij = scalarOperator(mult(Iij.PtsMask));
        multji = scalarOperator(mult(Iji.PtsMask));

        if(~isempty(Iij.PtsMask))

            BC(Iij.PtsMask,:) = (multij*Iij.Normal) * flux;
            BC(Iji.PtsMask,:) = (multji*Iji.Normal) * flux;

        end
        
        mask = (Iij.PtsMask | Iji.PtsMask);

    end