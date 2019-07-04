clear all

coloursforPaper
% Read the scalesummary file
S = readtable('./analysis/scale/output/scalesummary.csv');
submissionsData = readtable('./data/submissions-data.csv');
% Just for weekdays
% Only use arrivals after April 2012
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
(strcmp(submissionsData.category,'p')& submissionsData.r_arr_date_min>=19084);
submissionsData =submissionsData(entries>0,:);
arrivals = [submissionsData.r_arr_date_min(strcmp(submissionsData.category,'c'));
submissionsData.d_arr_date_min(strcmp(submissionsData.category,'p')|...
strcmp(submissionsData.category,'a'))];
numofDays = max(submissionsData.r_arr_date_max) -...
min(submissionsData.r_arr_date_min) + 2;
% Arrival per Day
arrivalperDay = zeros(1,numofDays);
for i= 1:numofDays
arrivalperDay(i) = sum(arrivals==(19083+i)) ;
end
% Just for weekdays

NKRarrivalPerYear = sum(entries)/(numofDays/365);


Weekday = arrivalperDay;
Weekday([1:7:977 7:7:977])=[];
centerDataDWL = readtable( './output/centers-deadweight-loss.csv');
centerSize = [centerDataDWL.Estimate_Q_Base];
centerSize(centerSize==0) = [];
fig = figure;
left_color = [0 0 0];
right_color = [0 0 0];
set(fig,'defaultAxesColorOrder',[left_color; right_color]);

yyaxis left
f.Position = [0, 0, 162*3, 100*3];
hold on;
h1 = plot([0, S.scaleGrid'], ...
[0, S.f_mean']' ./ [1, S.scaleGrid']', ...
...[0, S.scaleGrid'], repmat(theMaxAve,1,(length(S.scaleGrid)+1)),'g', ...
'color',navyblue,'LineWidth', 2);
hold on
h2 = plot([NKRarrivalPerYear NKRarrivalPerYear], [0 1],'LineStyle','-','color',lightblue,'LineWidth', 2);
xlim([0 1000]);
ylim([0 0.7]);
errorbar([0, S.scaleGrid'], ...
        [0, S.f_mean']' ./ [1, S.scaleGrid']', ...
        1.96 * [0, S.f_se']' ./ [1, S.scaleGrid']','k')
ylabel('Average Number of Transplantation Per Donor','FontSize', 14);
yyaxis right
h3 = histogram(centerSize,5,'FaceColor',darkgray);
hold on

lgd = ...
    legend([h1 h2 h3],{'Estimated Production Function','NKR Donors Per Year',...
    'Transplant Hospitals'},'Location','east');
lgd.FontSize = 10;

ylabel('Number of Transplant Hospitals','FontSize', 14)
xlabel('Number of Donors Submitted Per Year','FontSize', 14)
print('./output-for-manuscript/figures/prod-func-vs-trans-center.eps', '-depsc2');