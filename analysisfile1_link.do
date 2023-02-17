//
// Make analysis file
//

// Prepare education to be merged
use "../Grunnlagsdata/utdanning_c_mor_far", clear
preserve
bysort lopenr_mor_c faar: keep if _n==1
drop if lopenr_mor_c == " "
keep lopenr_mor_c faar medu*
save "temp_utdanning_mor", replace
restore
preserve
bysort lopenr_far_c faar: keep if _n==1
drop if lopenr_far_c == " "
keep lopenr_far_c faar pedu*
save "temp_utdanning_far", replace
restore

use "../Grunnlagsdata/analysefil_regforsk", clear


// Add information on mother's and father's education
merge m:1 lopenr_mor_c faar using "temp_utdanning_mor"
drop _merge
merge m:1 lopenr_far_c faar using "temp_utdanning_far"
drop _merge

// Make municipaliuty and grunnkrets variables
gen kommnr = substr(grunnkrets,1,4)
gen gkrets = substr(grunnkrets,5,8)


//
// Tar inn en ekstra IV, annen definisjon.
// 
foreach max_rank of numlist 1 2 3{
	foreach ratio of numlist .05 .1{
		// Add information about expected hospital size (IV)
		display("Rank `max_rank', ratio `ratio'")
		local rr = `ratio'*100
		merge m:1 faar kommnr using "liste_kommune_og_institusjoner_rank`max_rank'_ratio`rr'", keepusing(IV* hovedinstnr* N_*)
		keep if _merge == 3
		drop _merge

		// add information about travel distance to expected hosptials
		gen IV_kommunepar_per30min_base = 0
		rename hovedinstnr hovedinstnr_faktisk
		foreach j of numlist 1/`max_rank'{
			rename hovedinstnr`j' hovedinstnr
			merge m:1 kommnr gkrets hovedinstnr using "liste_reisetid_grkrets_inst" 
			drop if _merge==2
			replace reisetid_min = 0 if hovedinstnr==.
			replace IV_kommunepar_per30min_base  = IV_kommunepar_per30min_base + reisetid_min*N_inst`j'/N_komm/30
			drop _merge hovedinstnr reisetid_min distanse_km N_inst`j'
		}
		rename hovedinstnr_faktisk hovedinstnr 
		egen IV_kommunepar_per30min = mean(IV_kommunepar_per30min_base), by(kommnr faar)
		drop IV_kommunepar_per30min_base

		drop N_hosp* N_komm 

		rename IV_kommunepar_per30min IV_kommunepar_per30min_n`max_rank'_r`rr'
		rename IV_kommunepar_per1000 IV_kommunepar_per1000_n`max_rank'_r`rr'
	}
}





///

///
///
// Add information about expected hospital size (IV)
merge m:1 faar kommnr using "liste_kommune_og_institusjoner_rank3_ratio10", keepusing(IV* hovedinstnr* N_*)
keep if _merge == 3
drop _merge

// add information about travel distance to expected hosptials
*gen IV_kommunepar_perkm  = 0
gen IV_kommunepar_per30min_base = 0
rename hovedinstnr hovedinstnr_faktisk
foreach j of numlist 1 2 3{
	rename hovedinstnr`j' hovedinstnr
	merge m:1 kommnr gkrets hovedinstnr using "liste_reisetid_grkrets_inst" 
	drop if _merge==2
	replace reisetid_min = 0 if hovedinstnr==.
	replace IV_kommunepar_per30min_base  = IV_kommunepar_per30min_base + reisetid_min*N_inst`j'/N_komm/30
	rename hovedinstnr hovedinstnr_rank`j'
	rename reisetid_min reisetid_min_rank`j'
	drop _merge distanse_km N_inst`j'
}
rename hovedinstnr_faktisk hovedinstnr 
egen IV_kommunepar_per30min = mean(IV_kommunepar_per30min_base), by(kommnr faar)





// Add traveltime and -distance from residence(grunnkrets) to birth institution
merge m:1 kommnr gkrets hovedinstnr using "liste_reisetid_grkrets_inst"
drop if _merge ==2
drop _merge
replace reisetid_min = reisetid_min/10
rename reisetid_min reisetid_10min
gen reisetid_30min = reisetid_10min/3




// Add information about actual hospital size
merge m:1 faar hovedinstnr using "liste_MFR_hovedinstnr_fodsler_per_aar"
keep if _merge == 3
drop _merge

// Add municipality area and population
merge m:1 kommnr using "liste_kommuner_m_koordinat", keepusing(befolkning areal)
drop _merge

// Make an id-variable
gen fodsel_id = _n




save "analysefil_kommunepar_full", replace










