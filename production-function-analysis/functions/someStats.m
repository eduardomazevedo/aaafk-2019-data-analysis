function someStats = someStats(S)

numSim = length(S);

submissionsData = readtable('./data/submissions-data.csv', 'Delimiter', 'tab');
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
    & submissionsData.r_arr_date_min>=19084);
submissionsData = submissionsData(entries>0,:);
donors = submissionsData.index(strcmp(submissionsData.category,'a'));
patients = submissionsData.index(~strcmp(submissionsData.category,'a'));
pairs = submissionsData.index(strcmp(submissionsData.category,'p'));
Odonors = submissionsData.index(strcmp(submissionsData.d_abo,'O'));
Opatients = submissionsData.index(strcmp(submissionsData.r_abo,'O'));


donorWait = zeros(numSim,1);
donorWaitTrans = zeros(numSim,1);
patientWait = zeros(numSim,1);
patientWaitTrans = zeros(numSim,1);
pairWait = zeros(numSim,1);
pairWaitTrans = zeros(numSim,1);
Odonors2OpatientsRatio = zeros(numSim,1);

for i = 1 : numSim
    
table = S{i}.history.submissionsTable;
donorWait(i) = mean(table.donorDuration(ismember(table.type,donors)));
donorWaitTrans(i) = mean(table.donorDuration(table.donorTransplanted==1 ...
    & ismember(table.type,donors)));
patientWait(i) = mean(table.recipientDuration(ismember(table.type,patients)));
patientWaitTrans(i) = mean(table.recipientDuration(table.recipientTransplanted==1 ...
    & ismember(table.type,patients)));

pairWait(i) = mean(table.recipientDuration(ismember(table.type,pairs)));
pairWaitTrans(i) = mean(table.recipientDuration(table.recipientTransplanted==1 ...
    & ismember(table.type,pairs)));

patientsWithOTrans = table.transplantedRecipient(...
    ismember(table.type,Odonors) & ...
    (table.recipientTransplanted==1|table.donorTransplanted==1));
patientsWithOTrans(patientsWithOTrans==0)=[];

Odonors2OpatientsRatio(i) = mean(ismember(table.type(...
    ismember(table.id,patientsWithOTrans)),Opatients));

end
someStats.donorWait = donorWait;
someStats.donorWaitTrans = donorWaitTrans;
someStats.patientWait = patientWait;
someStats.patientWaitTrans = patientWaitTrans;
someStats.pairWait = pairWait;
someStats.pairWaitTrans = pairWaitTrans;
someStats.Odonors2OpatientsRatio = Odonors2OpatientsRatio;

end

