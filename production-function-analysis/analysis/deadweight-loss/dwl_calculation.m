function [dwl,q] = dwl_calculation(f_firms,prodApprox,grid,ap_NKR) 

% Given f function, f_firms (firms production function) and
% ap_NKR(average production at NKR) calculates deadweightloss vector. 


   
        nFirms = length(f_firms);
        dwl = zeros(nFirms,1);
        q = zeros(nFirms,1);
        
        for i = 1 : nFirms
        y_firm = f_firms(i);
        if y_firm==0 | isnan(y_firm)
            dwl(i) = 0;
            q(i) = 0;
        else            
            q_firm = grid(find(prodApprox > y_firm,1)); 
            inefficiency =  ap_NKR - y_firm./q_firm ;
            dwl(i) = mean(q_firm.*inefficiency);
            q(i) = mean(q_firm);
        end
        end
end
