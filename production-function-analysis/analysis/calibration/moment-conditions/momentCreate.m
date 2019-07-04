addpath('aass', 'classes', 'functions');

exercise = 'second';

directory = ['./analysis/calibration/' exercise '-exercise/'];

[simulation_calib,realmarket_stat] = figuresFromCalibration(directory);
[overallTypeTables]= simTypeTablesVector(directory);
[overallTransPer] = chainlength(directory);
[poolSize] = poolMoments(directory);
