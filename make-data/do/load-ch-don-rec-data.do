args a1 a2
tokenize "`a1'", parse("=")
if ("`1'"!="clearinghouse") | !inlist("`3'","nkr","apd","unos","sa") {
  di as error "Argument not of form clearinghouse=nkr/apd/unos/sa."
  exit 111  
}
local ch     = "`3'"

tokenize "`a2'", parse("=")
if ("`1'"!="suffix") | !inlist("`3'","_don","") {
  di as error "Argument not of form suffix=don/(nothing)."
  exit 111  
}
local suffix     = "`3'"
di "`suffix'"

* Get `ch'Historical file, created by py/parse-snapshots.py
    import delimited ${`ch'_file}, clear

* Recode the HLA Files (since each row is either a donor or a recip at this point, there is only one HLA vector to recode
    recode_hla a b dr 

* Rename variables to be more in line with KIDPAN
    ren   (extended_id  sex     bloodtype   center_star  transplanteddate  )     ///
          (`ch'_id       gender  abo_coarse  tx_ctr_id    tx_date          )

if "`ch'"=="unos" {
  assert mi(gender)
  drop gender
  gen gender=""
}

* Convert tx_date from string to Stata dates
    gen    tx_date2       = date(tx_date, "MDY")
    format tx_date2 %td
    drop   tx_date
    ren    tx_date2 tx_date

* Convert arr_date_min from string to Stata dates
    gen    arr_date2       = date(arr_date_min, "MDY")
    format arr_date2 %td
    drop   arr_date_min
    ren    arr_date2 arr_date_min

* Convert dep_date_max from string to Stata dates
    gen    dep_date2       = date(dep_date_max, "MDY")
    format dep_date2 %td
    drop   dep_date_max
    ren    dep_date2 dep_date_max

* In `ch'Historical, each transplant is represented by two rows: one for the donor and one for the recipient.  We will
* keep only the donor rows and merge in the pertinent data from the previous tempfile.
    egen num_tx = sum(!mi(tx_id)), by(index)
    if ("`suffix'"=="_don"){
        keep if isdonor==1
    }
    else {
        keep if isdonor==0
    }
    *keep if mi(tx_date)
    keep if mi(tx_id)
    keep  a1 a2 b1 b2 dr1 dr2 `ch'_id ///
              gender              abo_coarse      tx_ctr_id     tx_date       age       arr_date_min  ///
              dep_date_max        index           unpaired      alt           num_tx
                        
    ren (     gender              abo_coarse             tx_ctr_id       tx_date       age             arr_date_min    ///
              dep_date_max        unpaired      alt             num_tx       )  ///
        ( `ch'_gender`suffix'   `ch'_abo_coarse`suffix'  `ch'_tx_ctr_id   `ch'_tx_date   `ch'_age`suffix'  `ch'_arr_date_min    ///
          `ch'_dep_date_max  `ch'_unpaired  `ch'_alt_don     `ch'_num_tx)
    di "Suffix: `suffix'"
    if ("`suffix'"=="_don"){
      di "Howdy don!"
      ren `ch'_id           `ch'_id_don
      ren index `ch'_index_don
      drop `ch'_unpaired
    }
    else {
      di "Howdy rec!"
      ren `ch'_id `ch'_id_rec
      ren index  `ch'_index_rec
      drop `ch'_alt_don
    }
    foreach var of varlist a1 a2 b1 b2 dr1 dr2 {
        ren 	`var' 	`ch'_`var'`suffix'
    }
  if "`ch'"=="apd" {
    replace apd_gender`suffix' = "F" if apd_gender`suffix'=="Female"
    replace apd_gender`suffix' = "M" if apd_gender`suffix'=="Male"
  }
		
