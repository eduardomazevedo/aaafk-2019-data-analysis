function [hospitalPayoff]...
    = hospitalSub(submission2NKR,rewards,...
    internalizePar,groupEntries,sizeofHospital,numberOfIteration)
    
    groupEntries = ...
        groupEntries .* repmat( 1-submission2NKR, ...
        1,length(groupEntries))';
    
    Simulation = simulation(sum(groupEntries,2) * sizeofHospital);
    
    if nargin<3
        
        while isnan(Simulation.f_se / sum(Simulation.q))
            
            Simulation = Simulation.iterate(Simulation.burn+1);   
                    
        end
        
        while Simulation.f_se / sum(Simulation.q) < 0.005
            
            Simulation = Simulation.iterate(Simulation.burn);      
        
        end
        
    else
        
        while isnan(Simulation.f_se / sum(Simulation.q))
            
            Simulation = Simulation.iterate(Simulation.burn+1);   
                    
        end
        
        while Simulation.f_se / sum(Simulation.q) < 0.005
            
            Simulation = Simulation.iterate(numberOfIteration);      
        
        end
    end
    
    hospitalProd = Simulation.f_mean;
    
    hospitalPayoff = -( hospitalProd + internalizePar * ...
        submission2NKR' * rewards);
    Simulation.t
    submission2NKR

end