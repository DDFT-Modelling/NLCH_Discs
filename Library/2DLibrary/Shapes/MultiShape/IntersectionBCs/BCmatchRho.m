    function [BC,mask] = BCmatchRho(data,Intersections,iShape,jShape)
        
        lenx = data.lenx;

        IB = eye(lenx); 
        BC = zeros(size(IB));
        
        Iij = Intersections(iShape,jShape);
        Iji = Intersections(jShape,iShape);
        
        IBij = sparse(IB(Iij.PtsMask,:));
        IBji = sparse(IB(Iji.PtsMask,:));
                
        if(~isempty(Iij.PtsMask))
            if(~Iij.Flip)
                BC(Iij.PtsMask,:) = IBij - IBji;
            else
                BC(Iij.PtsMask,:) = IBij - flipud(IBji);
            end
        end

        mask = (Iij.PtsMask | Iji.PtsMask);

    end