function [flag] = isMatch(mu)
%isMatch Checks if input is a matching matrix
%   isMatch(mu) returns true if the input is a matching matrix and false
%   otherwise.
%
%   The tests are:
%       - Is mu a numeric square matrix?
%       - Does mu have all 0s and 1s?
%       - Do all the rows and columns sum to at most 1?
%       - Is the diagonal empty?


flag = false;

if ~ismatrix(mu)
    return;
elseif ~isnumeric(mu)
    return;
elseif size(mu, 1) ~= size(mu, 2)
    return;
elseif ~isequal((mu == 0) + (mu == 1), ones(size(mu)))
    return;
elseif any(sum(mu, 1) > 1) || any(sum(mu, 2) > 1)
    return;
elseif trace(mu) > 0
    return;
end

flag = true;

end

