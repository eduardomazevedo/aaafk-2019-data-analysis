* Initialize
set more off
clear

adopath + "./do"

* Filenames are kept as globals in one do file
quietly do ./do/globals/load-globals.do

*    local NKRHistorical_csv = "./intermediate-data/NKRHistoricalDataAll.csv"
*    import delimited `NKRHistorical_csv', clear
*    egen num_tx_NKR = sum(!mi(tx_id)), by(index)
*    tempfile NKRHistorical
*    save `NKRHistorical'
*    clear all
    use $all_ch_file

    //local nkr_star_notx_rec_map  = "./intermediate-data/nkr-star-recip-map-for-pairs-file.dta"
    //local nkr_star_notx_don_map  = "./intermediate-data/nkr-star-donor-map.dta"    

    set more off
    clear all

// Make a tempfile of all donors from NKR, prefixing their data with _nd_
    use $all_ch_file
    keep if isdonor==1
    quietly ds
    foreach var in `r(varlist)' {
        ren `var' _nd_`var'
    }
    ren _nd_index       index_base
    ren _nd_ch_id   ch_id_don_base
    tempfile donor_file
    save `donor_file'

// Pull up all recips from NKR, prefixing their data with _nr_
    use $all_ch_file
    keep if isdonor==0
    quietly ds
    foreach var in `r(varlist)' {
        ren `var' _nr_`var'
    }
    * the _base suffix ensures that the upcoming merges don't overwrite anything important.
    ren _nr_index       index_base
    ren _nr_ch_id   ch_id_rec_base

// Merge the donors to the recips on index.  This creates a file where every donor rec pair is 
// one line.
// NOTE: this means that a triad is on two lines, one for each donor (the recip is repeated).

    merge 1:m index  using `donor_file'
    assert _nd_ch==_nr_ch if !mi(_nd_ch,_nr_ch)
    assert !mi(_nd_ch) | !mi(_nr_ch)
    gen        ch =_nr_ch if !mi(_nd_ch,_nr_ch)
    replace    ch =_nr_ch if  mi(_nd_ch)
    replace    ch =_nd_ch if  mi(_nr_ch)
    drop _nr_ch _nd_ch
    drop _merge
    save $pair_dataset, replace
    save $pair_dataset_perfect, replace

foreach suffix in "" "_perfect" {
    use ${pair_dataset`suffix'}, clear
    di "suffix: `suffix'"
// Merge in wl_id_code, trr_id_code, and pt_code for all matched transplanted recips
    ren       ch_id_rec_base  ch_id_rec
    merge m:1 ch_id_rec       using ${all_ch_tx_match`suffix'}
    * This should match the total number of matched transplants in the map-stats log file
    distinct  ch_id_rec       if _merge==3
    drop      ch_id_don       ch_index*
    ren       ch_id_rec       ch_id_rec_base
    ren     (     pt_code          trr_id_code         wl_id_code ) ///
            ( _sr_pt_code      _sr_trr_id_code     _sr_wl_id_code )
    drop _merge

// Merge in wl_id_code, trr_id_code, and pt_code for all matched transplanted dons
    ren       ch_id_don_base  ch_id_don
    merge m:1 ch_id_don       using ${all_ch_tx_match`suffix'}
    * This should match the total number of matched transplanted donors in the map-stats log file
    distinct  ch_id_don       if _merge==3
    drop      ch_id_rec       ch_index*
    ren       ch_id_don       ch_id_don_base
    ren     (     pt_code          trr_id_code         wl_id_code ) ///
            ( _sd_pt_code      _sd_trr_id_code     _sd_wl_id_code )
    drop _merge

/*  This code can be incorporated once the untransplanted donor and recip matches are fixed.

* Merge in wl_id_code, trr_id_code, and pt_code for all matched untransplanted recips
    ren       nkr_id_rec_base  nkr_id_rec
    merge m:1 nkr_id_rec       using `nkr_star_notx_rec_map'
    * This should match the total number of matched untransplanted recips in the map-stats log file
    distinct  nkr_id_rec       if _merge==3
    drop      nkr_index*
    * num_tx_L and num_tx_C tell us how many living and deceased donor transplants the recip has in KIDPAN
    ren       num_tx_L        _sr_num_tx_L
    ren       num_tx_C        _sr_num_tx_C
    ren       max_death_date  _sr_max_death_date
    ren       nkr_id_rec       nkr_id_rec_base
    * Since _sr_pt_code, etc. have already been generated, we have to fill them in with replace, being careful not to overwrite data from the transplant matches
    replace   _sr_pt_code     = pt_code     if !mi(pt_code)
    replace   _sr_trr_id_code = trr_id_code if !mi(trr_id_code)
    replace   _sr_wl_id_code  = wl_id_code  if !mi(wl_id_code)
    drop      pt_code          trr_id_code         wl_id_code
    drop _merge

* Merge in wl_id_code, trr_id_code, and pt_code for all matched untransplanted dons
    ren       nkr_id_don_base  nkr_id_don
    merge m:1 nkr_id_don       using `nkr_star_notx_don_map'
    * This should match the total number of matched untransplanted donors in the map-stats log file
    distinct  nkr_id_don       if _merge==3
    drop      nkr_index*
    ren       nkr_id_don       nkr_id_don_base
    replace   _sd_pt_code      = pt_code     if !mi(pt_code)
    replace   _sd_trr_id_code  = trr_id_code if !mi(trr_id_code)
    replace   _sd_wl_id_code   = wl_id_code  if !mi(wl_id_code)
    drop      pt_code          trr_id_code         wl_id_code
    drop _merge
*/

* No more merges where nkr_id* or index might be overwritten, so we remove the _base suffix
    ren ch_id_rec_base  ch_id_rec
    ren ch_id_don_base  ch_id_don
    ren      index_base  index
 
    save  ${pair_dataset`suffix'}, replace

* Merge in any STAR data that pertains to recips, prefixing with _sr_
    use $star_file_with_dh, clear
    * This var name is too long to be a Stata name once we add _sd_, so we shorten it
    ren max_kdpi_import_non_zero_abdr ///
        max_kdpi_impt_nonzero_abdr
    quietly ds
    foreach var in `r(varlist)' {
        ren `var' _sr_`var'
    }
    merge 1:m _sr_trr_id_code  _sr_wl_id_code _sr_pt_code using ${pair_dataset`suffix'}
    drop if _merge==1
    * This should match the total number of matched donors (tx and notx) in the map-stats log file
    distinct ch_id_rec if _merge==3
    drop _merge
    save  ${pair_dataset`suffix'}, replace

* Merge in any STAR data that pertains to donors, prefixing with _sd_
    use $star_file_with_dh, clear
    * This var name is too long to be a Stata name once we add _sd_, so we shorten it
    ren max_kdpi_import_non_zero_abdr ///
        max_kdpi_impt_nonzero_abdr
    quietly ds
    foreach var in `r(varlist)' {
        ren `var' _sd_`var'
    }
    merge 1:m _sd_trr_id_code  _sd_wl_id_code _sd_pt_code using ${pair_dataset`suffix'}
    * This should match the total number of matched recips (tx and notx) in the map-stats log file
    distinct ch_id_don if _merge==3
    drop if _merge==1
    drop _merge
    save  ${pair_dataset`suffix'}, replace

* Deal with recips who have multiple donors
* NOTE WELL: This tie-breaking procedure should match the one in calc-hazard-rates!!!

    * One copy of an nkr_id_rec corresponds to bona fide pairs, as well as UPRs
    * Two copies  corresponds to a triad, three to a quartet, etc.
    * Many many copies correspons to the Alts who have nkr_id_rec==.
    * These numbers should match up with those from the map-stats log file.
    duplicates report ch_id_rec

    * The only duplicated nkr_id_don should be ., which is shared by all UPRs.
    duplicates report ch_id_don

    distinct ch_id*
    duplicates tag    ch_id_rec, gen(extras)
    tab extras
  
    * If a triad, quartet, etc has two NKR transplants, then we will drop the extra donors who did 
    * not contribute.
    *drop if mi(_nd_tx_id) & _nd_num_tx==2

    * Otherwise, we pick a "best" donor based on a tie-breaker.

    * Tag recs with extra donors by using extras
    distinct ch_id*
    drop extras
    duplicates tag    ch_id_rec, gen(extras)
    tab extras
    
    * Sort by transplanted status, then blood type, then age, then break ties with ch_id_don
    gsort + index - _nd_transplanted - _nd_abo + _nd_age + ch_id_don
    by index: gen don_num = _n
    drop if extras>0 & extras<10 & don_num!=1 

    egen matched_donors = total(!mi(_sd_trr_id_code)), by(index)
    tab  matched_donors
    tab ch if matched_donors==1
    
    * Without the un-transplanted donor and rec matches, there is no other way to decide who to drop.
    * Hence, we keep the conditions below for later and just drop at random, trying to keep the O 
    * donor if we can.


    /* These conditions depends on having the untransplanted donor match
    * If there is only one donor matched to STAR, then we retain that one
    
    drop if extras>0 & extras<10 & matched_donors==1 & mi(_sd_trr_id_code)

    distinct ch_id*
    drop extras
    duplicates tag    ch_id_rec, gen(extras)
    tab extras
    
    * If the recipient was matched to STAR, has no transplants in NKR, and no living donor transplants 
    * in STAR, then we arbitrarily pick one of the donors.  By sorting on bloodtype, we endeavor to 
    * pick an O donor over other blood types.
    gsort - _nd_abo
    bysort index: gen don_num = _n
    drop if extras>0 & extras<10 & _sr_num_tx_L==0 & _nr_num_tx==0 & don_num!=1

    distinct ch_id*
    drop extras
    duplicates tag ch_id_rec, gen(extras)
    tab extras
    

    * If the recipient was not matched to STAR, his index family has no transplants in NKR, and none 
    * of his donors are matched to STAR, we arbitrarily pick one of the donors.  By sorting on 
    * bloodtype, we endeavor to pick an O donor over other blood types.
    gsort - _nd_abo
    drop don_num
    bysort index: gen don_num = _n
    drop if extras>0 & extras<10  & mi(_sr_trr_id_code) & _nr_num_tx==0 & matched_donors==0 & don_num!=1

    distinct ch_id*
    drop extras
    duplicates tag ch_id_rec, gen(extras)
    tab extras

    * If no donor is matched to STAR, but the recipient is matched to a living tx in STAR, then we 
    * randomly pick a donor to keep
    gsort - _nd_abo
    drop don_num
    bysort index: gen don_num = _n
    drop if inlist(extras,1,2) & !mi(_sr_trr_id_code) & matched_donors==0 & don_num!=1

    distinct ch_id*
    drop extras
    duplicates tag ch_id_rec, gen(extras)
    tab extras 

    * These last triads look like recips who have tapped both of their donors, but outside of NKR.  
    * Again, we randomly pick one and proceed.
    gsort - _nd_abo
    drop don_num
    bysort index: gen don_num = _n
    drop if inlist(extras,1,2) & don_num!=1 */

    distinct ch_id*
    drop extras
    duplicates tag ch_id_rec, gen(extras)
    tab extras

  * Now we add tags that classify transplants
    gen is_pair  = !mi(ch_id_don) & !mi(ch_id_rec)
    gen is_chip  =  mi(ch_id_don) & !mi(ch_id_rec)
    gen is_alt   = !mi(ch_id_don) &  mi(ch_id_rec)
    label variable is_pair  "Pair"
    label variable is_chip  "Unmatched recipient"
    label variable is_alt   "Altruist"

    save ${pair_dataset`suffix'}, replace
}    
