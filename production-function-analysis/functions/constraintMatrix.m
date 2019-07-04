function    [newIndices, lastIndice] = constraintMatrix(constraintVector,numSubmissions,indiceStart)

    numVariable = size(constraintVector,1);  
    newIndices = constraintVector + ...
        repmat((indiceStart:numSubmissions:(numVariable-1)*numSubmissions+indiceStart)',1,...
        size(constraintVector,2));
    newIndices = newIndices(:);
    lastIndice = indiceStart + numSubmissions * numVariable;
    
end