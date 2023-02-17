// This code takes the list of all pairs of neighboring municipalities and a list of all pairs of
// neigboring grunnkrets (subdivisions of municipalities) and computes, for each grunnkrets, 
// how many steps from grunnkrets to grunnkrets (border crossings) is neccessary to get to any of 
// the neighboring municipalities.
// I.e., given "grunnkrets_id" and "nabo_nr" (municipality id for a neghboring municipality),
// this list can be queried to say how close those two are, topologically speaking.


// Make an empty dataset, which will be appended through the interation over municipality pairs
drop *
set obs 1
gen steg = .
save "liste_grunnkrets_kommunenabo", replace

// Import and prepare the list of grunnkrets-pairs
import delimited "..\Grunnlagsdata\Grunnkretsnaboer.txt", delim(";") clear
destring length, dpcomma replace
drop if length == 0
drop length node* objectid
rename (src_grunnkretsid_grunnkretsnr src_grunnkretsid_grunnkretsnavn) (grunnkrets_id grunnkrets_navn)
rename (nbr_grunnkretsid_grunnkretsnr nbr_grunnkretsid_grunnkretsnavn) (nabogrunnkrets_id nabogrunnkrets_navn)
tostring src_komm, replace
replace src_komm = "0"+src_komm if strlen(src_komm)==3
tostring nbr_komm, replace
replace nbr_komm = "0"+nbr_komm if strlen(nbr_komm)==3
save "liste_grunnkretsnaboer", replace

// Make list of grunnkrets
use grunnkrets_id src_komm using "liste_grunnkretsnaboer", clear
bysort grunnkrets_id: gen n = _n
keep if n==1
drop n
rename src_komm kommnr
tostring kommnr, replace
replace kommnr = "0"+kommnr if strlen(kommnr)==3
sort kommnr grunnkrets_id
save "liste_grunnkretser", replace



// Loop over all municipality pairs.
// For all grunnkrets within the two municipalities, find the least number of
// grunnkrets-borders to cross to get to the neighboring municipality
use "liste_kommunenaboer", clear
local N_pairs = _N
forval j = 1/`N_pairs'{
	// Select the pair of neighboring municipalities
	use "liste_kommunenaboer", clear
	local kommune1 = kommnr[`j']
	local kommune2 = nabonr[`j']
	// Import the list of all pairs of grunnkrets-neighbor-pairs
	use "liste_grunnkretsnaboer", clear

	// Keep only those grunnkrets-pairs where both grunnkrets in the pair are in  
	// one of the two municipalities of the municipality-pair
	gen kommnr = "`kommune1'"
	gen nabonr = "`kommune2'"
	gen     behold = 1 if (src_komm == kommnr)&(nbr_komm == nabonr)
	replace behold = 1 if (src_komm == nabonr)&(nbr_komm == kommnr)
	replace behold = 1 if (src_komm == kommnr)&(nbr_komm == kommnr)
	replace behold = 1 if (src_komm == nabonr)&(nbr_komm == nabonr)
	keep if behold == 1
	
	// Tag a pair if the grunnkrets are in different municipalities
	gen nabo = 1 if nbr_kom!= src_komm
	drop src* nbr*

	// Tag the grunnkrets (not only the pair) as beeing one step from the next municipality
	// The information on the number of steps will kept on grunnkrets_id (not the other in the pair)
	egen steg = max(nabo), by(grunnkrets_id)

	// Save the list of grunnkrets pairs with a variable steg that says how many steps the next municipality is
	// This list will be modified by adding steps 2,3,4,..
	drop nabo behold
	save "temp_grunnkretsnaboer", replace

	local videre = 1
	local teller = 0
	while `videre' {
		// From the list of grunnkrets pairs, make a list of grunnkrets and how many steps. 
		sort grunnkrets_id
		by grunnkrets_id: gen behold = _n==1
		keep if behold
		drop behold nabogrunnkrets*
		keep if steg != .
		rename grunnkrets_id nabogrunnkrets_id // Renamed for merging
		rename steg hopp
		save "temp", replace

		// Merge the list of grunnkrets-pairs with the list of grunnkrets with a neighboring municipality. 
		// By merging on the neighboring municipality, we get the second order neighbors(neighbors' neighbor) 
		use "temp_grunnkretsnaboer", clear
		merge m:1 nabogrunnkrets_id using "temp"
		drop _merge
		// Make sure that all pairs with the same grunnkrets_id has information on the number of steps from its 
		// neighbor to the next municipality
		egen hopp2 = max(hopp), by(grunnkrets_id)
		// Now the number of steps for grunnkrets_id is the nuber of steps for it's neighbor +1
		// The list of pairs is now updated with one extra potential step.
		replace steg = hopp2+1 if steg ==.
		drop hopp*
		save "temp_grunnkretsnaboer", replace
			
		// Stop the loop if all grunnkrets has had the number of steps computed
		count if steg==.
		local videre = r(N)
		local teller = `teller'+1
		if `teller'>30{
			local videre = 0
		}
	}
	// From grunnkrets-pairs, make a list of each grunnkrets in the municipality-pair
	// with the number of steps to the neighboring municipality
	sort grunnkrets_id
	by grunnkrets_id: gen behold = _n==1
	keep if behold
	drop behold nabogrunnkrets*
	// Append to the large list.
	append using "liste_grunnkrets_kommunenabo"
	save "liste_grunnkrets_kommunenabo", replace
	di `j'
}
// This should drop only the one fake initial observation
drop if steg == .


// Make sure that each grunnkrets is in the municipality kommune_nr
// Up to here, grunnkrets is assigned to pairs. The following code therefore halves 
// the size of the dataset
sort kommnr grunnkrets_id
merge m:1 kommnr grunnkrets_id using "liste_grunnkretser"
keep if _merge == 3
drop _merge

// Make grunnkrets-id variable compatible with MFR
gen gkrets = grunnkrets_id-floor(grunnkrets_id/10000)*10000
tostring gkrets, replace
replace gkrets = "0"+gkrets if strlen(gkrets)==3

save "liste_grunnkrets_kommunenabo", replace




