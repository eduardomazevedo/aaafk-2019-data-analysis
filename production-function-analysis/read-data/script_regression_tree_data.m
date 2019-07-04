clear all

% Load data

submissionsData = readtable('./data/submissions-data.csv');

gradientData = readtable( './analysis/gradient/output/gradient.csv');

%gradientData(strcmp(submissionsData.category(gradientData.index),'c'),:) = [];
%submissionsData = submissionsData(gradientData.index,:);
% Demand Types

overdemanded = ...
    ((strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'O')));

underdemanded = ...
    ((strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'AB')));

normaldemanded = ...
    ((strcmp(submissionsData.r_abo,'AB')& strcmp(submissionsData.d_abo,'AB'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'A'))|...
    (strcmp(submissionsData.r_abo,'O')& strcmp(submissionsData.d_abo,'O'))|...
    (strcmp(submissionsData.r_abo,'A')& strcmp(submissionsData.d_abo,'B'))|...
    (strcmp(submissionsData.r_abo,'B')& strcmp(submissionsData.d_abo,'A')));

altruistic = strcmp(submissionsData.category,'a');
demand = cell(size(submissionsData,1),1);
demand(overdemanded) = {'over'};
demand(underdemanded) = {'under'};
demand(normaldemanded) = {'normal'};
demand(altruistic) = {'altruistic'};

submissionsData.demand_type = demand;


% Category

gradientData.category = submissionsData.category(gradientData.index);


% Demand Type

gradientData.demand_type = submissionsData.demand_type(gradientData.index);


% Recipient Bloodtype

gradientData.r_abo = submissionsData.r_abo(gradientData.index);


% Donor Bloodtype

gradientData.d_abo = submissionsData.d_abo(gradientData.index);


% Age

gradientData.d_age = submissionsData.d_age(gradientData.index);
gradientData.r_age = submissionsData.r_age(gradientData.index);


% Weight

gradientData.d_weight = submissionsData.d_weight(gradientData.index);
gradientData.r_weight = submissionsData.r_weight(gradientData.index);


% Match Power

gradientData.dmp = submissionsData.d_mp_strict_noabo(gradientData.index);
gradientData.rmp = submissionsData.r_mp_strict_noabo(gradientData.index);


% PRA

gradientData.r_cpra = submissionsData.r_cpra(gradientData.index);

writetable(gradientData, './output/regressionTree.csv');
