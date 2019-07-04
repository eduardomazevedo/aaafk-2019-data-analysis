function weights = weightObjective(weightMatrix,cyclesNchains)

weights = [];
%% Cycles
if isfield(cyclesNchains, 'twoCycles')
% Two
ind1 = sub2ind(size(weightMatrix), cyclesNchains.twoCycles(:,1),...
    cyclesNchains.twoCycles(:,2));

ind2 = sub2ind(size(weightMatrix), cyclesNchains.twoCycles(:,2),...
    cyclesNchains.twoCycles(:,1));

weights = [weights ; weightMatrix(ind1) + weightMatrix(ind2)];

end
% Three
if isfield(cyclesNchains, 'threeCycles')
ind1 = sub2ind(size(weightMatrix), cyclesNchains.threeCycles(:,1),...
    cyclesNchains.threeCycles(:,2));

ind2 = sub2ind(size(weightMatrix), cyclesNchains.threeCycles(:,2),...
    cyclesNchains.threeCycles(:,3));

ind3 = sub2ind(size(weightMatrix), cyclesNchains.threeCycles(:,3),...
    cyclesNchains.threeCycles(:,1));

weights = [weights ; weightMatrix(ind1) + weightMatrix(ind2)...
     + weightMatrix(ind3)];
end

%% Chains

if isfield(cyclesNchains, 'twoChains')
    
ind1 = sub2ind(size(weightMatrix), cyclesNchains.twoChains(:,2),...
    cyclesNchains.twoChains(:,1));

weights = [weights ; weightMatrix(ind1)];   
    
end

if isfield(cyclesNchains, 'threeChains')
    
ind1 = sub2ind(size(weightMatrix), cyclesNchains.threeChains(:,2),...
    cyclesNchains.threeChains(:,1));

ind2 = sub2ind(size(weightMatrix), cyclesNchains.threeChains(:,3),...
    cyclesNchains.threeChains(:,2));

weights = [weights ; weightMatrix(ind1) + weightMatrix(ind2)];   
    
end

if isfield(cyclesNchains, 'fourChains')
    
ind1 = sub2ind(size(weightMatrix), cyclesNchains.fourChains(:,2),...
    cyclesNchains.fourChains(:,1));

ind2 = sub2ind(size(weightMatrix), cyclesNchains.fourChains(:,3),...
    cyclesNchains.fourChains(:,2));

ind3 = sub2ind(size(weightMatrix), cyclesNchains.fourChains(:,4),...
    cyclesNchains.fourChains(:,3));

weights = [weights ; weightMatrix(ind1) + weightMatrix(ind2)...
    + weightMatrix(ind3)];   
    
end


if isfield(cyclesNchains, 'fiveChains')
    
ind1 = sub2ind(size(weightMatrix), cyclesNchains.fiveChains(:,2),...
    cyclesNchains.fiveChains(:,1));

ind2 = sub2ind(size(weightMatrix), cyclesNchains.fiveChains(:,3),...
    cyclesNchains.fiveChains(:,2));

ind3 = sub2ind(size(weightMatrix), cyclesNchains.fiveChains(:,4),...
    cyclesNchains.fiveChains(:,3));

ind4 = sub2ind(size(weightMatrix), cyclesNchains.fiveChains(:,5),...
    cyclesNchains.fiveChains(:,4));

weights = [weights ; weightMatrix(ind1) + weightMatrix(ind2)...
    + weightMatrix(ind3) + weightMatrix(ind4)];   
    
end


if isfield(cyclesNchains, 'sixChains')
    
ind1 = sub2ind(size(weightMatrix), cyclesNchains.sixChains(:,2),...
    cyclesNchains.sixChains(:,1));

ind2 = sub2ind(size(weightMatrix), cyclesNchains.sixChains(:,3),...
    cyclesNchains.sixChains(:,2));

ind3 = sub2ind(size(weightMatrix), cyclesNchains.sixChains(:,4),...
    cyclesNchains.sixChains(:,3));

ind4 = sub2ind(size(weightMatrix), cyclesNchains.sixChains(:,5),...
    cyclesNchains.sixChains(:,4));

ind5 = sub2ind(size(weightMatrix), cyclesNchains.sixChains(:,6),...
    cyclesNchains.sixChains(:,5));

weights = [weights ; weightMatrix(ind1) + weightMatrix(ind2)...
    + weightMatrix(ind3) + weightMatrix(ind4) + weightMatrix(ind5)];   
    
end



end