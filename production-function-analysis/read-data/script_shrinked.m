clear all
submissionsData = readtable( './output/regressionTreeCategories.csv');
gradientData = readtable( './analysis/gradient/output/gradient.csv');
probabilityData = readtable( './analysis/matching-probability/output/matching-probability-2.csv');
%submissionsData = submissionsData(gradientData.index,:);
gradientData.MP = probabilityData.matching_probability;
gradientData.var_MP = probabilityData.var;
gradientData.group = submissionsData.groupTree;
gradientData.df_sesq = gradientData.df_se.^2;
aggregateData = grpstats(gradientData, ...
{'group'}, ...
{'mean', 'sum','std','var'}, ...
'DataVars', {'df','df_se','df_sesq','MP','var_MP'});
aggregateData.lamda = aggregateData.var_df./(aggregateData.mean_df_sesq+aggregateData.var_df);
aggregateData.lamdaMP = aggregateData.var_MP./(aggregateData.mean_var_MP+aggregateData.var_MP);
[~,b] = ismember (gradientData.group,aggregateData.group);
gradientData.lamda = aggregateData.lamda(b);
gradientData.mean_df = aggregateData.mean_df(b);
gradientData.shrinked = gradientData.mean_df .* (1 - gradientData.lamda) + ...
    gradientData.lamda .* gradientData.df;
gradientData.lamdaMP = aggregateData.lamdaMP(b);
gradientData.mean_MP = aggregateData.mean_MP(b);
gradientData.shrinkedMP = gradientData.mean_MP .* (1 - gradientData.lamdaMP) + ...
    gradientData.lamdaMP .* gradientData.MP;


aggregateData2 = grpstats(gradientData, ...
{'group'}, ...
{'mean','var'}, ...
'DataVars', {'MP','df','df_se','var_MP'});
aggregateData2 = aggregateData2(:,[1 2 3 5 7 9 4 6]);

aggregateData2.mean_df_se = aggregateData2.mean_df_se ./ sqrt(aggregateData2.GroupCount);
aggregateData2.mean_var_MP = aggregateData2.mean_var_MP ./ sqrt(aggregateData2.GroupCount);

gradientData.category = submissionsData.category;
gradientData.r_abo = submissionsData.r_abo;
gradientData.d_abo = submissionsData.d_abo;
gradientData.r_cpra = submissionsData.r_cpra;
writetable(gradientData, './output/shrinkedMP.csv');
%writetable(gradientData, './output/table2.csv');