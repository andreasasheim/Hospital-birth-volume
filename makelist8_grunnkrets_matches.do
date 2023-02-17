// 
// Takes list of municipality matches, determines which grunnkrets that are included
//

// Set seed for replicability
set seed 314159

// Add grunnkrets to municipality match file
gen faar = .
save "temp", replace
forval aar = 1999/2016{
	use "kommunematcher", clear	
	keep if faar == `aar'
	merge 1:m kommnr nabonr using "liste_grunnkrets_kommunenabo", keepusing(gkrets steg)
	keep if _merge==3
	drop _merge
	append using "temp"
	save "temp", replace
}

gen nevermatched = 1
foreach match of varlist match_*{
    	// Make an id-variable that is identical to id_pair_year.
	// Make it missing if the pair is not to be use in comparisons
    	local idname     = "id_" + substr("`match'",7,.)
	gen `idname'     = id_pair_year
	replace `idname' = . if `match' == 0
	
	// Each grunnkrets shall be in one matched pair, i.e., match with the closest border
	// Therefore, find the closest border among the municipalities that are a match
	egen min = min(steg), by(kommnr gkrets faar `match')
	replace `idname' = . if min!=steg
	
	// If a grunnkrets is equidistant from two municipalities, pick one at random 
	gen sortorder = runiform()
	sort kommnr gkrets faar `match' sortorder
	by kommnr gkrets faar `match': gen n = _n if `idname'!=.
	replace `idname' = . if n>1
	drop min n sortorder
	replace nevermatched = 0 if `idname' != .
}
drop if nevermatched   // Keep only combnations that are in use (save some space)
drop match_* nevermatched


// In this file, each id is unique by grunnkrets  if not missing
// To match onto births, we remove missing

save "grunnkretsmatcher", replace



// Make list of all grunnkrets-year combination, add id-variables to be used for different matchings
use "../Grunnlagsdata/analysefil_regforsk", clear
gen kommnr = substr(grunnkrets,1,4)
gen gkrets = substr(grunnkrets,5,8)
keep gkrets kommnr faar
bysort kommnr gkrets faar: keep if _n==1
save "liste_grunnkrets_m_kommuneparid", replace

use "grunnkretsmatcher", clear
drop id_pair_year
foreach id of varlist id_*{
	preserve
	di "`id'"
	keep if `id' !=.
	keep `id' gkrets kommnr faar steg
	local stegname     = "steg_"+substr("`id'",4,.)
	rename steg `stegname'
	
	merge 1:m kommnr gkrets faar using "liste_grunnkrets_m_kommuneparid"
	drop if _merge==1
	drop _merge
	save "liste_grunnkrets_m_kommuneparid", replace
	restore
}

use "liste_grunnkrets_m_kommuneparid", clear



