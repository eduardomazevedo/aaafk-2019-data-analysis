function transplantedRecipient = findTransplanted(F,departedId)

totalOfferNum = length(F.state.offers); 

for i = 1 : totalOfferNum
    departedOrder = ...
        find([F.state.offers(i).participants] == departedId, 1); 
    if ~isempty(departedOrder)
    break    
    end
end

if strcmp('chain',F.state.offers(i).type)
    
lengthOfChain = length(F.state.offers(i).participants); 

    if departedOrder==lengthOfChain
        transplantedRecipient = 0; 
    else
        chain = F.state.offers(i).participants; 
        transplantedRecipient = chain(departedOrder+1); 
    end
    
elseif strcmp('cycle',F.state.offers(i).type)

cycle = F.state.offers(i).participants; 
lengthOfCycle = length(cycle);    

    if departedOrder == lengthOfCycle
        transplantedRecipient = cycle(1); 
    else        
        transplantedRecipient = cycle(departedOrder+1); 
    end
end

end