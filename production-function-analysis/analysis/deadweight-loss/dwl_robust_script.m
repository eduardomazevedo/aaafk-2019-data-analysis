clear all
% Load the data from productions of centers
addpath('classes', 'aass', 'functions','data','analysis/deadweight-loss/');

% Interpolate from the estimated f function
options = 'base';
[prodApprox,grid] = f_inter(options);

options = 'base_high';
[prodApprox_high,grid_high] = f_inter(options);

options = 'base_low';
[prodApprox_low,grid_low] = f_inter(options);

options = 'base_normal';
[prodApprox_normal,grid_normal] = f_inter(options);
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
[DWL_High,Estimate_Q_High] = dwl_calculation(f_firms,prodApprox_high,grid_high,ap_NKR);
[DWL_Low,Estimate_Q_Low] = dwl_calculation(f_firms,prodApprox_low,grid_low,ap_NKR);
[DWL_Normal,Estimate_Q_Normal] = dwl_calculation(f_firms,prodApprox_normal,grid_normal,ap_NKR);

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
    Estimate_Q_Base,Estimate_Q_High,Estimate_Q_Low,Estimate_Q_Normal,...
    DWL_Base,DWL_High,DWL_Low,DWL_Normal);
writetable(T, './output/centers-deadweight-loss-robust.csv');
