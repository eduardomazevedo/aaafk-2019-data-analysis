clear all




directory = './analysis/calibration/first-exercise/';
directory = [directory 'output/calibration_output.mat'];
load(directory)
simulation_calib1 = simulation_calib;

directory = './analysis/calibration/second-exercise/';
directory = [directory 'output/calibration_output.mat'];
load(directory)

simulation_calib2 = simulation_calib;

%simulation_calib = [simulation_calib1([8 7 9]) simulation_calib2([2 4])  simulation_calib1(2)  simulation_calib2(1) ];


run('./output/coloursforPaper.m');



numofDays = size(simulation_calib.simAltPoolSize{1,1},2);




figureall  = figure;
    plot(1:numofDays,cumsum(realmarket_stat.pairTransinRealMark),'color',lightblue,'LineWidth',3)
    hold on
    plot(1:numofDays,cumsum(realmarket_stat.pairPerishinRealMark),'color',navyblue,'LineWidth',3)
    hold on
    plot(1:numofDays,(realmarket_stat.pairinRealMark),'color',darkergray,'LineWidth',3)
    hold on 
    
    for i = 8
    plot(1:numofDays,prctile(cumsum((simulation_calib1.simPairTrans{i})')',50),'color',lightblue,'LineWidth',2,'LineStyle','--')    
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib1.simPairPerish{i})')',50),'color',navyblue,'LineWidth',2,'LineStyle','--')
    hold on
    plot(1:numofDays,prctile((simulation_calib1.simPairPoolSize{i}')',50),'color',darkergray,'LineWidth',2,'LineStyle','--')       
    hold on
    end
    
    for i = [7 9 2]
    plot(1:numofDays,prctile(cumsum((simulation_calib1.simPairTrans{i})')',50),'color',lightblue,'LineWidth',1.5,'LineStyle',':')    
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib1.simPairPerish{i})')',50),'color',navyblue,'LineWidth',1.5,'LineStyle',':')
    hold on
    plot(1:numofDays,prctile((simulation_calib1.simPairPoolSize{i}')',50),'color',darkergray,'LineWidth',1.5,'LineStyle',':')       
    hold on   
    end
    
    for i = [2 4 1]
    plot(1:numofDays,prctile(cumsum((simulation_calib2.simPairTrans{i})')',50),'color',lightblue,'LineWidth',1.5,'LineStyle',':')    
    hold on
    plot(1:numofDays,prctile(cumsum((simulation_calib2.simPairPerish{i})')',50),'color',navyblue,'LineWidth',1.5,'LineStyle',':')
    hold on
    plot(1:numofDays,prctile((simulation_calib2.simPairPoolSize{i}')',50),'color',darkergray,'LineWidth',1.5,'LineStyle',':')       
        
    end
lgd = ...
    legend('Transplants (Flow)',...
    'Untransplanted Departures',...
    'Stock',...
    'Location','northwest');
lgd.FontSize = 10;
xlabel('Calendar/Simulation Days','FontSize', 14)
ylabel('Number of Patient-Donor Pairs','FontSize', 14)
%title('All Registrations')
print(['./output-for-manuscript/figures/calibration_robust.eps'], '-depsc2');
hold off


PairPoolSize = [overallTransPer1([8 7 9]) overallTransPer2([2 4])  overallTransPer1(2)  overallTransPer2(1) ];

PairPoolSize{1} = realmarket_stat.pairinRealMark;


PairPoolSize{2} = prctile((simulation_calib1.simPairPoolSize{8}')',50);
PairPoolSize{3} = prctile((simulation_calib1.simPairPoolSize{7}')',50);
PairPoolSize{4} = prctile((simulation_calib1.simPairPoolSize{9}')',50);
PairPoolSize{5} = prctile((simulation_calib2.simPairPoolSize{2}')',50);
PairPoolSize{6} = prctile((simulation_calib2.simPairPoolSize{4}')',50);
PairPoolSize{7} = prctile((simulation_calib1.simPairPoolSize{2}')',50);
PairPoolSize{8} = prctile((simulation_calib2.simPairPoolSize{1}')',50);





    plot(1:numofDays,PairPoolSize{1},'color','k','LineWidth',2)       
    hold on 
    plot(1:numofDays,PairPoolSize{2},'color',darkergray,'LineWidth',2)
    hold on 
    plot(1:numofDays,PairPoolSize{3},'color',navyblue,'LineWidth',1)
    hold on
    plot(1:numofDays,PairPoolSize{4},'color',navyblue,'LineWidth',1,'LineStyle','--')         
    hold on 
    plot(1:numofDays,PairPoolSize{5},'color',lightblue,'LineWidth',1)
    hold on
    plot(1:numofDays,PairPoolSize{6},'color',lightblue,'LineWidth',1,'LineStyle','--')     
    hold on 
    plot(1:numofDays,PairPoolSize{7},'color',darkgray,'LineWidth',1)
    hold on
    plot(1:numofDays,PairPoolSize{8},'color',darkgray,'LineWidth',1,'LineStyle','--')     
    
    
lgd =  legend('Observed Quantities',...
'Preferred Parameters',...
'Lower Friction',...
'Higher Friction',...
'Shorter Wait Time',...
'Longer Wait Time',...
'Shorter Bridge Donor Wait Time',...
'Longer Bridge Donor Wait Time','Location','southeast');
lgd.FontSize = 10;
xlabel('Calendar/Simulation Days','FontSize', 14)
ylabel('Number of Patient-Donor Pairs','FontSize', 14)
print(['./output-for-manuscript/figures/calibration_robust.eps'], '-depsc2');
hold off