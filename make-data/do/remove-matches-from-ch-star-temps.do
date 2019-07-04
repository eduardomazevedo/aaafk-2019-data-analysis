quietly do do/globals/load-globals.do

* Assumes that the variables num_dups_nkr and num_dups_kidpan exist.

* Whatever observations have keep num_dups_nkr==num_dups_kidpan==0, keep them and
* 1) add them to the $nkr_tx_match
* 2) remove them from $nkr_temp and $kidpan_temp, so that they aren't subsequently matched.

local ch       = subinstr("`1'","clearinghouse=","",1)
local type     = subinstr("`2'","type=",         "",1)

if !regexm("`1'","clearinghouse=")  | ///
   !inlist("`ch'","nkr","apd","unos","all_ch")  {
     di as error "Argument 1 not of form 'clearinghouse=apd/nkr/unos/all_ch'"
     error 111
}
if !regexm("`2'","type=")  | ///
   !inlist("`type'","tx","don","rec")  {
     di as error "Argument 2 not of form 'type=tx/don/rec'"
     error 111
}

count if num_dups_ch==0 & num_dups_kidpan==0
keep  if num_dups_ch==0 & num_dups_kidpan==0

*if "`ch'"=="nkr" {
  keep ch_id* ch_index* wl_id_code trr_id_code pt_code
*}
*if "`ch'"=="apd" {
*  keep `ch'_id* wl_id_code trr_id_code pt_code
*}

* Add the remaining nkr_ids and trr_id_code to $nkr_tx_match (or create it if it doesn't exist)
capture confirm file ${`ch'_`type'_match}
if (_rc==0){  // if the file already exists
  append using ${`ch'_`type'_match}
}
save           ${`ch'_`type'_match}, replace

count

capture mvpatterns trr_id_code wl_id_code
duplicates report trr_id_code
duplicates report pt_code
duplicates report ch_id*


* Remove matched from nkr_tmp
use ${`ch'_temp}, clear
if ("`type'"=="tx") {
    merge 1:1 ch_id* using ${`ch'_`type'_match}
}
if ("`type'"=="don") {
    merge 1:1 ch_id_don using ${`ch'_`type'_match}
}
if ("`type'"=="rec") {
    merge 1:1 ch_id_rec using ${`ch'_`type'_match}
}
tab _merge
keep if _merge==1
drop _merge pt_code wl_id_code trr_id_code
*if ("`type'"=="transplant"){
*    drop trr_id_code
*}
save ${`ch'_temp}, replace
count

* Remove matched from kidpan_temp
use $star_temp, clear
if      ("`type'"=="tx"){
    merge 1:1 trr_id_code pt_code using ${`ch'_`type'_match}
}
else if inlist("`type'","don","rec"){
    merge m:1             pt_code using ${`ch'_`type'_match}
}

tab _merge
keep if _merge==1
drop _merge ch_id* 
*if "`ch'"=="nkr" {
  drop ch_index*
*}
save $star_temp, replace
count

