function chains = findChains(mu)
%findChains Finds chains in a directed adjacency matrix.
%   chains = findChains(mu) returns a cell with array elements representing
%   each chain in adjacency matrix mu.
%
%   mu must be a matching matrix. Each node can have indegree and
%   outdegree at most 1.

% Validate that mu is a matching matrix
if ~isMatch(mu)
    display('findChains.m received an invalid match:');
    display(sparse(mu));
    error('findChains.m received a non-matching matrix as an input.');
end

sources = find(sum(mu, 2)' > sum(mu, 1));

if isempty(sources) == 1
    chains = {};
    return; 
end

numberOfChains = length(sources);
chains = cell(numberOfChains, 1);

for c = 1 : numberOfChains
    flag = 1;
    chain = sources(c);
    while flag
        newPair = find(mu(chain(end), :));
        if isempty(newPair)
            flag = 0;
        else
            chain = [chain, newPair];
        end
    end
    chains{c} = chain;
end

end