SHELL     := /bin/bash
stata     := ./sh/stata-batch.sh
python    := ./sh/python-batch.sh
user      := $(shell echo ${USER})
timestamp  = $(shell date +%s) 
start     := ${timestamp}
include gmsl

.PHONY: main clean remove-files stop-timer start-script print-% \
        confirm-base-files ensure-stata-packages check-clean

# FILENAMES SHARED WITH STATA
# ---------------------------
include filenames.mk
#include make-globals.mk

####
# TARGETS
####

# This target must be first, since simply entering "make" at the command line 
# runs the first target in the makefile.

main: start-script \
      $(tx_dataset) \
      $(pair_dataset) \
      $(ctr_partic_dataset) \
      $(star_file_with_dh) \
      $(all_ch_file) \
      $(all_ch_tx_match) \
      $(compat_matrix) \
      $(p_hard_block) \
      $(nkr_subs_w_hazard) \
      $(sim_out_subs) \
      stop-timer
      
# Creates a do file to import the filenames in filename.mk to Stata. This way, filenames 
# all stay in one central location.

./do/globals/load-filenames.do: ./py/export-filenames-for-stata.py ./filenames.mk 
	@echo "${yellow}Porting filenames.mk to load-filenames.do${cyan}"
	$(python) $<

# Creates a csv of all the Stata globals, so that Python scripts can use them.

$(globals_for_py_code): ./do/globals/export-globals-for-py-code.do \
                        ./do/globals/load-filenames.do \
                        ./do/globals/load-globals-dates.do \
                        ./do/globals/load-globals-match-conditions.do
	@echo "${yellow}Porting Stata globals to globals_for_py_code.csv.${cyan}"
	$(stata) $<

# Creates the Stata and csv version of the NKR center dictionary.  The do file creates
# both the dta and csv: this is the make idiom for one script generating multiple outputs.

$(nkr_star_ctr_dict) : ./do/prepare-data/make-nkr-center-dictionary.do \
                       $(nkr_star_ctr_names)
	@echo "${yellow}Making the NKR center dictionary.${cyan}"
	$(stata) $<

$(nkr_star_ctr_dict_csv) : $(nkr_star_ctr_dict)

# Exports STAR histo data to csv, but we still have multiple entries for 
# each patient

$(star_histo_pre_union) : ./do/prepare-data/export-star-histo-to-csv.do \
                          $(kidpan) $(kidpan_unacc_ant)
	@echo "${yellow}Exporting STAR histo data to csv.${cyan}"
	$(stata) $<

# Takes multiple histo entries for each patient and unions them.

$(star_histo) : ./py/compile-histo-data-from-STAR.py \
                $(star_histo_pre_union)
	@echo "${yellow}Taking unions of multiple histo entries for each patient (~20min).${cyan}"
	$(python) $<

# Compiling NKR data.  There are a lot of undeclared dependencies here, so if the NKR 
# data is changed or updated, we will need to run this target manually (since make 
# won't know to do it).

$(nkr_file_sans_MP_cPRA) : ./py/parse-snapshots-NKR.py $(nkr_star_ctr_dict_csv)
	@echo "${yellow}Compiling NKR data (~8min)${cyan}"
	$(python) $<

# Compiling APD data.  There are a lot of undeclared dependencies here, so if the APD 
# data is changed or updated, we will need to run this target manually (since make 
# won't know to do it).

$(apd_file_pre_conv) : ./py/parse-snapshots-APD.py
	@echo "${yellow}Compiling APD data${cyan}"
	$(python) $<

$(apd_file_with_dups) : ./do/prepare-data/convert-apd-to-nkr-format.do $(apd_file_pre_conv)
	@echo "${yellow}Converting APD data to NKR format${cyan}"
	$(stata) $<

$(apd_file_sans_MP_cPRA) : ./do/prepare-data/remove-dups-from-apd.do $(apd_file_with_dups)
	@echo "${yellow}Removing duplicates from APD data${cyan}"
	$(stata) $<

# Compiling the UNOS KPD data.  Here, we take the UNOSHistoricalDataAll-sans-MP-cPRA as 
# given.  At some point, we should make this work with parse-snapshots-UNOS.py.

$(unos_file_sans_MP_cPRA) : ./do/prepare-data/convert-unos-to-nkr-format.do $(unos_raw) $(star_file)
	@echo "${yellow}Converting UNOS data to NKR format${cyan}"
	$(stata) $<

# Compiling the STAR data
$(star_file_sans_all) : ./do/prepare-data/get-STAR-recent-tx-and-submissions-sans-MP-cPRA-donor-hosp.do \
                         $(star_histo)  $(nkr_star_ctr_dict)  $(kidpan)  $(kidpan_non_std) \
                         ./do/globals/load-globals-match-conditions.do \
                         ./do/fix_donor_classification.do
	@echo "${yellow}Compiling STAR data${cyan}"
	$(stata) $<

# Computing MP and PRA for all datasets.  Since MP is relative to the NKR pool, all recipes have
# $(nkr_file_sans_MP_cPRA) as a prereq.

define compute_mp = 
$($(1)_pra_mp) : ./py/compute-pra-mp.py \
                 $(nkr_file_sans_MP_cPRA) \
                 $($(1)_file_sans_MP_cPRA)
	@echo "$${yellow}Computing MP and PRA for $(call uc,$(1)) data (~10min)$${cyan}"
	$(python) $$< $(call uc,$(1))

endef

$(eval $(foreach ch,nkr apd unos,$(call compute_mp,$(ch))))

$(star_pra_mp) : ./py/compute-pra-mp.py $(nkr_file_sans_MP_cPRA) $(star_histo)
	@echo "${yellow}Computing MP and PRA for STAR data (~4hr)${cyan}"
	$(python) $< STAR

# Merge the MP and PRA data in with the rest of the data for both STAR and the clearinghouse 
# data

$(star_file) : ./do/prepare-data/merge-MP-cPRA-into-recent-STAR-tx-and-submissions.do \
               $(star_pra_mp) $(star_file_sans_all)
	@echo "${yellow}Merging PRA and MP into STAR data.${cyan}"
	$(stata) $<

$(nkr_file_csv) : ./do/prepare-data/merge-MP-cPRA-into-ch-data.do \
                  $(nkr_pra_mp)  $(nkr_file_sans_MP_cPRA)  \
                  $(apd_pra_mp)  $(apd_file_sans_MP_cPRA)  \
                  $(unos_pra_mp) $(unos_file_sans_MP_cPRA)
	@echo "${yellow}Merging PRA and MP into clearinghouse data.${cyan}"
	$(stata) $<

$(unos_file_csv) : $(apd_file_csv)
$(apd_file_csv)  : $(nkr_file_csv)


# Create the donor hospital dictionary: match donor_hospitals to tx_ctrs for all living donors

$(don_hosp_dic_CF) : ./do/prepare-data/make-donor-hosp-dict-CF.do \
                     $(star_file)  $(zip_to_state)
	@echo "$(yellow)Creating the donor hospital dictionary.$(cyan)"
	$(stata) $<

#  Merge the donor hospital dictionary into the STAR data 

$(star_file_with_dh) : ./do/prepare-data/merge-donor-hospital-to-recent-tx-and-submissions.do \
                       $(star_file)  $(don_hosp_dic_CF)
	@echo "$(yellow)Linking donor hospital to STAR center names. ()$(cyan)"
	$(stata) $<

# Format and merge clearinghouse data files

$(all_ch_file): ./do/prepare-data/format-merge-ch-data-files.do \
                $(nkr_file_csv) $(apd_file_csv) $(unos_file_csv)
	@echo "$(yellow)Formatting and merging clearinghouse data files.$(cyan)"
	$(stata) $<

$(nkr_file)  : $(unos_file)
$(unos_file) : $(apd_file)
$(apd_file)  : $(all_ch_file)

# Transplant match

$(all_ch_tx_match) : ./do/star-map/make-transplant-map.do \
                     ./do/load-kidpan-data.do \
                     $(star_file_with_dh) \
                     $(all_ch_file) \
                     ./do/globals/load-globals-match-conditions.do \
                     ./do/remove-matches-from-ch-star-temps.do \
                     ./do/joinby-geq-2-hla-matches.do \
                     ./do/load-ch-transplant-data.do \
                     ./do/calc-match-quality-vars.do
	@echo "$(yellow)Running transplant match and match distributions (~5min).$(cyan)"
	$(stata) $<  clearinghouse=all_ch

$(all_ch_tx_match_perfect)         : $(all_ch_temp)
$(all_ch_temp)                     : $(all_ch_leftovers)
$(all_ch_leftovers)                : $(all_ch_tx_match_with_merge) 
$(all_ch_tx_match_with_merge)      : $(all_ch_univ_minus_exact_matches)
$(all_ch_univ_minus_exact_matches) : $(all_ch_tx_match)

# Create transplant dataset

$(tx_dataset) : ./do/gen-datasets/gen-tx-level-dataset.do \
                ./do/globals/load-globals-match-conditions.do \
                $(all_ch_file) \
                $(all_ch_tx_match) \
                $(star_file_with_dh)
	@echo "$(yellow)Building transplant level dataset (~5min).$(cyan)"
	$(stata) $<

$(tx_dataset_perfect_csv) : $(tx_dataset_perfect)
$(tx_dataset_perfect)     : $(tx_dataset_csv)
$(tx_dataset_csv)         : $(tx_dataset)

# Pair level dataset: one NKR "pair" on each line

$(pair_dataset) : ./do/gen-datasets/gen-pair-level-dataset.do \
                  ./do/globals/load-globals-match-conditions.do \
                  $(all_ch_file) \
                  $(all_ch_tx_match)\
                  $(star_file_with_dh)
	@echo "$(yellow)Building pair level dataset (~2min).$(cyan)"
	$(stata) $<

$(pair_dataset_perfect)     : $(pair_dataset)

# Center participation dataset

$(ctr_partic_dataset) : ./do/gen-datasets/gen-ctr-partic-dataset.do \
                        ./do/globals/load-globals-match-conditions.do \
                        $(tx_dataset) \
                        $(pair_dataset)
	@echo "$(yellow)Building center level dataset (~1min).$(cyan)"
	$(stata) $<

$(ctr_partic_dataset_perfect)     : $(ctr_partic_dataset)

# Compute compatibility matrix

$(compat_matrix) : ./py/calculate-compatibility-matrix.py \
                   $(nkr_file_csv)
	@echo "${yellow}Calculating compatibility matrix. (~7min)${cyan}"
	$(python) $<

$(initial_hard_block_file) : $(weak_file)
$(weak_file)               : $(exclusion_crit_file)
$(exclusion_crit_file)     : $(compat_matrix)

# Hard block probabilities

$(p_hard_block) : ./do/sim-data/hard_blocks.do \
                  $(compat_matrix) \
                  $(nkr_file_csv) \
                  $(initial_hard_block_file)
	@echo "${yellow}Computing hard block probabilities. (~70min)${cyan}"
	$(stata) $<

$(compat_matrix_dta) : $(p_hard_block)

# Hazard rates

$(nkr_subs_w_hazard): ./do/sim-data/calc-hazard-rates.do \
                       $(nkr_file)
	@echo "${yellow}Computing hazard rates. (<1min)${cyan}"
	$(stata) $<

$(outfile)              : $(paper_table_int_file)
$(paper_table_int_file) : $(paper_table_outfile)
$(paper_table_outfile)  : $(nkr_subs_w_hazard)

# Omer data 

$(sim_out_subs): ./do/sim-data/create-omer-data.do \
                            $(nkr_subs_w_hazard) \
                            $(ctr_partic_dataset) \
                            $(compat_matrix) \
                            $(initial_hard_block_file) \
                            $(exclusion_crit_file) \
                            $(p_hard_block)
	@echo "${yellow}Creating data for Omer. (<1min)${cyan}"
	$(stata) $<

$(comp_matrix_out)  : $(hard_blocks_out)
$(hard_blocks_out)  : $(excl_matrix_out)
$(excl_matrix_out)  : $(p_hard_block_out)
$(p_hard_block_out) : $(sim_out_ctr)
$(sim_out_ctr)      : $(sim_out_subs)


### Utility targets

# Deletes everything but the raw data and scripts. Run by typing "make clean" at the command prompt
clean: check-clean remove-files stop-timer

check-clean:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} == y ]

# Makes sure that the globals and filenames are updated.
start-script: confirm-base-files \
              makedag.dot \
              ensure-stata-packages \
              ./do/globals/load-filenames.do \
              $(globals_for_py_code)

makedag.dot : makefile
	@echo "${yellow}[`date +"%T"`] Outputting makefile DAG to makedag.dot.  Can be read with an online reader, like webgraphviz.com.${cyan}"
	make -Bnd | ./make2graph > makedag.dot

ensure-stata-packages: ./do/install-stata-packages.do
	@echo "${yellow}Making sure Stata packages are installed.${cyan}"
	$(stata) $<

confirm-base-files: ./sh/confirm-base-files.sh
	@echo ""
	@echo "${yellow}Refreshing symbolic links and confirming base files.${cyan}"
	./sh/confirm-base-files.sh


# The meat of the removal described above the "clean" recipe.  Needs to be filled in
remove-files:
	@echo ""
	@echo "${yellow}Purging workspace.${cyan}"
	-rm -rf ./datasets/*
	-unlink datasets
	-rm ./do/load-filenames.do
	-rm -rf ./intermediate-data/*
	-unlink intermediate-data
	-rm ./makedag.dot
	-unlink raw-files/nkr
	-unlink raw-files/apd
	-unlink raw-files/unos-kpd
	-unlink raw-files/star
	-unlink raw-files/pra
	-unlink raw-files/zip
	-rm -rf ./simulation-data/*
	-rm -rf ./tables/*


# Gives the time elapsed during the makefile's run.
stop-timer:
	@(( runtime=${timestamp}-${start} )); \
	 (( rhr =$$runtime/3600 ));           \
	 (( runtime=$$runtime%3600 ));        \
	 (( rmin=$$runtime/60 ));             \
	 (( rsec=$$runtime%60 ));             \
	 echo "";                             \
	 echo "$(green)Runtime was $${rhr}h:$${rmin}m:$${rsec}s."; \
	 echo ""

# Entering "make print-VARNAME" at the command line will print the contents of $VARNAME in the
# makefile.  Useful for debugging.
print-%  : ; @echo $* = $($*)

# Colors
green  = $(shell tput setaf 2)
yellow = $(shell tput setaf 3)
blue   = $(shell tput setaf 4)
magenta= $(shell tput setaf 5)
cyan   = $(shell tput setaf 6)

