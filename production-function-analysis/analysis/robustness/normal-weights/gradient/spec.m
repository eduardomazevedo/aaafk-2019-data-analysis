%% Parameters
 
submissionsData = readtable('./data/submissions-data.csv');
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
    & submissionsData.r_arr_date_min>=19084);
 
     
arrivalRate= 365*...
        sum(entries)/(max(submissionsData.r_dep_date_max)-19084);
stepSize = 10;
% Get data
selectedTypes = find(entries);
clear data;
 
nSimulations = length(selectedTypes);
 
%% Set up arrays
qArray = cell(nSimulations, 1);
optionsArray = cell(nSimulations, 1);
 
for ii = 1 : nSimulations
    options = struct();
    options.NKRStrategy = 5;
    optionsArray{ii} = options;

    q = (entries/ sum(entries)) ...
        * arrivalRate;
    q(selectedTypes(ii)) =  q(selectedTypes(ii)) + stepSize;
    qArray{ii} = q;
end
 
clear ii q;