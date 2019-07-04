function [cycles] = findCycles(mu, k)
%findCycles Finds large cycles
%   cycles = findCycles(mu, k) returns all cycles of length greater or
%   equal to k in adjacency matrix mu. Return is a cell of arrays representing the cycles.
%   mu is required to be a matching
%   matrix. Each node can have indegree and outdegree at most 1.

% Validate that mu is a matching matrix
    if ~isMatch(mu)
        error('findCycles.m received a non-matching matrix as an input.');
    end

% Flag for nodes that haven't been reached yet
    n = size(mu, 1);
    remaining = ones(n, 1);
    
% Initialize output
    cycles = {};

while(true)
    % Head is the first remaining node
        head = find(remaining, 1);
    % If no heads are left return
        if isempty(head)
            return;
        end;

    % Initialize a cycle
        cycle = [];
        node = head;
        flag = 1;
    
    % Loop over nodes adding to cycle
        while(flag)
            cycle = [cycle, node];
            remaining(node) = 0;
            [flag, node] = max(mu(node, :));
            if flag
                flag = remaining(node);
            end;
        end;
    
    % Test if it is a cycle and save if so.
        if node == head ...
                && mu(cycle(end), head) ...
                && length(cycle) >= k
            cycles = [cycles; {cycle}];
        end;
end

end

