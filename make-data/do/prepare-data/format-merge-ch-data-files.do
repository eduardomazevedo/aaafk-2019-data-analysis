clear all 
set more off

quietly do ./do/globals/load-globals.do

foreach ch in "nkr" "apd" "unos" {
  *local ch = "unos"
  import delimited ${`ch'_file_csv}, clear
  gen ch="`ch'"

  adopath + "./do"
  recode_hla a b dr 
  unab datevars: *date*
  if "`ch'"!="apd" {
    local datevars "`datevars' registered"
  }
  d `datevars'
  di "`ch'"
  foreach dv of varlist `datevars' { 
    capture confirm string var `dv'
    if _rc==0{
      gen    temp_date       = date(`dv', "MDY")
      drop   `dv'
      ren    temp_date `dv'
    }
    format `dv' %td
  }
  
  gen  index_st = string(index,"%12.0f")
  drop index
  ren  index_st index
  replace    index =    index+"-`ch'" if !mi(index)
  egen fam_size = sum(!mi(   id)), by(index)

  gen  id_st = string(id, "%12.0f")
  drop id
  ren  id_st id
  replace    id =    id+"-`ch'" 

  replace extended_id = extended_id+"-`ch'" 
  replace tx_id = tx_id+"-`ch'" if !mi(tx_id)
  
  gen famid_st=""
  capture confirm var famidx, exact
  if _rc==0 {
    replace famid_st = famidx
    drop famidx
  }
  capture confirm var famid, exact
  if _rc==0 {
    replace famid_st = string(famid)
    drop famid
  }
  gen famid  = famid+"-`ch'" 
  ren   (extended_id  sex     bloodtype   transplanteddate  center_star )     ///
        (ch_id        gender  abo_coarse  tx_date           tx_ctr_id   )
  
  egen num_tx   = sum(!mi(tx_id)), by(index)

  if "`ch'"=="nkr" {
    di "NKR"
    drop antidrw
    drop antidpa
    drop antidqa
    gen  insnapshots_st = string(insnapshots)
    drop insnapshots
    ren  insnapshots_st insnapshots
  }

  if "`ch'" == "unos" {
    di "UNOS"
    //drop gender here
    drop alias
    drop antidrw
    drop antidpa
    drop relateddonors
    drop dialysisstartdate
    drop unoslistdate
    drop hard_blocked_donors
    gen     race_st = "Other"
    replace race_st = "Caucasian" if race==1
    replace race_st = "Black"     if race==2
    replace race_st = "Latino"    if race==4
    replace race_st = "Asian"     if race==5
    drop    race
    ren     race_st race
    gen  center_st = string(center)
    drop center
    ren  center_st center
    gen  antibw_st = string(antibw)
    drop antibw
    ren  antibw_st antibw
    drop num_tx
    egen num_tx   = sum(!mi(tx_id) | donated_to_wl==1), by(index)
  }
  if "`ch'"=="apd"{
    di "APD"
    drop race
    drop alias
    gen  antibw_st = string(antibw)
    drop antibw
    ren  antibw_st antibw
    drop anticw
    replace gender = "F" if gender=="Female"
    replace gender = "M" if gender=="Male"
  }
  save ${`ch'_file}, replace
}

use           $nkr_file
append using $unos_file
append using  $apd_file

order id

save $all_ch_file, replace
