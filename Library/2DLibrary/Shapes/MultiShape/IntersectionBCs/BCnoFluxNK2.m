    function [BC,mask] = BCnoFluxNK2(data,Intersections,iShape,jShape)

        lenx = data.lenx;
        flux = data.flux;
        mult = data.mult;

        IB = eye(lenx); 
        BC = zeros(size(IB));
        
        Iij = Intersections(iShape,jShape);
        Iji = Intersections(jShape,iShape);
        
        multij = scalarOperator(mult(Iij.PtsMask));
        multji = scalarOperator(mult(Iji.PtsMask));
        
        lres = multij*Iij.Normal*flux; % s x 1
        rres = multji*Iji.Normal*flux; % s x 1 
        
        ltemp = zeros(size(BC(Iij.PtsMask,:)));
        rtemp = zeros(size(BC(Iji.PtsMask,:)));

        ltemp(:,Iij.PtsMask) = scalarOperator(lres);
        rtemp(:,Iji.PtsMask) = scalarOperator(rres);

        if(~isempty(Iij.PtsMask))

            BC(Iij.PtsMask,:) = sparse(ltemp);
            BC(Iji.PtsMask,:) = sparse(rtemp);

        end
        
        mask = (Iij.PtsMask | Iji.PtsMask);

    end