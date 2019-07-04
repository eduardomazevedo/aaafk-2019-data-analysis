function [f_mean, f_se] = dechipize(Simulation)
numSim = length(Simulation);

submissionsData = readtable('./data/submissions-data.csv', 'Delimiter', 'tab');

chip = strcmp(submissionsData.category,'c');
f_se = nan(numSim,1);
f_mean  = nan(numSim,1);
for i = 1 : numSim
        if numSim == 1
            SimTable = Simulation.history.submissionsTable;
            numPeriod = Simulation.t;
            
                chipinSim = ismember([SimTable.type],find(chip));
                SimTable(chipinSim,:)= [];
                matchedOnes = SimTable.recipientTransplanted>0;
                matchedTimes = sort(SimTable.arrive(matchedOnes) + ...
                    SimTable.recipientDuration(matchedOnes));

                [a,b]=hist(matchedTimes,unique(matchedTimes));

                y_series = zeros(numPeriod,1);
                y_series(b) = a'*365;

                if numPeriod < 2000 + 1000
                    autocorrelation_sum = NaN;
                    return;
                else
                    % Batch means method: http://arxiv.org/pdf/1403.5536v1.pdf
                    n = length(y_series);
                    batchSize = floor(sqrt(n));
                    nBatches = floor(n / batchSize);
                    m = zeros(nBatches, 1);
                    for j = 1 : nBatches
                        batch = y_series(1 + (j-1)*batchSize : j * batchSize);
                        m(j) = mean(batch);
                    end
                    v_batch = var(m);
                    v = var(y_series);
                    autocorrelation_sum = 0.5 ...
                        * (batchSize ...
                        * v_batch ...
                        / v ...
                        -1 );
                end;

                if isnan(autocorrelation_sum)
                    f_se(i) = NaN;
                end
                
                f_se(i) = std(y_series) * sqrt(1 + 2*autocorrelation_sum) / ...
                    sqrt(numPeriod-2000);
                f_mean(i) = mean(y_series);
            
                        
        else 
            
            if iscell(Simulation) &&  ~isempty(Simulation{i})
                
                SimTable = Simulation{i}.history.submissionsTable;
                numPeriod = Simulation{i}.t;
                chipinSim = ismember([SimTable.type],find(chip));
                SimTable(chipinSim,:)= [];
                matchedOnes = SimTable.recipientTransplanted>0;
                matchedTimes = sort(SimTable.arrive(matchedOnes) + ...
                    SimTable.recipientDuration(matchedOnes));

                [a,b]=hist(matchedTimes,unique(matchedTimes));

                y_series = zeros(numPeriod,1);
                y_series(b) = a'*365;

                if numPeriod < 2000 + 1000
                    autocorrelation_sum = NaN;
                    return;
                else
                    % Batch means method: http://arxiv.org/pdf/1403.5536v1.pdf
                    n = length(y_series);
                    batchSize = floor(sqrt(n));
                    nBatches = floor(n / batchSize);
                    m = zeros(nBatches, 1);
                    for j = 1 : nBatches
                        batch = y_series(1 + (j-1)*batchSize : j * batchSize);
                        m(j) = mean(batch);
                    end
                    v_batch = var(m);
                    v = var(y_series);
                    autocorrelation_sum = 0.5 ...
                        * (batchSize ...
                        * v_batch ...
                        / v ...
                        -1 );
                end;

                if isnan(autocorrelation_sum)
                    f_se(i) = NaN;
                end
                
                f_se(i) = std(y_series) * sqrt(1 + 2*autocorrelation_sum) / ...
                    sqrt(numPeriod-2000);
                f_mean(i) = mean(y_series);
                
                
                
            elseif ~iscell(Simulation) && ~isempty(Simulation)
                SimTable = Simulation(i).history.submissionsTable;
                numPeriod = Simulation(i).t;

                chipinSim = ismember([SimTable.type],find(chip));
                SimTable(chipinSim,:)= [];
                matchedOnes = SimTable.recipientTransplanted>0;
                matchedTimes = sort(SimTable.arrive(matchedOnes) + ...
                    SimTable.recipientDuration(matchedOnes));

                [a,b]=hist(matchedTimes,unique(matchedTimes));

                y_series = zeros(numPeriod,1);
                y_series(b) = a'*365;

                if numPeriod < 2000 + 1000
                    autocorrelation_sum = NaN;
                    return;
                else
                    % Batch means method: http://arxiv.org/pdf/1403.5536v1.pdf
                    n = length(y_series);
                    batchSize = floor(sqrt(n));
                    nBatches = floor(n / batchSize);
                    m = zeros(nBatches, 1);
                    for j = 1 : nBatches
                        batch = y_series(1 + (j-1)*batchSize : j * batchSize);
                        m(j) = mean(batch);
                    end
                    v_batch = var(m);
                    v = var(y_series);
                    autocorrelation_sum = 0.5 ...
                        * (batchSize ...
                        * v_batch ...
                        / v ...
                        -1 );
                end;

                if isnan(autocorrelation_sum)
                    f_se(i) = NaN;
                end
                
                f_se(i) = std(y_series) * sqrt(1 + 2*autocorrelation_sum) / ...
                    sqrt(numPeriod-2000);
                f_mean(i) = mean(y_series);             
            end
        end


end
end