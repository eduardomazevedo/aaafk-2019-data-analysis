function [SimulationArray, qArray, optionsArray] = aassGet(dirPath)
%aassGet Loads arrays of simulations produced by the Advanced Asynchronous
%Simulation System (c).
%   aassGet(dirPath) returns an array of simulations that are saved in the
%   directory given by the string dirPath.
%   dirPath must include a valid spec.m file and data files saved by the
%   AASS.
%
%   See also aass, aassReduce, simulation.

%% Input parsing and validation
% Input validation
if ~ischar(dirPath) || ~exist(dirPath, 'dir')
    error('Invalid directory.');
elseif ~exist(fullfile(dirPath, 'spec.m'), 'file')
    error('spec.m not found.');
end

% Run spec file to set options and q arrays
addpath(dirPath);
spec;
rmpath(dirPath);

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
nTasks = size(qArray,1)*size(qArray,2);

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

% submissionsData = readtable('./data/submissions-data.csv', 'Delimiter', ',');
% if nTypes ~= size(submissionsData, 1)
%     error('Number of types in spec must match data files.');
% end
% clear submissionsData;

%% Open data files
addpath('./classes');
SimulationArray = cell(nTasks, 1);

dirPath = [dirPath 'data/'];

for task = 1 : nTasks
    fileName = ['data-', num2str(task), '.mat'];
    fileName = fullfile(dirPath, fileName);
    if exist(fileName, 'file')
        load(fileName);
        SimulationArray{task} = Simulation;
    end
end

%% Reshape
qArray = reshape(qArray, arraySize);
optionsArray = reshape(optionsArray, arraySize);
SimulationArray = reshape(SimulationArray, arraySize);


end

