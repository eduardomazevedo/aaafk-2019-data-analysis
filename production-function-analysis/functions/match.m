function [mu, computationOutput] = ...
    match(compatibilityMatrix, statusVector, weightMatrix, options)
% match  Finds an optimal kidney exchange match.
%   mu = match(compatibilityMatrix, statusVector, weightMatrix) returns the
%   optimal match. compatibilityMatrix describes whether submission i can
%   donate to submission j. statusVector describes the status of each
%   submission: 'a'ltruistic, 'p'air, 'b'ridge, or 'c'hip. weightMatrix
%   specifies how much weight we give to each transplant.
%
%   [mu, computationOutput] = match(compatibilityMatrix, statusVector,
%   weightMatrix) also returns a struct with output describing the
%   computation.
%
%   mu = match(compatibilityMatrix, statusVector, weightMatrix, options)
%   allows for a struct of options.
%
%   Options:
%       .itaiReps = 10: Maximum number of LP calls in Itai's algorithm phase.
%       .johnsonReps = 2: Maximum number of LP calls in Johnsons's algorithm phase.
%       .gurobiTimeOut = 30: Gurobi time limit.

%% Parse inputs
% Options: create if does not exist.
    if ~exist('options', 'var')
        options = struct();
    end

% Options: set unused fields to default values
    if ~isfield(options, 'itaiReps')
        options.itaiReps = 5;
    end
    if ~isfield(options, 'maxCycleAllowed')
        options.maxCycleAllowed = 3;
    end
    if ~isfield(options, 'heuristic')
        options.heuristic = 'wait-it-out';
    end
    if ~isfield(options, 'johnsonAlgorithm')
        options.johnsonAlgorithm = 1;
    end
    if ~isfield(options, 'johnsonTimeOut')
        options.johnsonTimeOut = 1;
    end
    if ~isfield(options, 'johnsonReps')
        options.johnsonReps = 2;
    end   
    if ~isfield(options,'useLongCycleNodes')
        options.useLongCycleNodes = true;
    end
    if ~isfield(options, 'gurobiTimeOut')
        options.gurobiTimeOut = 30;
    end
    if ~isfield(options, 'gurobiMemoryLimit')
        options.gurobiMemoryLimit = 6;
    end
    
% Set computation output to default values
    computationOutput.nIterationsItai          = 0;
    computationOutput.nIterationsJohnson       = 0;
    computationOutput.nCyclesJohnson           = 0;
    computationOutput.exactSolution            = 1;
    computationOutput.heuristic                = '';
    computationOutput.time.itaiPhase           = 0;
    computationOutput.time.johnsonPhase        = 0;
    computationOutput.time.cycles              = 0;
    computationOutput.time.cycleConstraints    = 0;
    computationOutput.time.python              = 0;
    computationOutput.maxItaiIterationsReached = 0;
    computationOutput.integerSolutionProblem   = 0;
    computationOutput.gurobiStatus   = '';
    

%% Start
    n = length(statusVector);
    hasGurobi = (exist('gurobi', 'file') == 3);

% Return 0 on empty input
    if n <= 1
        mu = [];
        return;
    end
    
% Set constants
    pairs     = strcmp(statusVector, 'p');
    bridges   = strcmp(statusVector, 'b');
    chips     = strcmp(statusVector, 'c');
    altruists = strcmp(statusVector, 'a');

    
%% Prepare data for linear program
% Objective
    model.obj = -reshape(weightMatrix, [n^2, 1]);

% Calculate constraint matrix A
% The calculations below are efficient but hard to follow.
% The idea is to index the nonzero constraints by k and l and compute the
% indexes of each. Then use the sparse command to create the matrix.
    % J1 and J2 are feasibility constraints
    % Entries with column = k
    J1 = bsxfun(@(k, l) k + (l-1).*n, (1:n)', (1:n));
    % Entries with row = k
    J2 = bsxfun(@(k, l) (k-1).*n + l, (1:n)', (1:n));

    pairsIndex = find(pairs);
    % Make the code more robust to empty pairs index in different MATLAB
    % versions.
    if isempty(pairsIndex)
        pairsIndex = zeros(0, 1);
    end
    nPairs = length(pairsIndex);

    % J3 and J4 are constraints that no pair wants to give a kidney
    % without getting one.
    % Entries w column = k
    J3 = bsxfun(@(k, l) k + (l-1).*n, pairsIndex, (1:n));
    % Entries w row = k
    J4 = bsxfun(@(k, l) (k-1).*n + l, pairsIndex, (1:n));

    I = [repelem((1:n)', n); ...
        repelem((1:n)' + n, n); ...
        repelem((1:nPairs)' + 2*n, n, 1); ...
        repelem((1:nPairs)' + 2*n, n, 1)];

    J1 = J1';
    J2 = J2';
    J3 = J3';
    J4 = J4';

    J = [J1(:); J2(:); J3(:); J4(:)];

    S = [ones(2*n^2, 1); ones(nPairs*n, 1); -ones(nPairs*n, 1)];

    % Create matrix. Right now I am leaving an extra n^2 space to add
    % constraints below. This uses more memory but will make growing the
    % matrix faster.
    model.A = sparse(I, J, S, 2*n + nPairs, n^2, 2*n^2 + 2*n*nPairs + n^2);
    clear I J J1 J2 J3 J4 S

% Other inputs to lp
    model.c = compatibilityMatrix;
    % Set matrix diagonal to 0
    model.c(1 : n+1 : n^2) = 0;
    % Bridge donors cannot receive
    model.c(:, bridges) = 0;
    % In the dynamic case altruistics don't give directly to chips (do we want this????)
    if nargin == 3
        model.c(altruists, chips) = 0;
    end

    model.rhs = ones(2*n + nPairs, 1);
    model.rhs(2*n + 1: 2*n + nPairs) = 0;
    model.ub = model.c(:);
    model.lb = zeros(n^2, 1);

% Gurobi options
    model.sense = '<';
    model.vtype = 'B';
    parameters.OutputFlag = 0;
    parameters.NodefileStart = options.gurobiMemoryLimit;
    parameters.TimeLimit = options.gurobiTimeOut;

    
%% Run Linear program, recursively removing long cycles if need be.
% This is algorithm #1 from Itai's PNAS paper.
nIterationsItai = 1;
hasCycle = 1;
timerItai = tic;
while(hasCycle && nIterationsItai <= options.itaiReps)  
    % Run linear program
    [mu, gurobiStatus, ...
            muCycles, hasCycle, ...
            computationOutput.integerSolutionProblem] = ...
            runLP(model, parameters, n, hasGurobi, options);
    
    % Add constraints for cycles if needed
    if hasCycle
        [I, J, newRhs] = cycleConstraints(muCycles, n);        
        model.A = [model.A; sparse(I, J, 1, length(muCycles), n^2, length(I))];        
        model.rhs = [model.rhs; newRhs];
    end
    
    nIterationsItai = nIterationsItai + 1;
end

computationOutput.nIterationsItai = nIterationsItai - 1;
computationOutput.time.itaiPhase = toc(timerItai);

if hasCycle
    computationOutput.maxItaiIterationsReached = 1;
else
    computationOutput.maxItaiIterationsReached = 0;
end


%% Johnson's cycle algorithm.
 % If there are still cycles, use Johnon's
 % algorithm to find all cycles in the compatibility matrix.

if hasCycle && options.johnsonAlgorithm
    timerJohnsonPhase = tic;
    
    % Python compatibility in the Wharton server
     if exist('/home/bepp/eazevedo/ra/omer/python-env/bin/', 'dir')
        [~, pythonVersion] = pyversion;
        if ~strcmp(pythonVersion, '/home/bepp/eazevedo/ra/omer/python-env/bin/python')
            pyversion('/home/bepp/eazevedo/ra/omer/python-env/bin/python');
        end
     elseif exist('/home/bepp/eazevedo/python-env/bin/', 'dir')
        [~, pythonVersion] = pyversion;
        if ~strcmp(pythonVersion, '/home/bepp/eazevedo/python-env/bin/python')
            pyversion('/home/bepp/eazevedo/python-env/bin/python');
        end

    end

    % Load relevant python libraries
    if count(py.sys.path, './py/') == 0
        insert(py.sys.path, int32(0), './py/');
    end
    py.importlib.import_module('networkx');    
    readcycles = py.importlib.import_module('readcycles');
    py.reload(readcycles);
    
    % Cycles from all pairs
    cyclesGen = getCyclesList(model.c(pairs, pairs));    
    
    for bb = 1:options.johnsonReps    
        computationOutput.nIterationsJohnson = ...
            computationOutput.nIterationsJohnson + 1;
        
        timerCycles = tic;
        
        % Loop until johnsonAlgorithm timeout
        [cycles, timedOut, t] = getCycles(cyclesGen, options.johnsonTimeOut, readcycles, pairsIndex);
        computationOutput.time.python = ...
            computationOutput.time.python + t;
        computationOutput.nCyclesJohnson = ...
            computationOutput.nCyclesJohnson + ...
            length(cycles);
        
        if timedOut && options.useLongCycleNodes
            % Also get an intelligent list of cycles from subset of pairs
            cycleNodes = sort(unique(cat(2, muCycles{:})));
            cyclesNodesGen = getCyclesList(model.c(cycleNodes, cycleNodes));  
            
            cyclesNodes = getCycles(cyclesNodesGen, options.johnsonTimeOut, readcycles, pairsIndex);
            cycles = cat(1, cycles, cyclesNodes);
        end
        
        computationOutput.time.cycles = ...
            computationOutput.time.cycles + ...
            toc(timerCycles);
        timerCycleConstraints = tic;
        
        % Add constraints for cycles
        [I, J, newRhs] = cycleConstraints(cycles, n);                
        model.A = [model.A; sparse(I, J, 1, length(cycles), n^2, length(I))];        
        model.rhs = [model.rhs; newRhs];
   
        computationOutput.time.cycleConstraints = ...
            computationOutput.time.cycleConstraints + ...
            toc(timerCycleConstraints);
        
        % If no cycles were found then break. This may happen if the reason
        % why an optimal solution was not found was a Gurobi timeout. That
        % is, we already have all cycles, but Gurobi gave up before finding
        % a solution in a previous Johnson iteration.
        if isempty(cycles)
            break;
        end
        
        % Run LP
        [mu, gurobiStatus, ...
         muCycles, hasCycle, ...
         computationOutput.integerSolutionProblem] = ...
            runLP(model, parameters, n, hasGurobi, options);
        
        if ~hasCycle
            break;
        end
    end
    
    computationOutput.time.johnsonPhase = toc(timerJohnsonPhase);
end


%% Heuristic solutions for when the recursion limit is reached.
if hasCycle
    display('Warning! Heuristic solution in match.m');
    if strcmp(options.heuristic, 'wait-it-out')
        mu(:, :) = 0;
        computationOutput.exactSolution = 0;
        % Save hard cases to check later on. 
        
        computationOutput.heuristic = options.heuristic;
        display('Heuristic returned empty match');
    end
end


%% Set output variables.
computationOutput.gurobiStatus = gurobiStatus;
if hasGurobi && ...
        ~strcmp(gurobiStatus, 'OPTIMAL')
    computationOutput.exactSolution = 0;
    display('Warning! Gurobi timeout in match.m');
end


%% Nested Functions
    function [mu, gurobiStatus, ...
            cycles, hasCycle, integerSolutionProblem] = ...
            runLP(model, parameters, n, hasGurobi, options)
        % Start
        integerSolutionProblem = 0;
        
        % Run LP
        if hasGurobi
            resultGurobi = gurobi(model, parameters);
            mu = resultGurobi.x;
            gurobiStatus = resultGurobi.status;
        else
            intcon = 1:n^2;
            optionsLP = optimoptions('intlinprog', 'Display', 'off');
            mu = intlinprog(model.obj, intcon,...
                model.A, model.rhs, [], [], model.lb, model.ub, ...
                optionsLP);
            gurobiStatus = 'matlab'; % Used MATLAB optimizer.            
        end
        
        mu = reshape(mu, n, n);
        
        % Validation
        if ~isequal(mu, round(mu))
            integerSolutionProblem = 1;
            mu = round(mu);
        end
        if ~isMatch(mu)
            error('Linear programming in match.m returned an invalid match.');
        end

        % Check for cycles        
        cycles = findCycles(mu, options.maxCycleAllowed + 1);
        hasCycle = ~isempty(cycles);
    end

    function [I, J, newRhs] = cycleConstraints(cycles, n)                                
        % Compute newRhs           
        newRhs = cellfun(@length, cycles) - 1;
        
        % Get the column indices for each cycle
        J_fun = @(cycle_c) ...
            cycle_c' + n * ([cycle_c(2:end) cycle_c(1)]-1)';
        J_cell = cellfun(J_fun, cycles, 'UniformOutput', false);
        J = cat(1, J_cell{:});
        
        % I indices
        I = repelem(1:length(cycles), newRhs+1)';               
    end

    % Generates a cycle generator
    function [cycles_list] = getCyclesList(adj)
        % Construct a python Directed Graph Object
        G = py.networkx.DiGraph();        
        [II, JJ] = find(adj);
        for ii = 1:length(II)        
            G.add_edge(II(ii), JJ(ii));    
        end
        
        % Generator for Cycles
        cycles_list = py.networkx.simple_cycles(G);
    end

    % Reads cycles from cycle generator cycles_list
    function [cycles, timedOut, timePython] = getCycles(cyclesGen, timeOut, readcycles, pairsIndex)
        % Read cycles
        output = readcycles.readcycles(cyclesGen, timeOut);
        
        % Read whether cycles was timed out
        timedOut = output{2};
        timePython = output{3};
        
        % Reformat cycles
        cycles = cell(output{1})';
        cycles = cellfun(@(c) cell(c), cycles, 'UniformOutput', false);
        
        % Get pair indices
        cycles = cellfun(@(c) pairsIndex(cat(2, c{:}))', ...
            cycles, 'UniformOutput', false);        
    end    
end
