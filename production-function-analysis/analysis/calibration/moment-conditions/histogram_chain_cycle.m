%% Chain Length Dist. and Cycle-Chain Ratio
clear all

load('/Users/omerkaraduman/Dropbox (Personal)/calibration2019/output/chain_lengths.mat')

submissionsData = readtable('./data/submissions-data.csv');
coloursforPaper              
entries = (strcmp(submissionsData.category,'a') & submissionsData.d_arr_date_min>=19084) + ...
((strcmp(submissionsData.category,'p') |strcmp(submissionsData.category,'c'))...
& submissionsData.r_arr_date_min>=19084);

submissionsData = submissionsData(entries>0,:);

% Cycles

cycleIndexes = submissionsData.r_transplant_index(submissionsData.r_tx_cycle==1);

uniqCycleIndexes = unique(cycleIndexes);
cycleLengths = zeros(1,length(uniqCycleIndexes));
for i = 1 : length(uniqCycleIndexes)
   cycleLengths(i) = sum(cycleIndexes==uniqCycleIndexes(i));
end
    
% Chains

chainIndexes = submissionsData.r_transplant_index(submissionsData.r_tx_chain==1);

uniqChainIndexes = unique(chainIndexes);
chainLengths = zeros(1,length(uniqChainIndexes));
for i = 1 : length(uniqChainIndexes)
    % +1 since we are only counting patients in the chains. +1 is the
    % altruistic donor who initiates the chain. 
   chainLengths(i) = sum(chainIndexes==uniqChainIndexes(i)) + 1;
end

h1 = histogram(chainLengths',0:1:30,'FaceColor',navyblue);
hold on
h2 = histogram(overallChains{8},0:1:30,'FaceColor',darkgray);
hold on 
h1.Normalization = 'probability';
h2.Normalization = 'probability';

lgd = legend('Data','Simulation');
lgd.FontSize = 10;

xlabel('Chain Length','FontSize', 14)
ylabel('Normalized Probability Distribution','FontSize', 14)

%title('Length of the Chains')
print('./output-for-manuscript/figures/chain-lengths.eps', '-depsc2');


totalTransplant = ...
    sum(submissionsData.r_transplanted==1 | submissionsData.d_transplanted==1);
chainRatio = sum(submissionsData.d_tx_chain==1| ...
    submissionsData.r_tx_chain==1)/totalTransplant;
cycleRatio = sum(submissionsData.d_tx_cycle==1 | ...
    submissionsData.r_tx_cycle==1)/totalTransplant;
twocycleRatio = cycleRatio * (sum(cycleLengths==2)*2/...
    (sum(cycleLengths==3)*3+sum(cycleLengths==2)*2));
threecycleRatio = cycleRatio * (sum(cycleLengths==3)*3/...
    (sum(cycleLengths==3)*3+sum(cycleLengths==2)*2));

ax2 = subplot(1,2,1);

Y = [twocycleRatio threecycleRatio chainRatio];
X = mean([overallTransPer{8}]);
    if length(Y)~=length(X)
        X = X(1:length(Y));    
    end
D = [Y;X];
D = D.*repmat(sum(D')',1,3);
figure(1)
hBar = bar(D, 'stacked');
ylim([0 1])
set(hBar(1),'FaceColor',navyblue)
set(hBar(2),'FaceColor',lightblue)
set(hBar(3),'FaceColor',darkgray)
xt = get(gca, 'XTick');
set(gca, 'XTick', xt, 'XTickLabel', {'Data' 'Simulation'})
yd = get(hBar, 'YData');
yjob = {'2-Cycles' '3-Cycles' 'Chains'};
barbase = cumsum([zeros(size(D,1),1) D(:,1:end-1)],2);
joblblpos = D/2 + barbase;
for k1 = 1:size(D,1)
    text(xt(k1)*ones(1,size(D,2)), joblblpos(k1,:), yjob, 'HorizontalAlignment','center')
end

ylabel('Fraction of Transplants','FontSize', 14)

%title('Cycle - Chain Ratio')
print('./output-for-manuscript/figures/chain-cycle-dist.eps', '-depsc2');