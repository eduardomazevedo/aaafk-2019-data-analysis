function [overallTransPer,overallChains] = chainlength(directory)

SS = aassGet(directory);

            numberOfSim = size(SS,2);
            numberOfRep = size(SS,1);

            for j = 1 : numberOfSim
                
                allChains= [];
                
                for i = 1 : numberOfRep
                    if numberOfRep == 1
                        if numberOfSim == 1
                            table = table2array(SS.history.submissionsTable);
                        else
                            table = table2array(SS{i,j}.history.submissionsTable);
                        end
                    else
                        table = table2array(SS{i,j}.history.submissionsTable);
                    end
                    
                    transplantations = [table(table(:,8)>0,[1,8]) ones(sum(table(:,8)>0),1)] ;
                    mu = sparse(transplantations(:,1),transplantations(:,2),transplantations(:,3));
                    
                        if size(mu,1)>size(mu,2)
                            mu(size(mu,1),size(mu,1)) = 0;
                        else
                            mu(size(mu,2),size(mu,2)) = 0;
                        end
                        
                    threeCycles = size(findCycles(full(mu),3),1);
                    twoCycles = size(findCycles(full(mu),2),1) - size(findCycles(full(mu),3),1);
                    chains = cellfun('length',findChains(mu));
                    totalTrans = 3*threeCycles +2*twoCycles+ sum(chains);
                    percentTrans(i,:) = [2*twoCycles/totalTrans 3*threeCycles/totalTrans  sum(chains)/totalTrans mean(chains)];
                    allChains = [ allChains ;chains];
                    
                end
                
                overallTransPer{j} = percentTrans;
                overallChains{j} = allChains;
                
            end
             
directory = [directory 'output/' ];
fileName = ['chain_lengths.mat'];
fileName = fullfile(directory, fileName);
save(fileName,'overallTransPer','overallChains');


end  