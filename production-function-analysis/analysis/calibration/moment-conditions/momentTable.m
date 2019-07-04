exercise = 'first';
directory = ['./analysis/calibration/' exercise '-exercise/output/'];

load([directory 'typeTables.mat'])
load([directory 'chain_lengths.mat'])
load('./analysis/calibration/moment-conditions/realMoments.mat')

overallTypeTables1 = overallTypeTables;
overallTransPer1 = overallTransPer;
%% Pool Moments
exercise = 'second';
directory = ['./analysis/calibration/' exercise '-exercise/output/'];

load([directory 'typeTables.mat'])
load([directory 'chain_lengths.mat'])
load('./analysis/calibration/moment-conditions/realMoments.mat')

overallTypeTables2 = overallTypeTables;
overallTransPer2 = overallTransPer;


overallTypeTables = [overallTypeTables1(:,[8 7 9]) overallTypeTables2(:,[2 4])  overallTypeTables1(:,2)  overallTypeTables2(:,1) ];
overallTransPer = [overallTransPer1([8 7 9]) overallTransPer2([2 4])  overallTransPer1(2)  overallTransPer2(1) ];

numPar = size(overallTypeTables,2);
numSim = size(overallTypeTables,1);

clear overallTransPer1 overallTransPer2 overallTypeTables1 overallTypeTables2

for j = 1 : numPar
    
    TypeTablesmean = [];    
    for i = 1 : numSim
        
    TypeTablesmean(:,:,i) = table2array(overallTypeTables{i,j});  
    
    end
    
TypeTablesmean = mean(TypeTablesmean,3);
Pair(j,:) = TypeTablesmean(1,[1 3 7 8 5 6]);
Chip(j,:) = TypeTablesmean(2,[1 3 7 8 5 6]);
Alt(j,:) = TypeTablesmean(3,[1 3 7 8 5 6]);
ChainMom(j+1,:) = mean(overallTransPer{j});

end
