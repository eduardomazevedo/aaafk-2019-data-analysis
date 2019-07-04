function [f_mean, f_se, iteration] = aassGetMean(dirPath, burn)
%aassGetMean Loads arrays of production (f), standard errors (se), and
%number of iterations (n), produced by the Advanced Asynchronous
%Simulation System (c).
%   aassGetMean(dirPath,burn) returns vector of production (f), standard 
%   errors (se), and number of iterations (n) that are saved in the
%   directory given by the string dirPath.
%   dirPath must include a valid spec.m file and data files saved by the
%   AASS. Burn input sets the number of initial periods to burn. If no burn
%   is set, burn = 2000.
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

% Check burning period input, if there is no input, set burn=2000
if nargin<2
   burn = 2000; 
end

%% Open data files
addpath('./classes');
f_mean = nan(nTasks, 1);
f_se = nan(nTasks, 1);
iteration = nan(nTasks, 1);
for task = 1 : nTasks
    fileName = ['data-', num2str(task), '.mat'];
    fileName = fullfile(dirPath, fileName);
    if exist(fileName, 'file')
        load(fileName);
        Simulation.burn = burn;
        f_mean(task) = Simulation.f_mean; 
        f_se(task) = Simulation.f_se; 
        iteration(task) = Simulation.t; 
    end
end

end

