%% Choose scale grid
scaleGrid = [linspace(5, 60, 20), ...
    linspace(65, 200, 10)];
submissionsData = readtable('./data/submissions-data.csv');
% Count
nPoints = length(scaleGrid);
 
%% Set up arrays
qArray = cell(1, nPoints);
optionsArray = cell(1, nPoints);
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c')) ...
    & submissionsData.r_arr_date_min>=19084);
 
entries = entries & ...
(submissionsData.center_nkr_share<=prctile(submissionsData.center_nkr_share(entries>0),25));
 
 
 
q = entries/ sum(entries);
     
arrivalRate= 365*...
        sum(entries)/(max(submissionsData.r_dep_date_max)-19084);
 
for jj = 1 : nPoints
    optionsArray{jj} = struct();
    qArray{jj} = q*scaleGrid(jj);
end