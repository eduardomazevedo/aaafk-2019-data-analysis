% Calculates the deadweight loss as a function of assumptions in the
% elasticity matrix.
%% Define calculation parameters
clear;


%% Load data
data = readtable( './output/regressionTreeCategories.csv');
treeData = readtable( './output/regressionTree.csv'); 

% Clear submissions who arrive before April 2012 
%data = data(probabilityData.index,:);

%% Merge data

% Clear chip patients, since we don't use them in regression Tree analysis 
data(strcmp(data.category, 'c' ), :) = [];

data = join(data, treeData, ...
    'Keys', {'index'}, ...
    'RightVariables', {'demand_type'});

% This nTypes different then size of the data since we are omitting chip
% patients here.
nTypes = size(data, 1);

totalDaysData = ...
    max(data.r_dep_date_max) - ...
    min(data.r_arr_date_min) + 1;

clear submissionsData gradientData probabilityData treeData;

%% Add columns
data.q = ones(nTypes, 1) .*(365/totalDaysData);


%% Create group variable for tree specification


%% Aggregate the data into buckets

% Loads D2f and D2f_se
load ./output/D2fMat.mat

N = find(D2f(1,:) == 0);

D2f(:,N) = []; 
D2f(N,:) = []; 

Chip = size(D2f,2);

D2f(:,Chip) = []; 
D2f(Chip,:) = [];


aggregateData = grpstats(data(data.groupTree ~= N,:), ...
    {'groupTree'}, ...
    {'mean', 'sum'}, ...
    'DataVars', {'df', 'matching_probability', 'q'});

p0  = aggregateData.mean_matching_probability';
df0 = aggregateData.mean_df';
q0  = aggregateData.sum_q;

%% Ploting dwl

wedge = df0 - p0;
epsilon = 0.2:0.05:6;
rho = [-0.05 0 0.05];
dwl = zeros(length(epsilon), length(rho));
changeinQ = zeros(length(epsilon), length(rho));
changeTrans = zeros(length(epsilon), length(rho));
changeinPositiveWedge = zeros(length(epsilon), length(rho));
changeinNegativeWedge = zeros(length(epsilon), length(rho));

for i = 1 : length(epsilon)
    i
    
    for j = 1 : length(rho)
        
        for k = 1 : i
            
            DS = zeros(length(p0));

            %[trace, df1, q] = dwl_algorithm_2 (p0, q0, df0, D2f, epsilon(i), rho(j));
            for ii = 1 : length(p0)

                for jj = 1 : length(p0)

                    if ii == jj

                        %DS (ii, ii) = (epsilon(i) / trace.p(end, ii) ) * q(ii);
                        DS (ii, ii) = (epsilon(k) / p0(ii) ) * q0(ii);
                        %DS (ii, ii) = epsilon(k);

                    else

                        %DS (ii, jj) = (rho(j) / trace.p(end, jj) ) * q(ii);  
                        DS (ii, jj) = (rho(j) / p0(jj) ) * q0(ii); 
                        %DS (ii, jj) = rho(j) * epsilon(k); 
                    end

                end

            end
            
            D2C = inv(DS);
            dwl2(k) = wedge * inv(D2C - D2f) * wedge' / 2;
                       
        end      


        dwl(i,j) = max(dwl2);
                


        %[trace, df1 ,q] = dwl_alg_har(p0, q0, df0, D2f, D2C);
        
        
        %D2C = dwl_d2c (epsilon(i), rho(j), p0, q0);
        

        %qStar = trace.q(end,:)';
        %changeQ = qStar - q0;
        %changeinQ (i, j) = sum(changeQ);
        %dwl2(i,j) = wedge * changeQ/2;
        %changeinPositiveWedge (i, j) = sum(changeQ(wedge>0));
        %changeinNegativeWedge (i, j)  = sum(changeQ(wedge<0));
        %pStar = trace.p(end,:);
        %changeTrans(i,j) =  changeQ' * df0' - ...
        %    changeQ' * (-D2f) * changeQ/2;
        %changeTrans2(i,j) =  changeQ' * (df0+df1)'/2;
        

    end
    
    
end

f = figure();
f.Position = [0, 0, 162*3, 100*3];

plot(epsilon,dwl(:,1),'b','LineWidth', 2)
hold on
plot(epsilon,dwl(:,ceil(end/2)),'m','LineWidth', 2)
hold on 
plot(epsilon,dwl(:,end),'k','LineWidth', 2)
legend(['Cross Elasticity, \rho = ' num2str(rho(1))], ...
    ['Cross Elasticity, \rho = ' num2str(rho(ceil(end/2)))],...
    ['Cross Elasticity, \rho = ' num2str(rho(end))],'Location','northwest')
xlabel('Own Elasticity, \epsilon')
ylabel('Total Deadweight Loss Transplants per Year')

print('./output-for-manuscript/figures/harberger-loss.eps', '-depsc2');

f = figure();
f.Position = [0, 0, 162*3, 100*3];

plot(epsilon,changeTrans(:,1),'b','LineWidth', 2)
hold on
plot(epsilon,changeTrans(:,ceil(end/2)),'m','LineWidth', 2)
hold on 
plot(epsilon,changeTrans(:,end),'k','LineWidth', 2)
legend(['Cross Elasticity, \rho = ' num2str(rho(1))], ...
    ['Cross Elasticity, \rho = ' num2str(rho(ceil(end/2)))],...
    ['Cross Elasticity, \rho = ' num2str(rho(end))],'Location','northwest')
xlabel('Own Elasticity, \epsilon')
ylabel('\Delta in Number of Transplants per Year')

print('./output-for-manuscript/figures/change-in-trans.eps', '-depsc2');


f = figure();
f.Position = [0, 0, 162*3, 100*3];

plot(epsilon,changeinQ(:,1),'b','LineWidth', 2)
hold on
plot(epsilon,changeinQ(:,ceil(end/2)),'m','LineWidth', 2)
hold on 
plot(epsilon,changeinQ(:,end),'k','LineWidth', 2)
legend(['Cross Elasticity, \rho = ' num2str(rho(1))], ...
    ['Cross Elasticity, \rho = ' num2str(rho(ceil(end/2)))],...
    ['Cross Elasticity, \rho = ' num2str(rho(end))],'Location','northwest')
xlabel('Own Elasticity, \epsilon')
ylabel('\Delta in Number of Submissions per Year')

print('./output-for-manuscript/figures/change-in-submissions.eps', '-depsc2');


f = figure();
f.Position = [0, 0, 162*3, 100*3];

plot(epsilon,changeinPositiveWedge(:,1),'b','LineWidth', 2)
hold on
plot(epsilon,changeinPositiveWedge(:,ceil(end/2)),'m','LineWidth', 2)
hold on 
plot(epsilon,changeinPositiveWedge(:,end),'k','LineWidth', 2)
legend(['Cross Elasticity, \rho = ' num2str(rho(1))], ...
    ['Cross Elasticity, \rho = ' num2str(rho(ceil(end/2)))],...
    ['Cross Elasticity, \rho = ' num2str(rho(end))],'Location','northwest')
xlabel('Own Elasticity, \epsilon')
ylabel('\Delta in Under-compansated Submissions per Year')

print('./output-for-manuscript/figures/change-in-submissions-positive.eps', '-depsc2');

f = figure();
f.Position = [0, 0, 162*3, 100*3];

plot(epsilon,changeinNegativeWedge(:,1),'b','LineWidth', 2)
hold on
plot(epsilon,changeinNegativeWedge(:,ceil(end/2)),'m','LineWidth', 2)
hold on 
plot(epsilon,changeinNegativeWedge(:,end),'k','LineWidth', 2)
legend(['Cross Elasticity, \rho = ' num2str(rho(1))], ...
    ['Cross Elasticity, \rho = ' num2str(rho(ceil(end/2)))],...
    ['Cross Elasticity, \rho = ' num2str(rho(end))],'Location','northwest')
xlabel('Own Elasticity, \epsilon')
ylabel('\Delta in Over-compansated Submissions per Year')

print('./output-for-manuscript/figures/change-in-submissions-negative.eps', '-depsc2');