function [muMatrix, computationOutput] = ...
    matchwithChainLimit(compatibilityMatrix, statusVector, weightMatrix, options)
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

    if ~isfield(options, 'heuristic')
        options.heuristic = 'wait-it-out';
    end
    if ~isfield(options, 'chainLimit')
        options.chainLimit = 4;
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
    muMatrix= zeros(n) ;

% Return 0 on empty input
    if n <= 1
        muVector = [];
        return;
    end
    
% Set constants
    bridges   = strcmp(statusVector, 'b');
    altruists = strcmp(statusVector, 'a');

    
%% Prepare data for linear program


% Calculate constraint matrix A
% The calculations below are efficient but hard to follow.
% The idea is to index the nonzero constraints by k and l and compute the
% indexes of each. Then use the sparse command to create the matrix.
    % J1 and J2 are feasibility constraints
    % Entries with column = k
   ChainSource = altruists | bridges;
   
   compatibilityMatrix(bridges,:)=0;
   
    cyclesNchains =...
    findCyclesChains(compatibilityMatrix,ChainSource,options.chainLimit);

% Objective

objective = weightObjective(weightMatrix,cyclesNchains);

constraints = cycleChainConstraints(compatibilityMatrix,cyclesNchains) ;


    model.obj = -objective;

    model.A = sparse(constraints);

    model.rhs = ones(length(statusVector), 1);
    model.ub = ones(size(constraints,2),1);
    model.lb = zeros(size(constraints,2),1);

% Gurobi options
    model.sense = '<';
    model.vtype = 'B';
    parameters.OutputFlag = 0;
    parameters.NodefileStart = options.gurobiMemoryLimit;
    parameters.TimeLimit = options.gurobiTimeOut;
   
%% Heuristic solutions for when the recursion limit is reached.

%% Set output variables.

[muVector, gurobiStatus, ...
            integerSolutionProblem] = ...
            runLP(model, parameters,hasGurobi);
               

computationOutput.gurobiStatus = gurobiStatus;

if hasGurobi && ...
        ~strcmp(gurobiStatus, 'OPTIMAL')
    computationOutput.exactSolution = 0;
    display('Warning! Gurobi timeout in match.m');
end

muMatrix = mu2Matrix (muVector,cyclesNchains,compatibilityMatrix);

        if ~isMatch(muMatrix)
            error('Linear programming in match.m returned an invalid match.');
        end
%% Nested Functions
    function [muVector, gurobiStatus, ...
            integerSolutionProblem] = ...
            runLP(model, parameters,hasGurobi)
        % Start
        integerSolutionProblem = 0;
        
        % Run LP
        if hasGurobi
            resultGurobi = gurobi(model, parameters);
            muVector = resultGurobi.x;
            gurobiStatus = resultGurobi.status;
        end

    end
end
