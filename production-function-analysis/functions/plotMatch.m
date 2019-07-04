function T = plotMatch(mu,status,compatilibilityMatrix)
            % PLOTLASTMATCH outputs the graph of last nontrivial offered set
            % of transplantations. It takes Simulation as and uses 
            % Simulation.history.lastMatch an input. Highlights offered 
            % cycles by red and offered chains by green. It also highlights
            % source nodes, 'a'ltruistic and 'b'ridges. 
        
        % Nodes that can start up a chain.
        sources = find(strcmp(status,'a') + strcmp(status,'b'));

        

        % Find cycles in the offered transplantation set. 
        cycles = findCycles(mu,1);
        cycleNodes = [cycles{:}];
        cycleMu = zeros(size(mu,2));
        cycleMu(cycleNodes,cycleNodes) = ...
             mu(cycleNodes,cycleNodes);
        % Find chains in the offered transplantation set, by 
        % simply substracting cycles from the whole set.  
        chainMu = mu - cycleMu;
        lastMatchCycleGraph = digraph(cycleMu);
        lastMatchChainGraph = digraph(chainMu);
        if nargin==2
       
        % Take digraph object of each matrices. 
        lastMatchGraph = digraph(mu);
        T = plot(lastMatchGraph);
                % Create a newCompatilibilityMatrix just includes offered
        % transplantations, first link between source nodes and the
        % others and the whole Compatilibility Matrix between offered
        % nodes. 
        elseif nargin>2
            
        newCompatilibilityMatrix = mu;
        [gives , recieves] = find(mu);
        transplanted = unique([gives;recieves]);
        newCompatilibilityMatrix(sources,:) = compatilibilityMatrix(sources,:);
        newCompatilibilityMatrix(transplanted,transplanted) = ...
            compatilibilityMatrix(transplanted,transplanted);
        lastNewCompatilibilityMatrix = ...
             digraph(newCompatilibilityMatrix);
        T = plot(lastNewCompatilibilityMatrix);
        end
        % Plot last offered set of transplantations. 

        labelnode(T,1:size(mu,1),'')
        % Highlight last offered set of Cycles to Red. 
        highlight(T,lastMatchCycleGraph,'EdgeColor','r','LineWidth',2,'MarkerSize',6)    
        % Highlight last offered set of Chains to Green. 
        highlight(T,lastMatchChainGraph,'EdgeColor','g','LineWidth',2,'MarkerSize',6)
        % Highlight last source nodes to Magenta. 
        highlight(T,sources,'NodeColor','magenta','MarkerSize',8)
 end