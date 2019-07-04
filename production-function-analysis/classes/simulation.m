classdef simulation
    %SIMULATION This class simulates a kidney exchange.
    %   SIMULATION(q) creates a simulation object for an exchange with
    %   yearly arrival rates given by the vector q. q should have length
    %   equal to the data for types of submissions stored in
    %   ./data/submissions-data.csv and ./data/compatibility-matrix.csv.
    %   Both files are required to exist for the iteration method.
    %
    %   SIMULATION(q, options) accepts a struct of options. TODO: document
    %   option fields.
    %
    %   iterate(Simulation, t) outputs a simulation object with an
    %   additional t days.
    %
    %   A simulation object stores a state, necessary to produce more
    %   iterations and a history of selected statistics and computational
    %   output. The simulation also has a host of useful calculated
    %   properties. See doc simulation for more details.
    %
    %   Options:
    %       .match: struct of match options.
    
    properties (SetAccess = immutable)
        q           % A vector of arrival rates of each type of pair. Should have the same number of rows as the data files.
        options     % A struct of options.
    end
    properties (SetAccess = private)
        t           % Number of days simulated so far.
        state       % Struct with all the information needed to update the simulation.
        history     % Array of structs with historical information that is saved every day.
    end
    properties
        burn        % Number of days to be ignored when calculating derived properties.
    end
    properties (SetAccess = private, Dependent = true)
        y_series                % Time series of number of transplants for each day after the burn period.
        autocorrelation_sum     % Sum of autocorrelations of y_series, including the zero-lag autocorrelation of 1. Equals NaN if there are less than .burn + 1050 simulated days.
        f_mean                  % Mean of the annualized number of tranplants (mean of 365 * y_series).
        f_sd                    % sd of the annualized number of tranplants (sd of 365 * y_series).
        f_se                    % Standard error of the mean of f. Equals NaN if there are not enough simulated days to estimate the sum of autocorrelations.
        time_per_iteration      % Average computation time per iteration after the burn.
        time_burn               % Time to do the burn.
        hours_of_calculation    % Total hours spent in .iterate.
        iterations_vs_se        % Function that returns the number of iterations needed to attain a given standard error.
        hours_vs_se             % Function that returns the number of hours of computations needed to attain a given standard error.
        fraction_exact_solution % Fraction of the time after the burn with an exact solution in the main match.
    end
    
    methods
        % Constructor
        function Simulation = simulation(q, options)
            % SIMULATION(q) Creates a simulation object for an exchange with the
            % arrival rate given by the vector q.
            %
            % SIMULATION(q, options) accepts a struct of options. TODO: document
            %   option fields.
            if nargin < 1 || nargin > 2
                display('Error');
                return;
            end;
            
            Simulation.q = q;
            
            % Options field
            if nargin == 2
                Simulation.options = options;
            else
                Simulation.options = struct();
            end
            
            % Default options
            if ~isfield(Simulation.options, 'match')
                Simulation.options.match = struct();
            end
            if ~isfield(Simulation.options, 'burn')
                Simulation.options.burn = 2000;
            end         
            if ~isfield(Simulation.options, 'bridgeTimeLimit')
                Simulation.options.bridgeTimeLimit = 30;
            end
            if ~isfield(Simulation.options, 'bridgeTimeLimitODABO')
                Simulation.options.bridgeTimeLimitODABO = ...
                    30;
            end
            if ~isfield(Simulation.options, 'waitMarketTime1')
                Simulation.options.waitMarketTime1 = 14;
            end
            if ~isfield(Simulation.options, 'waitMarketTime2')
                Simulation.options.waitMarketTime2 = 14;
            end
            if ~isfield(Simulation.options, 'acceptanceRate1')
                Simulation.options.acceptanceRate1 = 0.75;
            end
            if ~isfield(Simulation.options, 'acceptanceRate2')
                Simulation.options.acceptanceRate2 = 0.75;
            end
            if ~isfield(Simulation.options, 'matchFrequencyRegularMarket')
                Simulation.options.matchFrequencyRegularMarket = 1;
            end
            if ~isfield(Simulation.options, 'matchFrequencyChipMarket')
                Simulation.options.matchFrequencyChipMarket = 1;
            end
            if ~isfield(Simulation.options, 'saveSubmissionHistory')
                Simulation.options.saveSubmissionHistory = 1;
            end
            if ~isfield(Simulation.options, 'saveHardCases')
                Simulation.options.saveHardCases = 0;
            end
            if ~isfield(Simulation.options, 'bridgeOnlyForChip')
                Simulation.options.bridgeOnlyForChip = 1;
            end
            if ~isfield(Simulation.options, 'hazard_cpra')
                Simulation.options.hazard_cpra = {'no_cpra'};
            end   
            if ~isfield(Simulation.options, 'altruisticPointSystem')
                Simulation.options.altruisticPointSystem = 1;                
            end  
            if ~isfield(Simulation.options, 'hardBlock')
                Simulation.options.hardBlock = 1;                
            end      
            if ~isfield(Simulation.options, 'NKRStrategy')
                Simulation.options.NKRStrategy = 1;                
            end         
            if ~isfield(Simulation.options, 'exclusion')
                Simulation.options.exclusion = 1;                
            end  
            if ~isfield(Simulation.options, 'lessUnderdemandedBridge')
                Simulation.options.lessUnderdemandedBridge = 0;                
            end  
            % Set properties
            Simulation.burn = Simulation.options.burn;
            Simulation.t = 0;
            
            % Define simulation state data structure
            Simulation.state.totalNumberofEntry = 0;
            Simulation.state.totalNumberofOffer = 0;            
            Simulation.state.submissions = struct();
            Simulation.state.submissions.id = [];
            Simulation.state.submissions.type = [];
            Simulation.state.submissions.status = [];
            Simulation.state.submissions.phase = [];
            Simulation.state.submissions.acceptedDonor1 = [];
            Simulation.state.submissions.acceptedDonor2 = [];
            Simulation.state.submissions.rejectedDonors = [];
            Simulation.state.submissions.bridgeTime = [];
            Simulation.state.submissions.duration = [];           
            Simulation.state.offers = struct();
            Simulation.state.offers.type = [];
            Simulation.state.offers.time = [];
            Simulation.state.offers.participants = [];
            Simulation.state.offers.id = [];
            Simulation.history = struct();
            Simulation.history.submissionsTable = array2table(zeros(0,8));
            Simulation.history.submissionsTable.Properties.VariableNames = ...
                {'id','type','arrive',...
                'recipientTransplanted','recipientDuration',...
                'donorTransplanted','donorDuration','transplantedRecipient'};
            Simulation.history.submissionsBridge = struct();
            Simulation.history.submissionsBridge.id = [];            
            Simulation.history.hardCase = [];
        end;
        
        % Iterate
        function E = iterate(F, n, initialized)
            % ITERATE(Simulation, t,initialized) outputs a simulation object with an
            % additional t days. The simulation uses data from the files
            % ./data/submissions-data.csv and
            % ./data/compatibility-matrix.txt. Both files are required to
            % exist and to have the same number of rows as the arrival
            % rates q. Initialized is the option that is used for
            % calibration purposes. If initialized option is used then
            % simulation also uses the ./data/initial-hard-blocks.txt to
            % update the compatilibty matrix file. 
            
            % Load data
            if nargin == 3 && initialized
            % This script takes compatibility-matrix and delete some links in the
            % initial market April 1st 2012 by using file called initial-hard-blocks.
            % Initial-hard-block is has the same size of compatibility matrix and ones
            % in that matrix denotes a transplantation that shouldn't be offered for
            % some reason. The reason we are doing is, in the compatibility matrix of 
            % the initial market at April 1st 2012 we might have some transplantations 
            % offers that has been rejected before. 
            
            data.compatibility = dlmread('./data/compatibility-matrix.txt')';
            hardBlocks = dlmread('./data/initial-hard-blocks.txt');
            data.compatibility = data.compatibility - ...
            data.compatibility.*hardBlocks;
            submissionsData = readtable('./data/submissions-data.csv');
            data.category = submissionsData.category;    
                        
                        % The exclusion option uses
                        % ./data/excluded-matrix.txt to delete some links in
                        % the compatibility matrix. 
                        if F.options.exclusion==1
                        data.exclusion = dlmread('./data/excluded-matrix.txt')';
                        data.compatibility(data.exclusion==1) = 0;
                        end
                        
            else
                
            data.compatibility = dlmread('./data/compatibility-matrix.txt')';
            submissionsData = readtable('./data/submissions-data.csv');
            data.category = submissionsData.category;
                        
                        if F.options.exclusion==1
                        data.exclusion = dlmread('./data/excluded-matrix.txt')';
                        data.compatibility(data.exclusion==1) = 0;
                        end
                        
            end
            
            %HardBlock option uses ./data/p_hard_block.txt to potentially
            %delete links whenever a donor arrives. 
            
            if F.options.hardBlock > 0               
            data.hardBlock = dlmread('./data/p_hard_block.txt')';    
            end
            
            % Hazard Rate Selection
            
            % Hazard Rate Selection
            if strcmp(F.options.hazard_cpra,'base')==1
                hazardRates = submissionsData.hazard_base;
            elseif strcmp(F.options.hazard_cpra,'cpra')==1
                hazardRates = submissionsData.hazard_cpra;
            elseif strcmp(F.options.hazard_cpra,'no-hazard')==1
                hazardRates = zeros(length(submissionsData.hazard),1);                    
            elseif strcmp(F.options.hazard_cpra,'hazard1')==1
                hazardRates = submissionsData.hazard1;
            elseif strcmp(F.options.hazard_cpra,'hazard2')==1
                hazardRates = submissionsData.hazard2;
            elseif strcmp(F.options.hazard_cpra,'hazard3')==1
                hazardRates = submissionsData.hazard3;                
            elseif strcmp(F.options.hazard_cpra,'hazard4')==1
                hazardRates = submissionsData.hazard4;
            elseif strcmp(F.options.hazard_cpra,'hazard5')==1
                hazardRates = submissionsData.hazard5;
            elseif strcmp(F.options.hazard_cpra,'hazard6')==1
                hazardRates = submissionsData.hazard6;
            elseif strcmp(F.options.hazard_cpra,'hazard7')==1
                hazardRates = submissionsData.hazard7;
            elseif strcmp(F.options.hazard_cpra,'hazard8')==1
                hazardRates = submissionsData.hazard8;
            elseif strcmp(F.options.hazard_cpra,'hazard9')==1
                hazardRates = submissionsData.hazard9;
            elseif strcmp(F.options.hazard_cpra,'hazard10')==1
                hazardRates = submissionsData.hazard10;              
            else
                hazardRates = submissionsData.hazard;
            end
            
            
            if F.options.altruisticPointSystem
                if isfield(F.state,'centerPoints') ~= 1
                    centerNames = unique(submissionsData.ctr); 
                    for i = 1 : length(centerNames)
                    F.state.centerPoints(i).center = centerNames(i);
                    F.state.centerPoints(i).point = 0;
                    end
                end
               
            end
            
            % This option helps to decrease number of underdemanded bridge
            % donors by decreasing weight on underdemanded recipient and
            % increasing the weight on underdemanded donors transplantation
            % so that in total it stays the same. In this way nothing
            % changes for the underdemanded pairs who are intermediate part
            % of the chains or cycles. 
            if F.options.lessUnderdemandedBridge == 1
            underdemanded = find(strcmp(submissionsData.category,'p')...
                  & strcmp(submissionsData.r_abo,'O') & ~strcmp(submissionsData.d_abo,'O'));  
            end

            % Constants
            nTypes = length(data.category);
            %hasJVM = usejava('jvm');
            

            % Loop
            %if hasJVM
            %    hWaitbar = waitbar(0, 'Running simulation.');
            %end
            
            for ii = 1 : n
                
                ii

                %if hasJVM
                %    waitbar(ii/n, hWaitbar, 'Running simulation.');
                %end

                timerIteration = tic;
                F.t = F.t+1;
                %% 1) Departure Phase
                
                % If there are agents in the pool...
                if ~isempty([F.state.submissions.type])
                    
                    % Tag them for departures randomly accorindg to exit rates.
                    

                    departures = rand(length([F.state.submissions.type]), 1) ...
                        < hazardRates([F.state.submissions.type]);
                        
                    % If some agents are departed...
                    if sum(departures) > 0
                        
                        departedOrders = find(departures);
                        departedids = [F.state.submissions(departedOrders).id];
                        % For each departed entry
                        
                        for i = 1 : length(departedOrders)
                            departedSubmissionOrder = ...
                                find([F.state.submissions.id] == departedids(i));
                            % Check whether departed entry in regular
                            % market or not. 
                            if strcmp([F.state.submissions(departedSubmissionOrder)...
                                    .phase], 'regular market')
                                % If it is in regular market, delete
                                % the submission
                                F = saveSubmission(F,departedSubmissionOrder,'departed');
                                F.state.submissions(departedSubmissionOrder) = [];
                                
                            elseif strcmp([F.state.submissions(departedSubmissionOrder)...
                                    .phase], 'wait market')
                                % If it is in waitmarket check which offer
                                % it is in. 
                                % TODO: should we define a static method
                                % whichOffer to simplify this kind of
                                % calculation??
                                for j = 1 : size([F.state.offers], 2)
                                    offerOrder = find([F.state.offers(j).participants] ...
                                        == departedids(i));
                                    if ~isempty(offerOrder)
                                        % If the offer is a cycle...
                                        if strcmp([F.state.offers(j).type], 'cycle')
                                            rejectedCyclemembers = ...
                                                [F.state.offers(j).participants];
                                            % ... delete the cycle ...
                                            F.state.offers(j) = [];
                                            % ... and for all entries in cycle,
                                            % change the phase to 'regular market'
                                            for k = 1 : length(rejectedCyclemembers)
                                                rejectedMemberOrder = ([F.state.submissions.id] ...
                                                    == rejectedCyclemembers(k));
                                                F.state.submissions(rejectedMemberOrder).phase = ...
                                                    'regular market';
                                            end
                                        elseif strcmp([F.state.offers(j).type], 'chain')
                                            % If departed one is 1st or 2nd
                                            % one in the chain, delete the
                                            % whole chain. 
                                            if offerOrder < 3                                               
                                            rejectedChainmembers = ...
                                                [F.state.offers(j).participants];
                                            F.state.offers(j) = [];
                                            % For all entries of the chain
                                            % change the phase to 'regular market'
                                                for k = 1 : length(rejectedChainmembers)
                                                rejectedMemberOrder = ([F.state.submissions.id] ...
                                                    == rejectedChainmembers(k));
                                                F.state.submissions(rejectedMemberOrder).phase = ...
                                                    'regular market';
                                                end              
                                            % If departed one is not the
                                            % first or second one in the
                                            % chain, keep beginning of the chain. 
                                            elseif offerOrder >= 3
                                                % Reject members after
                                                % departed agent.
                                                rejectedChainmembers = ...
                                                    F.state.offers(j).participants(offerOrder:end);
                                                F.state.offers(j).participants = ...
                                                    F.state.offers(j).participants(1:offerOrder - 1);
                                                % Change the phase of each
                                                % rejected member to
                                                % regular market.
                                                for k = 1 : length(rejectedChainmembers)
                                                rejectedMemberOrder = ([F.state.submissions.id] ...
                                                    == rejectedChainmembers(k));
                                                F.state.submissions(rejectedMemberOrder).phase = ...
                                                    'regular market';
                                                end                                                 
                                            end
                                        end                                     
                                        % Stop searching once it finds
                                        % which offer that the submission in  
                                        break
                                    end
                                end
                                % Delete the submission
                                F = saveSubmission(F,departedSubmissionOrder,'departed');
                                F.state.submissions(departedSubmissionOrder)=[];
                            end
                        end
                    end
                end

                
                %% 2) Entry Phase
                
                % Everyday a arrival number is drawn from Poisson Dist. 
                nArrivals = random('Poisson', sum(F.q)/365);  
                arrivals = randsample(nTypes, nArrivals, true, F.q);
                % For each arrival fill out
                % submissions(i).id,type,status,phase,duration
                marketSize = length([F.state.submissions.id]);
                for i = 1 : nArrivals
                    F.state.submissions(marketSize+i).id = F.state.totalNumberofEntry + i;
                    F.state.submissions(marketSize+i).type = arrivals(i);
                    F.state.submissions(marketSize+i).status = data.category(arrivals(i));
                    F.state.submissions(marketSize+i).phase = {'regular market'};
                    F.state.submissions(marketSize+i).duration = 0;
                    F.state.submissions(marketSize+i).bridgeTime = 0;
                    
                    % At the entry, each patient choose donors to not to
                    % be offered. 
                    
                    if F.options.hardBlock > 0 
                    hardBlockedDonors = data.hardBlock([F.state.submissions.type]',arrivals(i))>...
                        rand(length([F.state.submissions.type]),1);
                    F.state.submissions(marketSize+i).rejectedDonors = ...
                        [F.state.submissions(hardBlockedDonors).id];
                    
                    % At the entry of each donor, patients in the market 
                    % can choose not to be offered the new donor. 
                    
                    hardBlockedbyDonors = data.hardBlock(arrivals(i),[F.state.submissions.type]')'>...
                        rand(length([F.state.submissions.type]),1);
                    hardBlockedbyDonorsOrder = find(hardBlockedbyDonors);
                    
                    for j = 1 : length(hardBlockedbyDonorsOrder)
                        F.state.submissions(hardBlockedbyDonorsOrder(j)).rejectedDonors =... 
                        [F.state.submissions(hardBlockedbyDonorsOrder(j)).rejectedDonors ...
                           F.state.submissions(marketSize+i).id];
                        
                    end
                    
                    end
                    
                    % This option is for pre-determined rejections, for
                    % robustness purposes.
                    
                    if F.options.hardBlock == 2
                        
                    preBlockedDonors = 0.8 < ...
                        rand(length([F.state.submissions.type]),1);                      
                                      
                    F.state.submissions(marketSize+i).rejectedDonors = ...
                        unique ([F.state.submissions(marketSize+i).rejectedDonors ...
                         F.state.submissions(preBlockedDonors).id] );
                    
                    % At the entry of each donor, patients in the market 
                    % can choose not to be offered the new donor. 
                    
                    preBlockedbyDonors = 0.8 < ...
                        rand(length([F.state.submissions.type]),1);
                    preBlockedbyDonorsOrder = find(preBlockedbyDonors);
                    for j = 1 : length(preBlockedbyDonorsOrder)
                        F.state.submissions(preBlockedbyDonorsOrder(j)).rejectedDonors =... 
                        unique ([F.state.submissions(preBlockedbyDonorsOrder(j)).rejectedDonors ...
                           F.state.submissions(marketSize+i).id]);
                        
                    end
                        
                    
                    end
                end
                F.state.totalNumberofEntry = ...
                    F.state.totalNumberofEntry + nArrivals;
                % Keep total number of entries for .ids
                % Keep market size in order to call new colunms in
                % submissions(i).
                
                
                %% 3.1) Match for Altruistic and Pairs           
                
                % Run match for every matchFrequencyRegularMarket periods
                if rem(ii,F.options.matchFrequencyRegularMarket) == 0
                    % Pick up pairs,altruistics and bridge donors

                    regularMarketPool = ...
                        strcmp([F.state.submissions.phase], 'regular market') ...
                        & ( ...
                            strcmp([F.state.submissions.status],'p') ...
                            | strcmp([F.state.submissions.status],'a') ...
                        );


                    if F.options.bridgeOnlyForChip==0
                    bridgeRegularMark = strcmp([F.state.submissions.phase], 'regular market') ...
                        & strcmp([F.state.submissions.status],'b');    
                    
                    % If we dont allow bridge donors to start a new chain
                    % after bridgeTime limit                   
                    
                    else
                    bridgeRegularMark = strcmp([F.state.submissions.phase], 'regular market') &...
                        strcmp([F.state.submissions.status],'b') &...
                        ([F.state.submissions.bridgeTime] < F.options.bridgeTimeLimit); 
                        
                        % If we have a different procedure for 'O' donors
                        % about bridgeTimeLimit
                        
                        if F.options.bridgeTimeLimitODABO ~= F.options.bridgeTimeLimit
                           oBridges = find(strcmp(submissionsData.d_abo(...
                               [F.state.submissions(bridgeRegularMark).type]),'O'));
                           bridgeRegularMarkOrder = find(bridgeRegularMark);
                           bridgeNotinRegularMark = ...
                               bridgeRegularMarkOrder( oBridges (...
                               [F.state.submissions(bridgeRegularMarkOrder(oBridges)).bridgeTime] ...
                               >= F.options.bridgeTimeLimitODABO));
                           bridgeRegularMark(bridgeNotinRegularMark) = 0;                          
                        end

                    end
                    regularMarketPool = (regularMarketPool ...
                        + bridgeRegularMark) > 0 ;
                    
                    typeVector = [F.state.submissions(regularMarketPool).type];
                    statusVector = ...
                        [F.state.submissions(regularMarketPool).status];
                    lastMatchStatus = statusVector;                  
                    compatibilityMatrix = data.compatibility(typeVector,typeVector);
                    
                    regularMarketPoolOrder = find(regularMarketPool);

                    % This part implements previous rejections to the
                    % compatibility matrix so that same offers will not be
                    % offered again. 
                    
                    % Compatibility Matrix
                    for i = 1 : length(regularMarketPoolOrder)
                        if ~isempty([F.state...
                                .submissions(regularMarketPoolOrder(i)).rejectedDonors])
                            
                            rejectedDonors = [F.state...
                                .submissions(regularMarketPoolOrder(i)).rejectedDonors];
                            
                            rejectedDonors = intersect([F.state.submissions.id],rejectedDonors);
                            
                            [~,rejectedOrder,~] = ...
                                intersect([F.state.submissions.id],rejectedDonors);
                            
                            [~,rejectedRegularMarketOrder,~] = ...
                                 intersect(regularMarketPoolOrder,rejectedOrder);
                            
                             compatibilityMatrix...
                                 (rejectedRegularMarketOrder,i) = 0;
                        end
                    end

                    % Weights                
                    NKR_rmpdmp = repmat(submissionsData.d_mp_strict_noabo(typeVector),1,length(typeVector))...
                        .*repmat(submissionsData.r_mp_strict_noabo(typeVector)',length(typeVector),1)*10200;
                    % NKR Strategy
                    
                    weightsMatrix = zeros(size(NKR_rmpdmp,1)); 
                 
                    if F.options.NKRStrategy ==1 
                        
                        weightsMatrix(NKR_rmpdmp>70) = 1;
                        weightsMatrix(NKR_rmpdmp>25&NKR_rmpdmp<=70) = 1.01;
                        weightsMatrix(NKR_rmpdmp>5&NKR_rmpdmp<=25) = 1.2;
                        weightsMatrix(NKR_rmpdmp<=5) = 1.5;
                        
                        % lessUnderdemandedBridge option is changing
                        % weights in a way that match.m favors
                        % nonunderdemanded donors as a bridge donor in ties. 
                        
                        if F.options.lessUnderdemandedBridge ==1 
                            
                        weightsMatrix((ismember(typeVector,underdemanded)),:) =  weightsMatrix(:,(ismember(typeVector,underdemanded)))'/2 +...
                            weightsMatrix((ismember(typeVector,underdemanded)),:);
                        weightsMatrix(:,(ismember(typeVector,underdemanded))) = weightsMatrix(:,(ismember(typeVector,underdemanded))) /2;
                        
                        end
                        
                    elseif F.options.NKRStrategy ==2
                        
                        weightsMatrix(NKR_rmpdmp>5) = 1;
                        weightsMatrix(NKR_rmpdmp<=5) = 1.2; 
                        
                        if F.options.lessUnderdemandedBridge ==1 
                            
                        weightsMatrix((ismember(typeVector,underdemanded)),:) =  weightsMatrix(:,(ismember(typeVector,underdemanded)))'/2 +...
                            weightsMatrix((ismember(typeVector,underdemanded)),:);
                        weightsMatrix(:,(ismember(typeVector,underdemanded))) = weightsMatrix(:,(ismember(typeVector,underdemanded))) /2;
                        
                        end     
                        
                    elseif F.options.NKRStrategy ==3
                        
                        weightsMatrix(NKR_rmpdmp>25) = 1;
                        weightsMatrix(NKR_rmpdmp>5&NKR_rmpdmp<=25) = 6;
                        weightsMatrix(NKR_rmpdmp<=5) = 8;   
                        
                        if F.options.lessUnderdemandedBridge ==1 
                            
                        weightsMatrix((ismember(typeVector,underdemanded)),:) =  weightsMatrix(:,(ismember(typeVector,underdemanded)))'/2 +...
                            weightsMatrix((ismember(typeVector,underdemanded)),:);
                        weightsMatrix(:,(ismember(typeVector,underdemanded))) = weightsMatrix(:,(ismember(typeVector,underdemanded))) /2;
                        
                        end
                        
                     elseif F.options.NKRStrategy ==4
                         
                     weightsMatrix = weightsMatrix + (repmat(submissionsData.r_cpra(typeVector)',length(typeVector),1) >= 90)/200;
                     
                        if F.options.lessUnderdemandedBridge ==1 
                            
                        weightsMatrix((ismember(typeVector,underdemanded)),:) =  weightsMatrix(:,(ismember(typeVector,underdemanded)))'/2 +...
                            weightsMatrix((ismember(typeVector,underdemanded)),:);
                        weightsMatrix(:,(ismember(typeVector,underdemanded))) = weightsMatrix(:,(ismember(typeVector,underdemanded))) /2;
                        
                        end
                        
                    elseif F.options.NKRStrategy ==5
                         
                     weightsMatrix = ones(size(NKR_rmpdmp,1)); 
                     
                        if F.options.lessUnderdemandedBridge ==1 
                            
                        weightsMatrix((ismember(typeVector,underdemanded)),:) =  weightsMatrix(:,(ismember(typeVector,underdemanded)))'/2 +...
                            weightsMatrix((ismember(typeVector,underdemanded)),:);
                        weightsMatrix(:,(ismember(typeVector,underdemanded))) = weightsMatrix(:,(ismember(typeVector,underdemanded))) /2;
                        
                        end   
                        
                    end
                    
                    bridges = strcmp(statusVector,'b');
                    altruistics = strcmp(statusVector,'a');
                    compatibilityMatrix(:,bridges) = 0;
                    compatibilityMatrix(:,altruistics) = 0;
                    compatibilityMatrix(1 : length(statusVector)+1 : ...
                        length(statusVector)^2) = 0;

                    [mu, computationOutput] = match( ...
                        compatibilityMatrix, ...
                        statusVector', ...
                        weightsMatrix, ...
                        F.options.match);
                    lastMatchCompatilibilityMatrix = compatibilityMatrix;
                    
                    if ~isempty(computationOutput.heuristic)
                        
                    [mu, computationOutput] = matchwithChainLimit( ...
                        compatibilityMatrix, ...
                        statusVector', ...
                        weightsMatrix, ...
                        F.options.match);
                    lastMatchCompatilibilityMatrix = compatibilityMatrix;    
                                            
                    end

                    % Save hardcases for further review
                    if F.options.saveHardCases==1 && ~computationOutput.exactSolution                  
                    hardCase.compatibilityMatrix = compatibilityMatrix; 
                    hardCase.statusVector = statusVector;
                    hardCase.weightsMatrix = weightsMatrix;
                    hardCase.options =  F.options.match;
                    
                    
                    numHardCases = length(F.history.hardCase);
                    F.history.hardCase{numHardCases+1} = hardCase;
                    end
                    %% 3.2) Count Cycles and Chains for Altruistic and Pairs

                    offeredChains = findChains(mu);
                    offeredCycles = findCycles(mu,2);
                    regularMarketOrder = find(regularMarketPool);
                    % This step turns offerings in to ids. 
                    for k = 1:size(offeredCycles,1)
                        offeredCycles{k} = ...
                            [F.state.submissions(regularMarketOrder(offeredCycles{k})).id];
                    end
                    for k = 1 : size(offeredChains,1)
                        offeredChains{k} = ...
                            [F.state.submissions(regularMarketOrder(offeredChains{k})).id];
                    end

                    %% 3.3) Update WaitMarket Status for Altruistic and Pairs

                    % Saving new offers to the waitmarket

                    currentOfferNumber = length([F.state.offers(:).time]);
                    % For each chain, we save the information
                    for i = 1 : length(offeredChains)
                        F.state.offers(currentOfferNumber+i).participants=offeredChains{i};
                        [~,orderofChainParticipants]=...
                            intersect([F.state.submissions(:).id],...
                            F.state.offers(currentOfferNumber+i).participants);
                        % Change the status of members of the chain to the 'wait market'
                        for j = 1 : length(orderofChainParticipants)
                            F.state.submissions(orderofChainParticipants(j)).phase = 'wait market';
                        end                
                        F.state.offers(currentOfferNumber+i).type = 'chain';
                        F.state.offers(currentOfferNumber+i).time = 0;
                        % Update the total offer number
                        F.state.totalNumberofOffer = F.state.totalNumberofOffer + 1;
                        F.state.offers(currentOfferNumber+i).id = F.state.totalNumberofOffer;
                    end

                    currentOfferNumber = length([F.state.offers(:).time]);

                    for i = 1 : length(offeredCycles)
                    % For each cycle, we save the information  
                    F.state.offers(currentOfferNumber+i).participants = ...
                        offeredCycles{i};
                    [~,orderofCycleParticipants] = ...
                        intersect([F.state.submissions(:).id],...
                        F.state.offers(currentOfferNumber+i).participants);
                    % Change the status of members of the chain to the 'wait market'
                        for j = 1 : length(orderofCycleParticipants)
                        F.state.submissions(orderofCycleParticipants(j)).phase = 'wait market';
                        end                
                    F.state.offers(currentOfferNumber+i).type =  'cycle';
                    F.state.offers(currentOfferNumber+i).time = 0;
                    % Update the total offer number
                    F.state.totalNumberofOffer = F.state.totalNumberofOffer + 1;
                    F.state.offers(currentOfferNumber+i).id = F.state.totalNumberofOffer;
                    end
                
                end  
                
                %% 4.1) Run Match for Bridges and Chips
                
                % Run match for every matchFrequencyChipMarket periods
                if rem(ii,F.options.matchFrequencyChipMarket)==0
                
                % Pick up chips, bridge donors whose
                % timelimit has been passed. 


                regularMarketPoolforChips = ...
                    strcmp([F.state.submissions.phase], 'regular market')...
                    &(...
                        strcmp([F.state.submissions.status], 'c')...               
                    );
                

                    bridgeChipMark = strcmp([F.state.submissions.phase], 'regular market') &...
                        strcmp([F.state.submissions.status],'b') &...
                        ([F.state.submissions.bridgeTime] >= F.options.bridgeTimeLimit); 
                        
                        % If we have a different procedure for 'O' donors
                        % about bridgeTimeLimit, we need to add 'O' bridge
                        % donors to the chip market. 
                        
                        if F.options.bridgeTimeLimitODABO ~= F.options.bridgeTimeLimit
                           oBridges = find(strcmp(submissionsData.d_abo(...
                               [F.state.submissions(bridgeChipMark).type]),'O'));
                           bridgeChipMarkOrder = find(bridgeChipMark);
                           bridgeinChipMark = ...
                               bridgeChipMarkOrder( oBridges (...
                               [F.state.submissions(bridgeChipMarkOrder(oBridges)).bridgeTime] ...
                               >= F.options.bridgeTimeLimitODABO));
                           bridgeChipMark(bridgeinChipMark) = 1;                          
                        end              
                
                regularMarketPoolforChips = (regularMarketPoolforChips +...
                    bridgeChipMark ) > 0 ;
                        
                typeVector = [F.state.submissions(regularMarketPoolforChips).type];
                statusVector = ...
                    [F.state.submissions(regularMarketPoolforChips).status];
                compatibilityMatrix = data.compatibility(typeVector,typeVector);
                regularMarketPoolOrder = find(regularMarketPoolforChips);
                
                % This part implements previous rejections to the
                % compatibility matrix so that same offers will not be
                % offered again. It is a bit messy now, I will fix it later
                % on. 
                
                % Compatibility Matrix
                for i = 1:length(regularMarketPoolOrder)
                        
                    if ~isempty([F.state...
                                .submissions(regularMarketPoolOrder(i)).rejectedDonors])
                            
                            rejectedDonors = [F.state...
                                .submissions(regularMarketPoolOrder(i)).rejectedDonors];
                            
                            rejectedDonors = intersect([F.state.submissions.id],rejectedDonors);
                            
                            [~,rejectedOrder,~] = ...
                                intersect([F.state.submissions.id],rejectedDonors);
                            
                            [~,rejectedRegularMarketOrder,~] = ...
                                 intersect(regularMarketPoolOrder,rejectedOrder);
                            
                             compatibilityMatrix...
                                 (rejectedRegularMarketOrder,i) = 0;
                    end
                        
                end
                
                % Weights
                NKR_rmpdmp = repmat(submissionsData.d_mp_strict_noabo(typeVector),1,length(typeVector))...
                .*repmat(submissionsData.r_mp_strict_noabo(typeVector)',length(typeVector),1)*10200;
                % NKR Strategy
                
                weightsMatrix = zeros(size(NKR_rmpdmp,1));  
                weightsMatrix(NKR_rmpdmp>70) = 1;
                weightsMatrix(NKR_rmpdmp>25&NKR_rmpdmp<=70) = 1.01;
                weightsMatrix(NKR_rmpdmp>5&NKR_rmpdmp<=25) = 1.2;
                weightsMatrix(NKR_rmpdmp<=5) = 1.5;               
                
                
                if F.options.altruisticPointSystem 
                    chipPoints = zeros(1,length(typeVector),1);
                    for i = 1 : length(typeVector);
                        chipPoints(i) = ...
                            F.state.centerPoints(strcmp([F.state.centerPoints.center],submissionsData.ctr(typeVector(i)))).point;
                    end
                pointSystemWeights = 2*(repmat(chipPoints,size(compatibilityMatrix,1),1)+10000).*compatibilityMatrix;               
                weightsMatrix = weightsMatrix + pointSystemWeights;
                end
                
                [mu2, ~] = match( ...
                    compatibilityMatrix, ...
                    statusVector', ...
                    weightsMatrix, ...
                    F.options.match);      
                % I have changed match.m little bit. Now it is taking
                % Compatibility Matrix as an input.
                
                
                %% 4.2) Count Cycles and Chains for Bridges and Chips
                
                offeredChains1 = findChains(mu2);
                regularMarketOrderforChips = find(regularMarketPoolforChips);
                % This step turns offerings in to ids. 
                for k = 1 : size(offeredChains1,1)
                offeredChains1{k} = ...
                    [F.state.submissions(regularMarketOrderforChips(offeredChains1{k})).id];
                end
                                
                %% 4.3) Update WaitMarket Status for Bridges and Chips
                
                % Saving new offers to the waitmarket

                currentOfferNumber = length([F.state.offers(:).time]);
                % For each chain, we save the information
                for i = 1 : length(offeredChains1)
                F.state.offers(currentOfferNumber+i).participants=offeredChains1{i};
                [~,orderofChainParticipants]=...
                    intersect([F.state.submissions(:).id],...
                    F.state.offers(currentOfferNumber+i).participants);
                % Change the status of members of the chain to the 'wait market'
                    for j = 1 : length(orderofChainParticipants)
                    F.state.submissions(orderofChainParticipants(j)).phase = 'wait market';
                    end                
                F.state.offers(currentOfferNumber+i).type = 'chain';
                F.state.offers(currentOfferNumber+i).time = 0;
                % Update the total offer number
                F.state.totalNumberofOffer = F.state.totalNumberofOffer + 1;
                F.state.offers(currentOfferNumber+i).id = F.state.totalNumberofOffer;
                end
                
                end
 
                %% 5.1) Wait Market 1
                
                % Check whether time limit has been reached for Wait
                % Market1
                offersReachedLimit1 = find([F.state.offers.time]==F.options.waitMarketTime1);
                offersReachedLimit1id = [F.state.offers(offersReachedLimit1).id];
                for i = 1 : length(offersReachedLimit1)
                    % Pick one the offers, check out its order in the
                    % offers
                    offerReachedLimitOrder = ...
                        [F.state.offers.id]==offersReachedLimit1id(i);
                    % Check whether offer is cycle or chain
                    if strcmp(F.state.offers(offerReachedLimitOrder).type, 'cycle')
                        % Set the ids of the cycle participants
                        cycle = F.state.offers(offerReachedLimitOrder).participants;
                        % In order to add 1st member's decision about 2nd
                        % member.
                        cycle2 = [cycle cycle(1)];
                        % Draw a random number for each of the
                        % transplantation, compare with the acceptancerate
                    randomDecisions = rand(length(cycle),1) < F.options.acceptanceRate1;
                    % Overrun Decisions by Previous Decisions
                    for j=2:length(cycle) + 1
                        % Find the order of the entry among submissions
                        orderofEntry = find([F.state.submissions.id]==cycle2(j));
                        % If the offered donor is accepted before, set the
                        % decision to 1. 
                        if ismember(cycle(j-1),...
                                F.state.submissions(orderofEntry).acceptedDonor1);
                           randomDecisions(j-1) = 1;
                        end
                        % Decision Saving                        
                        if randomDecisions(j-1)==1
                            if ~ismember(cycle(j-1),...
                                F.state.submissions(orderofEntry).acceptedDonor1);
                            F.state.submissions(orderofEntry).acceptedDonor1 = ...
                                [F.state.submissions(orderofEntry).acceptedDonor1 cycle(j-1)];
                            end
                        else
                            F.state.submissions(orderofEntry).rejectedDonors = ...
                                [F.state.submissions(orderofEntry).rejectedDonors cycle(j-1)];                           
                        end
                        
                    end
                    % Delete the cycle if there is rejection in cycle
                    if ismember(0,randomDecisions)
                        % Delete the the offer from the offers
                        F.state.offers(offerReachedLimitOrder) = [];
                        % Change the status of the members to the 'regular market'
                        for  j=1:length(cycle)
                            orderofEntry = ([F.state.submissions.id]==cycle(j));
                            F.state.submissions(orderofEntry).phase = 'regular market';
                        end
                    end
                    
                    
                    % Chain  
                    % If the offer is chain
                    elseif strcmp(F.state.offers(offerReachedLimitOrder).type, 'chain')
                    % Set the ids of the participants of the chain    
                    chain = F.state.offers(offerReachedLimitOrder).participants;
                    % Draw a random number for each of the
                    % transplantation, compare with the acceptancerate
                    randomDecisions = rand(length(chain)-1,1) < F.options.acceptanceRate1;
                    % Overrun Decisions by Previous Decisions
                    for j = 1 : length(chain) - 1    
                        % Find the order of the entry among submissions
                        orderofEntry = find([F.state.submissions.id]==chain(j+1));
                        % If the offered donor is accepted before, set the
                        % decision to 1.                       
                        if ismember(chain(j),...
                                F.state.submissions(orderofEntry).acceptedDonor1);
                           randomDecisions(j) = 1;
                        end
                        % Decision Saving
                        if randomDecisions(j)==1
                            if ~ismember(chain(j),...
                                F.state.submissions(orderofEntry).acceptedDonor1);
                            F.state.submissions(orderofEntry).acceptedDonor1 = ...
                                [F.state.submissions(orderofEntry).acceptedDonor1 chain(j)];
                            end
                        else
                            F.state.submissions(orderofEntry).rejectedDonors = ...
                                [F.state.submissions(orderofEntry).rejectedDonors chain(j)];                           
                        end
                        
                    end
                    % Delete the rest of the chain if there is rejection in chain
                    if ismember(0,randomDecisions)
                        % Find thr first rejected transplantation
                        firstRejection = find(randomDecisions==0,1);
                        % If it is the first transplantation 
                        if firstRejection==1
                         % delete the offer
                         F.state.offers(offerReachedLimitOrder) = []; 
                         % Change the status of the members of the chain to
                         % the 'regular market'
                            for  j = 1 : length(chain)
                            orderofEntry=([F.state.submissions.id]==chain(j));
                            F.state.submissions(orderofEntry).phase = 'regular market';
                            end
                        % If it is not the first transplantation
                        else
                            % Delete the rest of the participants from the
                            % chain
                            F.state.offers(offerReachedLimitOrder)...
                                .participants(firstRejection+1:end) = [];
                            for  j = firstRejection + 1 : length(chain)    
                            % Change phase of the ones who are deleted from
                            % the chain to 'regular market'
                            orderofEntry=([F.state.submissions.id]==chain(j));
                            F.state.submissions(orderofEntry).phase = 'regular market';    
                            end
                            
                        end
                    end
                    
                    end
                end
                
                
                %% 5.2) Wait Market 2
                
                % Same comments follows as Wait Market 1
                offersReachedLimit2 = find([F.state.offers.time]==...
                    F.options.waitMarketTime1 + F.options.waitMarketTime2);
                offersReachedLimit2id = [F.state.offers(offersReachedLimit2).id];
                
                for i = 1 : length(offersReachedLimit2)
                    offerReachedLimitOrder = ...
                        [F.state.offers.id]==offersReachedLimit2id(i);
                    if strcmp(F.state.offers(offerReachedLimitOrder).type, 'cycle')
                        cycle = F.state.offers(offerReachedLimitOrder).participants;
                        cycle2 = [cycle cycle(1)];
                    randomDecisions = rand(length(cycle),1) < F.options.acceptanceRate2;
                    % Overrun Decisions by Previous Decisions
                    for j = 2 : length(cycle) + 1
                        orderofEntry = find([F.state.submissions.id]==cycle2(j));
                        if ismember(cycle(j-1),...
                                F.state.submissions(orderofEntry).acceptedDonor2);
                           randomDecisions(j-1) = 1;
                        end
                        % Decision Saving
                        if randomDecisions(j-1)==1
                            if ~ismember(cycle(j-1),...
                                F.state.submissions(orderofEntry).acceptedDonor2);                            
                            F.state.submissions(orderofEntry).acceptedDonor2 = ...
                                [F.state.submissions(orderofEntry).acceptedDonor2 cycle(j-1)];
                            end
                        else
                            F.state.submissions(orderofEntry).rejectedDonors = ...
                                [F.state.submissions(orderofEntry).rejectedDonors cycle(j-1)];                           
                        end
                        
                    end
                    
                    % Delete the cycle if there is rejection in cycle
                    if ismember(0,randomDecisions)
                        F.state.offers(offerReachedLimitOrder) = [];
                        for  j = 1 : length(cycle)
                            orderofEntry = ([F.state.submissions.id]==cycle(j));
                            F.state.submissions(orderofEntry).phase = 'regular market';
                        end
                    end
                    
                    
                    % Chain    
                    elseif strcmp(F.state.offers(offerReachedLimitOrder).type, 'chain')
                           chain = F.state.offers(offerReachedLimitOrder).participants;
                    randomDecisions = rand(length(chain)-1,1) < F.options.acceptanceRate2;
                    % Overrun Decisions by Previous Decisions
                    for j = 1 : length(chain) - 1
                        orderofEntry=find([F.state.submissions.id]==chain(j+1));
                        if ismember(chain(j),...
                                F.state.submissions(orderofEntry).acceptedDonor2);
                           randomDecisions(j) = 1;
                        end
                        % Decision Saving
                        if randomDecisions(j)==1
                            if ~ismember(chain(j),...
                                F.state.submissions(orderofEntry).acceptedDonor2);                            
                            F.state.submissions(orderofEntry).acceptedDonor2 = ...
                                [F.state.submissions(orderofEntry).acceptedDonor2 chain(j)];
                            end
                        else
                            F.state.submissions(orderofEntry).rejectedDonors = ...
                                [F.state.submissions(orderofEntry).rejectedDonors chain(j)];                           
                        end
                        
                    end
                    % Delete the rest of the chain if there is rejection in chain
                    if ismember(0,randomDecisions)
                        firstRejection = find(randomDecisions==0,1);
                        if firstRejection==1
                         F.state.offers(offerReachedLimitOrder)=[]; 
                            for  j = 1 : length(chain)
                            orderofEntry = ([F.state.submissions.id]==chain(j));
                            F.state.submissions(orderofEntry).phase = 'regular market';
                            end
                        else
                            F.state.offers(offerReachedLimitOrder)...
                                .participants(firstRejection+1:end) = [];
                            for  j = firstRejection + 1 : length(chain)    
                            orderofEntry = ([F.state.submissions.id]==chain(j));
                            F.state.submissions(orderofEntry).phase = 'regular market';    
                            end
                            
                        end
                    end
                    
                    end
                end
                
                %% 6) Transplants
                
                cycleTransplanted = 0;
                chainTransplanted = 0;
                transplantedviaCycle = 0;
                transplantedviaChain = 0;
                % Find the offers which survives after
                % waitMarketTime1+waitMarketTime2 days
                offersPassed = find([F.state.offers.time]==...
                    F.options.waitMarketTime1 + F.options.waitMarketTime2);
                % Find the ids of the offers
                offersPassedid = [F.state.offers(offersPassed).id];             
                for i = 1 : length(offersPassed)         
                % Find the order of the offer among offers
                offerPassedOrder = ...
                    find([F.state.offers.id]==offersPassedid(i));
                    % Cycles
                    
                    if strcmp(F.state.offers(offerPassedOrder).type, 'cycle')
                    % Set the ids of the cycle        
                    cycle = F.state.offers(offerPassedOrder).participants;
                    % For each participants of the cycle, delete the
                    % submissions. 
                        for j=1:length(cycle)
                        orderofEntry = ...
                            ([F.state.submissions.id]==cycle(j));
                        F = saveSubmission(F,find(orderofEntry),'transplanted');                        
                        F.state.submissions(orderofEntry) = [];                        
                        end
                    % Delete the offer from offers
                    F.state.offers(offerPassedOrder) = [];                        
                    % Save the number of cycles
                    cycleTransplanted = cycleTransplanted + 1;
                    % Save the number of transplantations via cycles
                    transplantedviaCycle = ...
                        transplantedviaCycle + length(cycle);
                    
                    % Chain
                    
                    elseif strcmp(F.state.offers(offerPassedOrder).type, 'chain')
                    % Set the ids of the chain        
                    chain = F.state.offers(offerPassedOrder).participants;
                    
                    % If there is a point system, add 1 point to centers
                    % whose altruistic donor has been transplanted and
                    % substract 1 point from centers whose chip patient has
                    % been transplanted. 
                    
                    if F.options.altruisticPointSystem
                    chainSource = [F.state.submissions.id]==chain(1);
                    
                        if  strcmp(F.state.submissions(chainSource).status,'a')
                        centerSource = ...
                            submissionsData.ctr(F.state.submissions([F.state.submissions.id]==chain(1)).type);
                    
                        F.state.centerPoints(strcmp([F.state.centerPoints.center],centerSource)).point ...
                            = F.state.centerPoints(strcmp([F.state.centerPoints.center],centerSource)).point + 1;
                        end
                    
                        chainSink = [F.state.submissions.id]==chain(end);
                    
                        if  strcmp(F.state.submissions(chainSink).status,'c')
                        centersink = ...
                            submissionsData.ctr(F.state.submissions([F.state.submissions.id]==chain(end)).type);
                    
                        F.state.centerPoints(strcmp([F.state.centerPoints.center],centersink)).point ...
                            = F.state.centerPoints(strcmp([F.state.centerPoints.center],centersink)).point - 1;
                        end
                    
                    end
                    
                    % For each participants of the chain, delete the
                    % submissions except the last one.                          
                        for j = 1 : length(chain) - 1
                        orderofEntry = ...
                            ([F.state.submissions.id]==chain(j));
                        F = saveSubmission(F,find(orderofEntry),'transplanted');  
                        F.state.submissions(orderofEntry)=[];                        
                        end
                    % Save the number of chain                    
                    chainTransplanted = chainTransplanted+1;
                    % Save the number of transplantations via chains    
                    transplantedviaChain = transplantedviaChain+length(chain)-1;                      
                    % For the last member of the chain check whether it is
                    % chip or pair.
                    potentialBridge = find([F.state.submissions.id]==chain(end));
                    % If it is chip, delete the submission
                    if strcmp(F.state.submissions(potentialBridge).status,'c')
                    F = saveSubmission(F,potentialBridge,'transplanted');   
                    F.state.submissions(potentialBridge) = []; 
                    % If it is bridge, change the phase to 'regular market'
                    % and the status to 'b'
                    elseif strcmp(F.state.submissions(potentialBridge).status,'p')
                       F = saveSubmission(F,potentialBridge,'bridge');                          
                       F.state.submissions(potentialBridge).status = 'b';
                       F.state.submissions(potentialBridge).bridgeTime = 0;
                       F.state.submissions(potentialBridge).phase = 'regular market'; 
                    end
                    % Delete the offer from offers                        
                    F.state.offers(offerPassedOrder) = [];
                    end 
                end
                
                
                %% 7) Save Data
                
                F.history.nTransplants(F.t) = ...
                    transplantedviaCycle + transplantedviaChain;
                F.history.nTransplantsCycles(F.t) = transplantedviaCycle;
                F.history.nTransplantsChains(F.t) = transplantedviaChain;
                F.history.cycleTransplanted(F.t) = cycleTransplanted;
                F.history.chainTransplanted(F.t) = chainTransplanted;
                %F.history.nTransplantsChains=
                %F.history.nTransplantsCycles=
                F.history.time(F.t) = toc(timerIteration);
                marketSize=length([F.state.submissions(:).id]);
                F.history.poolSize.overallMarket(F.t) = marketSize;
                F.history.entrySize(F.t) = F.state.totalNumberofEntry;
                F.history.regularMarket(F.t) = ...
                    sum(strcmp([F.state.submissions(:).phase],'regular market'));
                F.history.poolSize.chip(F.t) = ...
                    sum(strcmp([F.state.submissions.status], 'c'));
                F.history.poolSize.pair(F.t) = ...
                    sum(strcmp([F.state.submissions.status], 'p'));
                F.history.poolSize.altruistic(F.t) =  ...
                    sum(strcmp([F.state.submissions.status], 'a'));
                F.history.poolSize.bridge(F.t) =  ...
                    sum(strcmp([F.state.submissions.status], 'b'));
                if rem(ii,F.options.matchFrequencyRegularMarket) == 0
                    if sum(mu(:))>0
                    F.history.lastMatch.matrix = mu;
                    F.history.lastMatch.status = lastMatchStatus;
                    % I added lastMatchCompatilibilityMatrix, because this will
                    % help us to run better debugging checks for match.m
                    F.history.lastMatch.compatilibilityMatrix = ...
                        lastMatchCompatilibilityMatrix;
                    end
                end
                % Save computation output. Must be careful because this is
                % not defined if the pool was empty and match was not
                % called.
                if exist('computationOutput', 'var')
                    F.history.computationOutput(F.t) = computationOutput;
                    clear computationOutput;
                else
                    [~, F.history.computationOutput(F.t)] = match([], [], [], F.options.match);
                end
                
                
                %% 8) Update Time
                
                for i = 1 : length([F.state.offers.time])
                    F.state.offers(i).time = F.state.offers(i).time + 1;
                end
                
                for i = 1 : length([F.state.submissions(:).duration])
                    F.state.submissions(i).duration = ...
                        F.state.submissions(i).duration + 1;
                end
                
                bridges = find(strcmp([F.state.submissions(:).status],'b'));
                
                for i=1:length(bridges)
                    F.state.submissions(bridges(i)).bridgeTime = ...
                    F.state.submissions(bridges(i)).bridgeTime + 1;
                end
             
            end;
            E = F;
            %if hasJVM
            %    close(hWaitbar);
            %end
        end;
        
        % Creates a table for each types in the simulation, matching
        % probabilities, duration for patient and donor
        function T = typeTable(E)
            
            if E.t <= E.burn
                T = NaN;
                return;
            else
                table = E.history.submissionsTable;                   
                arrayTable = table2array(table);                
                variableNames = table.Properties.VariableNames; 
                arrive = strcmp(variableNames,'arrive');
                recipientDuration = strcmp(variableNames,'recipientDuration');
                donorDuration = strcmp(variableNames,'donorDuration');
                recipientTransplanted = ...
                    strcmp(variableNames,'recipientTransplanted');
                donorTransplanted = ...
                    strcmp(variableNames,'donorTransplanted');
                
                arrayTable((arrayTable(:,donorDuration)==0),donorDuration) =...
                    arrayTable((arrayTable(:,donorDuration)==0),recipientDuration);
                
                arrayTable((arrayTable(:,recipientDuration)==0),recipientDuration) =...
                    arrayTable((arrayTable(:,recipientDuration)==0),donorDuration);
                
                recipientLeave = ...
                    arrayTable(:,arrive) + arrayTable(:,recipientDuration);
                donorLeave = ...
                    arrayTable(:,arrive) + arrayTable(:,donorDuration);
                
                afterBurn = (donorLeave > E.burn &recipientLeave > E.burn); 
                
                table = table(afterBurn,:);
                
                tableDonorTransplanted = ...
                    table(table2array(table(:,donorTransplanted))>0,:); 
                
                tableDonorNotTransplanted = ...
                    table(table2array(table(:,donorTransplanted))==0,:);
                
                tableRecipientTransplanted = ...
                    table(table2array(table(:,recipientTransplanted))>0,:); 
                
                tableRecipientNotTransplanted = ...
                    table(table2array(table(:,recipientTransplanted))==0,:);
                
                reducedTable = varfun(@mean,table,'GroupingVariables',{'type'}) ;
                
                reducedTableDonorTrans = ...
                    varfun(@mean,tableDonorTransplanted,'GroupingVariables',{'type'}) ;
                
                reducedTableDonorNotTrans = ...
                    varfun(@mean,tableDonorNotTransplanted,'GroupingVariables',{'type'}) ;
                
                reducedTableRecipientTrans = ...
                    varfun(@mean,tableRecipientTransplanted,'GroupingVariables',{'type'}) ;
                
                reducedTableRecipientNotTrans = ...
                    varfun(@mean,tableRecipientNotTransplanted,'GroupingVariables',{'type'}) ;
                              
                
                variableNames = reducedTable.Properties.VariableNames;
                id = find(strcmp(variableNames,'mean_id'));
                arrive = find(strcmp(variableNames,'mean_arrive'));
                donorDuration = ...
                    find(strcmp(variableNames,'mean_donorDuration'));
                recipientDuration = ...
                    find(strcmp(variableNames,'mean_recipientDuration'));
                type = find(strcmp(variableNames,'type'));
                reducedTable(:,[id arrive]) = [];
                
                arrayReducedTable = table2array(reducedTable);
                arrayReTaDonTra= ...
                    table2array(reducedTableDonorTrans(:,[type donorDuration]));                
                arrayReTaDonNotTra = ...
                    table2array(reducedTableDonorNotTrans(:,[type donorDuration]));                
                arrayReTaRecTra = ...
                    table2array(reducedTableRecipientTrans(:,[type recipientDuration]));
                arrayReTaRecNotTra = ...
                    table2array(reducedTableRecipientNotTrans(:,[type recipientDuration]));
                              
                entryTypes = (1:length(E.q))'; 
                
                notArrivedTypes = setdiff(entryTypes,arrayReducedTable(:,type));
                notArrTypesDonTra = setdiff(entryTypes,arrayReTaDonTra(:,type));
                notArrTypesDonNotTra = setdiff(entryTypes,arrayReTaDonNotTra(:,type));
                notArrTypesRecTra = setdiff(entryTypes,arrayReTaRecTra(:,type));
                notArrTypesRecNotTra = setdiff(entryTypes,arrayReTaRecNotTra(:,type));
                
                arrayReTaDonTra = sortrows([arrayReTaDonTra ; ...
                    [notArrTypesDonTra  zeros(length(notArrTypesDonTra),1)]],1);
                arrayReTaDonNotTra = sortrows([arrayReTaDonNotTra ; ...
                    [notArrTypesDonNotTra  zeros(length(notArrTypesDonNotTra),1)]],1);
                arrayReTaRecTra = sortrows([arrayReTaRecTra ; ...
                    [notArrTypesRecTra  zeros(length(notArrTypesRecTra),1)]],1);
                arrayReTaRecNotTra = sortrows([arrayReTaRecNotTra ; ...
                    [notArrTypesRecNotTra  zeros(length(notArrTypesRecNotTra),1)]],1);
               
                reducedTableDurations = array2table([arrayReTaDonTra(:,2) ...
                    arrayReTaDonNotTra(:,2) arrayReTaRecTra(:,2) arrayReTaRecNotTra(:,2)]);
                reducedTableDurations.Properties.VariableNames = {'mean_durationDonorTransplanted' ...
                    'mean_durationDonorNotTransplanted' 'mean_durationRecipientTransplanted'...
                    'mean_durationRecipientNotTransplanted'};
                reducedTable(length(arrayReducedTable(:,type)) + 1 : length(entryTypes),1) = ...
                    num2cell(notArrivedTypes);
                % Fix this part later on, substract transplantedRecipient
                % column
                reducedTable = [sortrows(reducedTable(:,1:end-1),'type') reducedTableDurations ] ;

                T = reducedTable;

            end
        end
        % Create an initial market for the simulation from the real
        % registration and departure dates. 
        function [E, randomizedEntry] = initializeMarket(F, submissionsData, forSure, initializingDate)
        % Takes Simulation, submissionsData and two parameters forSure,
        % initializingDate and simulate the initial market at time
        % "initializingData". For some submissions arrival date and
        % departure dates are not points but intervals. forSure makes sure
        % that arrival interval and departure interval doesn't intersect
        % with initializingDate. randomizedEntry gives the number of
        % entries in the initial market that wouldn't ve here if we use
        % forSure. 
            if ~isempty([F.state.submissions.id])
                error('Simulation state space is not empty, create a new simulation class.');
            end
 
            if nargin < 4
                marketStart = 19084;
            else
                marketStart = initializingDate;
            end
 
            %submissionsData.r_departuremax(isnan(submissionsData.r_departuremax)) ...
            %    = submissionsData.r_departure(isnan(submissionsData.r_departuremax));
            %submissionsData.r_arr_datemin(isnan(submissionsData.r_arr_datemin)) ...
            %    = submissionsData.r_date(isnan(submissionsData.r_arr_datemin));
            %submissionsData.d_departuremax(isnan(submissionsData.d_departuremax)) ...
            %    = submissionsData.r_departure(isnan(submissionsData.d_departuremax));
            %submissionsData.d_arr_arr_datemin(isnan(submissionsData.d_arr_arr_datemin)) ...
            %    = submissionsData.d_date(isnan(submissionsData.d_arr_arr_datemin));
 
            chipPatient = strcmp(submissionsData.category,'c');
 
            pairPatient = strcmp(submissionsData.category,'p');
 
            altruisticDonors = strcmp(submissionsData.category,'a');
 
        if nargin < 3 
        % Entries who are in the market at marketStart for sure. 
            recipients = (submissionsData.r_arr_date_max < marketStart ) ...
                & (submissionsData.r_dep_date_min > marketStart );
 
            donors = (submissionsData.d_arr_date_max < marketStart ) ...
                & (submissionsData.d_dep_date_min > marketStart );
    
            randomizedEntry = 0; 
    
            entries = (recipients & (pairPatient + chipPatient)) + ...
                (donors & altruisticDonors); 
        else
        % Entries who may be in the market at marketStart. Here I randomize
        % those entries given the duration interval possibilities. 
            if forSure==1
                recipients = (submissionsData.r_arr_date_max < marketStart ) ...
                    & (submissionsData.r_dep_date_min > marketStart );
 
                donors = (submissionsData.d_arr_date_max < marketStart ) ...
                    & (submissionsData.d_dep_date_min > marketStart );
        
                randomizedEntry = 0;
        
                entries = (recipients & (pairPatient + chipPatient)) + ...
                    (donors & altruisticDonors); 
    
            else
                recipientsSure = (submissionsData.r_arr_date_max < marketStart ) ...
                    & (submissionsData.r_dep_date_min > marketStart );
 
                donorsSure = (submissionsData.d_arr_date_max < marketStart ) ...
                    & (submissionsData.d_dep_date_min > marketStart ); 
        
                recipientDepartureInterval = ...
                    submissionsData.r_dep_date_max - submissionsData.r_dep_date_min ;
                rDepIntLen = find(recipientDepartureInterval > 0) ;
                rDepIntRan = zeros(length(recipientDepartureInterval),1); 
 
            for i = 1 : length(rDepIntLen) 
                rDepIntRan(rDepIntLen(i)) = randperm(rDepIntLen(i),1);   
            end
 
                recipientRegistrationInterval = ...
                    submissionsData.r_arr_date_max - submissionsData.r_arr_date_min ;
                rRegIntLen = find(recipientRegistrationInterval > 0) ;
                rRegIntRan = zeros(length(recipientRegistrationInterval),1); 
    
            for i = 1 : length(rRegIntLen) 
                rRegIntRan(rRegIntLen(i)) = randperm(rRegIntLen(i),1);   
            end
 
                donorDepartureInterval = ...
                    submissionsData.d_dep_date_max - submissionsData.d_dep_date_min ;
                dDepIntLen = find(donorDepartureInterval > 0) ;
                dDepIntRan = zeros(length(donorDepartureInterval),1); 
 
            for i = 1 : length(dDepIntLen) 
                dDepIntRan(rDepIntLen(i)) = randperm(dDepIntLen(i),1);   
            end
 
                donorRegistrationInterval = ...
                    submissionsData.d_arr_date_max - submissionsData.d_arr_date_min ;
                dRegIntLen = find(donorRegistrationInterval > 0) ;
                dRegIntRan = zeros(length(donorRegistrationInterval),1); 
                for i = 1 : length(dRegIntLen) 
                    dRegIntRan(dRegIntLen(i)) = randperm(dRegIntLen(i),1);   
                end
 
                recipients =...
                    ((submissionsData.r_arr_date_min + rDepIntRan)< marketStart)...
                    & (submissionsData.r_dep_date_min + rRegIntRan > marketStart );
        
                donors =...
                    ((submissionsData.d_arr_date_min + dDepIntRan)< marketStart)...
                    & (submissionsData.d_dep_date_min + dRegIntRan > marketStart );
        
                entries = (recipients & (pairPatient + chipPatient)) + ...
                (donors & altruisticDonors); 
    
                entriesForSure = (recipientsSure & (pairPatient + chipPatient)) + ...
                (donorsSure & altruisticDonors); 
    
                randomizedEntry = sum(entries) - sum(entriesForSure);
    
            end
        end
    
        entriesOrder = find(entries);
    
            for i = 1 : length(entriesOrder)
                F.state.submissions(i).id = i;
                F.state.submissions(i).type = submissionsData.index(entriesOrder(i));
                F.state.submissions(i).status = submissionsData.category(entriesOrder(i));
                F.state.submissions(i).phase = {'regular market'};
                if strcmp(submissionsData.category(entriesOrder(i)),'a')
                F.state.submissions(i).duration = ...
                    marketStart - submissionsData.d_arr_date_max(entriesOrder(i));
                else
                F.state.submissions(i).duration = ...
                    marketStart - submissionsData.r_arr_date_max(entriesOrder(i));    
                end
                F.state.submissions(i).bridgeTime = 0;
            end
        F.state.totalNumberofEntry = size([F.state.submissions.id],2);
        E = F ;    
    
        end
        
        % Plot last Match
        function T = plotLastMatch(Y)
            
            if ~isfield(Y.history, 'lastMatch')
                T = [];
                return
            end
            
             % Offer matrix
             mu = Y.history.lastMatch.matrix;
             % Status of the nodes who were in the regular market.
             status = Y.history.lastMatch.status;
             % Compatilibity Matrix for last match run problem. 
             % compatilibilityMatrix = Y.history.lastMatch.compatilibilityMatrix ;
             
             T = plotMatch(mu,status);
        end
       
        

        %% Convenience methods
        function series = get.y_series(E)
            if E.t < E.burn
                series = [];
                return;
            else
                series = E.history.nTransplants;
                series = series(E.burn + 1 : length(series));
            end;
        end;
        
        function value = get.f_mean(E)
            value = mean(365 * E.y_series);
        end;
        
        function value = get.f_sd(E)
            value = std(365 * E.y_series);
        end;
        
        function value = get.autocorrelation_sum(E)
            if E.t < E.burn + 1000
                value = NaN;
                return;
            else
                % Batch means method: http://arxiv.org/pdf/1403.5536v1.pdf
                n = length(E.y_series);
                batchSize = floor(sqrt(n));
                nBatches = floor(n / batchSize);
                m = zeros(nBatches, 1);
                for i = 1 : nBatches
                    batch = E.y_series(1 + (i-1)*batchSize : i * batchSize);
                    m(i) = mean(batch);
                end
                v_batch = var(m);
                v = var(E.y_series);
                value = 0.5 ...
                    * (batchSize ...
                    * v_batch ...
                    / v ...
                    -1 );
            end;
        end;
        
        function value = get.f_se(E)
            if isnan(E.autocorrelation_sum)
                value = NaN;
                return;
            end
            value = E.f_sd * sqrt(1 + 2*E.autocorrelation_sum) / ...
                sqrt(E.t-E.burn);
        end;
        
        function value = get.time_per_iteration(E)
            if E.t <= E.burn
                value = NaN;
                return;
            else
                series = E.history.time;
                series = series(E.burn + 1 : length(series));
                value = mean(series);
            end;
        end;
        
        function value = get.time_burn(E)
            if E.t <= E.burn
                value = NaN;
                return;
            else
                series = E.history.time;
                series = series(1 : E.burn);
                value = sum(series);
            end;
        end;
        
        function value = get.hours_of_calculation(E)
            value = sum(E.history.time) / 3600;
        end;
        
        function value = get.iterations_vs_se(E)
            if E.t <= E.burn + 50;
                value = @(x) NaN;
                return;
            else
                c = E.f_sd * sqrt(1 + 2*E.autocorrelation_sum);
                value = @(x) (c/x) .^ 2;
            end;
        end;
        
        function value = get.hours_vs_se(E)
            value = @(x) (E.iterations_vs_se(x) ...
                .* E.time_per_iteration ...
                ./ 3600) ...
                + (E.burn / 3600);
        end;        
        
        function value = get.fraction_exact_solution(E)
            if E.t <= E.burn
                value = NaN;
                return;
            else
                series = [E.history.computationOutput.exactSolution];
                series = series(E.burn + 1 : length(series));
                value = mean(series);
            end;
        end;
                 
    end
    
end

% Save the departed entries
function F = saveSubmission(F,departedSubmissionOrder,status)

    % If you don't want to save, saveSubmission returns same F
    if ~F.options.saveSubmissionHistory
        return;
    end
    
    warning('off','all')
    
    departedId = F.state.submissions(departedSubmissionOrder).id ; 
    id = strcmp(F.history.submissionsTable...
        .Properties.VariableNames,'id');
    type = strcmp(F.history.submissionsTable...
        .Properties.VariableNames,'type');
    arrive = strcmp(F.history.submissionsTable...
        .Properties.VariableNames,'arrive');
    recipientTransplanted = strcmp(F.history.submissionsTable...
        .Properties.VariableNames,'recipientTransplanted');
    recipientDuration = strcmp(F.history.submissionsTable...
        .Properties.VariableNames,'recipientDuration');
    donorTransplanted = strcmp(F.history.submissionsTable...
        .Properties.VariableNames,'donorTransplanted');
    donorDuration = strcmp(F.history.submissionsTable...
        .Properties.VariableNames,'donorDuration');
    transplantedRecipientOrder = strcmp(F.history.submissionsTable...
        .Properties.VariableNames,'transplantedRecipient');
    
    % If the submission is a bridge donor
    
    if ismember(departedId,...
            [F.history.submissionsBridge.id]);
        
        submissionBridgeOrder = find([F.history.submissionsBridge.id]==...
            departedId);
        
        
        totalLeavedSubmission = size(F.history.submissionsTable,1);
        
        F.history.submissionsTable(totalLeavedSubmission+1,id) = ...
            {departedId};
        
        F.history.submissionsTable(totalLeavedSubmission+1,type) = ...
            {F.state.submissions(departedSubmissionOrder).type};
        
        F.history.submissionsTable(totalLeavedSubmission+1,arrive) = ...
            {F.t - F.state.submissions(departedSubmissionOrder).duration};
        
        F.history.submissionsTable(totalLeavedSubmission+1,recipientTransplanted) = ...
            {F.history.submissionsBridge(submissionBridgeOrder).recipientTransplanted};
        
        F.history.submissionsTable(totalLeavedSubmission+1,recipientDuration) = ...
            {F.history.submissionsBridge(submissionBridgeOrder).recipientDuration};
        
        F.history.submissionsTable(totalLeavedSubmission+1,donorDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};
        
        if strcmp(status,'departed')

            F.history.submissionsTable(totalLeavedSubmission+1,donorTransplanted) = {0};

        elseif strcmp(status,'transplanted')

            F.history.submissionsTable(totalLeavedSubmission+1,donorTransplanted) = {1};
            
            transplantedRecipient = findTransplanted(F,departedId);
            
            F.history.submissionsTable(totalLeavedSubmission+1,transplantedRecipientOrder) = ...
                {transplantedRecipient};
            
        end
        % Delete the info of the Bridge
        F.history.submissionsBridge(submissionBridgeOrder) = [] ;
        return;
    end
    
            


    if strcmp(status,'departed')
        % If submission is departed
        
        totalLeavedSubmission = size(F.history.submissionsTable,1);
        
        F.history.submissionsTable(totalLeavedSubmission+1,id) = ...
            {departedId};
        
        F.history.submissionsTable(totalLeavedSubmission+1,type) = ...
            {F.state.submissions(departedSubmissionOrder).type};
        
        F.history.submissionsTable(totalLeavedSubmission+1,arrive) = ...
            {F.t - F.state.submissions(departedSubmissionOrder).duration}; 

            if strcmp(F.state.submissions(departedSubmissionOrder).status,'p')

                % Donor and Recipient aren't transplanted
                
                F.history.submissionsTable(totalLeavedSubmission+1,recipientTransplanted) = {0};

                F.history.submissionsTable(totalLeavedSubmission+1,donorTransplanted) = {0};

                F.history.submissionsTable(totalLeavedSubmission+1,recipientDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};                                

                F.history.submissionsTable(totalLeavedSubmission+1,donorDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};     

            elseif strcmp(F.state.submissions(departedSubmissionOrder).status,'a')

                F.history.submissionsTable(totalLeavedSubmission+1,donorTransplanted) = {0};

                F.history.submissionsTable(totalLeavedSubmission+1,donorDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};                                    

            elseif strcmp(F.state.submissions(departedSubmissionOrder).status,'c')

                F.history.submissionsTable(totalLeavedSubmission+1,recipientTransplanted) = {0};

                F.history.submissionsTable(totalLeavedSubmission+1,recipientDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};      

            end


    elseif strcmp(status,'transplanted')
        
        totalLeavedSubmission = size(F.history.submissionsTable,1);
        
        F.history.submissionsTable(totalLeavedSubmission+1,id) = ...
            {departedId};
        
        F.history.submissionsTable(totalLeavedSubmission+1,type) = ...
            {F.state.submissions(departedSubmissionOrder).type};
        
        F.history.submissionsTable(totalLeavedSubmission+1,arrive) = ...
            {F.t - F.state.submissions(departedSubmissionOrder).duration}; 

            if strcmp(F.state.submissions(departedSubmissionOrder).status,'p')

                % Donor and Recipient are transplanted
                
                F.history.submissionsTable(totalLeavedSubmission+1,recipientTransplanted) = {1};

                F.history.submissionsTable(totalLeavedSubmission+1,donorTransplanted) = {1};

                transplantedRecipient = findTransplanted(F,departedId);
            
                F.history.submissionsTable(totalLeavedSubmission+1,transplantedRecipientOrder) = ...
                    {transplantedRecipient};  
                
                F.history.submissionsTable(totalLeavedSubmission+1,recipientDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};                                

                F.history.submissionsTable(totalLeavedSubmission+1,donorDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};   
                
              

            elseif strcmp(F.state.submissions(departedSubmissionOrder).status,'a')

                F.history.submissionsTable(totalLeavedSubmission+1,donorTransplanted) = {1};

                F.history.submissionsTable(totalLeavedSubmission+1,donorDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};
                
                transplantedRecipient = findTransplanted(F,departedId);
            
                F.history.submissionsTable(totalLeavedSubmission+1,transplantedRecipientOrder) = ...
                {transplantedRecipient};                

            elseif strcmp(F.state.submissions(departedSubmissionOrder).status,'c')

                F.history.submissionsTable(totalLeavedSubmission+1,recipientTransplanted) = {1};

                F.history.submissionsTable(totalLeavedSubmission+1,recipientDuration) = ...
                    {F.state.submissions(departedSubmissionOrder).duration};       

            end
            
    elseif strcmp(status,'bridge')

        totalBridgeSubmission = size([F.history.submissionsBridge.id],2) ; 
        
        F.history.submissionsBridge(totalBridgeSubmission + 1).id = ...
            departedId;
        
        F.history.submissionsBridge(totalBridgeSubmission + 1).type = ...
            F.state.submissions(departedSubmissionOrder).type ;
        
        F.history.submissionsBridge(totalBridgeSubmission + 1).arrive = ...
            F.t - F.state.submissions(departedSubmissionOrder).duration ;
        
        F.history.submissionsBridge(totalBridgeSubmission + 1).recipientTransplanted = 1 ;
        
        F.history.submissionsBridge(totalBridgeSubmission + 1).recipientDuration = ...
            F.state.submissions(departedSubmissionOrder).duration ;
        
    end
end