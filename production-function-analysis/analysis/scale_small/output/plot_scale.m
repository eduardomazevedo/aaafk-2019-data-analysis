clear;
addpath('aass', 'classes', 'functions');

% Get Data
scaleGrid = [linspace(5, 60, 20), ...
    linspace(65, 200, 10)];

data = readtable('./data/submissions-data.csv');
submissionsData = data;

entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
    ((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c')) ...
    & submissionsData.r_arr_date_min>=19084);

scaleGrid = scaleGrid * ...
    (1 - sum(strcmp(submissionsData.category(entries>0),'c'))/sum(entries));

SS = aassGet('./analysis/scale_small/');

for i = 1:length(SS)
    if ~isempty(SS{i})
        S(i) = SS{i};
        S(i).burn = 2000;
    end
end
I = ~cellfun(@isempty, SS);
S = S(I);
scaleGrid = scaleGrid(I);
clear SS;

f_mean = [S.f_mean]';
f_se = [S.f_se]';
scaleGrid = scaleGrid';
clear S

S = table(f_mean,f_se,scaleGrid);


writetable(S, './analysis/scale_small/output/scalesummary.csv');



% Plot graph
% Production function:
f = figure();
    f.Position = [0, 0, 162*3, 100*3];
    errorbar([0, S.scaleGrid'], ...
        [0, S.f_mean']', 1.96 * [0, S.f_se']');
    hold on;
    plot([0, S.scaleGrid'], ...
        [0, S.f_mean']', ...
        'LineWidth', 2);
    % Code to plot line through last point and zero.
    %plot([0, scaleGrid(end)], ...
    %    [0, S(end).f_mean]);
    xlim([0 max(S.scaleGrid)]);
    title('Production Function');
    xlabel('Arrival Rate');
print('./output-for-manuscript/figures/production-function-small.eps', '-depsc2');
print('./output/figures/production-function-small.eps', '-depsc2');
% Average product:
f = figure();
    f.Position = [0, 0, 162*3, 100*3];
    errorbar([0, S.scaleGrid'], ...
        [0, S.f_mean']' ./ [1, S.scaleGrid']', ...
        1.96 * [0, S.f_se']' ./ [1, S.scaleGrid']')
    hold on;
    plot([0, S.scaleGrid'], ...
        [0, S.f_mean']' ./ [1, S.scaleGrid']', ...
        'LineWidth', 2);
    xlim([0 max(scaleGrid)]);
    title('Average Product');
    xlabel('Arrival Rate');
    % Save
print('./output-for-manuscript/figures/average-product-func-small.eps', '-depsc2');
print('./output/figures/average-product-func-small.eps', '-depsc2');