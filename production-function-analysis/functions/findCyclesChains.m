%This function finds max number of transplantation via chains, cycles given
% compatability matrix, PMP weights and altrustic donor orders
function [cyclesNchains]=...
    findCyclesChains(CompMat,ChainSource,chainLength)
cyclesNchains = [];
if islogical(ChainSource)
ChainSource = find(ChainSource);
end
CompMat = CompMat - diag(diag(CompMat));

%% Two length cycles
CompMat2=CompMat;
CompMat2(ChainSource,:)=0; %Clear out all Altrustic Donor links
CompMat2(:,ChainSource)=0;
CompMat2(find(1-logical(CompMat2==CompMat2')))=0;
%For allowing just 2 ways exchange, create an undirected graph
[b, a]=find(triu(CompMat2)); % a Xij edge's j coordinate, b Xij edge's i coordinate
twoCycles=[a b]; %Two length cycles in variable order
%a1=a+[0:npairs:npairs*(TwoCycle-1)]';
%b1=b+[0:npairs:npairs*(TwoCycle-1)]';
%twocons=zeros(npairs,TwoCycle); %Constraint for Two length cycles
%twocons([a1 ;b1])=1;  
clear  CompMat2;

%% Three length cycles
CompMat3=CompMat;

for m=1:5 %This step clears out the pairs who cannot give or cannot get a kidney, makes algorithm a bit faster.
  NoGet=find(sum(CompMat3')==0); % The ones who cannot get
  NoGive=find(sum(CompMat3)==0); % The ones who cannot give (If there is altrustic donor then this is an empty set)
  CompMat3(NoGet,:)=0;
  CompMat3(:,NoGet)=0;
  CompMat3(:,NoGive)=0;
  CompMat3(NoGive,:)=0;
end

[Xcor,Ycor]=find(triu(CompMat3>0)); % Find edges on upper triangle of comptability matrix
Z=CompMat3(Ycor,:).*CompMat3(:,Xcor)'; 
% Finds any node that has outgoing edge to Xcor and ingoing edge to Ycor
[Zedge, Znode]=find(Z); 
numThreecycle=length(Znode);
threeCycles=[reshape(Xcor(Zedge),[numThreecycle,1]) reshape(Ycor(Zedge),[numThreecycle,1]) reshape(Znode,[numThreecycle,1])];

clear  CompMat3;

CompMat = CompMat';
%% Chains
%% Two Chains
[firstPairs,source]=find(CompMat(:,ChainSource)); % Find links from Altrus to Pairs

twoChains=[reshape(ChainSource(source),length(source),1) reshape(firstPairs,length(firstPairs),1)];

cyclesNchains.twoCycles      = twoCycles;
cyclesNchains.threeCycles    = threeCycles;

%% Three length chains
if size(twoChains,1) > 0
threeChains = nextChains(twoChains,CompMat);

%% Four length chains
if size(threeChains,1) > 0
fourChains = nextChains(threeChains,CompMat);



cyclesNchains.twoChains      = twoChains;
cyclesNchains.threeChains    = threeChains;
cyclesNchains.fourChains     = fourChains;
     
%% Five length chains

if nargin>2 && chainLength > 4
    if size(fourChains,1) > 0
    fiveChains = nextChains(fourChains,CompMat);
    cyclesNchains.fiveChains     = fiveChains;
        if nargin>2 && chainLength > 5
            if size(fiveChains,1) > 0
            sixChains = nextChains(fiveChains,CompMat);
            cyclesNchains.sixChains     = sixChains;
                if nargin>2 && chainLength > 6 
                    if size(sixChains,1) > 0
                        sevenChains = nextChains(sixChains,CompMat);
                        cyclesNchains.sevenChains     = sevenChains;
                    end
                end
            end
        end
    end
end
end
end


end


