======================================================================	
Guide to Replication Archive for
“Market Failure in Kidney Exchange” by Nikhil Agarwal, Itai Ashlagi, Eduardo Azevedo, Clayton R. Featherstone and Ömer Karaduman
======================================================================

Repository for creating main datasets.
--------------------------------------

This code repository generates three datasets: 

	1. The center participation dataset keeps track of center
	   level statistics, like number of Kidney Exchange
	   transplants and number of transplants organized through
	   clearinghouses.

	2. The pair level dataset keeps track of all "pairs"
	   (including altruists and unpaired patients) submitted to
	   the three clearinghouses.
	
	3. The transplant level dataset keeps track of all transplants
	   done in the US during the period of study.  These
	   transplants are also linked with submissions to the
	   clearinghouses.


A. Setup Instructions
----------------------------------------------------------------------

Analysis uses Stata 13, Python 2.7, GNU make 3.82, and bash
4.2.46. The code was run and tested on a 64-bit linux based machine,
kernel 3.10.0.


B. Directory Structure and Included Files
--------------------------------------------------------------------------------

The directory structure for the project is as follows. Not all
directories are in the repository, since some cannot be shared while
others are for output. These directories are marked with an asterisk
(*). The user has to create these directories. Symbolic links wll
suffice.

datasets*: external link to encrypted location for final datasets.
	   This is where the main output of the make file goes.

do:	   Contains Stata scripts

	/gen-datasets: scripts to prepare the datasets from the
		       intermediate files

	/globals:      scripts to hold globals, like dates for analysis and
		       conditions for matches.
	
	/prepare-data: scripts to convert raw data into the
		       intermediate data that is used to generate the
		       datasets

	/sim-data:     scripts to calculate data used in the simulations.
	
	/star-map:     scripts to match clearinghouse transplants to
		       transplants in the STAR data.

intermediate-data*:    encrypted location for intermediate files used to
		       generate the datasets
	
	/all_ch: holds merged platform data and a map from platform
		 identifiers to the STAR data
	/apd:	 ditto for the APD
	/nkr:	 ditto for the NKR
	/unos:	 ditto for UNOS
	/sim:	 files used to generate inputs for simulations
	/star:	 STAR data, appropriately cleaned for merging with the other datasets
	

log:		logs from all scripts that are run by the makefile

raw-files:	contains all the raw data that is processed by this repo.
	/apd:	data from APD
	/nkr:	data from NKR
	/pra:	data about the population used to compute PRA
	/star:  standard request KIDPAN data, along with special-request
		histocompatibility data and hospital name data

	/unos-kpd: UNOS KPD data, speacial-request
	/zip:	zip code database, used to put together the donor hospital name dictionary.

py: 		python scripts. these are largely used to compute PRA and match
		power and to parse the raw clearinhouse data files.

sh:		bash utility scripts go here

simulation-data*:
		This data is the input to the simulations

tables: 	One LaTeX table concerning the hazard rate calculations done
		for the simulations. The estimates are in the appendix.


Researchers interested in using our dataset should directly contact APD, NKR and UNOS to obtain permission:

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


C. Code Generating Cleaned Datasets
------------------------------------------------------------------------

In order to generate the results, one should run the makefile by typing the command "make" in the root directory. The datasets will be saved in the datasets directory in the root.

The makefile implements the following logical flow

1. Create files containing global definitions, like filenames, match
   criteria, etc, that can be used by the Stata and Python scripts.
2. Create a dictionary linking NKR hospital names to STAR hospital names.
3. Take the special-order STAR histocompatibility data and parse it.
4. Parse the NKR, UNOS, and APD data and convert all fields to NKR format.
5. Create one file from STAR data and histocompatibility data.
6. Compute PRA and Match Power for APD, NKR, UNOS, and STAR.
7. Donor hospitals are stored using a different naming system than
   transplant centers in the STAR data. Create a dictionary to convert
   between the two. Merge into the STAR data.
8. Merge all clearinghouse data into one datafile.
9. Run match to link clearinhouse transplants to STAR transplants based on biological data.
10. Create datasets.
11. Create simulation data.
