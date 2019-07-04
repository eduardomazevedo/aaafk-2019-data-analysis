%This script creates sets of constants for the manuscript. It uses data
%folder and output folder of various analyses then creates .txt files
%within the ./output-for-manuscript folder. 


%% NKR average production

addpath('aass', 'classes', 'functions');
data = readtable('./data/submissions-data.csv');
submissionsData = data;
entries = (strcmp(submissionsData.category, 'a') & submissionsData.d_arr_date_min>=19084) + ...
((strcmp(submissionsData.category, 'p') |strcmp(submissionsData.category, 'c'))...
& submissionsData.r_arr_date_min>=19084);

onlyDonor = (1 - sum(strcmp(submissionsData.category(entries>0),'c'))/sum(entries));
arrivalPerYear = (onlyDonor*365*sum(entries)/(max(submissionsData.r_dep_date_max) - 19084));
arrivalPerYear = round((arrivalPerYear*100))/100;

SS = readtable('./analysis/scale/output/scalesummary.csv');
SS2 = readtable('./analysis/scale-NKR-double/output/scalesummary.csv');

scaleGrid = SS.scaleGrid;
scaleGrid = scaleGrid * onlyDonor;
   

NKRsize = find(abs(scaleGrid - arrivalPerYear)==min(abs(scaleGrid - arrivalPerYear)));
halfNKR = find(abs(scaleGrid - arrivalPerYear/2)==min(abs(scaleGrid - arrivalPerYear/2)));

data = submissionsData(entries>0,:);
theoreticalMaxNKR = theoreticalMax(data);

averageProdNKR = SS.f_mean(NKRsize)/scaleGrid(NKRsize);
averageProdHalfNKR = SS.f_mean(halfNKR)/scaleGrid(halfNKR);
averageProdDoubleNKR = SS2.f_mean(1)/SS2.scaleGrid(1);
averageProdTripleNKR = SS2.f_mean(2)/SS2.scaleGrid(2);
averageProdQuadrupleNKR = SS2.f_mean(3)/SS2.scaleGrid(3);


dlmwrite('./output-for-manuscript/constants/c-average-product-nkr.txt',averageProdNKR,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-average-product-half-nkr-size.txt',averageProdHalfNKR,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-average-product-double-nkr-size.txt',averageProdDoubleNKR,'precision','%.3f')
dlmwrite('./output-for-manuscript/constants/c-average-product-triple-nkr-size.txt',averageProdTripleNKR,'precision','%.3f')
dlmwrite('./output-for-manuscript/constants/c-average-product-quadruple-nkr-size.txt',averageProdQuadrupleNKR,'precision','%.3f')
dlmwrite('./output-for-manuscript/constants/c-arrivals-per-year-nkr.txt',arrivalPerYear,'precision','%.0f')

%% DWL & Centers

centerDataDWL = readtable( './output/centers-deadweight-loss.csv');
numberofPke = centerDataDWL.Center_IntPkeTransplantationPerYear(...
    centerDataDWL.Center_IntPkeTransplantationPerYear>0);
pkeCenters = [centerDataDWL.Estimate_Q_Base(centerDataDWL.Estimate_Q_Base>0)];
pkeCenters = sort(pkeCenters);
medianCenterArrival = median(pkeCenters);
ninetyorder = floor((length(pkeCenters)/100)*90);
ninetythPercentileCenterArrival = pkeCenters(ninetyorder);
methodistArrival = max(pkeCenters);


estimatedHospitalFlow = sum(centerDataDWL.Estimate_Q_Base);
estimatedHospitalFlow_75 = sum(centerDataDWL.Estimate_Q_25th);
estimatedHospitalFlow_25 = sum(centerDataDWL.Estimate_Q_75th);



averageProdmedianCenter = mean(centerDataDWL.Center_IntPkeTransplantationPerYear(...
    (centerDataDWL.Estimate_Q_Base == medianCenterArrival))./medianCenterArrival);

averageProdnintythPercentileCenter = mean(centerDataDWL.Center_IntPkeTransplantationPerYear(...
    (centerDataDWL.Estimate_Q_Base == ninetythPercentileCenterArrival))./ninetythPercentileCenterArrival);

averageProdmethodist = mean(centerDataDWL.Center_IntPkeTransplantationPerYear(...
    (centerDataDWL.Estimate_Q_Base == methodistArrival))./methodistArrival);

PKEmedianCenter = median(numberofPke);
PKEstandardDeviation = std(numberofPke);
PKEnintypercentile = prctile(numberofPke,90);
PKEmethodist = max(numberofPke);

totalDWL = sum(centerDataDWL.DWL_Base);
centerData = readtable( './data/ctr-data.csv');
centerData(centerData.n_pke_tx_per_year == 0,:) = [];  

QuartileNKR4 = centerData.nkr_share <= prctile(centerData.nkr_share(centerData.nkr_share>0),25)& ...
    centerData.nkr_share > 0;
centersinLowestQuantile = sum(QuartileNKR4);

DWLLowestQuantile = sum(centerDataDWL.DWL_Base(QuartileNKR4));

partNo = centerData.nkr_ctr == 0;
centersinNoParticipate = sum(partNo);
DWLNoParticipate = sum(centerDataDWL.DWL_Base(partNo));


QuartileLive1 = ...
    centerData.n_live_tx_per_year >= ...
    prctile(centerData.n_live_tx_per_year(centerData.n_live_tx_per_year>0),75) ;
QuartilePke1 = ...
    centerData.n_pke_tx_per_year >= ...
    prctile(centerData.n_pke_tx_per_year(centerData.n_pke_tx_per_year>0),75) ;

quartile1LiveLossRatio = (sum(centerDataDWL.DWL_Base(QuartileLive1))/totalDWL)*100;
quartile1PkeLossRatio = (sum(centerDataDWL.DWL_Base(QuartilePke1))/totalDWL)*100;



dlmwrite('./output-for-manuscript/constants/c-total-DWL.txt',totalDWL,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-number-of-centers-low-participate.txt',centersinLowestQuantile,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-total-DWL-of-centers-low-participate.txt',DWLLowestQuantile,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-number-of-centers-no-participate.txt',centersinNoParticipate,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-total-DWL-of-centers-no-participate.txt',DWLNoParticipate,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-efficiency-loss-live-quartile.txt',quartile1LiveLossRatio,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-efficiency-loss-pke-quartile.txt',quartile1PkeLossRatio,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-internal-pke-median-center.txt',PKEmedianCenter,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-internal-pke-90th-percentile.txt',PKEnintypercentile,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-internal-pke-methodist.txt',PKEmethodist,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-internal-pke-standard-deviation.txt',PKEstandardDeviation,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-estimated-hospital-pke-inflow.txt',estimatedHospitalFlow,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-estimated-hospital-pke-inflow-75.txt',estimatedHospitalFlow_75,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-estimated-hospital-pke-inflow-25.txt',estimatedHospitalFlow_25,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-average-product-theoretical-maximum.txt',theoreticalMaxNKR,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-arrival-rate-median-center.txt',medianCenterArrival,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-arrival-rate-90th-percentile.txt',ninetythPercentileCenterArrival,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-arrival-rate-methodist.txt',methodistArrival,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-average-product-median-center.txt',averageProdmedianCenter,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-average-product-90th-percentile.txt',averageProdnintythPercentileCenter,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-average-product-methodist.txt',averageProdmethodist,'precision','%.2f')








%% Some summary stats

gradient = readtable( './analysis/gradient/output/gradient.csv');

matchProb = readtable( './analysis/matching-probability/output/matching-probability.csv');
data = submissionsData;
overdemanded = ((strcmp(data.r_abo,'A')&strcmp(data.d_abo,'O'))|...
(strcmp(data.r_abo,'B')&strcmp(data.d_abo,'O'))|...
(strcmp(data.r_abo,'AB')&strcmp(data.d_abo,'O'))|...
(strcmp(data.r_abo,'AB')&strcmp(data.d_abo,'A'))|...
(strcmp(data.r_abo,'AB')&strcmp(data.d_abo,'B')));
underdemanded = (strcmp(data.r_abo,'O')&strcmp(data.d_abo,'A'))|...
(strcmp(data.r_abo,'O')&strcmp(data.d_abo,'B'))|...
(strcmp(data.r_abo,'O')&strcmp(data.d_abo,'AB'))|...
(strcmp(data.r_abo,'A')&strcmp(data.d_abo,'AB'))|...
(strcmp(data.r_abo,'B')&strcmp(data.d_abo,'AB'));
selfdemanded = (strcmp(data.r_abo,'A')&strcmp(data.d_abo,'A'))|...
(strcmp(data.r_abo,'B')&strcmp(data.d_abo,'B'))|...
(strcmp(data.r_abo,'AB')&strcmp(data.d_abo,'AB'))|...
(strcmp(data.r_abo,'O')&strcmp(data.d_abo,'O'))|...
(strcmp(data.r_abo,'A')&strcmp(data.d_abo,'B'))|...
(strcmp(data.r_abo,'B')&strcmp(data.d_abo,'A'));

submissionsData.type = cell(length(submissionsData.category), 1);
submissionsData.type(overdemanded) = {'overdemanded'};
submissionsData.type(underdemanded) = {'underdemanded'};
submissionsData.type(selfdemanded) = {'selfdemanded'};
submissionsData.type(strcmp(submissionsData.category,'a')) = {'altruistic'};
submissionsData.type(strcmp(submissionsData.category,'c')) = {'chip'};

submissionsData.cpraType = cell(length(submissionsData.category), 1);
submissionsData.cpraType(submissionsData.r_cpra<10) = {'low'};
submissionsData.cpraType(submissionsData.r_cpra<=90 & submissionsData.r_cpra>=10) = {'medium'};
submissionsData.cpraType(submissionsData.r_cpra>90) = {'high'};
submissionsData.cpraType(cellfun('isempty',submissionsData.cpraType)) = {'-'};

submissionsData.altruisttype = cell(length(submissionsData.category), 1);
submissionsData.altruisttype(1:length(submissionsData.category))  = {'-'};
submissionsData.altruisttype(strcmp(submissionsData.category,'a')&strcmp(submissionsData.d_abo,'O')) = {'O-blood'};
submissionsData.altruisttype(strcmp(submissionsData.category,'a')&~strcmp(submissionsData.d_abo,'O')) = {'Non-O-blood'};

submissionsData.r_abo(strcmp(submissionsData.r_abo, '')) = {'-'};
submissionsData.d_abo(strcmp(submissionsData.d_abo, '')) = {'-'};

matchProb.type = submissionsData.type(matchProb.index);
matchProb.category = submissionsData.category(matchProb.index);
matchProb.cpraType = submissionsData.cpraType(matchProb.index);
matchProb.gradient = gradient.df;
matchProb.altruisttype = submissionsData.altruisttype(matchProb.index);

summarytable = ...
    grpstats(matchProb,{'category', 'type','cpraType','altruisttype'},'mean','DataVars',{'matching_probability','gradient'});

writetable(summarytable, './output/tables/summarytable.csv');

overdemandlowsensprod = summarytable.mean_gradient(strcmp(summarytable.type,'overdemanded') ...
    & strcmp(summarytable.cpraType,'low'));
overdemandlowsensmatch = summarytable.mean_matching_probability(strcmp(summarytable.type,'overdemanded') ...
    & strcmp(summarytable.cpraType,'low'));

underdemandlowsensprod = summarytable.mean_gradient(strcmp(summarytable.type,'underdemanded') ...
    & strcmp(summarytable.cpraType,'low'));
underdemandlowsensmatch = summarytable.mean_matching_probability(strcmp(summarytable.type,'underdemanded') ...
    & strcmp(summarytable.cpraType,'low'));

altruisticOprod = summarytable.mean_gradient(strcmp(summarytable.category,'a') ...
    & strcmp(summarytable.altruisttype,'O-blood'));
altruisticOmatch = summarytable.mean_matching_probability(strcmp(summarytable.category,'a') ...
    & strcmp(summarytable.altruisttype,'O-blood'));

numberofTypes = sum(entries)*onlyDonor;


dlmwrite('./output-for-manuscript/constants/c-number-of-types.txt',numberofTypes,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-overdemanded-low-sens-match.txt',overdemandlowsensmatch,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-overdemanded-low-sens-gradient.txt',overdemandlowsensprod,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-underdemanded-low-sens-match.txt',underdemandlowsensmatch,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-underdemanded-low-sens-gradient.txt',underdemandlowsensprod,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-altruistic-O-blood-match.txt',altruisticOmatch,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-altruistic-O-blood-gradient.txt',altruisticOprod,'precision','%.2f')


%% For heuristics 

load('analysis/matching-probability/data/data-1.mat')
S = Simulation;
exactSolution = mean([S.history.computationOutput.exactSolution])*100;
noexactSolution = 100 - exactSolution;
nIterationsItai = [S.history.computationOutput.nIterationsItai];
withoutItai = mean(nIterationsItai==1)*100;

nowithoutItai = 100 - withoutItai;
meanIterations = mean(nIterationsItai(nIterationsItai>1));
nonJohnson = mean([S.history.computationOutput.nIterationsJohnson]==0)*100;
solvedwithItai = - withoutItai + nonJohnson;
exactSolutionInd = [S.history.computationOutput.exactSolution];
timestamp = [find(diff([-1 exactSolutionInd -1]) ~= 0)]; 
runlength = diff(timestamp) ;
runlength0 = runlength(1+(exactSolutionInd(1)==1):2:end);
meanNonMatchPeriod = mean(runlength0);

lambda = sum(entries)/977;

dlmwrite('./output-for-manuscript/constants/c-exact-solution.txt',exactSolution,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-no-exact-solution.txt',noexactSolution,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-without-itai.txt',withoutItai,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-solved-with-itai.txt',solvedwithItai,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-mean-itai-iteration.txt',meanIterations,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-without-johnson.txt',nonJohnson,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-no-match-consecutive.txt',meanNonMatchPeriod,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-lambda.txt',lambda,'precision','%.3f')






%% UNOS APD

S = readtable('./analysis/scale/output/scalesummary.csv');
        [~,B] = unique(S.scaleGrid);
        S = S(B,:);
APDTrans = sum([centerData.n_apd_tx_per_year]) ;
UNOSTrans = sum([centerData.n_unos_tx_per_year]) ;
averageProdInterpol = [0:0.1:1000 ; interp1(S.scaleGrid,S.f_mean ./ S.scaleGrid, 0:0.1:1000)]';
averageProdInterpol(:,3) = averageProdInterpol(:,1).*averageProdInterpol(:,2);
APDRow = min(find(averageProdInterpol(:,3)>APDTrans));
APDSize = (averageProdInterpol(APDRow,1) + averageProdInterpol(APDRow+1,1))/2;
averageProdAPD = (averageProdInterpol(APDRow,2) + averageProdInterpol(APDRow+1,2))/2;
UNOSRow = min(find(averageProdInterpol(:,3)>UNOSTrans));
UNOSSize = (averageProdInterpol(UNOSRow,1) + averageProdInterpol(UNOSRow+1,1))/2;
averageProdUNOS = (averageProdInterpol(UNOSRow,2) + averageProdInterpol(UNOSRow+1,2))/2;

DWLAPD = (averageProdNKR - averageProdAPD)*APDSize;
DWLUNOS = (averageProdNKR - averageProdUNOS)*UNOSSize;
DWLAPD_UNOS = DWLAPD + DWLUNOS;

partNoNKR = centerData.nkr_ctr == 0;
partNoPlatform = (centerData.unos_ctr == 0 &  centerData.apd_ctr == 0 & centerData.nkr_ctr == 0);
centersinNoParticipateNKR = sum(partNoNKR);
DWLNoParticipateNKR = sum(centerDataDWL.DWL_Base(partNoNKR));
centersinNoParticipatePlatform = sum(partNoPlatform);
DWLNoParticipatePlatform = sum(centerDataDWL.DWL_Base(partNoPlatform));
DWLNonNKRRobust = DWLNoParticipatePlatform + DWLAPD + DWLUNOS;

dlmwrite('./output-for-manuscript/constants/c-average-product-APD.txt',averageProdAPD,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-average-product-UNOS.txt',averageProdUNOS,'precision','%.2f')
dlmwrite('./output-for-manuscript/constants/c-arrival-rate-APD.txt',APDSize,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-arrival-rate-UNOS.txt',UNOSSize,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-number-of-transplant-rate-APD.txt',APDTrans,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-number-of-transplant-rate-UNOS.txt',UNOSTrans,'precision','%.0f')
dlmwrite('./output-for-manuscript/constants/c-total-DWL-of-APD.txt',DWLAPD,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-total-DWL-of-UNOS.txt',DWLUNOS,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-total-DWL-of-APD-and-UNOS.txt',DWLAPD_UNOS,'precision','%.1f')
dlmwrite('./output-for-manuscript/constants/c-total-DWL-of-Non-NKR-robust.txt',DWLNonNKRRobust,'precision','%.1f')




