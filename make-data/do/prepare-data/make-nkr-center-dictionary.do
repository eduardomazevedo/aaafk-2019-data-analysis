
*
*   Makes a dictionary to translate nkr center names into STAR center ids. I am just taking a .txt file that nikhil had which did that, and saving as a sata file.
*       Created by edu on 2016-05
*

* Files
    * Input:    Pipe delimited file.  Each row is a transplant center and 
    *           contains the UNOS/STAR id (tx_ctr_id) as well as alternate 
    *           designations used by both UNOS and NKR.  Not all transplant 
    *           centers deal with NKR, so not all with have NKR designations.
        
    *
    * Output:   dta where each row is a transplant center that deals with NKR 
    *           and contains the designations used by both UNOS/STAR and NKR
        

* Start
    set more off
    clear
    do ./do/globals/load-globals.do
    
* Load data
    import  delimited $nkr_star_ctr_names, delimiter("|") varnames(1) // encoding(ISO-8859-1)
    drop    tx_ctr
    
* Reshape so that there is a row for each UNOS/STAR ID - NKR designation        ///
* combination.  There will be rows that share a UNOS/STAR id, but that have a   ///
* different NKR designation.
    rename  nkr_name        nkr_name1
    rename  nkr_name_alt    nkr_name2
    reshape long nkr_name, i(tx_ctr_id)
    drop _j

* Drop duplicates
    drop if mi(nkr_name)
    duplicates drop

* Arrange and sort
    order   nkr_name
    sort    nkr_name    tx_ctr_id
    
* Rename
    rename  nkr_name    nkr_center_name
    rename  tx_ctr_id   star_center_id
    
* Manually add names
    local   new = _N + 1
    set     obs `new'
    replace nkr_center_name = "SCarolina"   if _n == _N
    replace star_center_id  = "SCMU-TX"     if _n == _N
    
    local   new = _N + 1
    set     obs `new'
    replace nkr_center_name = "UMinn"       if _n == _N
    replace star_center_id  = "MNUM-TX"     if _n == _N
    
    sort    nkr_center_name

* Check if is id
    isid    nkr_center_name 
    
* Save
    save              $nkr_star_ctr_dict,     replace
    export delimited  $nkr_star_ctr_dict_csv, replace
