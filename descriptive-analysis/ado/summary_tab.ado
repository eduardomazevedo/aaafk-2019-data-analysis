*** Generates a summary table
* Stores the output in outdir/filestub.dta and outdir/filestub.xls
*  Arguments, in this order
  * vars = variables to summarize
  * by_vars = categories
  * outdir = output directory
  * filestub = stub of the filenames to use
  * sheetname = sheet for the excel file

program define summary_tab
  args vars  by_vars  outdir  filestub  sheetname

  preserve
    clear
    set obs 0
    gen statistic = ""
    save "`outdir'/`filestub'", replace
  restore

  * Loop over count mean and sd
  foreach statistic in count mean sd {
    preserve
      * Collapse and append
      collapse (`statistic') `vars', by(`by_vars')
      gen stat = "`statistic'"
      append using "`outdir'/`filestub'"
      save "`outdir'/`filestub'", replace
    restore
  }

  * Sort the statistics, save and export
  preserve
    use "`outdir'/`filestub'", clear  
    gen     stat_order = 0 if        stat == "count"
    replace stat_order = 1 if        stat == "mean"
    replace stat_order = 2 if        stat == "sd"
    * sort by category and stat_order
    sort `by_vars' stat_order
    order stat_order `by_vars' stat
    save "`outdir'/`filestub'", replace

    * Export to excel
    export excel using "`outdir'/`filestub'.xls", sheet("`sheetname'") firstrow(varlabels) sheetreplace
  restore

end
