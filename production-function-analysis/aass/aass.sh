#!/bin/bash
# aass: Advanced asynchronous simulation system.
# Computes simulations parallel with an array job.
# Usage: aass target-diretory number-of-cores [n-iterations-per-run [maximum-iterations]]
# Target directory must contain a MATLAB script named spec.m. Spec must define a cell array qArray of input vectors for simulations and a cell array optionsArray of options structs. The cell arrays should have the same size.
# aass.sh will launch a job array with number-of-cores who will perform the required simulations until the job is stopped. The load is distributed so that work is saved roughly every half hour.
# This works a lot better if the number of simulations to be done is a multiple of the number of cores.
# Adding more cores than simulations is useless (we may want to revisit this in the future by having extra cores repeat simulations for extra precision.)

jobname=$(basename $1)

qsub -l m_mem_free=10G -v TODOPATH="$1"  -v NITER="$3" -v MAXT="$4" -o ./log/ -e ./log/ -N aass-$jobname -t 1-$2 -b y 'matlab -nodisplay -nojvm < ./aass/run_aass.m'
