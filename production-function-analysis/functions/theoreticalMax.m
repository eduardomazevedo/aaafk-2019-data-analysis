function theMaxAve = theoreticalMax(submissionsData)

numberofEntries = sum(strcmp(submissionsData.category,'a')|...
    strcmp(submissionsData.category,'p'));

%% Step 0: Type vector

submissionsData.r_abo(strcmp(submissionsData.category,'a'))= {'NaN'};
submissionsData.d_abo(strcmp(submissionsData.category,'c'))= {'NaN'};
data = submissionsData(:,{'category', 'r_abo', 'd_abo'});
typeVector = ...
grpstats(data,{'category', 'r_abo', 'd_abo'},'mean');

clear submissionsData data
%% Step 1: Count selfdemanded, compatibility within pair

selfdemanded = ((strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'A'))|...
(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'B'))|...
(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.d_abo,'AB'))|...
(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'O')));

theMax = sum(typeVector.GroupCount(selfdemanded));
typeVector.GroupCount(selfdemanded) = 0;

%% Step 2: Count A-B, B-A. r = |(||A-B|| - ||B-A||)|
ABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'B'));
BApair = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'A'));

if ABpair > BApair
theMax = theMax+2*BApair;  
residual = ABpair - BApair;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'B')) = residual;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'A')) = 0;

elseif BApair > ABpair
    
theMax = theMax+2*ABpair;  
residual = BApair - ABpair;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'A')) = residual;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'B')) = 0;
        
end

%% Step 3: Let residual r comes from A-B. Count O-A underdemanded and B-O
% overdemanded.

ABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'B'));
BApair = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'A'));

if ABpair>0

OApair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'A'));
BOpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'O'));
  
threeCycles = min([residual OApair BOpair]);
theMax = theMax+3*threeCycles;

typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'A')) = OApair - threeCycles;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'O')) = BOpair - threeCycles;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'B')) = ABpair - threeCycles;
elseif BApair > 0

OBpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'B'));
AOpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'O'));
  
threeCycles = min([residual OBpair AOpair]);
theMax = theMax + 3*threeCycles;

typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'B')) = OBpair - threeCycles;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'O')) = AOpair - threeCycles;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'A')) = BApair - threeCycles;
    
end

%% Step 4: Count X-Y overdemanded and Y-X underdemanded

AOpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'O'));
BOpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'O'));
ABOpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.d_abo,'O'));
ABBpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.d_abo,'B'));
ABApair = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.d_abo,'A'));

OApair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'A'));
OBpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'B'));
OABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'AB'));
BABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'AB'));
AABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'AB'));

twoCycleAOOA = min([AOpair OApair]);
twoCycleBOOB = min([BOpair OBpair]);
twoCycleABOOBA = min([ABOpair OABpair]);
twoCycleABBBBA = min([ABBpair BABpair]);
twoCycleABAABA = min([ABApair AABpair]);

theMax = theMax + 2*(twoCycleAOOA + twoCycleBOOB + twoCycleABOOBA + twoCycleABBBBA + twoCycleABAABA);

typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'O')) = AOpair - twoCycleAOOA ;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'O')) = BOpair - twoCycleBOOB;
typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.d_abo,'O')) = ABOpair - twoCycleABOOBA;
typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.d_abo,'B')) = ABBpair - twoCycleABBBBA;
typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.d_abo,'A')) = ABApair - twoCycleABAABA;

typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'A')) = OApair - twoCycleAOOA ;
typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'B')) = OBpair - twoCycleBOOB;
typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'AB')) = OABpair - twoCycleABOOBA;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'AB')) = BABpair - twoCycleABBBBA;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'AB')) = AABpair - twoCycleABAABA;

%% Step 5: O blood type altruistics, O - O-X(underdemanded) -
% X-AB(underdemanded) - AB chip

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));
OApair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'A'));
AABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'AB'));


threeChain1 = min([Oaltruist OApair AABpair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - threeChain1;
typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'A')) = OApair - threeChain1;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'AB')) = AABpair - threeChain1;

theMax = theMax + 2*threeChain1;

ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

threeChainChip1 = min(threeChain1,ABchip);

typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - threeChainChip1;

theMax = theMax + threeChainChip1;

% 

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));
OBpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'B'));
BABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'AB'));


threeChain2 = min([Oaltruist OBpair BABpair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - threeChain2;
typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'B')) = OBpair - threeChain2;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'AB')) = BABpair - threeChain2;

theMax = theMax + 2*threeChain2;

ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

threeChainChip2 = min(threeChain2,ABchip);

typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - threeChainChip2;

theMax = theMax + threeChainChip2;




%% Step 6: X blood type altruistics, X-AB(underdemanded) - AB chip

% O altruistic
Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));

OApair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'A'));
Achip = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.category,'c'));

twoOChain1 = min([Oaltruist OApair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChain1;
typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'A')) = OApair - twoOChain1;

theMax = theMax + twoOChain1;

twoOChainChip1 = min([twoOChain1 Achip]);

typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.category,'c')) = Achip - twoOChainChip1;

theMax = theMax + twoOChainChip1;

%
Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));

OBpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'B'));
Bchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.category,'c'));

twoOChain2 = min([Oaltruist OBpair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChain2;
typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'B')) = OBpair - twoOChain2;

theMax = theMax + twoOChain2;

twoOChainChip2 = min([twoOChain2 Bchip]);

typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.category,'c')) = Bchip - twoOChainChip2;

theMax = theMax + twoOChainChip2;

%

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));

OABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'AB'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoOChain3 = min([Oaltruist OABpair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChain3;
typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.d_abo,'AB')) = OABpair - twoOChain3;

theMax = theMax + twoOChain3;

twoOChainChip3 = min([twoOChain3 ABchip]);

typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoOChainChip3;

theMax = theMax + twoOChainChip3;

% 

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));

AABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'AB'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoOChain4 = min([Oaltruist AABpair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChain4;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'AB')) = AABpair - twoOChain4;

theMax = theMax + twoOChain4;

twoOChainChip4 = min([twoOChain4 ABchip]);

typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoOChainChip4;

theMax = theMax + twoOChainChip4;

% 

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));

BABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'AB'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoOChain5 = min([Oaltruist BABpair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChain5;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'AB')) = BABpair - twoOChain5;

theMax = theMax + twoOChain5;

twoOChainChip5 = min([twoOChain5 ABchip]);

typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoOChainChip5;

theMax = theMax + twoOChainChip5;

% A altruistic

Aaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'A')&strcmp(typeVector.category,'a'));

AABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'AB'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoAChain = min([Aaltruist AABpair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'A')&strcmp(typeVector.category,'a')) = Aaltruist - twoAChain;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.d_abo,'AB')) = AABpair - twoAChain;

theMax = theMax + twoAChain;

twoAChainChip = min([twoAChain ABchip]);

typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoAChainChip;

theMax = theMax + twoAChainChip;

% B altruistic

Baltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'B')&strcmp(typeVector.category,'a'));

BABpair = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'AB'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoBChain = min([Baltruist BABpair]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'B')&strcmp(typeVector.category,'a')) = Baltruist - twoBChain;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.d_abo,'AB')) = BABpair - twoBChain;

theMax = theMax + twoBChain;

twoBChainChip = min([twoBChain ABchip]);

typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoBChainChip;

theMax = theMax + twoBChainChip;

%% Step 7  X blood type altruistics, X bloodtype chips

% A altruistic

Aaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'A')&strcmp(typeVector.category,'a'));
Achip = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.category,'c'));

twoAChip1 = min([Aaltruist Achip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'A')&strcmp(typeVector.category,'a')) = Aaltruist - twoAChip1;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.category,'c')) = Achip - twoAChip1;

theMax = theMax + twoAChip1;

Aaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'A')&strcmp(typeVector.category,'a'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoAChip2 = min([Aaltruist ABchip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'A')&strcmp(typeVector.category,'a')) = Aaltruist - twoAChip2;
typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoAChip2;

theMax = theMax + twoAChip2;


% B altruistic

Baltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'B')&strcmp(typeVector.category,'a'));
Bchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.category,'c'));

twoBChip1 = min([Baltruist Bchip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'B')&strcmp(typeVector.category,'a')) = Baltruist - twoBChip1;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.category,'c')) = Bchip - twoBChip1;

theMax = theMax + twoBChip1;

Baltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'B')&strcmp(typeVector.category,'a'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoBChip2 = min([Baltruist ABchip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'A')&strcmp(typeVector.category,'a')) = Baltruist - twoBChip2;
typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoBChip2;

theMax = theMax + twoBChip2;


% O altruistic

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));
Ochip = typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.category,'c'));

twoOChip1 = min([Oaltruist Ochip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChip1;
typeVector.GroupCount(strcmp(typeVector.r_abo,'O')&strcmp(typeVector.category,'c')) = Ochip - twoOChip1;

theMax = theMax + twoOChip1;

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));
Achip = typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.category,'c'));

twoOChip2 = min([Oaltruist Achip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChip2;
typeVector.GroupCount(strcmp(typeVector.r_abo,'A')&strcmp(typeVector.category,'c')) = Achip - twoOChip2;

theMax = theMax + twoOChip2;

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));
Bchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.category,'c'));

twoOChip3 = min([Oaltruist Bchip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChip3;
typeVector.GroupCount(strcmp(typeVector.r_abo,'B')&strcmp(typeVector.category,'c')) = Bchip - twoOChip3;

theMax = theMax + twoOChip3;

Oaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoOChip4 = min([Oaltruist ABchip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'O')&strcmp(typeVector.category,'a')) = Oaltruist - twoOChip4;
typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoOChip4;

theMax = theMax + twoOChip4;

% AB altruistic

ABaltruist = typeVector.GroupCount(strcmp(typeVector.d_abo,'AB')&strcmp(typeVector.category,'a'));
ABchip = typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c'));

twoABChip = min([ABaltruist ABchip]);

typeVector.GroupCount(strcmp(typeVector.d_abo,'AB')&strcmp(typeVector.category,'a')) = ABaltruist - twoABChip;
typeVector.GroupCount(strcmp(typeVector.r_abo,'AB')&strcmp(typeVector.category,'c')) = ABchip - twoABChip;

theMax = theMax + twoABChip;


theMaxAve = theMax / numberofEntries;
end