%% Start
clear;
addpath('./classes', './aass');


%% Load data
S = aassGet('./analysis/different-compositions/25th-participation/matching-probability/');


%% Aggregate history table
aggregateTable = table();
data = readtable('./data/submissions-data.csv');
altruists = strcmp(data.category, 'a');
for ii = 1 : length(S)
    s = S{ii};
    s.burn = 2000;
    t = (s.typeTable);
    %t = t(t.arrive > s.burn, {'type', 'recipientTransplanted', 'donorTransplanted'});
    %altruists = cellfun(@isempty, t.mean_recipientTransplanted);
    t.matched = t.mean_recipientTransplanted;
    t.matched(altruists) = t.mean_donorTransplanted(altruists);
    %t.matched = cell2mat(t.matched);
    t = t(:, {'type', 'matched'});
    %t = table2array(t);
    aggregateTable = [aggregateTable; t];
end;

clear S s t


%% Compute probabilities
aggregateTable = grpstats(aggregateTable, 'type', 'mean', 'DataVars', 'matched');

results = table();
results.index = aggregateTable.type;
results.matching_probability = aggregateTable.mean_matched;

%if height(results) ~= 2929
%    error('We dont have estimates for 2929 types.');
%end;

% Only save results for the submissions for which we ran a simulation.
entries = (strcmp(data.category,'a') & data.d_arr_date_min>=19084) + ...
((strcmp(data.category,'p') |strcmp(data.category,'c'))...
& data.r_arr_date_min>=19084);
results = results(entries>0,:);
%% Save
writetable(results, './analysis/different-compositions/25th-participation/matching-probability/output/matching-probability.csv');