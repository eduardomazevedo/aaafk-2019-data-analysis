function  [simulation_calib,realmarket_stat] = figuresFromCalibration(directory)
% Given the directory of calibration exercise this function creates plots
% for pairs, chips and altruistics for cumulative matching, cumulative
% perishing versus market size numbers with real data. It also gives a
% struct with all these pool sizes. 

addpath('aass', 'classes', 'functions','analysis');
warning('off','all')
addpath(directory)
spec;
addpath(directory)
SS = aassGet(directory);
numofSim = size(SS,1);

% April 1st 2012
stataFormatInitialDay = 19084;
I = ~cellfun(@isempty, SS);
SS(:,sum(I) == 0) = [];
numofPar = size(SS,2);

numofDays = SS{1,1}.t;

submissionsData = readtable('./data/submissions-data.csv');

chipOrders = find(strcmp(submissionsData.category,'c')) ;
pairOrders = find(strcmp(submissionsData.category,'p')) ;
altruisticOrders = find(strcmp(submissionsData.category,'a'));
simPairTrans = cell(numofPar,1);
simPairPerish = cell(numofPar,1);
simChipTrans = cell(numofPar,1);
simChipPerish = cell(numofPar,1);
simAltruisticTrans = cell(numofPar,1);
simAltruisticPerish = cell(numofPar,1);

simPairPoolSize = cell(numofPar,1);
simChipPoolSize = cell(numofPar,1);
simAltPoolSize = cell(numofPar,1);
simOverallPoolSize = cell(numofPar,1);

for j= 1 : numofPar
    
pairPool = zeros(numofSim,SS{1}.t);
chipPool = zeros(numofSim,SS{1}.t);
altPool = zeros(numofSim,SS{1}.t);
overallPool = zeros(numofSim,SS{1}.t);
transplanted = zeros(numofSim,SS{1}.t);
pairTransplanted = zeros(numofSim,SS{1}.t);
pairPerished = zeros(numofSim,SS{1}.t);
chipTransplanted = zeros(numofSim,SS{1}.t);
chipPerished = zeros(numofSim,SS{1}.t);
altruisticTransplanted = zeros(numofSim,SS{1}.t);
altruisticPerished = zeros(numofSim,SS{1}.t);

for i = 1 : numofSim
pairPool(i,:) = SS{i,j}.history.poolSize.pair;
chipPool(i,:) = SS{i,j}.history.poolSize.chip;
altPool(i,:) = SS{i,j}.history.poolSize.altruistic;
overallPool(i,:) = SS{i,j}.history.poolSize.overallMarket;
transplanted(i,:) = SS{i,j}.history.nTransplants;

table = table2array(SS{i,j}.history.submissionsTable);
PairinSim=find(ismember(table(:,2),pairOrders));
ChipinSim=find(ismember(table(:,2),chipOrders));
Alt=find(ismember(table(:,2),altruisticOrders));

for k = 1 :numofDays

pairTransplanted(i,k) = sum(((table(PairinSim,3) + table(PairinSim,5) )==k) & table(PairinSim,4)==1);
pairPerished(i,k) = sum(((table(PairinSim,3) + table(PairinSim,5) )==k) & table(PairinSim,4)==0);

chipTransplanted(i,k) = sum(((table(ChipinSim,3) + table(ChipinSim,5) )==k) & table(ChipinSim,4)==1);
chipPerished(i,k) = sum(((table(ChipinSim,3) + table(ChipinSim,5) )==k) & table(ChipinSim,4)==0);

altruisticTransplanted(i,k) = sum(((table(Alt,3) + table(Alt,7) )==k) & table(Alt,6)==1);
altruisticPerished(i,k) = sum(((table(Alt,3) + table(Alt,7) )==k) & table(Alt,6)==0);
end

end
simPairTrans{j} = pairTransplanted;
simPairPerish{j} = pairPerished;
simChipTrans{j} = chipTransplanted;
simChipPerish{j} = chipPerished;
simAltruisticTrans{j} = altruisticTransplanted;
simAltruisticPerish{j} = altruisticPerished;

simPairPoolSize{j} = pairPool;
simChipPoolSize{j} = chipPool;
simAltPoolSize{j} = altPool;
simOverallPoolSize{j} = overallPool;


end
simulation_calib.simPairTrans = simPairTrans;
simulation_calib.simPairPerish = simPairPerish;
simulation_calib.simChipTrans = simChipTrans;
simulation_calib.simChipPerish = simChipPerish;
simulation_calib.simAltruisticTrans = simAltruisticTrans;
simulation_calib.simAltruisticPerish = simAltruisticPerish;
simulation_calib.simPairPoolSize = simPairPoolSize;
simulation_calib.simChipPoolSize = simChipPoolSize;
simulation_calib.simAltPoolSize = simAltPoolSize;
simulation_calib.simOverallPoolSize = simOverallPoolSize;


for i = 1: numofDays
    
chipinRealMark(i) = sum(strcmp(submissionsData.category,'c') & ...
    (submissionsData.r_arr_date_min<= stataFormatInitialDay-1+i &...
    submissionsData.r_dep_date_max> stataFormatInitialDay-1+i));
pairinRealMark(i) = sum(strcmp(submissionsData.category,'p') & ...
    (submissionsData.r_arr_date_min<= stataFormatInitialDay-1+i &...
    submissionsData.r_dep_date_max> stataFormatInitialDay-1+i));
altruisticinRealMark(i) = sum(strcmp(submissionsData.category,'a') & ...
    (submissionsData.d_arr_date_min<= stataFormatInitialDay-1+i &...
    submissionsData.d_dep_date_max> stataFormatInitialDay-1+i));
chipTransinRealMark(i) = sum(strcmp(submissionsData.category,'c') & ...
    (...
    submissionsData.r_dep_date_max== stataFormatInitialDay-1+i)&...
    submissionsData.r_transplanted==1);
pairTransinRealMark(i) = sum(strcmp(submissionsData.category,'p') & ...
    (...
    submissionsData.r_dep_date_max== stataFormatInitialDay-1+i)&...
    submissionsData.r_transplanted==1);
altruisticTransinRealMark(i) = sum(strcmp(submissionsData.category,'a') & ...
    (...
    submissionsData.d_dep_date_max== stataFormatInitialDay-1+i)&...
    submissionsData.d_transplanted==1);

chipPerishinRealMark(i) = sum(strcmp(submissionsData.category,'c') & ...
    (...
    submissionsData.r_dep_date_max== stataFormatInitialDay-1+i)&...
    isnan(submissionsData.r_transplanted)==1);
pairPerishinRealMark(i) = sum(strcmp(submissionsData.category,'p') & ...
    (...
    submissionsData.r_dep_date_max== stataFormatInitialDay-1+i)&...
    isnan(submissionsData.r_transplanted)==1);
altruisticPerishinRealMark(i) = sum(strcmp(submissionsData.category,'a') & ...
    (...
    submissionsData.d_dep_date_max== stataFormatInitialDay-1+i)&...
    isnan(submissionsData.d_transplanted)==1);

allMarkSizeinRealMark(i) = chipinRealMark(i)+pairinRealMark(i)+altruisticinRealMark(i) ;
allTransinRealMark(i) = chipTransinRealMark(i)+pairTransinRealMark(i)+altruisticTransinRealMark(i) ;
allPerishinRealMark(i) = chipPerishinRealMark(i)+pairPerishinRealMark(i)+altruisticPerishinRealMark(i) ;
end
realmarket_stat.chipinRealMark = chipinRealMark;
realmarket_stat.pairinRealMark = pairinRealMark;
realmarket_stat.altruisticinRealMark = altruisticinRealMark;
realmarket_stat.chipTransinRealMark = chipTransinRealMark;
realmarket_stat.pairTransinRealMark = pairTransinRealMark;
realmarket_stat.altruisticTransinRealMark = altruisticTransinRealMark;
realmarket_stat.chipPerishinRealMark = chipPerishinRealMark;
realmarket_stat.pairPerishinRealMark = pairPerishinRealMark;
realmarket_stat.altruisticPerishinRealMark = altruisticPerishinRealMark;
realmarket_stat.allMarkSizeinRealMark = allMarkSizeinRealMark;
realmarket_stat.allTransinRealMark = allTransinRealMark;
realmarket_stat.allPerishinRealMark = allPerishinRealMark;
directory = [directory '/output'];
cd(directory)
save calibration_output realmarket_stat simulation_calib
cd ../
cd ../
cd ../
cd ../
end