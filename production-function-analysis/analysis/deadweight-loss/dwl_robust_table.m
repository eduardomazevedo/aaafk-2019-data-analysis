clear all

% Load center data
centerData = readtable('./data/ctr-data.csv');

% Load calculated qs and dwls for centers 
centerDataDWL = readtable( './output/centers-deadweight-loss-robust.csv');


centerData(centerData.n_pke_tx_per_year == 0,:) = [];  
centerData = sortrows(centerData);
centerDataDWL = sortrows(centerDataDWL);


% Check the match

if size(centerData,1) ~= size(centerDataDWL,1)
    error('Datasets are different')
end


%% Center Size by Live Trans

QuartileLive1 = centerDataDWL.Center_LiveTransplantationPerYear>=prctile(centerDataDWL.Center_LiveTransplantationPerYear(centerDataDWL.Center_LiveTransplantationPerYear>0),75) ;
QuartileLive2 = centerDataDWL.Center_LiveTransplantationPerYear>=prctile(centerDataDWL.Center_LiveTransplantationPerYear(centerDataDWL.Center_LiveTransplantationPerYear>0),50) & ...
    centerDataDWL.Center_LiveTransplantationPerYear<prctile(centerDataDWL.Center_LiveTransplantationPerYear(centerDataDWL.Center_LiveTransplantationPerYear>0),75);
QuartileLive3 = centerDataDWL.Center_LiveTransplantationPerYear>=prctile(centerDataDWL.Center_LiveTransplantationPerYear(centerDataDWL.Center_LiveTransplantationPerYear>0),25) & ...
    centerDataDWL.Center_LiveTransplantationPerYear<prctile(centerDataDWL.Center_LiveTransplantationPerYear(centerDataDWL.Center_LiveTransplantationPerYear>0),50);
QuartileLive4 = centerDataDWL.Center_LiveTransplantationPerYear<prctile(centerDataDWL.Center_LiveTransplantationPerYear(centerDataDWL.Center_LiveTransplantationPerYear>0),25) & ...
    centerDataDWL.Center_LiveTransplantationPerYear>0;


%% Center Size by PKE 

QuartilePKE1 = centerDataDWL.Center_PkeTransplantationPerYear>=prctile(centerDataDWL.Center_PkeTransplantationPerYear(centerDataDWL.Center_PkeTransplantationPerYear>0),75) ;
QuartilePKE2 = centerDataDWL.Center_PkeTransplantationPerYear>=prctile(centerDataDWL.Center_PkeTransplantationPerYear(centerDataDWL.Center_PkeTransplantationPerYear>0),50) & ...
    centerDataDWL.Center_PkeTransplantationPerYear<prctile(centerDataDWL.Center_PkeTransplantationPerYear(centerDataDWL.Center_PkeTransplantationPerYear>0),75);
QuartilePKE3 = centerDataDWL.Center_PkeTransplantationPerYear>=prctile(centerDataDWL.Center_PkeTransplantationPerYear(centerDataDWL.Center_PkeTransplantationPerYear>0),25) & ...
    centerDataDWL.Center_PkeTransplantationPerYear<prctile(centerDataDWL.Center_PkeTransplantationPerYear(centerDataDWL.Center_PkeTransplantationPerYear>0),50);
QuartilePKE4 = centerDataDWL.Center_PkeTransplantationPerYear<prctile(centerDataDWL.Center_PkeTransplantationPerYear(centerDataDWL.Center_PkeTransplantationPerYear>0),25) & ...
    centerDataDWL.Center_PkeTransplantationPerYear>0;

%% Center NKR participation


partNKR = centerData.nkr_ctr == 1;
partonlyUNOSAPD = (centerData.unos_ctr == 1 | centerData.apd_ctr == 1) & ...
    centerData.nkr_ctr == 0;
partNoOne = centerData.nkr_ctr == 0 & centerData.unos_ctr == 0 & centerData.apd_ctr == 0 ;


%% Center NKR participation

QuartileNKR1 = centerData.nkr_share > prctile(centerData.nkr_share(centerData.nkr_share>0),75);
QuartileNKR2 = centerData.nkr_share > prctile(centerData.nkr_share(centerData.nkr_share>0),50) & ...
    centerData.nkr_share <= prctile(centerData.nkr_share(centerData.nkr_share>0),75);
QuartileNKR3 = centerData.nkr_share > prctile(centerData.nkr_share(centerData.nkr_share>0),25) & ...
    centerData.nkr_share <= prctile(centerData.nkr_share(centerData.nkr_share>0),50);
QuartileNKR4 = centerData.nkr_share <= prctile(centerData.nkr_share(centerData.nkr_share>0),25)& ...
    centerData.nkr_share > 0;

%% DWL NKR
NumberofCenters = [length(centerDataDWL.DWL_Low) ;...
    nansum((QuartileLive1)) ;...
    nansum((QuartileLive2)) ;...
    nansum((QuartileLive3)) ;...
    nansum((QuartileLive4)) ;...
    sum((partNKR)) ;...
    nansum((partonlyUNOSAPD)) ;...
        nansum((partNoOne)) ;...
    sum((QuartileNKR1)) ;...
    sum((QuartileNKR2)) ;...
    sum((QuartileNKR3)) ;...
    sum((QuartileNKR4)) ;...
    sum((QuartilePKE1)) ;...
    sum((QuartilePKE2)) ;...
    sum((QuartilePKE3)) ;...
    sum((QuartilePKE4))];

DWLNKR = [nansum(centerDataDWL.DWL_Base) ;...
    nansum(centerDataDWL.DWL_Base(QuartileLive1)) ;...
    nansum(centerDataDWL.DWL_Base(QuartileLive2)) ;...
    nansum(centerDataDWL.DWL_Base(QuartileLive3)) ;...
    nansum(centerDataDWL.DWL_Base(QuartileLive4)) ;...
    sum(centerDataDWL.DWL_Base(partNKR)) ;...
    nansum(centerDataDWL.DWL_Base(partonlyUNOSAPD)) ;...
        nansum(centerDataDWL.DWL_Base(partNoOne)) ;...
    sum(centerDataDWL.DWL_Base(QuartileNKR1)) ;...
    sum(centerDataDWL.DWL_Base(QuartileNKR2)) ;...
    sum(centerDataDWL.DWL_Base(QuartileNKR3)) ;...
    sum(centerDataDWL.DWL_Base(QuartileNKR4)) ;...
    sum(centerDataDWL.DWL_Base(QuartilePKE1)) ;...
    sum(centerDataDWL.DWL_Base(QuartilePKE2)) ;...
    sum(centerDataDWL.DWL_Base(QuartilePKE3)) ;...
    sum(centerDataDWL.DWL_Base(QuartilePKE4))];

DWL_High = [nansum(centerDataDWL.DWL_High) ;...
    nansum(centerDataDWL.DWL_High(QuartileLive1)) ;...
    nansum(centerDataDWL.DWL_High(QuartileLive2)) ;...
    nansum(centerDataDWL.DWL_High(QuartileLive3)) ;...
    nansum(centerDataDWL.DWL_High(QuartileLive4)) ;...
    sum(centerDataDWL.DWL_High(partNKR)) ;...
    nansum(centerDataDWL.DWL_High(partonlyUNOSAPD)) ;...
        nansum(centerDataDWL.DWL_High(partNoOne)) ;...
    sum(centerDataDWL.DWL_High(QuartileNKR1)) ;...
    sum(centerDataDWL.DWL_High(QuartileNKR2)) ;...
    sum(centerDataDWL.DWL_High(QuartileNKR3)) ;...
    sum(centerDataDWL.DWL_High(QuartileNKR4)) ;...
    sum(centerDataDWL.DWL_High(QuartilePKE1)) ;...
    sum(centerDataDWL.DWL_High(QuartilePKE2)) ;...
    sum(centerDataDWL.DWL_High(QuartilePKE3)) ;...
    sum(centerDataDWL.DWL_High(QuartilePKE4))];

DWL_Low = [nansum(centerDataDWL.DWL_Low) ;...
    nansum(centerDataDWL.DWL_Low(QuartileLive1)) ;...
    nansum(centerDataDWL.DWL_Low(QuartileLive2)) ;...
    nansum(centerDataDWL.DWL_Low(QuartileLive3)) ;...
    nansum(centerDataDWL.DWL_Low(QuartileLive4)) ;...
    sum(centerDataDWL.DWL_Low(partNKR)) ;...
    nansum(centerDataDWL.DWL_Low(partonlyUNOSAPD)) ;...
        nansum(centerDataDWL.DWL_Low(partNoOne)) ;...
    sum(centerDataDWL.DWL_Low(QuartileNKR1)) ;...
    sum(centerDataDWL.DWL_Low(QuartileNKR2)) ;...
    sum(centerDataDWL.DWL_Low(QuartileNKR3)) ;...
    sum(centerDataDWL.DWL_Low(QuartileNKR4)) ;...
    sum(centerDataDWL.DWL_Low(QuartilePKE1)) ;...
    sum(centerDataDWL.DWL_Low(QuartilePKE2)) ;...
    sum(centerDataDWL.DWL_Low(QuartilePKE3)) ;...
    sum(centerDataDWL.DWL_Low(QuartilePKE4)) ];


yNKRPKE = [nansum(centerDataDWL.Center_PkeTransplantationPerYear) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartileLive1)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartileLive2)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartileLive3)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartileLive4)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(partNKR)) ;...
    nansum(centerDataDWL.Center_PkeTransplantationPerYear(partonlyUNOSAPD)) ;...
        nansum(centerDataDWL.Center_PkeTransplantationPerYear(partNoOne)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartileNKR1)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartileNKR2)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartileNKR3)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartileNKR4)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartilePKE1)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartilePKE2)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartilePKE3)) ;...
    sum(centerDataDWL.Center_PkeTransplantationPerYear(QuartilePKE4))];

yNKRIntPKE = [nansum(centerDataDWL.Center_IntPkeTransplantationPerYear) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartileLive1)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartileLive2)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartileLive3)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartileLive4)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(partNKR)) ;...
    nansum(centerDataDWL.Center_IntPkeTransplantationPerYear(partonlyUNOSAPD)) ;...
        nansum(centerDataDWL.Center_IntPkeTransplantationPerYear(partNoOne)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartileNKR1)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartileNKR2)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartileNKR3)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartileNKR4)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartilePKE1)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartilePKE2)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartilePKE3)) ;...
    sum(centerDataDWL.Center_IntPkeTransplantationPerYear(QuartilePKE4))];

yNKRLive = [nansum(centerDataDWL.Center_LiveTransplantationPerYear) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartileLive1)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartileLive2)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartileLive3)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartileLive4)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(partNKR)) ;...
    nansum(centerDataDWL.Center_LiveTransplantationPerYear(partonlyUNOSAPD)) ;...
        nansum(centerDataDWL.Center_LiveTransplantationPerYear(partNoOne)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartileNKR1)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartileNKR2)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartileNKR3)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartileNKR4)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartilePKE1)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartilePKE2)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartilePKE3)) ;...
    sum(centerDataDWL.Center_LiveTransplantationPerYear(QuartilePKE4))];

submissionsData = readtable('./data/submissions-data.csv');

entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
((strcmp(submissionsData.category,'p'))...
& submissionsData.r_arr_date_min>=19084);

entries75th = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
& submissionsData.r_arr_date_min>=19084) & ...
submissionsData.center_nkr_share>=prctile(submissionsData.center_nkr_share(entries>0),75);

entries25th = ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
& submissionsData.r_arr_date_min>=19084) & ...
submissionsData.center_nkr_share<prctile(submissionsData.center_nkr_share(entries>0),25);


Data = [[NumberofCenters yNKRLive yNKRPKE yNKRIntPKE DWLNKR DWL_High DWL_Low]];

% If you have a MAC
if ismac
addpath('./vendor//MatlabExcelMac/Archive');
    javaaddpath('./vendor/MatlabExcelMac/Archive/jxl.jar');
    javaaddpath('./vendor//MatlabExcelMac/Archive/MXL.jar');

    import mymxl.*;
    import jxl.*;   

    xlwrite('./output/tables/deadweight-loss-table-robust.xls',Data,'data')
rmpath('./vendor//MatlabExcelMac/Archive');
else  
    xlswrite('./output/tables/deadweight-loss-table-robust.xls',Data,'data')
end


