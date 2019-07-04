function [m, se] = aassReduce(S)
%aassReduce Calculates mean and standard error given array of simulations
%   [m se] = aassReduce(S) Given a cell array of simulations S with the same
%   parameters returns numeric aggregated mean and standard error. Some
%   cells of S may be empty.

if ~iscell(S)
    error('S msut be a cell array of simulations.');
end;

addpath('classes', 'functions');

n = length(S(:));

m = zeros(n, 1);
v = zeros(n, 1);
t = zeros(n, 1);

for ii = 1 : length(S)
    if ~isempty(S{ii})
        if ~isa(S{ii}, 'simulation')
            error('The cell array S can only contain empty entries or simulations');
        else
            m(ii) = S{ii}.f_mean;
            v(ii) = S{ii}.f_se ^ 2;
            t(ii) = max(0, S{ii}.t - S{ii}.burn);
        end
    end
end

if sum(t==0)>0
    m(t==0) = [];
    v(t==0) = [];
    t(t==0) = [];
end

if sum(t) == 0
    m = NaN;
    se = NaN;
    return;
else
    shares = t ./ sum(t);
    m = dot(shares, m);
    v = dot(shares.^2, v);
    se = sqrt(v);
end
end

