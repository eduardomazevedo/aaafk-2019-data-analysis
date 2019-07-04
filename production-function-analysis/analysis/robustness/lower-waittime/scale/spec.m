%% Choose scale grid
scaleGrid = [linspace(5, 50, 10), ...
    linspace(60, 150, 10), ...
    linspace(150, 420, 10), ...
    linspace(460, 820, 10), ...
    linspace(880, 1420, 10),...
    linspace(1500, 2000, 5)];
submissionsData = readtable('./data/submissions-data.csv');
% Count
nPoints = length(scaleGrid);
 
%% Set up arrays
qArray = cell(1, nPoints);
optionsArray = cell(1, nPoints);
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c')) ...
    & submissionsData.r_arr_date_min>=19084);
 
q = entries/ sum(entries);
     
arrivalRate= 365*...
        sum(entries)/(max(submissionsData.r_dep_date_max)-19084);
 
for jj = 1 : nPoints
    options = struct();
    options.acceptanceRate1 = .70;
    options.acceptanceRate2 = .70;
    options.waitMarketTime1 = 3;
    options.waitMarketTime2 = 21;
    optionsArray{jj} = options;
    qArray{jj} = q*scaleGrid(jj);
     
end