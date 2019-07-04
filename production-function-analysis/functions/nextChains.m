    
function newChains = nextChains(exChains,CompMat)

exChainLength = size(exChains,2);

newChains = [];

exChains = sortrows(exChains,exChainLength);

lastPairs =unique(exChains(:,exChainLength)); % Number of 3rd node on 3 length cycles


for i = 1 : length(lastPairs)
    
    firstPart = exChains(exChains(:,exChainLength)==lastPairs(i),1 : exChainLength); 
    
    newPair = find(CompMat(:,lastPairs(i)));
    
    newChainsPart = ...
        [repelem(firstPart,length(newPair),1) ...
        repmat(newPair,size(firstPart,1),1)];
              
    A = sum(bsxfun(@eq,...
        repelem(firstPart,length(newPair),1),repmat(newPair,size(firstPart,1),1)),2);
    
    newChainsPart(A>0,:) = [];
    
    newChains = [newChains ; newChainsPart ];
    
end

end
