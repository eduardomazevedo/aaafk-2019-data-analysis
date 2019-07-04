function [statTable, statTableVar] = summaryTable(table,initial,realData)
% This function takes the typeTable of a simulation and creates 6*8 table
% with the summary statistics such as transplantation probs, durations of
% transplanted and not transplanted for chips, pairs, altruistics,
% over-under-normal demanded pairs. 
addpath('classes', 'functions','analysis');

submissionsData = readtable('./data/submissions-data.csv');

if nargin>1 && initial
    initial=19084;
else
    initial=0;
end
%% Simulation Summary
if nargin <3 
chips = (strcmp(submissionsData.category,'c') & ...
    submissionsData.r_arr_date_min>= initial);
pairs = (strcmp(submissionsData.category,'p') & ...
    submissionsData.r_arr_date_min>= initial);
altruistics = (strcmp(submissionsData.category,'a') & ...
    submissionsData.d_arr_date_min>= initial);
overdemanded = ...
    ((strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'O')))& ...
    (submissionsData.r_arr_date_min>= initial);

underdemanded = ...
    ((strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'AB')))& ...
    (submissionsData.r_arr_date_min>= initial);

normaldemanded = ...
    ((strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'A')))& ...
    (submissionsData.r_arr_date_min>= initial);

varNames = table.Properties.VariableNames;

statTable = array2table(zeros(0,size(varNames,2)-2));
statTable.Properties.VariableNames = varNames(3:end) ;

arrayTable = table2array(table);
%arrayTable = [arrayTable(:,1:2)...
%    arrayTable(:,3:6).*repmat(arrayTable(:,2),1,4)...
%    arrayTable(:,7).*((arrayTable(:,2).*arrayTable(:,5)))...
%    arrayTable(:,8).*((arrayTable(:,2).*(1-arrayTable(:,5))))...
%    arrayTable(:,9).*((arrayTable(:,2).*arrayTable(:,3)))...
%    arrayTable(:,10).*((arrayTable(:,2).*(1-arrayTable(:,3))))];

arrayTableContemp = nansum(arrayTable(chips,:));
arrayTableContemp = [...
    arrayTableContemp(3:6)/arrayTableContemp(2)...
    arrayTableContemp(7)/arrayTableContemp(5)...
    arrayTableContemp(8)/(arrayTableContemp(2)-arrayTableContemp(5))...
    arrayTableContemp(9)/arrayTableContemp(3)...
    arrayTableContemp(10)/(arrayTableContemp(2)-arrayTableContemp(3))];
ChipSummary = arrayTableContemp;

arrayTableContemp = nansum(arrayTable(pairs,:));
arrayTableContemp = [ ...
    arrayTableContemp(3:6)/arrayTableContemp(2)...
    arrayTableContemp(7)/arrayTableContemp(5)...
    arrayTableContemp(8)/(arrayTableContemp(2)-arrayTableContemp(5))...
    arrayTableContemp(9)/arrayTableContemp(3)...
    arrayTableContemp(10)/(arrayTableContemp(2)-arrayTableContemp(3))];
PairSummary = arrayTableContemp;

arrayTableContemp = nansum(arrayTable(altruistics,:));
arrayTableContemp = [ ...
    arrayTableContemp(3:6)/arrayTableContemp(2)...
    arrayTableContemp(7)/arrayTableContemp(5)...
    arrayTableContemp(8)/(arrayTableContemp(2)-arrayTableContemp(5))...
    arrayTableContemp(9)/arrayTableContemp(3)...
    arrayTableContemp(10)/(arrayTableContemp(2)-arrayTableContemp(3))];
AltSummary = arrayTableContemp;

arrayTableContemp = nansum(arrayTable(overdemanded,:));
arrayTableContemp = [ ...
    arrayTableContemp(3:6)/arrayTableContemp(2)...
    arrayTableContemp(7)/arrayTableContemp(5)...
    arrayTableContemp(8)/(arrayTableContemp(2)-arrayTableContemp(5))...
    arrayTableContemp(9)/arrayTableContemp(3)...
    arrayTableContemp(10)/(arrayTableContemp(2)-arrayTableContemp(3))];
OverdemandedSummary = arrayTableContemp;

arrayTableContemp = nansum(arrayTable(underdemanded,:));
arrayTableContemp = [ ...
    arrayTableContemp(3:6)/arrayTableContemp(2)...
    arrayTableContemp(7)/arrayTableContemp(5)...
    arrayTableContemp(8)/(arrayTableContemp(2)-arrayTableContemp(5))...
    arrayTableContemp(9)/arrayTableContemp(3)...
    arrayTableContemp(10)/(arrayTableContemp(2)-arrayTableContemp(3))];
UnderdemandedSummary = arrayTableContemp;

arrayTableContemp = nansum(arrayTable(normaldemanded,:));
arrayTableContemp = [ ...
    arrayTableContemp(3:6)/arrayTableContemp(2)...
    arrayTableContemp(7)/arrayTableContemp(5)...
    arrayTableContemp(8)/(arrayTableContemp(2)-arrayTableContemp(5))...
    arrayTableContemp(9)/arrayTableContemp(3)...
    arrayTableContemp(10)/(arrayTableContemp(2)-arrayTableContemp(3))];
NormaldemandedSummary = arrayTableContemp;

statTable(1,:)= array2table(PairSummary);
statTable(2,:)= array2table(ChipSummary);
statTable(3,:)= array2table(AltSummary);
statTable(4,:)= array2table(UnderdemandedSummary);
statTable(5,:)= array2table(OverdemandedSummary);
statTable(6,:)= array2table(NormaldemandedSummary);
statTable.Properties.RowNames = {'Pairs', 'Chips', 'Altruistics',...
    'UnderDemanded','OverDemanded','NormalDemanded'};

statTableVar = [];

elseif nargin==3 && realData
%% Real Data Summary
submissionsData = readtable('./data/submissions-data.csv');
initial = 19084;
chips = (strcmp(submissionsData.category,'c') & ...
    submissionsData.r_dep_date_min>= initial);
pairs = (strcmp(submissionsData.category,'p') & ...
    submissionsData.r_dep_date_min>= initial);
altruistics = (strcmp(submissionsData.category,'a') & ...
    submissionsData.d_dep_date_min>= initial);
submissionsData = submissionsData([chips + pairs+altruistics]>0,:);

chips = (strcmp(submissionsData.category,'c') & ...
    submissionsData.r_arr_date_min>= initial);
pairs = (strcmp(submissionsData.category,'p') & ...
    submissionsData.r_arr_date_min>= initial);
altruistics = (strcmp(submissionsData.category,'a') & ...
    submissionsData.d_arr_date_min>= initial);

overdemanded = ...
    ((strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'O')))& ...
    (submissionsData.r_arr_date_min>= initial);

underdemanded = ...
    ((strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'AB')))& ...
    (submissionsData.r_arr_date_min>= initial);

normaldemanded = ...
    ((strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'A')))& ...
    (submissionsData.r_arr_date_min>= initial);

varNames = {'type','GroupCount','mean_recipientTransplanted','mean_recipientDuration','mean_donorTransplanted','mean_donorDuration','mean_durationDonorTransplanted','mean_durationDonorNotTransplanted','mean_durationRecipientTransplanted','mean_durationRecipientNotTransplanted'};
statTable = array2table(zeros(6,size(varNames,2)-2));
statTable.Properties.VariableNames = varNames(3:end) ;
statTable.Properties.RowNames = {'Pairs', 'Chips', 'Altruistics',...
    'UnderDemanded','OverDemanded','NormalDemanded'};

statTable(:,1) = array2table ([...
    mean(isnan(submissionsData.r_transplanted(submissionsData.r_dep_date_max~=20061&pairs))==0);...
    mean(isnan(submissionsData.r_transplanted(submissionsData.r_dep_date_max~=20061&chips))==0);...
    mean(isnan(submissionsData.r_transplanted(submissionsData.d_dep_date_max~=20061&altruistics))==0);...
    mean(isnan(submissionsData.r_transplanted(submissionsData.r_dep_date_max~=20061&underdemanded))==0);...
    mean(isnan(submissionsData.r_transplanted(submissionsData.r_dep_date_max~=20061&overdemanded))==0);...
    mean(isnan(submissionsData.r_transplanted(submissionsData.r_dep_date_max~=20061&normaldemanded))==0);...
    ]);

statTable(:,2) = array2table ([...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&pairs))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&pairs)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&chips))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&chips)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&altruistics))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&altruistics)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&underdemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&underdemanded)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&overdemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&overdemanded)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&normaldemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&normaldemanded)))]);

statTable(:,3) = array2table ([...
    mean(isnan(submissionsData.d_transplanted(submissionsData.d_dep_date_max~=20061&pairs))==0);...
    mean(isnan(submissionsData.d_transplanted(submissionsData.d_dep_date_max~=20061&chips))==0);...
    mean(isnan(submissionsData.d_transplanted(submissionsData.d_dep_date_max~=20061&altruistics))==0);...
    mean(isnan(submissionsData.d_transplanted(submissionsData.d_dep_date_max~=20061&underdemanded))==0);...
    mean(isnan(submissionsData.d_transplanted(submissionsData.d_dep_date_max~=20061&overdemanded))==0);...
    mean(isnan(submissionsData.d_transplanted(submissionsData.d_dep_date_max~=20061&normaldemanded))==0);...
    ]);

statTable(:,4) = array2table ([...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&pairs))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&pairs)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&chips))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&chips)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&altruistics))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&altruistics)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&underdemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&underdemanded)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&overdemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&overdemanded)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&normaldemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&normaldemanded)))]);

statTable(:,5) = array2table ([...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&pairs))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&pairs)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&chips))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&chips)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&altruistics))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&altruistics)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&underdemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&underdemanded)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&overdemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&overdemanded)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&normaldemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==0&normaldemanded)))]);

statTable(:,6) = array2table ([...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&pairs))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&pairs)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&chips))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&chips)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&altruistics))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&altruistics)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&underdemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&underdemanded)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&overdemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&overdemanded)));...
        mean((submissionsData.d_dep_date_max(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&normaldemanded))...
    -(submissionsData.d_arr_date_min(submissionsData.d_dep_date_max~=20061&isnan(submissionsData.d_transplanted)==1&normaldemanded)))]);

statTable(:,7) = array2table ([...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&pairs))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&pairs)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&chips))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&chips)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&altruistics))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&altruistics)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&underdemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&underdemanded)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&overdemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&overdemanded)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&normaldemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==0&normaldemanded)))]);

statTable(:,8) = array2table ([...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&pairs))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&pairs)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&chips))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&chips)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&altruistics))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&altruistics)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&underdemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&underdemanded)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&overdemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&overdemanded)));...
        mean((submissionsData.r_dep_date_max(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&normaldemanded))...
    -(submissionsData.r_arr_date_min(submissionsData.r_dep_date_max~=20061&isnan(submissionsData.r_transplanted)==1&normaldemanded)))]);
    
    
for i = 1 : 100
    
    submissionsDataSample = submissionsData(randsample(1: size(submissionsData,1),size(submissionsData,1),1)',:);
    
chips = (strcmp(submissionsDataSample.category,'c') & ...
    submissionsDataSample.r_arr_date_min>= initial);
pairs = (strcmp(submissionsDataSample.category,'p') & ...
    submissionsDataSample.r_arr_date_min>= initial);
altruistics = (strcmp(submissionsDataSample.category,'a') & ...
    submissionsDataSample.d_arr_date_min>= initial);

overdemanded = ...
    ((strcmp(submissionsDataSample.r_abo,'AB')& strcmp(submissionsDataSample.d_abo,'B'))|...
    (strcmp(submissionsDataSample.r_abo,'AB')& strcmp(submissionsDataSample.d_abo,'A'))|...
    (strcmp(submissionsDataSample.r_abo,'AB')& strcmp(submissionsDataSample.d_abo,'O'))|...
    (strcmp(submissionsDataSample.r_abo,'A')& strcmp(submissionsDataSample.d_abo,'O'))|...
    (strcmp(submissionsDataSample.r_abo,'B')& strcmp(submissionsDataSample.d_abo,'O')))& ...
    (submissionsDataSample.r_arr_date_min>= initial);

underdemanded = ...
    ((strcmp(submissionsDataSample.r_abo,'O')& strcmp(submissionsDataSample.d_abo,'AB'))|...
    (strcmp(submissionsDataSample.r_abo,'O')& strcmp(submissionsDataSample.d_abo,'B'))|...
    (strcmp(submissionsDataSample.r_abo,'O')& strcmp(submissionsDataSample.d_abo,'A'))|...
    (strcmp(submissionsDataSample.r_abo,'A')& strcmp(submissionsDataSample.d_abo,'AB'))|...
    (strcmp(submissionsDataSample.r_abo,'B')& strcmp(submissionsDataSample.d_abo,'AB')))& ...
    (submissionsDataSample.r_arr_date_min>= initial);

normaldemanded = ...
    ((strcmp(submissionsDataSample.r_abo,'AB')& strcmp(submissionsDataSample.d_abo,'AB'))|...
    (strcmp(submissionsDataSample.r_abo,'B')& strcmp(submissionsDataSample.d_abo,'B'))|...
    (strcmp(submissionsDataSample.r_abo,'A')& strcmp(submissionsDataSample.d_abo,'A'))|...
    (strcmp(submissionsDataSample.r_abo,'O')& strcmp(submissionsDataSample.d_abo,'O'))|...
    (strcmp(submissionsDataSample.r_abo,'A')& strcmp(submissionsDataSample.d_abo,'B'))|...
    (strcmp(submissionsDataSample.r_abo,'B')& strcmp(submissionsDataSample.d_abo,'A')))& ...
    (submissionsDataSample.r_arr_date_min>= initial);

varNames = {'type','GroupCount','mean_recipientTransplanted','mean_recipientDuration','mean_donorTransplanted','mean_donorDuration','mean_durationDonorTransplanted','mean_durationDonorNotTransplanted','mean_durationRecipientTransplanted','mean_durationRecipientNotTransplanted'};
statTableVarSample = array2table(zeros(6,size(varNames,2)-2));
statTableVarSample.Properties.VariableNames = varNames(3:end) ;
statTableVarSample.Properties.RowNames = {'Pairs', 'Chips', 'Altruistics',...
    'UnderDemanded','OverDemanded','NormalDemanded'};

statTableVarSample(:,1) = array2table ([...
    mean(isnan(submissionsDataSample.r_transplanted(submissionsDataSample.r_dep_date_max~=20061&pairs))==0);...
    mean(isnan(submissionsDataSample.r_transplanted(submissionsDataSample.r_dep_date_max~=20061&chips))==0);...
    mean(isnan(submissionsDataSample.r_transplanted(submissionsDataSample.d_dep_date_max~=20061&altruistics))==0);...
    mean(isnan(submissionsDataSample.r_transplanted(submissionsDataSample.r_dep_date_max~=20061&underdemanded))==0);...
    mean(isnan(submissionsDataSample.r_transplanted(submissionsDataSample.r_dep_date_max~=20061&overdemanded))==0);...
    mean(isnan(submissionsDataSample.r_transplanted(submissionsDataSample.r_dep_date_max~=20061&normaldemanded))==0);...
    ]);

statTableVarSample(:,2) = array2table ([...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&pairs))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&pairs)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&chips))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&chips)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&altruistics))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&altruistics)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&underdemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&underdemanded)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&overdemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&overdemanded)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&normaldemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&normaldemanded)))]);

statTableVarSample(:,3) = array2table ([...
    mean(isnan(submissionsDataSample.d_transplanted(submissionsDataSample.d_dep_date_max~=20061&pairs))==0);...
    mean(isnan(submissionsDataSample.d_transplanted(submissionsDataSample.d_dep_date_max~=20061&chips))==0);...
    mean(isnan(submissionsDataSample.d_transplanted(submissionsDataSample.d_dep_date_max~=20061&altruistics))==0);...
    mean(isnan(submissionsDataSample.d_transplanted(submissionsDataSample.d_dep_date_max~=20061&underdemanded))==0);...
    mean(isnan(submissionsDataSample.d_transplanted(submissionsDataSample.d_dep_date_max~=20061&overdemanded))==0);...
    mean(isnan(submissionsDataSample.d_transplanted(submissionsDataSample.d_dep_date_max~=20061&normaldemanded))==0);...
    ]);

statTableVarSample(:,4) = array2table ([...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&pairs))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&pairs)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&chips))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&chips)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&altruistics))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&altruistics)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&underdemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&underdemanded)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&overdemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&overdemanded)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&normaldemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&normaldemanded)))]);

statTableVarSample(:,5) = array2table ([...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&pairs))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&pairs)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&chips))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&chips)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&altruistics))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&altruistics)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&underdemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&underdemanded)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&overdemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&overdemanded)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&normaldemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==0&normaldemanded)))]);

statTableVarSample(:,6) = array2table ([...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&pairs))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&pairs)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&chips))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&chips)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&altruistics))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&altruistics)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&underdemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&underdemanded)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&overdemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&overdemanded)));...
        mean((submissionsDataSample.d_dep_date_max(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&normaldemanded))...
    -(submissionsDataSample.d_arr_date_min(submissionsDataSample.d_dep_date_max~=20061&isnan(submissionsDataSample.d_transplanted)==1&normaldemanded)))]);

statTableVarSample(:,7) = array2table ([...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&pairs))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&pairs)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&chips))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&chips)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&altruistics))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&altruistics)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&underdemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&underdemanded)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&overdemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&overdemanded)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&normaldemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==0&normaldemanded)))]);

statTableVarSample(:,8) = array2table ([...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&pairs))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&pairs)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&chips))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&chips)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&altruistics))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&altruistics)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&underdemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&underdemanded)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&overdemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&overdemanded)));...
        mean((submissionsDataSample.r_dep_date_max(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&normaldemanded))...
    -(submissionsDataSample.r_arr_date_min(submissionsDataSample.r_dep_date_max~=20061&isnan(submissionsDataSample.r_transplanted)==1&normaldemanded)))]);
statTableVar{i} = statTableVarSample;
end



end
end