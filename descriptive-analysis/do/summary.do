   * Selection in levels, and does it vary with participation and size.

*** Load the ado library
prog drop _allado
sysdir set PERSONAL ./ado/

*** Start ***
  set more off
  graph drop _all

  * Files
  local dataset      = "./datasets/pair-level-data-full.dta"
  *local star_dataset = "~/orgad-star/raw-extract-3/KIDPAN_DATA.DTA"
  local star_dataset = "./raw-files/star/KIDPAN_DATA.DTA"

*** Summary statistics for deceased donor pool
  use `star_dataset', clear
  drop if init_date < date("04/02/2012","MDY") | init_date>= date("12/04/2014","MDY") 
  replace abo_don = "" if don_ty ~= "C"

  * Blood Types
  abo_dum abo      r_abo
  abo_dum abo_don  d_abo

  * PRA
  gen pra = end_cpra

  gen category = "Deceased List"

*** Generates a summary table with count, mean, sd
* Stores the output in outdir/filestub.dta and outdir/filestub.xls
*  Arguments, in this order
  * vars = variables to summarize
  * by_vars = categories
  * outdir = output directory
  * filestub = stub of the filenames to use
  * sheetname = sheet for the excel file

summary_tab "r_abo* d_abo* pra"        ///
            "category"                 ///
            "./intermediate-tables/"   ///
            "nkr-submissions-summary"  ///
            "summ_deceased_don"


*** Summary for submissions ***
  clear
  use `dataset'

** Keep sample of registrations starting from 2012
  drop if _nr_arr_date_min < date("04/02/2012","MDY") & !mi(_nr_arr_date_min)
  drop if _nd_arr_date_min < date("04/02/2012","MDY") & !mi(_nd_arr_date_min)


** Generate variables to summarize

  * abo_dum generates dummies from abo
  * First arugment is abo field and second argument is output abo

  * Pra
  gen pra = _nr_cpra

  *abo_dum _nr_bloodtype  r_abo
  *abo_dum _nd_bloodtype  d_abo
  abo_dum _nr_abo_coarse  r_abo
  abo_dum _nd_abo_coarse  d_abo

  gen underdemanded = ((r_abo_O == 1 & d_abo_O == 0) | (d_abo_AB==1 & r_abo_AB==0))  if is_pair == 1
  gen overdemanded  = ((r_abo_O == 0 & d_abo_O == 1) | (d_abo_AB==0 & r_abo_AB==1))  if is_pair == 1

  * Category
  gen     category = "nkr pair"        if is_pair & ch=="nkr"
  replace category = "nkr chip"        if is_chip & ch=="nkr"
  replace category = "nkr altruistic"  if is_alt  & ch=="nkr"
  replace category = "apd pair"        if is_pair & ch=="apd"
  replace category = "apd chip"        if is_chip & ch=="apd"
  replace category = "apd altruistic"  if is_alt  & ch=="apd"
  replace category = "unos pair"       if is_pair & ch=="unos"
  replace category = "unos chip"       if is_chip & ch=="unos"
  replace category = "unos altruistic" if is_alt  & ch=="unos"

  * Match Power
  gen mp           = _nr_mp_strict
  gen mp_noabo     = _nr_mp_strict_noabo
  gen mp_don       = _nd_mp_strict
  gen mp_don_noabo = _nd_mp_strict_noabo

*** Save a file with the summary statistics, by submissions

*** Generates a summary table with count, mean, sd
* Stores the output in outdir/filestub.dta and outdir/filestub.xls
*  Arguments, in this order
  * vars = variables to summarize
  * by_vars = categories
  * outdir = output directory
  * filestub = stub of the filenames to use
  * sheetname = sheet for the excel file
summary_tab "r_abo* d_abo* mp* pra overdemanded underdemanded"  ///
            "category"                                          ///
            "./intermediate-tables/"                            ///
            "nkr-submissions-summary"                           ///
            "summ_raw"


