
addpath('./classes', './aass');
 
SS = aassGet('./analysis/scale-NKR-double/');
 
numSim = size(SS,1);
numPar = size(SS,2);
 
f_mean = zeros(numPar,1);
f_se = zeros(numPar,1);
scaleGrid = zeros(numPar,1);
S = table();
 
for i = 1 : numPar
     
[f_mean1,f_se1] = aassReduce(SS((i-1)*numSim+1 : (i)*numSim));
 
f_mean(i) = f_mean1;
f_se(i) = f_se1;
scaleGrid(i) = sum(SS{(i)*numSim}.q);
 
end
 
 
submissionsData = readtable('./data/submissions-data.csv');
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
& submissionsData.r_arr_date_min>=19084);
 
scaleGrid = scaleGrid * ...
    (1 - sum(strcmp(submissionsData.category(entries>0),'c'))/sum(entries));
 
S.f_mean = f_mean;
S.f_se = f_se;
S.scaleGrid = scaleGrid;
 
 
writetable(S, './analysis/scale-NKR-double/output/scalesummary.csv');


