%% n parallel simulations
nSimulations = 50;
submissionsData = readtable('./data/submissions-data.csv');
%% Set up arrays
qArray = cell(nSimulations, 1);
optionsArray = cell(nSimulations, 1);
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
    & submissionsData.r_arr_date_min>=19084);
 
q = entries/ sum(entries);
     
arrivalRate= 365*...
        sum(entries)/(max(submissionsData.r_dep_date_max)-19084);
for ii = 1 : nSimulations
    options = struct();
    options.saveSubmissionHistory = 1;
    options.NKRStrategy = 5;
    optionsArray{ii} = options;
    qArray{ii} = q*arrivalRate;
     
end
 
clear ii;