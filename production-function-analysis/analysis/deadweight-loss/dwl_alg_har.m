function [trace, df1 ,q ] = dwl_alg_har(p0, q0, df0, D2f, D2C)
 
alpha0 = 0.01;
eps = 0.0001 ; 
 
p = p0;
q = q0';
 
k = 1;
 
trace.p(k, :) = p;
trace.q(k, :) = q;
 
 
g_0 = alpha0 * df0 + (1 - alpha0) * p(:,1); 
 
p = g_0;
 
trace.p(2, :) = p;
 
q = trace.q(1,:) +  (trace.p(2,:) - p0) * inv(D2C)';
 
trace.q(2, :) = q;
 
df1 = df0 +  (trace.q(2,:) - q0') * D2f';
 
k = 2;
 
while sum(abs(df1 - trace.p(k,:))) > eps
     
 g = alpha0 * df1 + (1 - alpha0) * trace.p(k,:);  
  
 p = g;
  
 trace.p(k+1, :) = p;
   
 q = trace.q(k,:) + (trace.p(k+1,:) - trace.p(k,:)) * inv(D2C)';
  
 trace.q(k+1, :) = q;
  
 df1 = df0 +  (trace.q(k+1,:) - q0') * D2f;
  
 k = k + 1;  
  
 
end
 
 
 
end