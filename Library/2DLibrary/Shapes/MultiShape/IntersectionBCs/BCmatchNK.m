    function [BC,mask] = BCmatchNK(data,Intersections,iShape,jShape)
        
        lenx = data.lenx;
        flux = data.flux;
        mult = data.mult;

        IB = eye(lenx); 
        BC = zeros(size(IB));
        
        Iij = Intersections(iShape,jShape);
        Iji = Intersections(jShape,iShape);
        
        IBij = sparse(IB(Iij.PtsMask,:));
        IBji = sparse(IB(Iji.PtsMask,:));
        
        multij = scalarOperator(mult(Iij.PtsMask));
        multji = scalarOperator(mult(Iji.PtsMask));
        
        if(~isempty(Iij.PtsMask))
            if(~Iij.Flip)
                BC(Iij.PtsMask,:) = IBij - IBji;
                BC(Iji.PtsMask,:) = (multij*Iij.Normal + multji*Iji.Normal)*flux;
            else
                disp('still to implement')
                BC(Iij.PtsMask,:) = IBij - flipud(IBji);
                BC(Iji.PtsMask,:) = flipud(multij*Iij.Normal*flux) + multji*Iji.Normal*flux;
            end
        end

        mask = (Iij.PtsMask | Iji.PtsMask);

    end