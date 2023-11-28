* This do file replicates Figure 1 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 15, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Clean Data
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Re-scale two variables of interest
gen corporate_rate_scaled = corporate_rate/100
gen r_g = rev_corptax/GDP*100


********************************************************************************
**# Panel A
********************************************************************************

* Keep only 50 states in four years
drop if fips_state == 0 | fips_state == 11 | fips_state > 56
keep if inlist(year, 1980, 1990, 2000, 2010)

preserve

* Construct x axis
sort year fips_state
scalar xaxis_max = 0.12
gen id = mod(_n - 1, 50) + 1
replace id = id/50
gen xaxis = id*xaxis_max

tempfile pA
save `pA', replace

* Estimate kernel density for each year
foreach year in 1980 1990 2000 2010 {
	use `pA', clear
	keep if year == `year'
	kdensity corporate_rate_scaled, gen(x_corporate_rate_scaled kd_corporate_rate_scaled_`year') at(xaxis) nograph
	keep fips_state year kd*
	tempfile pA_`year'
	save `pA_`year'', replace
}

use `pA', clear
foreach year in 1980 1990 2000 2010 {
	merge 1:1 fips_state year using `pA_`year'', nogen
}

* Plot
twoway (line kd_corporate_rate_scaled_1980 xaxis, c(l) lcolor(black) lwidth(medthick)) ///
	(line kd_corporate_rate_scaled_1990 xaxis, c(l) lcolor(black) lpattern(dash) lwidth(medthick)) ///
	(line kd_corporate_rate_scaled_2000 xaxis, c(l) lcolor(gs9)) ///
	(line kd_corporate_rate_scaled_2010 xaxis, c(l) lcolor(gs9) lpattern(dash)), ///
	title("A) State Corporate Tax Rate") ///
	xtitle("State Corporate Tax Rate", size(medlarge)) ///
	ytitle("Kernel Density", size(medlarge)) ///
	ylab(, nogrid) xlab(0(0.03)0.12, nogrid) ///
	legend(label(1 "1980") label(2 "1990") label(3 "2000") label(4 "2010") size(medlarge) position(6) row(1) region(lc(gs9))) ///
	name(panelA, replace)

restore


********************************************************************************
**# Panel B
********************************************************************************

preserve

* Construct x axis
sort year fips_state
scalar xaxis_max = 1.1
gen id = mod(_n - 1, 50) + 1
replace id = id/50
gen xaxis = id*xaxis_max

tempfile pB
save `pB', replace

* Estimate kernel density for each year
foreach year in 1980 1990 2000 2010 {
	use `pB', clear
	keep if year == `year'
	kdensity r_g, gen(x_r_g kd_r_g_`year') at(xaxis) nograph
	keep fips_state year kd*
	tempfile pB_`year'
	save `pB_`year'', replace
}

use `pB', clear
foreach year in 1980 1990 2000 2010 {
	merge 1:1 fips_state year using `pB_`year'', nogen
}

* Plot
twoway (line kd_r_g_1980 xaxis, c(l) lcolor(black) lwidth(medthick)) ///
	(line kd_r_g_1990 xaxis, c(l) lcolor(black) lpattern(dash) lwidth(medthick)) ///
	(line kd_r_g_2000 xaxis, c(l) lcolor(gs9)) ///
	(line kd_r_g_2010 xaxis, c(l) lcolor(gs9) lpattern(dash)), ///
	title("B) Corporate Tax Revenue as a Share of GDP") ///
	xtitle("Corporate Tax Revenue as a Share of GDP", size(medlarge)) ///
	ytitle("Kernel Density", size(medlarge)) ///
	ylab(, nogrid) xlab(0(0.1)1.1, nogrid) ///
	legend(label(1 "1980") label(2 "1990") label(3 "2000") label(4 "2010") size(medlarge) position(6) row(1) region(lc(gs9))) ///
	name(panelB, replace)

* Combine and export
graph combine panelA panelB, row(2) xsize(7) ysize(10)
graph export "Figures/Figure1.svg", replace