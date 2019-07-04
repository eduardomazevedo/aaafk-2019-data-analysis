
do do/globals/load-globals.do

* Load the histo data and save it in Stata format so it can be merged later.
import delimited  $star_histo, clear
tempfile  star_histo_data
save     `star_histo_data'


** Start by loading up the nkr center dictionary.  Since there are multiple NKR designations, we make 
** the dictionary one-to-one by only using the first.  Then we save to a tempfile.

use $nkr_star_ctr_dict, clear

bysort star_center: ///
    gen dup_num = _n
keep if dup_num==1
drop    dup_num
tempfile  nkr_center_dictionary_no_dups
save     `nkr_center_dictionary_no_dups'


** Now, we load the raw data from KIDPAN, keep only the part we are interested in, and then merge
** with the previous two tempfiles.

use $kidpan, clear

** Keep all records that meet the import condition.  This includes deceased 
** transplants and untransplanted wl candidates.

keep if $star_import_cond
mvpatterns init_date tx_date end_date
count

** Merge in data about the hospitals, transplant centers, and OPOs involved

merge 1:1 trr_id_code wl_id_code using $kidpan_non_std, keep(match master) nogen

count

** Merge in NKR names for tx_ctr

gen       star_center_id = substr(tx_ctr,1,7)
merge m:1 star_center_id   using `nkr_center_dictionary_no_dups'
keep if inlist(_merge,1,3)
drop _merge
ren       star_center_id   tx_ctr_id
ren      nkr_center_name   tx_ctr_id_nkr

count

** Merge in NKR names for listing_ctr

gen       star_center_id = substr(listing_ctr,1,7)
merge m:1 star_center_id   using `nkr_center_dictionary_no_dups'
keep if inlist(_merge,1,3)
drop _merge
ren       star_center_id   listing_ctr_id
ren      nkr_center_name   listing_ctr_id_nkr

count

** Merge in histo data

merge m:1 wl_id_code using `star_histo_data'
keep if inlist(_merge,1,3)
drop _merge

** Fix donor classifications: that is, make the "better" liv_don_ty_reclassified

quietly do "./do/fix_donor_classification.do"

save $star_file_sans_all, replace


