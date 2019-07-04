%% Start
clear;
addpath('classes', 'aass', 'functions');


%% Load data on f outside the origin.
addpath('./analysis/different-compositions/25th-participation/gradient/');
spec;
rmpath('./analysis/different-compositions/25th-participation/gradient/');
clear optionsArray qArray;

[f, f_se] = aassGetMean('./analysis/different-compositions/25th-participation/gradient/');


%% Load data of f at the origin
[f0, f0_se] = aassReduce(aassGet('./analysis/different-compositions/25th-participation/matching-probability/'));


%% Calculate derivatives
df = (f - f0) / stepSize;
df_se_idiosyncratic = f_se / stepSize;


%% Save output
outputTable = table();
outputTable.index = selectedTypes;
outputTable.df = df;
outputTable.df_se_idiosyncratic = df_se_idiosyncratic;
outputTable.df_se_systematic = repmat(f0_se / stepSize, length(df), 1);
outputTable.df_se = sqrt(outputTable.df_se_systematic.^2 + outputTable.df_se_idiosyncratic.^2);
writetable(outputTable, './analysis/different-compositions/25th-participation/gradient/output/gradient.csv');


%% Make table
hasData = ~isnan(df);
hasDataTypes = selectedTypes(hasData);
data = readtable('./data/submissions-data.csv');
data.df = nan(length(data.category), 1);
data.df(hasDataTypes) = df(hasData);

data.df_se_idiosyncratic = nan(length(data.category), 1);
data.df_se_idiosyncratic(hasDataTypes) = df_se_idiosyncratic(hasData);

data = data(hasDataTypes, :);


%% Summary table
seIdiosyncraticAverage = mean(data.df_se_idiosyncratic);

data.r_abo(strcmp(data.r_abo, '')) = {'-'};
data.d_abo(strcmp(data.d_abo, '')) = {'-'};
summaryTable = ...
    grpstats(data,{'category', 'r_abo', 'd_abo'},'mean','DataVars',{'df'});
summaryTable.se = sqrt( ...
    seIdiosyncraticAverage^2 ./ summaryTable.GroupCount ...
    + (f0_se/stepSize)^2);
writetable(summaryTable, './analysis/different-compositions/25th-participation/gradient/output/summarytable.csv');