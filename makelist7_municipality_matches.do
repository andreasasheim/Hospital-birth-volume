// 
// Combines hospital use per municipality-year with list of municipality pairs 
// Makes a list of municipalitypair-years that will be analysed, based on differences
// in hospital use
//

cls
cd "N:\durable\regforsk\Kommunepar\Data"


// Make temp file with births, year, institutions, municipalities
use "../Grunnlagsdata/analysefil_regforsk", clear
gen kommnr = substr(grunnkrets,1,4)
keep kommnr faar hovedinstnr

save "temp", replace


// Take list of all pairs of municipalities, compute a chi2-test on 
// the table of hospital use in the pair (not used)
use "liste_kommunenaboer", clear
local N = _N
drop *
set obs 1
gen faar = .
forval j = 1/`N'{
    save "temp_naboer", replace
    // Pick one pair to be tested
	use "liste_kommunenaboer", clear
	keep if _n==`j'
	rename (kommnr nabonr) (kommnr1 kommnr2)
	reshape long kommnr, i(id_pair) j(kommunepar)
	merge 1:m kommnr using "temp",  keep(3)
	drop _merge

	// Tabulate and compute chi2-test for the selected municipality pair
	gen p_chi2 = .
	foreach aar of numlist 1999/2016{
		tab hovedinstnr kommnr if faar == `aar', chi2
		replace p_chi2 = r(p) if faar == `aar'	
	}
	drop hovedinstnr
	sort faar kommunepar
	by faar kommunepar: keep if _n==1
	reshape wide kommnr, i(id_pair faar) j(kommunepar)
	rename (kommnr1 kommnr2) (kommnr nabonr) 
	
	append using "temp_naboer"
}
drop if faar ==. | kommnr=="" | nabonr==""
save "temp_naboer", replace



// List of municipalities having or bordering a municipality with hospital

use "liste_MFR_hovedinstnr_fodsler_per_aar", clear
collapse (sum) sykehuskommune = N_hosp, by(kommnr faar)
drop if kommnr =="." | faar==. | kommnr ==""
replace sykehuskommune = 1 if sykehuskommune>1
save "temp_fodsler_i_kommunen", replace
merge 1:m kommnr faar using "temp_naboer", keepusing(nabonr)
drop _merge
rename (kommnr nabonr sykehuskommune) (kommnr1 kommnr sykehuskommune1)
merge m:1 kommnr faar using "temp_fodsler_i_kommunen", keepusing(sykehuskommune)
rename (kommnr1 kommnr sykehuskommune sykehuskommune1) (kommnr nabonr sykehuskommunenabo sykehuskommune)
collapse (max) sykehuskommune sykehuskommunenabo, by(kommnr faar)
save "temp_sykehuskommuner", replace

	
// Add information on municipalities in the pairs
use "temp_naboer", clear
rename (kommnr nabonr) (kommnr1 kommnr)
merge m:1 kommnr faar using "liste_kommune_og_institusjoner", keepusing(hovedinstnr1 ratio1 nivaa1 N_komm)
drop if _merge == 2
drop _merge
merge m:1 kommnr using "liste_reisetid_universitetssykehus", keepusing(reisetid_*)
drop if _merge == 2
drop _merge
gen rank_dist = 1
merge m:1 kommnr rank_dist faar using "liste_reisetid_kommune_inst_closest", keepusing(reisetid_min)
drop if _merge ==2
drop _merge rank_dist
merge m:1 kommnr faar using "temp_sykehuskommuner"
drop if _merge==2
drop _merge

rename sykehuskommune sykehuskommune_nabo
rename sykehuskommunenabo sykehuskommunenabo_nabo
rename reisetid_min reisetid_min_rank1_nabo
rename reisetid_unisykehus reisetid_unisykehus_nabo
rename hovedinstnr1 hovedinstnr1_nabo
rename ratio1 p_rank1_nabo
rename nivaa1 nivaa_rank1_nabo
rename N_komm N_komm_nabo

rename (kommnr1 kommnr) (kommnr nabonr)
merge m:1 kommnr faar using "liste_kommune_og_institusjoner", keepusing(hovedinstnr1 ratio1 nivaa1 N_komm)
drop if _merge == 2
drop _merge
merge m:1 kommnr using "liste_reisetid_universitetssykehus", keepusing(reisetid_*)
drop if _merge ==2
drop _merge
gen rank_dist = 1
merge m:1 kommnr rank_dist faar using "liste_reisetid_kommune_inst_closest", keepusing(reisetid_min)
drop if _merge ==2
drop _merge rank_dist
rename ratio1 p_rank1
rename nivaa1 nivaa_rank1
rename reisetid_min reisetid_min_rank1
merge m:1 kommnr faar using "temp_sykehuskommuner"
drop if _merge==2
drop _merge

// Make variable that indicates difference in proportion at top ranked hospital
// It is 1 if the municipalities have a different top ranked hospital
gen p_diff = 1
replace p_diff = abs(p_rank1-p_rank1_nabo) if hovedinstnr1 == hovedinstnr1_nabo


//
// Variables that indicate that the pair is eligible for matching, may run variations for sensitivity
//
foreach p_diff of numlist 0 0.2 .9{  
		local pd  = `p_diff'*100
		// Selection from chi2 and difference in proportions
		gen ppmatch = p_diff>`p_diff'
		
		// Matches on differences in hospital use
		gen match_diffp`pd'    = ppmatch
		
		// Matches, conditional on municipality size
		foreach Nmax of numlist 100{ 
		    gen small_pair = N_komm<`Nmax' & N_komm_nabo<`Nmax'
			gen match_N`Nmax'_diffp`pd'    = ppmatch & small_pair
			drop small_pair
		}	
		
		// Matches, conditional on traveltime to university hospital
		foreach tmin of numlist 45 60 90{ 
		    gen pair = reisetid_unisykehus>`tmin' & reisetid_unisykehus_nabo>`tmin'
			gen match_Tuni`tmin'_diffp`pd'    = ppmatch & pair
			drop pair
		}	
				
		gen pair = sykehuskommune==. & sykehuskommune_nabo==.
		gen match_nohosp_diffp`pd'    = ppmatch & pair
		drop pair
		
		gen pair = sykehuskommune==. & sykehuskommune_nabo==. & sykehuskommunenabo==. & sykehuskommunenabo_nabo==.
		gen match_nohosp_neigh_diffp`pd'    = ppmatch & pair
		drop pair
			
		
		drop ppmatch

	}
}

// Make the id-variable that groups municipality-pair-years
egen id_pair_year = group(id_pair faar)

keep kommnr nabonr faar id_pair_year match_*
save "kommunematcher", replace

