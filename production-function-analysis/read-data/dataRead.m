%This script runs a sets of scripts that reads data-*.mat files, the
%results of the simulations. Those scripts create .csv and .eps outputs 
%that contains relevant summary stats. These outputs later are used to
%create constants and plots for the manuscript. 


addpath('./read-data/');

%% Main exercises/ NKR

addpath('analysis/scale/output/');
run plot_scale.m
rmpath('analysis/scale/output/');

addpath('analysis/scale_small/output/');
run plot_scale.m
rmpath('analysis/scale_small/output/');

addpath('analysis/matching-probability/output/');
run matchingProbability.m
rmpath('analysis/matching-probability/output/');

addpath('analysis/gradient/output/');
run gradient.m
rmpath('analysis/gradient/output/');

addpath('functions/');
figuresFromCalibration('./analysis/calibration/first-exercise/');
figuresFromCalibration('./analysis/calibration/second-exercise/');
rmpath('functions/');

%% Different compositions

% 1st Quartile participation

addpath('analysis/different-compositions/25th-participation/scale/output/');
run plot_scale.m
rmpath('analysis/different-compositions/25th-participation/scale/output/');

addpath('analysis/different-compositions/25th-participation/scale_small/output/');
run plot_scale.m
rmpath('analysis/different-compositions/25th-participation/scale_small/output/');

addpath('analysis/different-compositions/25th-participation/matching-probability/output/');
run matchingProbability.m
rmpath('analysis/different-compositions/25th-participation/matching-probability/output/');

addpath('analysis/different-compositions/25th-participation/gradient/output/');
run gradient.m
rmpath('analysis/different-compositions/25th-participation/gradient/output/');


% Last Quartile participation 

addpath('analysis/different-compositions/75th-participation/scale/output/');
run plot_scale.m
rmpath('analysis/different-compositions/75th-participation/scale/output/');

addpath('analysis/different-compositions/75th-participation/scale_small/output/');
run plot_scale.m
rmpath('analysis/different-compositions/75th-participation/scale_small/output/');

addpath('analysis/different-compositions/75th-participation/matching-probability/output/');
run matchingProbability.m
rmpath('analysis/different-compositions/75th-participation/matching-probability/output/');

addpath('analysis/different-compositions/75th-participation/gradient/output/');
run gradient.m
rmpath('analysis/different-compositions/75th-participation/gradient/output/');


%% Robustness 

% Lower waittime

addpath('analysis/robustness/lower-waittime/scale/output/');
run plot_scale.m
rmpath('analysis/robustness/lower-waittime/scale/output/');

addpath('analysis/robustness/lower-waittime/scale_small/output/');
run plot_scale.m
rmpath('analysis/robustness/lower-waittime/scale_small/output/');

addpath('analysis/robustness/lower-waittime/matching-probability/output/');
run matchingProbability.m
rmpath('analysis/robustness/lower-waittime/matching-probability/output/');

addpath('analysis/robustness/lower-waittime/gradient/output/');
run gradient.m
rmpath('analysis/robustness/lower-waittime/gradient/output/');

% Higher waittime

addpath('analysis/robustness/higher-waittime/scale/output/');
run plot_scale.m
rmpath('analysis/robustness/higher-waittime/scale/output/');

addpath('analysis/robustness/higher-waittime/scale_small/output/');
run plot_scale.m
rmpath('analysis/robustness/higher-waittime/scale_small/output/');

addpath('analysis/robustness/higher-waittime/matching-probability/output/');
run matchingProbability.m
rmpath('analysis/robustness/higher-waittime/matching-probability/output/');

addpath('analysis/robustness/higher-waittime/gradient/output/');
run gradient.m
rmpath('analysis/robustness/higher-waittime/gradient/output/');

% Uniform weights

addpath('analysis/robustness/normal-weights/scale/output/');
run plot_scale.m
rmpath('analysis/robustness/normal-weights/scale/output/');

addpath('analysis/robustness/normal-weights/scale_small/output/');
run plot_scale.m
rmpath('analysis/robustness/normal-weights/scale_small/output/');

addpath('analysis/robustness/normal-weights/matching-probability/output/');
run matchingProbability.m
rmpath('analysis/robustness/normal-weights/matching-probability/output/');

addpath('analysis/robustness/normal-weights/gradient/output/');
run gradient.m
rmpath('analysis/robustness/normal-weights/gradient/output/');




