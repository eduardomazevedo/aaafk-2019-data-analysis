%% Get data
 
% Original submission data file with demand types and regression groups

submissionsData = readtable('./data/submissions-data.csv');
data = readtable( './output/regressionTreeCategories.csv');
groupTree = zeros(size(submissionsData,1),1);
groupTree(ismember(submissionsData.index,data.index)) = data.groupTree;
submissionsData.groupTree = groupTree;

entries = (strcmp(submissionsData.category, 'a') & submissionsData.d_arr_date_min >= 19084) + ...
    ((strcmp(submissionsData.category, 'p') |strcmp(submissionsData.category, 'c'))...
    & submissionsData.r_arr_date_min >= 19084);
 
arrivalRate= 365 * ...
        sum(entries)/(max(submissionsData.r_dep_date_max) - 19084);
     
stepSize = 25;
 
numberOfSimulation = 1;
%% Type selection
 
% Not counting 0s
numberofGroups = length(unique([submissionsData.groupTree])) - 1;
 
N = 3;
 
groups = [1:(N-1) (N+1):numberofGroups ];
% For cross derivative calculations we use each groups and each
% combinations of two. So we have (numberofGroups * (numberofGroups - 1) /
% 2) + 2 * numberofGroups simulations. 
 
typeSelection = [([groups ; groups ])' ; ...
    ([groups ; groups ])' ; ...
    combnk(groups, 2)];
 
% We are going to add more chips in to the market, in order to altruists to
% be able to close up chains.
 
neutralizedGroup = submissionsData.groupTree == N & entries;
 
nSimulations = size(typeSelection, 1);
 
expectedNSimulations = ((numberofGroups - 1) * (numberofGroups - 2)) / 2 + ...
    2 * (numberofGroups - 1);
 
if nSimulations ~= expectedNSimulations
  error('Number of groups is different than expected!');
end
 
%% Set up arrays
 
qArray = cell(nSimulations * numberOfSimulation, 1);
optionsArray = cell(nSimulations * numberOfSimulation, 1);
 
for ii = 1 : nSimulations
     
    for jj = 1 : numberOfSimulation
         
    optionsArray{ (ii - 1) * numberOfSimulation + jj} = struct();
     
    q = (entries / sum(entries)) ...
        * arrivalRate;
     
    % Adding chips
     
    q =  q - (neutralizedGroup *...
       (stepSize / sum(neutralizedGroup)));
 
    % Here we pick the types for each group and increase the total arrival 
    % rate of the group by the stepsize      
    q =  q + (([submissionsData.groupTree] == typeSelection(ii, 1)) *...
        (stepSize / sum([submissionsData.groupTree] == typeSelection(ii, 1))));
     
    % For cross derivatives, increase both groups arrival rate by stepsize
     
    if ii > numberofGroups
         
    q =  q + (([submissionsData.groupTree] == typeSelection(ii, 2)) *...
        (stepSize / sum([submissionsData.groupTree] == typeSelection(ii, 2))));
     
    q =  q - (neutralizedGroup *...
       (stepSize / sum(neutralizedGroup)));    
     
    end
     
    qArray{ (ii - 1) * numberOfSimulation + jj} = q;
  
    end
     
end
 
clear submissionsData;
 
clear ii q;