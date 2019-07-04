function muMatrix = mu2Matrix (muVector,cyclesNchains,compatibilityMatrix)

muMatrix = zeros(size(compatibilityMatrix,1));
chosenObjects = find(muVector);
soFarObjects = 0;

%% Cycles

if isfield(cyclesNchains, 'twoCycles')
    
num2Cycles = size(cyclesNchains.twoCycles,1)    ;

twoCycles = chosenObjects(chosenObjects <= num2Cycles);

for i  = 1 : length(twoCycles)
    
    muMatrix(cyclesNchains.twoCycles(twoCycles(i),1), ...
        cyclesNchains.twoCycles(twoCycles(i),2)) = 1;
    
    muMatrix(cyclesNchains.twoCycles(twoCycles(i),2), ...
        cyclesNchains.twoCycles(twoCycles(i),1)) = 1;
    
end

soFarObjects = soFarObjects + num2Cycles;

end

if isfield(cyclesNchains, 'threeCycles')

num3Cycles = size(cyclesNchains.threeCycles,1)  ;

threeCycles = chosenObjects(soFarObjects < chosenObjects &...
    chosenObjects <= (num3Cycles + soFarObjects)) - soFarObjects;

for i  = 1 : length(threeCycles)
    
    muMatrix(cyclesNchains.threeCycles(threeCycles(i),1), ...
        cyclesNchains.threeCycles(threeCycles(i),2)) = 1;
    
    muMatrix(cyclesNchains.threeCycles(threeCycles(i),2), ...
        cyclesNchains.threeCycles(threeCycles(i),3)) = 1;
        
    muMatrix(cyclesNchains.threeCycles(threeCycles(i),3), ...
        cyclesNchains.threeCycles(threeCycles(i),1)) = 1;
    
end

soFarObjects = soFarObjects + num3Cycles;

end
%% Chains

if isfield(cyclesNchains, 'twoChains')
    
    num2Chains = size(cyclesNchains.twoChains,1)    ;

    twoChains = chosenObjects(soFarObjects < chosenObjects &...
        chosenObjects <= (num2Chains + soFarObjects)) - soFarObjects;

    for i  = 1 : length(twoChains)
    
        muMatrix(cyclesNchains.twoChains(twoChains(i),2), ...
            cyclesNchains.twoChains(twoChains(i),1)) = 1;
    
    end

    soFarObjects = soFarObjects + num2Chains;

end


if isfield(cyclesNchains, 'threeChains')
    
    num3Chains = size(cyclesNchains.threeChains,1) ;

    threeChains = chosenObjects(soFarObjects < chosenObjects &...
        chosenObjects <= (num3Chains+ soFarObjects)) - soFarObjects;

    for i  = 1 : length(threeChains)
    
        muMatrix(cyclesNchains.threeChains(threeChains(i),2), ...
            cyclesNchains.threeChains(threeChains(i),1)) = 1;

        muMatrix(cyclesNchains.threeChains(threeChains(i),3), ...
            cyclesNchains.threeChains(threeChains(i),2)) = 1;    
    end

    soFarObjects = soFarObjects + num3Chains;


end

if isfield(cyclesNchains, 'fourChains')
    
    num4Chains = size(cyclesNchains.fourChains,1)  ;

    fourChains = chosenObjects(soFarObjects < chosenObjects &...
        chosenObjects <= (num4Chains+ soFarObjects)) - soFarObjects;

    for i  = 1 : length(fourChains)
    
        muMatrix(cyclesNchains.fourChains(fourChains(i),2), ...
            cyclesNchains.fourChains(fourChains(i),1)) = 1;

        muMatrix(cyclesNchains.fourChains(fourChains(i),3), ...
            cyclesNchains.fourChains(fourChains(i),2)) = 1;   
        
        muMatrix(cyclesNchains.fourChains(fourChains(i),4), ...
            cyclesNchains.fourChains(fourChains(i),3)) = 1;           
    end

    soFarObjects = soFarObjects + num4Chains;

end
if isfield(cyclesNchains, 'fiveChains')
    
    num5Chains = size(cyclesNchains.fiveChains,1)  ;

    fiveChains = chosenObjects(soFarObjects < chosenObjects &...
        chosenObjects <= (num5Chains + soFarObjects)) - soFarObjects;

    for i  = 1 : length(fiveChains)
    
        muMatrix(cyclesNchains.fiveChains(fiveChains(i),2), ...
            cyclesNchains.fiveChains(fiveChains(i),1)) = 1;

        muMatrix(cyclesNchains.fiveChains(fiveChains(i),3), ...
            cyclesNchains.fiveChains(fiveChains(i),2)) = 1;   
        
        muMatrix(cyclesNchains.fiveChains(fiveChains(i),4), ...
            cyclesNchains.fiveChains(fiveChains(i),3)) = 1;    
        
        muMatrix(cyclesNchains.fiveChains(fiveChains(i),5), ...
            cyclesNchains.fiveChains(fiveChains(i),4)) = 1;  
    end

    soFarObjects = soFarObjects + num5Chains;
end
if isfield(cyclesNchains, 'sixChains')
    
    num6Chains = size(cyclesNchains.sixChains,1)   ;

    sixChains = chosenObjects(soFarObjects < chosenObjects &...
        chosenObjects <= (num6Chains + soFarObjects)) - soFarObjects;

    for i  = 1 : length(sixChains)
    
        muMatrix(cyclesNchains.sixChains(sixChains(i),2), ...
            cyclesNchains.sixChains(sixChains(i),1)) = 1;

        muMatrix(cyclesNchains.sixChains(sixChains(i),3), ...
            cyclesNchains.sixChains(sixChains(i),2)) = 1;   
        
        muMatrix(cyclesNchains.sixChains(sixChains(i),4), ...
            cyclesNchains.sixChains(sixChains(i),3)) = 1;    
        
        muMatrix(cyclesNchains.sixChains(sixChains(i),5), ...
            cyclesNchains.sixChains(sixChains(i),4)) = 1;  
                
        muMatrix(cyclesNchains.sixChains(sixChains(i),6), ...
            cyclesNchains.sixChains(sixChains(i),5)) = 1;  
    end

    soFarObjects = soFarObjects + num6Chains;
end

end