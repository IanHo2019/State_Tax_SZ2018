* This do file replicates Figure 3 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 15, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in 1980-2010
drop if fips_state == 0 | fips_state == 11 | fips_state > 56
keep if inrange(year, 1980, 2010)

* Re-scale some variables
replace sales_wgt = sales_wgt/100
replace payroll_wgt = payroll_wgt/100


********************************************************************************
**# Panels A, B, C
********************************************************************************

preserve

* Weighted by mean state GDP across periods
bysort fips_state: egen mean_GDP = mean(GDP)

* Calculate weighted means
collapse (mean) rec_val investment_credit Losscarryforward Losscarryback payroll_wgt sales_wgt [aw = mean_GDP], by(year)

* Panel A: Tax Credits
line rec_val investment_credit year, ///
	lc(black black) lpattern(solid dash) lwidth(medthick medthick) ///
	xti("Year", size(medsmall)) ///
	yti("Average Rate", size(medsmall)) ///
	xlab(, nogrid) ylab(, angle(90)) ///
	legend(label(1 "R&D Credit") label(2 "Investment Credit") size(*0.8) row(1) position(6) span region(lc(gs9)))
graph export "Figures/Figure3_A.svg", replace

* Panel B: Loss Rules
line Losscarryforward Losscarryback year, ///
	lcolor(black black) lpattern(solid dash) lwidth(medthick medthick) ///
	xti("Year", size(medsmall)) ///
	yti("Average Years", size(medsmall)) ///
	xlab(, nogrid) ylab(, angle(90)) ///
	legend(label(1 "Loss Carryforward") label(2 "Loss Carryback") size(*0.8) row(1) position(6) span region(lc(gs9)))
graph export "Figures/Figure3_B.svg", replace
								 
* Panel C: Apportionment Weights
line payroll_wgt sales_wgt year, ///
	lcolor(black black) lpattern(solid dash) lwidth(thick thick) ///
	xti("Year", size(medsmall)) ///
	yti("Average Apportionment Weight", size(medsmall)) ///
	xlab(, nogrid) ylab(, angle(90)) ///
	legend(label(1 "Payroll Apportionment") label(2 "Sales Apportionment") size(*0.8) row(1) position(6) span region(lc(gs9)))
graph export "Figures/Figure3_C.svg", replace

restore


********************************************************************************
**# Panel D
********************************************************************************

preserve

* Count the number of states with tax rule (all the variables are indicators)
collapse (sum) throwback combined FedIncomeTaxDeductible FederalIncomeasStateTaxBase ACRSDepreciation AllowFedAccDep FederalBonusDepreciation FranchiseTax incr_ma incr_fixed, by(year)

* Panel D: Misc. State Tax Base Provisions
twoway (scatter throwback year, c(l) msymbol(none) lc(black) lpattern(solid) lwidth(thick)) ///
	(scatter combined year, c(l) msymbol(none) lc(black) lpattern(dash) lwidth(thick)) ///
	(scatter FedIncomeTaxDeductible year, c(l) msymbol(none) lc(gs9) lpattern(solid)) ///
	(scatter FederalIncomeasStateTaxBase year, c(l) msymbol(none) lc(gs9) lpattern(dash)) ///
	(scatter ACRSDepreciation year, c(l) msymbol(circle) mc(black) lc(black) lpattern(solid) lwidth(medthick)) ///
	(scatter AllowFedAccDep year, c(l) msymbol(circle) mc(black) lc(black) lpattern(dash) lwidth(medthick)) ///
	(scatter FederalBonusDepreciation year, c(l) msymbol(circle) mc(gs9) lc(gs9) lpattern(solid)) ///
	(scatter FranchiseTax year, c(l) msymbol(circle) mc(gs9) lc(gs9) lpattern(dash)) ///
	(scatter incr_ma year, c(l) msymbol(circle) mc(gs9) lc(gs9) lpattern(shortdash)) ///
	(scatter incr_fixed year, c(l) msymbol(circle) mc(black) lc(black) lwidth(medthick) lpattern(dot)), ///
	xtitle("Year", size(medsmall)) ///
	ytitle("Number of States with Tax Rule", size(medsmall)) ///
	xlab(, nogrid) ylab(0(10)50, angle(90)) ///
	legend(label(1 "Throwback Rule") label(2 "Combined Reporting Rule") label(3 "Fed Inc Tax Deductible") label(4 "Fed Inc as State Tax Base") label(5 "ACRS Depreciation") label(6 "Fed Accelerated Depreciation") label(7 "Fed Bonus Depreciation") label(8 "Franchise Tax") label(9 "R&D Base is Moving Avg") label(10 "R&D Base is Fixed") cols(2) size(*0.8) position(6) span region(lc(gs9)))
graph export "Figures/Figure3_D.svg", replace

restore