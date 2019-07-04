quietly do ./do/globals/load-globals.do

* First load up file of PRAs and MPs produced by compute-pra-mp.py
tempfile  pras_file

foreach ch in "nkr" "unos" "apd" {
  import delimited ${`ch'_pra_mp}, clear
  save     `pras_file', replace
  
  import delimited ${`ch'_file_sans_MP_cPRA}, clear

  count
  if inlist("`ch'","nkr","unos") {
    local mvar = "extended_id"
  }
  if "`ch'"=="apd" {
    local mvar = "idx"
  }

  merge m:1 `mvar' using `pras_file', keep(match master) nogen

  count

  export delimited ${`ch'_file_csv}, replace

}

