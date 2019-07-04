% Create matchprob-2

%% Start
clear;
addpath('./classes', './aass');


%% Load data
S = aassGet('./analysis/matching-probability/');


%% Aggregate history table
aggregateTable = table();
data = readtable('./data/submissions-data.csv');
altruists = strcmp(data.category, 'a');

AA = find(altruists);
AltStat = table();
RestStat = table();
for i = 1 : 10 
    A = S{i}.history.submissionsTable;
    A1 = ismember (A.type,AA);
    Altruists = A(A1,:);
    AltLeft = Altruists.arrive + Altruists.donorDuration;
    Rest = A(~A1,:);
    RestLeft = Rest.arrive + Rest.recipientDuration;
    period = S{i}.t;
    
    for j = 1 :10000: period
        
       TargAlt = (AltLeft >= j & (AltLeft < j + 10000)) ;
       TargRest = (RestLeft >= j & (RestLeft < j + 10000)) ;
       
       Alt = grpstats(Altruists(TargAlt,:), ...
        {'type'}, ...
        {'mean'}, ...
        'DataVars', {'donorTransplanted'});
       Alt.Properties.RowNames = {};
       AltStat = [AltStat ; Alt];

       Rests = grpstats(Rest(TargRest,:), ...
        {'type'}, ...
        {'mean'}, ...
        'DataVars', {'recipientTransplanted'});
       Rests.Properties.RowNames = {};
       
       RestStat = [RestStat ; Rests];
    
    end
    
end
Rests2 = grpstats(RestStat, ...
{'type'}, ...
{'mean','var'}, ...
'DataVars', {'mean_recipientTransplanted'});
Alt2 = grpstats(AltStat, ...
{'type'}, ...
{'mean','var'}, ...
'DataVars', {'mean_donorTransplanted'});

matching_probability = table();
matching_probability.index = [Rests2.type ; Alt2.type];
matching_probability.matching_probability = [Rests2.mean_mean_recipientTransplanted...
    ; Alt2.mean_mean_donorTransplanted];
matching_probability.var =  [Rests2.var_mean_recipientTransplanted...
    ; Alt2.var_mean_donorTransplanted];

writetable(matching_probability, './analysis/matching-probability/output/matching-probability-2.csv');

