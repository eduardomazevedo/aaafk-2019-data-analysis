function  constraints = cycleChainConstraints(compatibilityMatrix,cyclesNchains)
numSubmissions = size(compatibilityMatrix,1);
indices = [];
indiceStart = 0;
%% Cycles  
if isfield(cyclesNchains, 'twoCycles')
    [newIndices, lastIndice] = constraintMatrix(...
        cyclesNchains.twoCycles,numSubmissions,indiceStart);
    
    indices = [indices ; newIndices ];
    indiceStart = lastIndice;
    
end

if isfield(cyclesNchains, 'threeCycles')
    
    [newIndices, lastIndice] = constraintMatrix(...
        cyclesNchains.threeCycles,numSubmissions,indiceStart);
    
    indices = [indices ; newIndices ];
    indiceStart = lastIndice;
end
    

if isfield(cyclesNchains, 'twoChains')
    [newIndices, lastIndice]  = constraintMatrix(...
        cyclesNchains.twoChains,numSubmissions,indiceStart); 
    indices = [indices ; newIndices ];
    indiceStart =  lastIndice;
end
if isfield(cyclesNchains, 'threeChains')
    [newIndices, lastIndice]  = constraintMatrix(...
        cyclesNchains.threeChains,numSubmissions,indiceStart); 
    indices = [indices ; newIndices ];
    indiceStart = lastIndice;
end
if isfield(cyclesNchains, 'fourChains')
    [newIndices, lastIndice]  = constraintMatrix(...
        cyclesNchains.fourChains,numSubmissions,indiceStart); 
    indices = [indices ; newIndices ];
    indiceStart = lastIndice;
end
if isfield(cyclesNchains, 'fiveChains')
    [newIndices, lastIndice]  = constraintMatrix(...
        cyclesNchains.fiveChains,numSubmissions,indiceStart); 
    indices = [indices ; newIndices ];
    indiceStart = lastIndice;    
end
if isfield(cyclesNchains, 'sixChains')
    [newIndices, lastIndice]  = constraintMatrix(...
        cyclesNchains.sixChains,numSubmissions,indiceStart); 
    indices = [indices ; newIndices ];
    indiceStart = lastIndice;
end

constraints = zeros(numSubmissions,indiceStart/numSubmissions);
constraints(indices) = 1 ;

end