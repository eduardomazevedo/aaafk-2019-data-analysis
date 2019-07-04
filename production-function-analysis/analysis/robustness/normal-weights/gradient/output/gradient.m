%% Start
clear;
addpath('classes', 'aass', 'functions');


%% Load data on f outside the origin.
addpath('./analysis/robustness/normal-weights/gradient/');
spec;
rmpath('./analysis/robustness/normal-weights/gradient/');
clear optionsArray qArray;

[f, f_se] = aassGetMean('./analysis/robustness/normal-weights/gradient/');


%% Load data of f at the origin
[f0, f0_se] = aassReduce(aassGet('./analysis/robustness/normal-weights/matching-probability/'));


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
writetable(outputTable, './analysis/robustness/normal-weights/gradient/output/gradient.csv');


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
writetable(summaryTable, './analysis/robustness/normal-weights/gradient/output/summarytable.csv');