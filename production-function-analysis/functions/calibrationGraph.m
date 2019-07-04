function calibrationGraph(directory,parameterset)
addpath('output/')
coloursforPaper
directory = [directory '/output/calibration_output.mat'];
load(directory)
numofDays = size(simulation_calib.simAltPoolSize{1,1},2);


i = parameterset;
%% All  
figureall  = figure;
    plot(1:numofDays,cumsum(realmarket_stat.allTransinRealMark),'color',navyblue,'LineWidth',2)
    hold on
    plot(1:numofDays,cumsum(realmarket_stat.allPerishinRealMark),'color',lightblue,'LineWidth',2)
    hold on
    plot(1:numofDays,(realmarket_stat.allMarkSizeinRealMark),'color',darkergray,'LineWidth',2)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairPerish{i}+simulation_calib.simAltruisticPerish{i}+simulation_calib.simChipPerish{i})')',50),'color',lightblue,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile((simulation_calib.simOverallPoolSize{i}')',50),'color',darkergray,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairTrans{i}+simulation_calib.simAltruisticTrans{i}+simulation_calib.simChipTrans{i})')',50),'color',navyblue,'LineWidth',2,'LineStyle','--')
    hold on   
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairTrans{i}+simulation_calib.simAltruisticTrans{i}+simulation_calib.simChipTrans{i})')',97.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairTrans{i}+simulation_calib.simAltruisticTrans{i}+simulation_calib.simChipTrans{i})')',2.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairPerish{i}+simulation_calib.simAltruisticPerish{i}+simulation_calib.simChipPerish{i})')',97.5),'color',darkgray,'LineWidth',1) 
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairPerish{i}+simulation_calib.simAltruisticPerish{i}+simulation_calib.simChipPerish{i})')',2.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile((simulation_calib.simOverallPoolSize{i}')',97.5),'color',darkgray,'LineWidth',1) 
    hold on
    plot(1:numofDays,prctile((simulation_calib.simOverallPoolSize{i}')',2.5),'color',darkgray,'LineWidth',1)
lgd = ...
    legend('Transplants (Flow)',...
    'Untransplanted Departures',...
    'Stock',...
    'Location','northwest');
lgd.FontSize = 10;
xlabel('Calendar/Simulation Days','FontSize', 14)
ylabel('Number of Registrations','FontSize', 14)
%title('All Registrations')
print(['./output-for-manuscript/figures/calibrationAll_' num2str(i) '.eps'], '-depsc2');
print('./output/figures/calibrationAll.eps', '-depsc2');
hold off
%% Chip 
figurechip  = figure;
    plot(1:numofDays,cumsum(realmarket_stat.chipTransinRealMark),'color',navyblue,'LineWidth',2)
    hold on
    plot(1:numofDays,cumsum(realmarket_stat.chipPerishinRealMark),'color',lightblue,'LineWidth',2)
    hold on
    plot(1:numofDays,(realmarket_stat.chipinRealMark),'color',darkergray,'LineWidth',2)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simChipPerish{i})')',50),'color',lightblue,'LineWidth',2,'LineStyle','--')    
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simChipTrans{i})')',50),'color',navyblue,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile((simulation_calib.simChipPoolSize{i}')',50),'color',darkergray,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simChipTrans{i})')',97.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simChipTrans{i})')',2.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simChipPerish{i})')',97.5),'color',darkgray,'LineWidth',1) 
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simChipPerish{i})')',2.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile((simulation_calib.simChipPoolSize{i}')',97.5),'color',darkgray,'LineWidth',1) 
    hold on
    plot(1:numofDays,prctile((simulation_calib.simChipPoolSize{i}')',2.5),'color',darkgray,'LineWidth',1)

lgd = ...
    legend('Transplants (Flow)',...
    'Untransplanted Departures',...
    'Stock',...
    'Location','northwest');
lgd.FontSize = 10;
xlabel('Calendar/Simulation Days','FontSize', 14)
ylabel('Number of Unpaired Patients','FontSize', 14)
%title('Unpaired Patients')
print(['./output-for-manuscript/figures/calibrationChip_' num2str(i) '.eps'], '-depsc2');
print('./output/figures/calibrationChip.eps', '-depsc2');
hold off
 %% Pair
figurepair  = figure;
    plot(1:numofDays,cumsum(realmarket_stat.pairTransinRealMark),'color',navyblue,'LineWidth',2)
    hold on
    plot(1:numofDays,cumsum(realmarket_stat.pairPerishinRealMark),'color',lightblue,'LineWidth',2)
    hold on
    plot(1:numofDays,(realmarket_stat.pairinRealMark),'color',darkergray,'LineWidth',2)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairTrans{i})')',50),'color',navyblue,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile((simulation_calib.simPairPoolSize{i}')',50),'color',darkergray,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairPerish{i})')',50),'color',lightblue,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairTrans{i})')',97.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairTrans{i})')',2.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairPerish{i})')',97.5),'color',darkgray,'LineWidth',1) 
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simPairPerish{i})')',2.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile((simulation_calib.simPairPoolSize{i}')',97.5),'color',darkgray,'LineWidth',1) 
    hold on
    plot(1:numofDays,prctile((simulation_calib.simPairPoolSize{i}')',2.5),'color',darkgray,'LineWidth',1)

lgd = ...
    legend('Transplants (Flow)',...
    'Untransplanted Departures',...
    'Stock',...
    'Location','northwest');
lgd.FontSize = 10;
xlabel('Calendar/Simulation Days','FontSize', 14)
ylabel('Number of Patient-Donor Pairs','FontSize', 14)
%title('Pairs')
print(['./output-for-manuscript/figures/calibrationPair_' num2str(i) '.eps'], '-depsc2');
print('./output/figures/calibrationPair.eps', '-depsc2');
hold off
%% Altruistic 
figurealt  = figure;
    plot(1:numofDays,cumsum(realmarket_stat.altruisticTransinRealMark),'color',navyblue,'LineWidth',2)
    hold on
    plot(1:numofDays,(realmarket_stat.altruisticinRealMark),'color',darkergray,'LineWidth',2)
    hold on
    plot(1:numofDays,cumsum(realmarket_stat.altruisticPerishinRealMark),'color',lightblue,'LineWidth',2)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simAltruisticTrans{i})')',50),'color',navyblue,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simAltruisticPerish{i})')',50),'color',lightblue,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile((simulation_calib.simAltPoolSize{i}')',50),'color',darkergray,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simAltruisticTrans{i})')',97.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simAltruisticTrans{i})')',2.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simAltruisticPerish{i})')',97.5),'color',darkgray,'LineWidth',1) 
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib.simAltruisticPerish{i})')',2.5),'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,prctile((simulation_calib.simAltPoolSize{i}')',97.5),'color',darkgray,'LineWidth',1) 
    hold on
    plot(1:numofDays,prctile((simulation_calib.simAltPoolSize{i}')',2.5),'color',darkgray,'LineWidth',1)

lgd = ...
    legend('Transplants (Flow)',...
    'Untransplanted Departures',...
    'Stock',...
    'Location','northwest');
lgd.FontSize = 10;
xlabel('Calendar/Simulation Days','FontSize', 14)
ylabel('Number of Altruistic Donors','FontSize', 14)
%title('Altruistic Donors')
print(['./output-for-manuscript/figures/calibrationAlt_' num2str(i) '.eps'], '-depsc2');
print('./output/figures/calibrationAlt.eps', '-depsc2');
end
