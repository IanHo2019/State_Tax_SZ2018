* This do file replicates Figure 10 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 16, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in four years
keep if inrange(year, 1980, 2010)
drop if fips_state == 0 | fips_state == 11 | fips_state > 56

* Generate main variables
gen r_g = rev_corptax/GDP*10^4
gen log_corp = corporate_rate

* Weighted by mean state GDP across years
bys fips_state: egen mean_GDP = mean(GDP)

* Normalization
foreach xvar of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	 sum `xvar' [aw=mean_GDP], detail
	 replace `xvar' = (`xvar'-r(mean))/r(sd)
}

* Assign variables
local i = 1 
foreach var of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	gen s`i' = `var'
	local ++i 
}

********************************************************************************
**# Regression and Plotting
********************************************************************************

* Regression
reg r_g log_corp i.year i.fips c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15 c.log_corp#(c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15) [aw=mean_GDP]	

gen temp_prog = _b[log_corp] + _b[c.log_corp#c.s1]*s1 + _b[c.log_corp#c.s2]*s2 + _b[c.log_corp#c.s3]*s3 + _b[c.log_corp#c.s4]*s4 + _b[c.log_corp#c.s5]*s5 +_b[c.log_corp#c.s6]*s6 + _b[c.log_corp#c.s7]*s7 + _b[c.log_corp#c.s8]*s8 + _b[c.log_corp#c.s9]*s9 + _b[c.log_corp#c.s10]*s10 + _b[c.log_corp#c.s11]*s11 + _b[c.log_corp#c.s12]*s12 + _b[c.log_corp#c.s13]*s13 + _b[c.log_corp#c.s14]*s14 + _b[c.log_corp#c.s15]*s15 if e(sample)

* Plot for 4 states (DE, MI PA RI)
line temp_prog year if inlist(fips_state, 10, 26, 42, 44) & temp_prog!=., ///
	by(State, note("")) ///
	lc(navy) ///
	yline(0, lc(cranberry) lpattern(solid)) ///
	yti("Effect of {&tau} on Revenue to GDP Ratio") ///
	xlab(, labsize(small) nogrid)
graph export "Figures/Figure10.svg", replace