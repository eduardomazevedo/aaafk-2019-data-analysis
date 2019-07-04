globals_for_py_code  = ./intermediate-data/globals_for_py_code.csv

### Sim filenames
compat_matrix           = ./intermediate-data/sim/compatibility-matrix.txt
compat_matrix_dta       = ./intermediate-data/sim/compatibilityMatrix.dta
initial_hard_block_file = ./intermediate-data/sim/initial-hard-blocks.txt
weak_file               = ./intermediate-data/sim/weak-compatibility-matrix.txt
exclusion_crit_file     = ./intermediate-data/sim/excluded-matrix.txt
p_hard_block            = ./intermediate-data/sim/p_hard_block.txt
block_file_real         = ./raw-files/nkr/blockFileReal.csv
nkr_subs_w_hazard       = ./intermediate-data/sim/nkr-submissions-with-hazard.dta
sim_out_subs            = ./simulation-data/submissions-data.csv
sim_out_ctr             = ./simulation-data/ctr-data.csv
comp_matrix_out         = ./simulation-data/compatibility-matrix.txt
hard_blocks_out         = ./simulation-data/initial-hard-blocks.txt
excl_matrix_out         = ./simulation-data/excluded-matrix.txt
p_hard_block_out        = ./simulation-data/p_hard_block.txt
outfile                 = ./intermediate-data/sim/HazardAnalysis.xls 
paper_table_int_file    = ./intermediate-data/sim/HazardAnalysis_Paper.tex
paper_table_outfile     = ./tables/HazardAnalysis_Paper.tex

### Raw filenames
# Files straight from STAR: non_std has the donor_hospital information, ki_unacc_antigen has 
# information about which antigens a patient can't accept
kidpan               = ./raw-files/star/KIDPAN_DATA.DTA
kidpan_non_std       = ./raw-files/star/kidpan_non_std.DTA
kidpan_unacc_ant     = ./raw-files/star/ki_unacc_antigen.DTA

# The zip code database tells us which zips correspond to which states, counties, etc.  Used in 
# making the donor hospital dictionary
zip_to_state         = ./raw-files/zip/zip_code_database.dta
nkr_star_ctr_names   = ./raw-files/nkr/tx_ctr_id_nkr_name.txt
unos_raw             = ./raw-files/unos-kpd/UNOSHistoricalDataAll-raw.csv

# APD and NKR raw files are hard coded in their respective parse-snapshots scripts in the py folder.
# We could re-route those hard-codes through this file if we wanted, but it seems like a headache.

### Datasets filenames
tx_dataset                       = ./datasets/transplant-level-data-full.dta
tx_dataset_csv                   = ./datasets/transplant-level-data-full.csv
tx_dataset_perfect               = ./datasets/transplant-level-data-full-perfect.dta
tx_dataset_perfect_csv           = ./datasets/transplant-level-data-full-perfect.csv
pair_dataset                     = ./datasets/pair-level-data-full.dta
pair_dataset_perfect             = ./datasets/pair-level-data-full-perfect.dta
ctr_partic_dataset               = ./datasets/ctr-participation-dataset.dta
ctr_partic_dataset_perfect       = ./datasets/ctr-participation-dataset-perfect.dta

nkr_tx_dataset                   = ./datasets/nkr-transplant-level-data-full.dta
apd_tx_dataset                   = ./datasets/apd-transplant-level-data-full.dta
unos_tx_dataset                  = ./datasets/unos-transplant-level-data-full.dta

### Miscellaneous filenames
# The PRA and MatchPower computed from the STAR histo data.
star_pra_mp           = ./intermediate-data/star/star-pra-mp.csv
nkr_pra_mp            = ./intermediate-data/nkr/nkr-pra-mp.csv
apd_pra_mp            = ./intermediate-data/apd/apd-pra-mp.csv
unos_pra_mp           = ./intermediate-data/unos/unos-pra-mp.csv

# These are the two donor_hospital dictionaries.  CF only matches those donor_hospitals that are 
# used in living donor transplants, and does so without referencing anything but the names of the 
# donor hospitals and transplant centers.  EA matches the other hospitals, but to do so, it uses the 
# transplant match.  
don_hosp_dic_CF      = ./intermediate-data/star/don-hosp-dic-CF.dta
don_hosp_dic_EA      = ./intermediate-data/star/don-hosp-dic-EA.dta
#don_hosp_dic_EA      = ./intermediate-data/donor-hospital-dictionary.dta

### Intermediate filenames
# STAR data, with various degrees of extra stuff merged in
star_file_sans_all   = ./intermediate-data/star/STAR-recent-tx-and-submissions-sans-MP-cPRA-donor-hosp.dta
star_file            = ./intermediate-data/star/STAR-recent-tx-and-submissions-sans-donor-hosp.dta
star_file_with_dh    = ./intermediate-data/star/STAR-recent-tx-and-submissions.dta
# This is a place to store chunks of STAR that need to be passed between do files
star_temp            = ./intermediate-data/star/star-temp.dta
# The STAR histo data, copied directly from ki_unacc_antigen
star_histo_pre_union = ./intermediate-data/star/star-histo-pre-union.csv
# The union of unacceptable antigens for every patient.
star_histo           = ./intermediate-data/star/star-histo-data.csv
#star_histo           = ./intermediate-data/star-pra-mp.csv

all_ch_file                     = ./intermediate-data/all_ch/AllCHHistoricalDataAll.dta
all_ch_tx_match                 = ./intermediate-data/all_ch/all_ch-star-transplant-map.dta
all_ch_tx_match_perfect         = ./intermediate-data/all_ch/all_ch-star-transplant-map-perfect.dta
all_ch_temp                     = ./intermediate-data/all_ch/all_ch-temp.dta
all_ch_leftovers                = ./intermediate-data/all_ch/all_ch-star-transplant-leftovers.dta
all_ch_tx_match_with_merge      = ./intermediate-data/all_ch/all_ch-star-transplant-map-with-merge.dta
all_ch_univ_minus_exact_matches = ./intermediate-data/all_ch/all_ch-star-universe-minus-exact.dta

nkr_file                         = ./intermediate-data/nkr/NKRHistoricalDataAll.dta
nkr_file_csv                     = ./intermediate-data/nkr/NKRHistoricalDataAll.csv
nkr_file_sans_MP_cPRA            = ./intermediate-data/nkr/NKRHistoricalDataAll-sans-MP-cPRA.csv
nkr_tx_match                     = ./intermediate-data/nkr/nkr-star-transplant-map.dta
nkr_leftovers                    = ./intermediate-data/nkr/nkr-star-transplant-leftovers.dta
nkr_tx_match_with_merge          = ./intermediate-data/nkr/nkr-star-transplant-map-with-merge.dta
nkr_univ_minus_exact_matches     = ./intermediate-data/nkr/nkr-star-universe-minus-exact.dta
nkr_distr_stem_match             = ./intermediate-data/nkr/nkr-star-distr-matched-
nkr_distr_stem_unmatch           = ./intermediate-data/nkr/nkr-star-distr-unmatched-
nkr_temp                         = ./intermediate-data/nkr/nkr-temp.dta


nkr_star_ctr_dict                = ./intermediate-data/nkr/nkr-center-dictionary.dta
nkr_star_ctr_dict_csv            = ./intermediate-data/nkr/nkr-center-dictionary.csv
nkr_rec_match                    = ./intermediate-data/nkr/nkr-star-recip-map.dta
nkr_rec_match_with_merge         = ./intermediate-data/nkr/nkr-star-recip-map-with-merge.dta
nkr_don_match                    = ./intermediate-data/nkr/nkr-star-donor-map.dta
nkr_don_match_with_merge         = ./intermediate-data/nkr/nkr-star-donor-map-with-merge.dta
nkr_prob_distr_rec_gph           = ./intermediate-data/nkr/nkr-max-prob-recip-kdensity.gph
nkr_prob_distr_don_gph           = ./intermediate-data/nkr/nkr-max-prob-donor-kdensity.gph

apd_file                         = ./intermediate-data/apd/APDHistoricalDataAll.dta
apd_file_csv                     = ./intermediate-data/apd/APDHistoricalDataAll.csv
apd_file_pre_conv                = ./intermediate-data/apd/APDHistoricalDataAll-pre-conv.csv
apd_file_with_dups               = ./intermediate-data/apd/APDHistoricalDataAll-with-dups.csv
apd_file_sans_MP_cPRA            = ./intermediate-data/apd/APDHistoricalDataAll-sans-MP-cPRA.csv
apd_tx_match                     = ./intermediate-data/apd/apd-star-transplant-map.dta
apd_leftovers                    = ./intermediate-data/apd/apd-star-transplant-leftovers.dta
apd_tx_match_with_merge          = ./intermediate-data/apd/apd-star-transplant-map-with-merge.dta
apd_univ_minus_exact_matches     = ./intermediate-data/apd/apd-star-universe-minus-exact.dta
apd_distr_stem_match             = ./intermediate-data/apd/apd-star-distr-matched-
apd_distr_stem_unmatch           = ./intermediate-data/apd/apd-star-distr-unmatched-
apd_temp                         = ./intermediate-data/apd/apd-temp.dta

apd_rec_match                    = ./intermediate-data/apd/apd-star-recip-map.dta
apd_rec_match_with_merge         = ./intermediate-data/apd/apd-star-recip-map-with-merge.dta
apd_don_match                    = ./intermediate-data/apd/apd-star-donor-map.dta
apd_don_match_with_merge         = ./intermediate-data/apd/apd-star-donor-map-with-merge.dta
apd_prob_distr_rec_gph           = ./intermediate-data/apd/apd-max-prob-recip-kdensity.gph
apd_prob_distr_don_gph           = ./intermediate-data/apd/apd-max-prob-donor-kdensity.gph

unos_file                         = ./intermediate-data/unos/UNOSHistoricalDataAll.dta
unos_file_csv                     = ./intermediate-data/unos/UNOSHistoricalDataAll.csv
unos_file_sans_MP_cPRA            = ./intermediate-data/unos/UNOSHistoricalDataAll-sans-MP-cPRA.csv

unos_tx_match                     = ./intermediate-data/unos/unos-star-transplant-map.dta
unos_leftovers                    = ./intermediate-data/unos/unos-star-transplant-leftovers.dta
unos_tx_match_with_merge          = ./intermediate-data/unos/unos-star-transplant-map-with-merge.dta
unos_univ_minus_exact_matches     = ./intermediate-data/unos/unos-star-universe-minus-exact.dta
unos_temp                         = ./intermediate-data/unos/unos-temp.dta
unos_rec_match_with_merge         = ./intermediate-data/unos/unos-star-recip-map-with-merge.dta

unos_distr_stem_match             = ./intermediate-data/unos/unos-star-distr-matched-
unos_distr_stem_unmatch           = ./intermediate-data/unos/unos-star-distr-unmatched-
unos_rec_match                    = ./intermediate-data/unos/unos-star-recip-map.dta
unos_rec_match_with_merge         = ./intermediate-data/unos/unos-star-recip-map-with-merge.dta
unos_don_match                    = ./intermediate-data/unos/unos-star-donor-map.dta
unos_don_match_with_merge         = ./intermediate-data/unos/unos-star-donor-map-with-merge.dta
unos_prob_distr_rec_gph           = ./intermediate-data/unos/unos-max-prob-recip-kdensity.gph
unos_prob_distr_don_gph           = ./intermediate-data/unos/unos-max-prob-donor-kdensity.gph

