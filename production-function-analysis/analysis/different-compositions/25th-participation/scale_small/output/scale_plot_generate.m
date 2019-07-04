clear;

addpath functions

% Read the scalesummary file
S = readtable('./analysis/different-compositions/25th-participation/scale_small/output/scalesummary.csv');

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
    ylabel('Number of Transplantation Per Year');
    xlabel('Number of Registrations Per Year');
print('./output-for-manuscript/figures/production-function-25th-small.eps', '-depsc2');
print('./output/figures/production-function-25th-small.eps', '-depsc2');


% Average product:

submissionsData = readtable('./data/submissions-data.csv');

entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
& submissionsData.r_arr_date_min>=19084);

data = submissionsData(entries>0,:);
theMaxAve = theoreticalMax(data);

f = figure();    
    f.Position = [0, 0, 162*3, 100*3];
    hold on;
    plot([0, S.scaleGrid'], ...
        [0, S.f_mean']' ./ [1, S.scaleGrid']','r', ...
        ...[0, S.scaleGrid'], repmat(theMaxAve,1,(length(S.scaleGrid)+1)),'g', ...
        'LineWidth', 2);
    xlim([0 1400]);
    ylim([0 0.7]);
    errorbar([0, S.scaleGrid'], ...
        [0, S.f_mean']' ./ [1, S.scaleGrid']', ...
        1.96 * [0, S.f_se']' ./ [1, S.scaleGrid']','b')
    ...title('Average Product');
    xlabel('Number of Registrations Per Year');
    ylabel('Average Number of Transplantation Per Registration');
    % Save
print('./output-for-manuscript/figures/average-product-func-25th-small.eps', '-depsc2');
print('./output/figures/average-product-func-25th-small.eps', '-depsc2');
