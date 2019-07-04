exercise = 'first';
directory = ['./analysis/calibration/' exercise '-exercise/output/'];


load([directory 'chain_lengths.mat'])
load([directory 'poolSizeMoments.mat'])
load([directory 'typeTables.mat'])
load('./analysis/calibration/moment-conditions/realMoments.mat')



overallChains1 = overallChains;
overallpoolSize1 = overallpoolSize;
overallTransPer1 = overallTransPer;
overallTypeTables1 = overallTypeTables;

%% Pool Moments
exercise = 'second';
directory = ['./analysis/calibration/' exercise '-exercise/output/'];


load([directory 'chain_lengths.mat'])
load([directory 'poolSizeMoments.mat'])
load([directory 'typeTables.mat'])
load('./analysis/calibration/moment-conditions/realMoments.mat')

overallChains2 = overallChains;
overallpoolSize2 = overallpoolSize;
overallTransPer2 = overallTransPer;
overallTypeTables2 = overallTypeTables;

overallChains = [overallChains1([8 7 9]) overallChains2([2 4])  overallChains1(2)  overallChains2(1) ];
overallpoolSize = [overallpoolSize1([8 7 9]) overallpoolSize2([2 4])  overallpoolSize1(2)  overallpoolSize2(1) ];
overallTransPer = [overallTransPer1([8 7 9]) overallTransPer2([2 4])  overallTransPer1(2)  overallTransPer2(1) ];
overallTypeTables = [overallTypeTables1(:,[8 7 9]) overallTypeTables2(:,[2 4])  overallTypeTables1(:,2)  overallTypeTables2(:,1) ];


numPar = size(overallTypeTables,2);
numSim = size(overallTypeTables,1);
numSample = size(real.matchTypeVar,2);


clear overallChains1 overallChains2 overallpoolSize1 overallpoolSize2 overallTransPer1 overallTransPer2 overallTypeTables1 overallTypeTables2
%poolSize = [mean(mean(simAltPoolSize(1:330))) ; mean(mean(simAltPoolSize(331:660))) ; mean(mean(simAltPoolSize(661:end))) ;...
%    mean(mean(simChipPoolSize(1:330))) ; mean(mean(simChipPoolSize(331:660))) ; mean(mean(simChipPoolSize(661:end))) ;...
%    mean(mean(simPairPoolSize(1:330))) ; mean(mean(simPairPoolSize(331:660))) ; mean(mean(simPairPoolSize(661:end))) ;...
%    mean(mean(simAltruisticTrans(1:330))) ; mean(mean(simAltruisticTrans(331:660))) ; mean(mean(simAltruisticTrans(661:end))) ;...
%    mean(mean(simChipTrans(1:330))) ; mean(mean(simChipTrans(331:660))) ; mean(mean(simChipTrans(661:end))); ...
%    mean(mean(simPairTrans(1:330))) ; mean(mean(simPairTrans(331:660))) ; mean(mean(simPairTrans(661:end))); ...
%    mean(mean(simAltruisticPerish(1:330))) ; mean(mean(simAltruisticPerish(331:660))) ; mean(mean(simAltruisticPerish(661:end))); ...
%    mean(mean(simChipPerish(1:330))) ; mean(mean(simChipPerish(331:660))) ; mean(mean(simChipPerish(661:end))) ;...
%    mean(mean(simPairPerish(1:330))) ; mean(mean(simPairPerish(331:660))) ; mean(mean(simPairPerish(661:end)))];

poolSizeMoms = [1 : 9];

%% Table Moments

statTableMoms = [1 7 9 15 19 21];


%% Match Type Moments
% [twocycleRatio  threecycleRatio chainRatio sum(chainObs)/sum(chainObs./chainLenuUnq') ];

matchTypeMoms = [1 2 4];


for j = 1 : numPar
    
    for i = 1 : numSim
    
       
    statTable1 = table2array(overallTypeTables{i,j})';
    statTable1 = statTable1(:);
    statTable1 = statTable1(statTableMoms);
    statTableMoments(i,1 : length(statTableMoms))= statTable1;  
   
    end
    
    poolSize1  = overallpoolSize{j}';
    poolSize1  = poolSize1(:,poolSizeMoms);
    poolSizeMoments(: , 1 :  length(poolSizeMoms)) = poolSize1;
    
    matchType1 = overallTransPer{j};
    matchType1 = matchType1(:,matchTypeMoms);
    matchTypeMoments(: , 1 :  length(matchTypeMoms)) = matchType1;
    
    Moments{j} = [statTableMoments poolSizeMoments matchTypeMoments];

end

clear statTableMoments poolSizeMoments matchTypeMoments

for i = 1 : numSample
    
    statTable1 = table2array(real.statTableVar{i})';
    statTable1 = statTable1(:);
    statTable1 = statTable1(statTableMoms);
    statTableMoments(i,1 : length(statTableMoms))= statTable1;  
    
    poolSize1  = real.poolSizeVar{i}';
    poolSize1  = poolSize1(:,poolSizeMoms);
    poolSizeMoments(i , 1 :  length(poolSizeMoms)) = poolSize1;
    
end

matchType1 = real.matchTypeVar';
matchType1 = matchType1(:,matchTypeMoms);
matchTypeMoments(: , 1 :  length(matchTypeMoms)) = matchType1;

SampleMoments = [statTableMoments poolSizeMoments matchTypeMoments];

clear statTableMoments poolSizeMoments matchTypeMoments

    statTable1 = table2array(real.statTable)';
    statTable1 = statTable1(:);
    statTable1 = statTable1(statTableMoms);
    statTableMoments = statTable1';  
    
    
    poolSize1  = real.poolSize';
    poolSize1  = poolSize1(:,poolSizeMoms);
    poolSizeMoments = poolSize1;
   
    matchType1 = real.matchType;
    matchType1 = matchType1(:,matchTypeMoms);
    matchTypeMoments = matchType1;
    
    RealMoments = [statTableMoments poolSizeMoments matchTypeMoments];
    
for i = 1 : numPar
loss(i) = mean(Moments{i} - RealMoments) * inv(cov(SampleMoments)) * mean(Moments{i} - RealMoments)';
end

for i = 1 : numPar
loss2(i) = mean(Moments{i} - RealMoments) * inv(cov(Moments{i} - RealMoments)) * mean(Moments{i} - RealMoments)';
end

for i = 1 : numPar
loss3(i) = mean(Moments{i} - RealMoments) * inv(eye(18).*(diag(cov(SampleMoments)))) * mean(Moments{i} - RealMoments)';
end

for j = 1 : numPar
for i = 1 : numPar
lossGeneral(j,i) = mean(Moments{i} - RealMoments)*inv(cov(Moments{j} - RealMoments))*mean(Moments{i} - RealMoments)';
end
end

loss = [min(lossGeneral(:,1)) mean((lossGeneral(:,2:end)))]';
loss(5) = mean(loss(5:7));

dlmwrite('./output-for-manuscript/constants/c-calibration-loss-function-preferred.txt',loss(1),'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-calibration-loss-function-lower-fric.txt',loss(2),'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-calibration-loss-function-higher-fric.txt',loss(3),'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-calibration-loss-function-shorter-waittime.txt',loss(4),'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-calibration-loss-function-longer-waittime.txt',loss(5),'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-calibration-loss-function-shorter-bridge-waittime.txt',loss(6),'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-calibration-loss-function-longer-bridge-waittime.txt',loss(7),'precision','%.0f')
