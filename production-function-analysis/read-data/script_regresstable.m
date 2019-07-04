
submissionsData = readtable( './output/shrinkedMP.csv');
summaryTable = ...
    grpstats(submissionsData,{'group'},'mean','DataVars',...
    {'shrinkedMP', 'shrinked'});
summaryTable2 = ...
    grpstats(submissionsData,{'group'},'mean','DataVars',...
    {'shrinkedMP', 'var_MP'});

seIdiosyncraticAverage = mean(submissionsData.df_se_idiosyncratic);

numberofGroup = length(unique(submissionsData.group));
Variance = zeros(numberofGroup,1);
Variance_MP = zeros(numberofGroup,1);

for i = 1 : numberofGroup
    Variance(i) = ...
        var(submissionsData.shrinked(submissionsData.group == i));
    Variance_MP(i) = ...
        var(submissionsData.shrinkedMP(submissionsData.group == i));
    
end

summaryTable.se_df = sqrt( ...
    seIdiosyncraticAverage^2 ./ summaryTable.GroupCount ...
    + (mean(submissionsData.df_se_systematic)/10)^2);
summaryTable.se_mp = sqrt(summaryTable2.mean_var_MP./ summaryTable.GroupCount);
summaryTable.variance_df = sqrt(Variance);
summaryTable.variance_mp = sqrt(Variance_MP);
writetable(summaryTable, './output/regressionTree_table.csv');