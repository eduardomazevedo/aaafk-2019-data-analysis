* Creates spreadsheet for omer and saves as a .csv

* Initialize
set more off
clear

adopath + "./do"

* Filenames are kept as globals in one do file
quietly do ./do/globals/load-globals.do

use $nkr_subs_w_hazard

* Use the recipient's center, except for altruists
*gen     ctr = r_center_star
*replace ctr = d_center_star if category == "a"
gen     ctr = r_tx_ctr_id
replace ctr = d_tx_ctr_id if category == "a"

* Merge with center level participation data
merge  m:1 ctr using $ctr_partic_dataset, ///
  keepusing(nkr_share nkr_don_share_submission) keep(master matched) nogenerate
sort   index
rename nkr_share                center_nkr_share
rename nkr_don_share_submission center_don_sub_share
gen    has_center_data = !missing(ctr)

* Due diligence
isid   index
split  index, parse("-")
gen    index_num=real(index1)
sort   index_num
assert index_num == _n
drop   index_num index1 index2

foreach var in r_arr_date_min   r_arr_date_max   r_dep_date_max   r_dep_date_min   r_transplanteddate ///
               d_arr_date_min   d_arr_date_max   d_dep_date_max   d_dep_date_min   d_transplanteddate {
  format `var' %9.0g
}
split index, parse("-") destring
drop  index  index2
ren   index1 index

ren r_abo_coarse  r_abo
ren d_abo_coarse  d_abo

* Outsheet the submissions-data file
export delimited ///
          index              category         r_abo               d_abo               r_age               ///
          d_age              r_weight         r_transplanted      d_transplanted      r_arr_date_min      ///
          d_arr_date_min     r_dep_date_min   d_dep_date_min      r_arr_date_max      r_dep_date_max      ///
          d_arr_date_max     d_dep_date_max                                           r_mp_strict         ///
          r_mp_strict_noabo  d_mp_strict      d_mp_strict_noabo   d_weight            r_cpra              ///
          center_nkr_share   center_don_sub_share has_center_data hazard              hazard_cpra         ///
          hazard_base        d_tx_chain       d_tx_cycle          d_transplant_index  r_tx_chain          ///
          r_tx_cycle         r_transplant_index ctr               r_transplanteddate  d_transplanteddate  ///
   using $sim_out_subs, replace

local n_rows  = _N

* Check number of rows
clear
insheet using  $compat_matrix 
assert `n_rows' == _N

!cp $compat_matrix           $comp_matrix_out
!cp $initial_hard_block_file $hard_blocks_out
!cp $exclusion_crit_file     $excl_matrix_out
!cp $p_hard_block            $p_hard_block_out

* Output data on n_tx_per_year
clear
use $ctr_partic_dataset
export delimited ctr                     n_tx_per_year                   n_live_tx_per_year              ///
                 n_pke_tx_per_year       n_nkr_tx_per_year               n_internal_pke_per_year         ///
                 n_external_pke_per_year n_internal_non_nkr_pke_per_year n_external_non_nkr_pke_per_year ///
                 nkr_share               nkr_don_share_submission        nkr_ctr                         ///
                 apd_share               apd_ctr                         n_apd_tx                        ///
                 unos_share              unos_ctr                        n_unos_tx                       ///
                 n_apd_tx_per_year       n_unos_tx_per_year                                              ///
  using $sim_out_ctr, replace
