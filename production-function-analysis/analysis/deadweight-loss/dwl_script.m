clear all
% Load the data from productions of centers
addpath('classes', 'aass', 'functions','data','analysis/deadweight-loss/');

% Interpolate from the estimated f function
options = 'basesmall';
[prodApprox,grid] = f_inter(options);

options = '75thsmall';
[prodApprox_75th,grid_75th] = f_inter(options);

options = '25thsmall';
[prodApprox_25th,grid_25th] = f_inter(options);

% Load the submission data to check chip patient ratios. 
submissionsData = readtable('./data/submissions-data.csv');

centerData = readtable('./data/ctr-data.csv');

centerData(centerData.n_pke_tx_per_year == 0,:) = [];  

entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
    & submissionsData.r_arr_date_min>=19084);
        
nonChipRatioNKR = (1 - sum(strcmp(submissionsData.category(entries>0),'c'))/sum(entries));

% NKR qs and NKR level average production calculations

entriesChip = strcmp(submissionsData.category,'c')...
    & submissionsData.r_arr_date_min>=19084;

q_NKR = sum(entries) * nonChipRatioNKR;

ap_NKR = (nansum(submissionsData.d_transplanted(entries>0)) + ...
    nansum(submissionsData.r_transplanted(entriesChip>0))) / q_NKR ;


% Hospitals productions

f_firms = centerData.n_internal_pke_per_year;
f_firms(isnan(f_firms))=0;

% DWL calculation
[DWL_Base,Estimate_Q_Base] = dwl_calculation(f_firms,prodApprox,grid,ap_NKR);
[DWL_75th,Estimate_Q_75th] = dwl_calculation(f_firms,prodApprox_75th,grid_75th,ap_NKR);
[DWL_25th,Estimate_Q_25th] = dwl_calculation(f_firms,prodApprox_25th,grid_25th,ap_NKR);


Center_Participation = centerData.nkr_ctr;
Center = centerData.ctr;
Center_NumTransplantationPerYear = centerData.n_tx_per_year;
Center_PkeTransplantationPerYear = centerData.n_pke_tx_per_year;
Center_LiveTransplantationPerYear = centerData.n_live_tx_per_year;
Center_IntPkeTransplantationPerYear = centerData.n_internal_pke_per_year;

% Create an table

T = table(Center,Center_NumTransplantationPerYear,...
    Center_PkeTransplantationPerYear, Center_LiveTransplantationPerYear,...
    Center_IntPkeTransplantationPerYear,...
    Estimate_Q_Base,Estimate_Q_75th,Estimate_Q_25th,...
    DWL_Base,DWL_75th,DWL_25th);
writetable(T, './output/centers-deadweight-loss.csv');
