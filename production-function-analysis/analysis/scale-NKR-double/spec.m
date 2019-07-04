%% Choose scale grid
scaleGrid = [2 3 4 5];
submissionsData = readtable('./data/submissions-data.csv');
% Count
nPoints = length(scaleGrid);
numberofSimulation = 10;
 
%% Set up arrays
qArray = cell(numberofSimulation, nPoints);
optionsArray = cell(numberofSimulation, nPoints);
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c')) ...
    & submissionsData.r_arr_date_min>=19084);
 
NKRsize = (sum(entries)/977)*365;
 
q = NKRsize * (entries/ sum(entries));
     
arrivalRate= 365*...
        sum(entries)/(max(submissionsData.r_dep_date_max)-19084);
 
for jj = 1 : nPoints
     
    for ii = 1 : numberofSimulation
         
    optionsArray{ii,jj} = struct();
    qArray{ii,jj} = q*scaleGrid(jj);
     
    end
end