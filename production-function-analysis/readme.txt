======================================================================

Guide to Replication Archive for “Market Failure in Kidney Exchange”
by Nikhil Agarwal, Itai Ashlagi, Eduardo Azevedo, Clayton Featherstone
and Ömer Karaduman

======================================================================


A. Setup Instructions
----------------------------------------------------------------------
1. Setup

	a. Analysis requires installation of MATLAB R2018a with an
	access to Python libraries, Python 2.7, Gurobi 7.5. The code
	was run and tested on a 64-bit linux based machine, kernel
	3.10.0.

	b. In order to run any analysis in ./analysis files follow the
	instructions on the readme.txt in ./aass folder. Running the
	analysis in parallel requires a linux cluster, but the
	individual scripts can be run one-by-one on a single
	computer. We tested the scripts on Univa Grid Engine, and
	tweaks might be necessary in other cluster setups.


B. Directory Structure and Included Files
----------------------------------------------------------------------
a. The directories are organized as follows:

	i. ./aass (Advanced Asynchronous Simulation System) .sh files
		used to submit simulation jobs and save data in the cluster.
	ii.	./analysis contains code for generating all calculations
	iii. ./classes contains main classes file, simulation.m. This
		includes the core algorithms for kidney matching and
		for running simulations.
	iv. ./data contains the processed data files. These files are
		created by the make-data repository.
	v.	./functions contains functions that are used by files in ./analysis
	vi.	./generate-output stores results from simulations
	vii.	./log saves the log files for analysis
	viii.	./output saves figures, tables and some functions
	ix.	./output-for-manuscript keeps figures, tables and constants for the manuscript
	x.	./py has the relevant python functions.
	xi.	./read-data creates interim outputs that are used by ./generate-output file

b. Obtaining original data files:

 	Researchers interested in using our dataset should directly
 	contact APD, NKR and UNOS to obtain permission:

	APD (Alliance for Paired Donation, Inc.)
	PO Box 965,
	Perrysburg, OH 4352
	Main Number: 419.866.5505

	NKR (National Kidney Registry)
	PO Box 460
	Babylon, NY 11702-0460

	UNOS (United Network for Organ Sharing)
	700 N 4th St,
	Richmond, VA 23219
	Main Number: 804.782.4800


C. Reproducing the results
------------------------------------------------------------------------
In order to reproduce the results, one should run all the analyses
through AASS system. AASS system takes spec.m files within the
analysis folder and runs a set of simulations. Relevant analysis’s
results will be saved ./data with in the directory of the
analysis. ./read-data has the relevant pieces of code to read the raw
data and create interim structs and matrices. ./generate-output has
the relevant pieces of code to read the interim outputs from
./read-data and create relevant structs and matrices for the paper.

   a. List of analysis within the ./analysis file as follows:

	i. ./calibration contains code for calibrating the parameters
	ii. ./deadweight-loss contains scripts to calculate
	    deadweight-loss under various assumptions
	iii. ./gradient, ./matching-probability and ./scale contain
	     code for calculating these three sets of quantities. A similar
	     structure within ./different-compositions contains code for
	     robustness to different compositions.
	iv. ./gradient contains an exercise for marginal product 1930
	     patients, 20000 repetitions for each
	v. ./gradient-cross-derivative contains code for calculating cross 
	   derivatives, 1M repeititions for each
	vi. ./matching-probability contains an exercise for matching
	    probabilities 5M rep
	vii. ./robustness contains exercises for effects of different
	     calibration parameters Similar to ./gradient,
	     ./matching-probability and ./scale
	viii. ./scale contains exercises for calculating production at 50
	     different sizes, 300000 rep for each
	ix. ./scale_small contains an exercise for effect of scale for
	    smaller markets 50 different sizes, 300000 rep for each
	x. ./scale_NKR_double contains an exercise for size effect for
	   larger markets 5 different sizes, 200000 rep for each

   b. To read the data from ./analysis/*/data folders, one should run
      relevant scripts in the ./output folder under relevant analysis
      folder. In order to read all the data at once, one should run
      scripts under the ./read-data folder.

   c. To create relevant files for the manuscript, one should run
      relevant scripts in the ./output folder under relevant analysis
      folder. In order to create all the constants and plots at once, one
      should run scripts under the ./generate-output folder.
