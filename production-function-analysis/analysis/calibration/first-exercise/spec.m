% Calibration exercise
submissionsData = readtable('./data/submissions-data.csv');
%% n parallel simulations
nSimulations = 100;

entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
    & submissionsData.r_arr_date_min>=19084);

q = entries/ sum(entries);
    
arrivalRate= 365*...
        sum(entries)/(max(submissionsData.r_dep_date_max)-19084);
%% Set up arrays



waitMarket1 =           [14 14 14 14 14 14 14 14 14];
waitMarket2 =           [14 14 14 14 14 14 14 14 14];
acceptPhase1 =          [0.8 0.75 0.7 0.8 0.75 0.7 0.8 0.75 0.7];
acceptPhase2 = acceptPhase1;
bridgeTimeLimitODABO = [7 7 7 21 21 21 30 30 30];
bridgeTimeLimit = [7 7 7 21 21 21 30 30 30];
numParameter = length(acceptPhase1); 
qArray = cell(nSimulations, numParameter);
optionsArray = cell(nSimulations, numParameter);
for ii = 1 : nSimulations
    for jj = 1 : numParameter
    options = struct();
    options.acceptanceRate1 = acceptPhase1(jj);
    options.acceptanceRate2 = acceptPhase2(jj);
    options.waitMarketTime1 = waitMarket1(jj);
    options.waitMarketTime2 = waitMarket2(jj);
    options.bridgeTimeLimit = bridgeTimeLimit(jj);
    options.bridgeTimeLimitODAB0 = bridgeTimeLimitODABO(jj);
    
    %options.match.itaiReps = 25;
    %options.match.johnsonReps = 5;
    %options.match.johnsonTimeOut = 10;
    options.match.gurobiTimeOut = 600;
    optionsArray{ii,jj} = options;
    qArray{ii,jj} = q*arrivalRate;
    end
end

clear ii jj submissionsData;