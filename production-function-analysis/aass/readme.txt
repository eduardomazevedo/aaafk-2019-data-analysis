{\rtf1\ansi\ansicpg1252\cocoartf1504\cocoasubrtf760
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww31780\viewh12060\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs24 \cf0 aass Advanced asynchronous simulation system.\
# Computes simulations parallel with an array job.\
# Usage: aass target-diretory number-of-cores [n-iterations-per-run [maximum-iterations]]\
# Target directory must contain a MATLAB script named spec.m. Spec must define a cell array qArray of input vectors for simulations and a cell array optionsArray of options structs. The cell arrays should have the same size.\
# aass.sh will launch a job array with number-of-cores who will perform the required simulations until the job is stopped. The load is distributed so that work is saved roughly every half hour.\
# This works a lot better if the number of simulations to be done is a multiple of the number of cores.\
# Adding more cores than simulations is useless (we may want to revisit this in the future by having extra cores repeat simulations for extra precision.)\
\
aass.sh Run through the terminal, \
* first argument path, \
* second argument number of cores\
* third argument number of iterations for each core\
* fourth argument is max number of iterations for the each simulation\
\
run_aass.m Starts aass.m\
\
aass.m Reads simulation options from spec.m target folder, performs the required simulations, and saves .mat files\
\
aassCalibration.m aass.m\'92s version for calibration exercises\
aassCalibration.sh aass.mshs version for calibration exercises\
\
aassGet.m Reads the target folder\'92s .mat files and gives simulation results. \
\
aassGetMean.m, aassReduce.m Reads the target folder\'92s .mat files and gives summary statistics of simulation results. \
\
}