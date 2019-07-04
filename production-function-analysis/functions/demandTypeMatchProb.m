function results = demandTypeMatchProb(directory)

addpath('./classes','./data', './aass');
addpath(directory)
spec;
rmpath(directory)

clear optionsArray qArray arrivalRate q nPoints

scaleGrid = scaleGrid * ...
    (1 - sum(strcmp(submissionsData.category(entries>0),'c'))/sum(entries));

%% Load data
%% Aggregate history table

S = aassGet(directory);

overdemanded = find((strcmp(submissionsData.r_abo,'A')&strcmp(submissionsData.d_abo,'O'))|...
(strcmp(submissionsData.r_abo,'B')&strcmp(submissionsData.d_abo,'O'))|...
(strcmp(submissionsData.r_abo,'AB')&strcmp(submissionsData.d_abo,'O'))|...
(strcmp(submissionsData.r_abo,'AB')&strcmp(submissionsData.d_abo,'A'))|...
(strcmp(submissionsData.r_abo,'AB')&strcmp(submissionsData.d_abo,'B')));
underdemanded = find((strcmp(submissionsData.r_abo,'O')&strcmp(submissionsData.d_abo,'A'))|...
(strcmp(submissionsData.r_abo,'O')&strcmp(submissionsData.d_abo,'B'))|...
(strcmp(submissionsData.r_abo,'O')&strcmp(submissionsData.d_abo,'AB'))|...
(strcmp(submissionsData.r_abo,'A')&strcmp(submissionsData.d_abo,'AB'))|...
(strcmp(submissionsData.r_abo,'B')&strcmp(submissionsData.d_abo,'AB')));
selfdemanded = find((strcmp(submissionsData.r_abo,'A')&strcmp(submissionsData.d_abo,'A'))|...
(strcmp(submissionsData.r_abo,'B')&strcmp(submissionsData.d_abo,'B'))|...
(strcmp(submissionsData.r_abo,'AB')&strcmp(submissionsData.d_abo,'AB'))|...
(strcmp(submissionsData.r_abo,'O')&strcmp(submissionsData.d_abo,'O'))|...
(strcmp(submissionsData.r_abo,'A')&strcmp(submissionsData.d_abo,'B'))|...
(strcmp(submissionsData.r_abo,'B')&strcmp(submissionsData.d_abo,'A')));

overdemandedMatch = zeros(length(S),1);
underdemandedMatch = zeros(length(S),1);
selfdemandedMatch = zeros(length(S),1);





for ii = 1 : length(S)
s = S{ii};
Table = s.history.submissionsTable;
Table = Table(Table.arrive>2000,{'type','recipientTransplanted'});
overdemandedMatch(ii) = ...
    mean(Table.recipientTransplanted(ismember(Table.type,overdemanded)));
underdemandedMatch(ii) = ...
    mean(Table.recipientTransplanted(ismember(Table.type,underdemandedMatch)));
selfdemandedMatch(ii) = ...
    mean(Table.recipientTransplanted(ismember(Table.type,selfdemandedMatch)));
end;

results = [scaleGrid' overdemandedMatch underdemandedMatch selfdemandedMatch];



end

