%This script creates sets of plots for the manuscript. It uses data
%folder and output folder of various analyses then creates .eps files
%within the ./output-for-manuscript folder. 

addpath('./generate-output/');


%% Main exercises/ NKR

addpath('analysis/scale/output/');
run scale_plot_generate.m
rmpath('analysis/scale/output/');

addpath('analysis/scale_small/output/');
run scale_plot_generate.m
rmpath('analysis/scale_small/output/');

%% Different compositions

% 1st Quartile participation

addpath('analysis/different-compositions/25th-participation/scale/output/');
run scale_plot_generate.m
rmpath('analysis/different-compositions/25th-participation/scale/output/');

addpath('analysis/different-compositions/25th-participation/scale_small/output/');
run scale_plot_generate.m
rmpath('analysis/different-compositions/25th-participation/scale_small/output/');

% Last Quartile participation 

addpath('analysis/different-compositions/75th-participation/scale/output/');
run scale_plot_generate.m
rmpath('analysis/different-compositions/75th-participation/scale/output/');

addpath('analysis/different-compositions/75th-participation/scale_small/output/');
run scale_plot_generate.m
rmpath('analysis/different-compositions/75th-participation/scale_small/output/');

%% Robustness 

% Lower waittime

addpath('analysis/robustness/lower-waittime/scale/output/');
run scale_plot_generate.m
rmpath('analysis/robustness/lower-waittime/scale/output/');

addpath('analysis/robustness/lower-waittime/scale_small/output/');
run scale_plot_generate.m
rmpath('analysis/robustness/lower-waittime/scale_small/output/');

% Higher waittime

addpath('analysis/robustness/higher-waittime/scale/output/');
run scale_plot_generate.m
rmpath('analysis/robustness/higher-waittime/scale/output/');

addpath('analysis/robustness/higher-waittime/scale_small/output/');
run scale_plot_generate.m
rmpath('analysis/robustness/higher-waittime/scale_small/output/');

% Uniform weights

addpath('analysis/robustness/normal-weights/scale/output/');
run scale_plot_generate.m
rmpath('analysis/robustness/normal-weights/scale/output/');

addpath('analysis/robustness/normal-weights/scale_small/output/');
run scale_plot_generate.m
rmpath('analysis/robustness/normal-weights/scale_small/output/');

% Various other plots

addpath('analysis/robustness/')
run plot_robust_func.m
rmpath('analysis/robustness/')

addpath('analysis/deadweight-loss/')
run plot_scalewithhospitals.m
addpath('analysis/deadweight-loss/')

addpath('analysis/calibration/moment-conditions/')
run calibration_robust_graph.m
rmpath('analysis/calibration/moment-conditions/')

addpath('analysis/calibration/moment-conditions/')
run histogram_chain_cycle.m
rmpath('analysis/calibration/moment-conditions/')


