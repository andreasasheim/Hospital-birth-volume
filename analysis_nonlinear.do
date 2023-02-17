
use "analysefil_kommunepar", clear

gen bef_tetthet = befolkning /areal
local innenmor faar alderkat* paritetkat*
local kommunepar faar alderkat* paritetkat* medukat*
local innenmor_befolkning faar alderkat* paritetkat* bef_tetthet befolkning
local justeringer innenmor kommunepar innenmor_befolkning


*local idlist  id_innenmor  id_N100_chi2p100_diffp20 id_N100_chi2p100_diffp90


local idlist id_innenmor id_kommunepar_alle id_alle id_kommunepar_N100 id_kommunepar_steg3




// Sett opp IV og levels
gen IV_vol  = IV_kommunepar_per1000*1000
gen IV_dist = IV_kommunepar_per30min*30

levelsof(IV_vol), local(levels_vol)
levelsof(IV_vol), local(levels_vol_temp)
levelsof(IV_dist), local(levels_dist) 
levelsof(IV_dist), local(levels_dist_temp)

foreach ii of local levels_dist_temp{
	if `ii'>240 {
		local levels_dist: list levels_dist - ii		
	}
}

mkspline spl_vol  = IV_vol, cubic nknots(4) displayknots
mkspline spl_dist = IV_dist, cubic nknots(4) displayknots

ppmlhdfe outcome_b_perinataldeath alderkat* paritetkat* medukat* faar spl_vol* spl_dist* , absorb(id_kommunepar_alle) vce(cluster kommune_int lopenr_mor_c) irr d
// Volume
levelsof(IV_vol), local(levels)
xblc spl_vol*, cov(IV_vol) at(`levels') eform reference(500) line
// Travel time
levelsof(IV_dist), local(levels)
xblc spl_vol*, cov(IV_dist) at(`levels') eform reference(30) line


ppmlhdfe outcome_b_perinataldeath alderkat* paritetkat* faar spl_vol* spl_dist* , absorb(id_innenmor) vce(cluster kommune_int lopenr_mor_c) irr d
// Volume
levelsof(IV_vol), local(levels)
xblc spl_vol*, cov(IV_vol) at(`levels') eform reference(500) line
// Travel time
levelsof(IV_dist), local(levels)
xblc spl_vol*, cov(IV_dist) at(`levels') eform reference(30) line
