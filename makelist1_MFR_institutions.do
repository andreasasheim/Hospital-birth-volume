//
// Import list of institutions in MFR and save as Stata-datasets to be merged
// Make two lists: Institutions with coordinates, institutions-year with number of births
//
import delimited "..\Grunnlagsdata\MFR_hovedinstnr.csv", clear

foreach var of varlist lat lon utm* {
    rename `var' `var'_inst
}
save "liste_MFR_institusjoner", replace
outsheet * using "MFR_hovedinstnr_mkoordinat.csv", comma replace

// Prepare list of hospitals for merging
import excel "..\Grunnlagsdata\Hospital_level", clear firstrow
tostring Municipality, ge(kommnr) 
replace kommnr = "0"+kommnr if strlen(kommnr)==3

keep hovedinstnr sykehus nivaa universitetssykehus kommnr
keep if hovedinstnr!=.
save "list_hospitallevels", replace


// Count the number of births per institition per year, plus hospital level
use "../Grunnlagsdata/analysefil_regforsk", clear
merge m:1 hovedinstnr using "list_hospitallevels", keepusing(nivaa kommnr)
collapse (count) N_hosp = versjon_record (first) nivaa kommnr, by(hovedinstnr faar)
save "liste_MFR_hovedinstnr_fodsler_per_aar", replace

