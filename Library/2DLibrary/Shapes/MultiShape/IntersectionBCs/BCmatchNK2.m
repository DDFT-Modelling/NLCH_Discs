    function [BC,mask] = BCmatchNK2(data,Intersections,iShape,jShape)
        
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
        
        lres = multij*Iij.Normal*flux; % s x 1
        rres = multji*Iji.Normal*flux; % s x 1 
        
        ltemp = zeros(size(BC(Iij.PtsMask,:)));
        rtemp = zeros(size(BC(Iji.PtsMask,:)));

        ltemp(:,Iij.PtsMask) = scalarOperator(lres);
        rtemp(:,Iji.PtsMask) = scalarOperator(rres);
        
        if(~isempty(Iij.PtsMask))
            if(~Iij.Flip)
                BC(Iij.PtsMask,:) = IBij - IBji;
                BC(Iji.PtsMask,:) = ltemp + rtemp;
            else
                disp('still to implement')
%                 BC(Iij.PtsMask,:) = IBij - flipud(IBji);
%                 BC(Iji.PtsMask,:) = multij*flipud(Iij.Normal*flux) + multji*Iji.Normal*flux; 
            end
        end

        mask = (Iij.PtsMask | Iji.PtsMask);

    end