%% Start
clear;
addpath('classes', 'aass', 'functions');
 
 
%% Load spec.m files for stepsize and data description.
addpath('./analysis/gradient-cross-derivative/');
spec;
addpath('./analysis/gradient-cross-derivative/');
clear optionsArray qArray;
 
%% Load data on second and cross derivatives of S
[f, f_se] = aassGetMean('./analysis/gradient-cross-derivative/');
 
 
 
%% Load data of f at the origin
[f0, f0_se] = aassReduce(aassGet('./analysis/matching-probability/'));



cd output
save D2f f f_se f0 f0_se
cd ..



 
D2f = zeros(numberofGroups);
 
D2f_se = zeros(numberofGroups);
 
% We use f(x+2h)-2*f(x+h)+f(x)/h^2 for second derivatives
% and  f(x+h,y+h)-f(x+h,y)-f(x,y+h)+f(x,y)/h^2 for cross derivatives
for i = groups 
     
    for j = groups
         
        if i == j
             
            D2f(i,i) = (f(i+numberofGroups) - 2 * f(i) + f0) / stepSize^2;
            D2f_se(i,i) = (f_se(i+numberofGroups) + 2 * f_se(i) + f0_se) / stepSize^2;
             
        elseif i < j
             
            crossIncrease = find(ismember(typeSelection , [i j],'rows'));
             
            D2f(i,j) = (f(crossIncrease) - f(i) - f(j) + f0) / stepSize^2;
            D2f_se(i,j) = (f_se(crossIncrease) + f_se(i) + f_se(j) + f0_se) / stepSize^2;
        end
    end
end
D2f = D2f' + D2f - diag(diag(D2f));
D2f_se = D2f_se' + D2f_se - diag(diag(D2f_se));
cd output
save D2fMat D2f D2f_se
cd ..