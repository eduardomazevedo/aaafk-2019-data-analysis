function [overallTypeTables] = simTypeTablesVector(directory)
% This function aggregates tables for calibration exercise of same
% parameters in one table. The output is struct of aggregated tables of each
% parameters. 

addpath('aass', 'classes', 'functions','analysis');

warning('off','all')
addpath(directory)
spec;
addpath(directory)
SS = aassGet(directory);
I = ~cellfun(@isempty, SS);
SS(:,sum(I) == 0) = [];
numofPar = size(SS,2);
overallTypeTables = cell(numofPar,1);
for j = 1 : numofPar

for i = 1 : 100
    SS{i,j}.burn = 0;
overallTypeTable = table2array(SS{i,j}.typeTable);
variableNames = SS{i,j}.typeTable.Properties.VariableNames;
typeVar = find(strcmp(variableNames,'type'));
countVar = find(strcmp(variableNames,'GroupCount'));
overallTypeTable = [overallTypeTable(:,[typeVar countVar])...
    overallTypeTable(:,3:6).*repmat(overallTypeTable(:,countVar),1,4)...
    overallTypeTable(:,7).*(overallTypeTable(:,countVar).*overallTypeTable(:,5))...
    overallTypeTable(:,8).*(overallTypeTable(:,countVar).*(1-overallTypeTable(:,5)))...
    overallTypeTable(:,9).*(overallTypeTable(:,countVar).*overallTypeTable(:,3))...
    overallTypeTable(:,10).*(overallTypeTable(:,countVar).*(1-overallTypeTable(:,3)))];
overallTypeTable = array2table(overallTypeTable,...
    'VariableNames',variableNames);

overallTypeTables{i,j} = summaryTable(overallTypeTable,1);
end
end

directory = [directory 'output/' ];

fileName = ['typeTables.mat'];
fileName = fullfile(directory, fileName);
save(fileName, 'overallTypeTables');

end