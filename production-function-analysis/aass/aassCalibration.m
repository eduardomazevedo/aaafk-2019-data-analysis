%AASS Advanced asynchronous simulation system (c).
%   Should be called by run_aass.m and aass.sh, not by the user. Reads
%   simulation options from spec.m in target folder, performs the required
%   simulations, and saves .mat files.
%
%   See also aassReduce, simulation.

%% Input parsing and validation
% Path
dirPath = getenv('TODOPATH');

if ~ischar(dirPath) || ~exist(dirPath, 'dir')
    error('Invalid directory.');
elseif ~exist(fullfile(dirPath, 'spec.m'), 'file')
    error('spec.m not found.');
end

% Run spec file to set options and q arrays
addpath(dirPath);
spec;
rmpath(dirPath);

dirPath = [dirPath 'data/'];

% Validate spec.m settings.
if ~(iscell(qArray) && iscell(optionsArray))
    error('qArray and optionsArray must be cell arrays.');
end
if ~all(cellfun(@isstruct, optionsArray(:)))
    error('optionsArray elements must be structs.');
end
if ~all(cellfun(@isnumeric, qArray(:)))
    error('qArray elements must be vectors.');
end
if ~isequal(size(qArray), size(optionsArray))
    error('qArray and optionsArray must have the same size');
end

% Melt arrays.
arraySize = size(qArray);
qArray = qArray(:);
optionsArray = optionsArray(:);
nTasks = length(qArray);

% Validate q vectors
nTypes = length(qArray{1});
for ii = 1:nTasks
    if ~isequal(size(qArray{ii}), [nTypes, 1])
        error('qArray must contain nTypesx1 vectors.');
    end
end

% Check that number of types matches the data
if ~exist('./data/submissions-data.csv', 'file') ...
        || ~exist('./data/compatibility-matrix.txt', 'file')
    error('Data not found.');
end

submissionsData = readtable('./data/submissions-data.csv');
if nTypes ~= size(submissionsData, 1)
    error('Number of types in spec must match data files.');
end


% Get environment variables
display('get environment variables');
iWorker = getenv('SGE_TASK_ID');
nWorkers = getenv('SGE_TASK_LAST');
if strcmp(iWorker, '') || strcmp(nWorkers, '')
    error('Could not get environment variables from bash.');
end
iWorker  = str2num(iWorker);
nWorkers = str2num(nWorkers);

% Get optional NITER and MAXT environment variable
nIterations = getenv('NITER');

if ~strcmp(nIterations, '')
    try
        nIterations = eval(nIterations);
    catch
        error('n-iterations-per-run input is invalid.');
    end
    if ~isnumeric(nIterations) || ~isscalar(nIterations)
        error('n-iteration-per-run has to be a scalar.');
    end
    if (nIterations <= 0)
        error('n-iterations-per-run must be positive.');
    end
    if ~isequal(nIterations, round(nIterations))
        error('n-iterations-per-run must be an integer.');
    end
else
    % Use default value
    nIterations = 977;
end

display(nIterations);


maxT = getenv('MAXT');

if ~strcmp(maxT, '')
    try
        maxT = eval(maxT);
    catch
        error('max-t input is invalid.');
    end
    if ~isnumeric(maxT) || ~isscalar(maxT)
        error('max-t has to be a scalar.');
    end
    if (maxT <= 0)
        error('max-t must be positive.');
    end
else
    maxT = Inf;
end

display(maxT);

%% Assign task vectors todo.
display(iWorker);
display('assign jobs');
display(nTasks);
display(iWorker);
if iWorker > nTasks
    display('Worker not needed. Exiting.');
    quit;
end;

if nTasks <= nWorkers
    display('Less tasks than workers.');
    todo = iWorker;
    display('todo set');
    display(todo);
else
    iterationsPerWorker = floor(nTasks/nWorkers);
    remainingIterations = nTasks - nWorkers * iterationsPerWorker;
    todo = ...
        (1 + iterationsPerWorker*(iWorker-1)) : ...
        (iterationsPerWorker*(iWorker));
    if iWorker <= remainingIterations
        todo = [todo, nWorkers * iterationsPerWorker + iWorker];
    end
end

display(todo);

%% Run jobs
% Make sure output is random
rng('shuffle');

% Verbose
echo on;

display('Starting simulation.');

addpath('./classes');
addpath('./functions');

while length(todo) > 0
    for task = todo(randperm(length(todo)))
        display(task);
        fileName = ['data-', num2str(task), '.mat'];
        fileName = fullfile(dirPath, fileName);

        if exist(fileName, 'file')
            display('Simulation file exists. Loading.');
            load(fileName);
            if Simulation.t>0
                error('Simulation is not initialized')
            end
        else
            display('No simulation file. Starting new simulation.');
            Simulation = simulation(qArray{task}, optionsArray{task});
            Simulation = Simulation.initializeMarket(submissionsData); 
            Simulation.burn = 0 ;
        end 

        if Simulation.t >= maxT
            display('Reached maximum t.');
            todo(todo == task) = [];
        else
            display('Iterating');
            Simulation = Simulation.iterate(nIterations,1);
            display('Saving.');    
            save(fileName, 'Simulation');
            display('Simulation days:');
            display(Simulation.t);
        end
    end
end