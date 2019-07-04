set more off

quietly do ./do/globals/load-globals.do

drop _all // START WITH AN EMPTY DATA SET
set obs 1
gen name    = ""
gen content = ""

local o = 1
foreach n in star_histo_pre_union    star_histo              nkr_file                apd_file       ///
             star_pra_mp             nkr_pra_mp              apd_pra_mp              unos_pra_mp    ///
             apd_file_sans_MP_cPRA   nkr_file_sans_MP_cPRA   nkr_star_ctr_dict                      ///
             nkr_star_ctr_dict_csv   apd_file_pre_conv       unos_file_sans_MP_cPRA  unos_file      ///
             nkr_file_csv            unos_file_csv           apd_file_csv            compat_matrix  ///
             initial_hard_block_file weak_file               strict_file             exclusion_crit_file {
  replace name    =   "`n'"  in `o'
  replace content = "${`n'}" in `o'
  local o = `o'+1
  set obs `o'
}

drop if mi(name)

list // SEE WHAT YOU GOT

export delimited $globals_for_py_code, replace

