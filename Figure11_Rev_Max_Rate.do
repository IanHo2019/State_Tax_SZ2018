* This do file replicates Figure 11 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 16, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in 1980-2010
drop if fips_state == 0 | fips_state == 11 | fips_state > 56
keep if inrange(year, 1980, 2010)

* Generate main varaibles
gen r_g = rev_corptax/GDP*10^4		// expressed in basis points
replace corporate_rate = corporate_rate/100

* Assign variables
local i = 1
foreach var of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	gen s`i' = `var'
	local i = `i'+1 
}

* Create base index
reg r_g s1-s15 i.year i.fips_state, vce(cluster fips_state)

gen base_index= _b[s1]*s1 + _b[s2]*s2 + _b[s3]*s3 + _b[s4]*s4 + _b[s5]*s5 + _b[s6]*s6 + _b[s7]*s7 + _b[s8]*s8 + _b[s9]*s9 + _b[s10]*s10 + _b[s11]*s11 + _b[s12]*s12 + _b[s13]*s13 + _b[s14]*s14 + _b[s15]*s15

sum base_index, detail
replace base_index = (base_index-r(mean))/r(sd)


********************************************************************************
**# Panel A
********************************************************************************

* Run the regression preferred by the authors
reg r_g c.corporate_rate c.corporate_rate#c.corporate_rate i.year base_index c.base_index#(c.corporate_rate c.corporate_rate#c.corporate_rate) i.fips_state, vce(cluster fips_state)

* Compute the revenue-maximizing rate
nlcom -_b[c.corporate_rate]/(2*_b[c.corporate_rate#c.corporate_rate]) 
local top_mean = el(r(b),1,1)

* Laffer curve with base-independent rate:
twoway (function y = (x<.52)*(x*_b[c.corporate_rate]+x^2*_b[c.corporate_rate#c.corporate_rate]), range(0 .6)), ///
	xline(`top_mean', lc(gs9) lpattern(dash)) ///
	yline(0, lc(cranberry) lpattern(solid)) ///
	xtitle("Corporate Tax Rate", size(medsmall)) ///
	ytitle("Tax Revenue/GDP", size(medsmall)) ///
	xlab(0(0.05)0.6, labs(small) nogrid) ylab(, labs(small) angle(90))
graph export "Figures/Figure11_A.svg", replace


********************************************************************************
**# Panel B
********************************************************************************

* Create base-dependent rate
gen top_base = -(_b[c.corporate_rate] + base_index*_b[c.corporate_rate#c.base_index]) / (2 * (_b[c.corporate_rate#c.corporate_rate] + base_index*_b[c.corporate_rate#c.corporate_rate#c.base_index]))

gen denom = (2 * (_b[c.corporate_rate#c.corporate_rate] + base_index*_b[c.corporate_rate#c.corporate_rate#c.base_index]))

* Top rate equals 1 if quadratic term (denom) is non-negative 
replace top_base = 1 if denom>=0 & top_base !=.
 
* Top rate is coded to 1 if it is greater than 1
replace top_base = 1 if top_base>1 & top_base != .

* Plot
sum top_base

cdfplot top_base, ///
	xline(`top_mean', lc(gs9) lpattern(solid)) ///
	xline(`r(mean)', lc(gs9) lpattern(dash)) ///
	text(1.05 `top_mean' "Base-independent rate", size(small)) ///
	text(1.05 `r(mean)' "Mean base-dependent rate", size(small)) ///
	yline(0, lc(cranberry) lpattern(solid)) ///
	xtitle("Corporate Tax Rate", size(medsmall)) ///
	ytitle("Cumulative Probability", size(medsmall)) ///
	xlab(0(0.05)1, labs(small) nogrid) ylab(, labs(small) angle(90))
graph export "Figures/Figure11_B.svg", replace


********************************************************************************
**# Panel C
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in 1980-2010
drop if fips_state == 0 | fips_state == 11 | fips_state > 56
keep if inrange(year, 1980, 2010)

gen total_r_g = rev_totaltaxes/GDP*10^4		// expressed in basis points
replace corporate_rate = corporate_rate/100

* Assign variables
local i = 1 
foreach var of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	gen s`i' = `var'
	local i = `i'+1 
}

* Create base index
reg total_r_g s1-s15 i.year i.fips_state, vce(cluster fips_state)

gen base_index = _b[s1]*s1 + _b[s2]*s2 + _b[s3]*s3 + _b[s4]*s4 + _b[s5]*s5 + _b[s6]*s6 + _b[s7]*s7 + _b[s8]*s8 + _b[s9]*s9 + _b[s10]*s10 + _b[s11]*s11 + _b[s12]*s12 + _b[s13]*s13 + _b[s14]*s14 + _b[s15]*s15

sum base_index, detail
replace base_index = (base_index-r(mean))/r(sd)

* Regression
reg total_r_g c.corporate_rate c.corporate_rate#c.corporate_rate i.year base_index c.base_index#(c.corporate_rate c.corporate_rate#c.corporate_rate) i.fips_state, vce(cluster fips_state)

nlcom -_b[c.corporate_rate]/(2*_b[c.corporate_rate#c.corporate_rate])
local top_mean = r(b)[1,1]

* Plot
twoway (function y = max((x<.58)*(x*_b[c.corporate_rate]+x^2*_b[c.corporate_rate#c.corporate_rate]),0) if c.corporate_rate <= 0.3, range(0 .21)), ///
	xline(`top_mean', lc(gs9) lpattern(dash)) ///
	yline(0, lc(cranberry) lpattern(solid)) ///
	xtitle("Corporate Tax Rate", size(medsmall)) ///
	ytitle("Tax Revenue/GDP", size(medsmall)) ///
	xlab(0(0.05)0.6, labs(small) nogrid) ylab(, labs(small) angle(90))
graph export "Figures/Figure11_C.svg", replace


********************************************************************************
**# Panel D
********************************************************************************

* Create base-dependent rate
gen top_base = -(_b[c.corporate_rate]+base_index*_b[c.corporate_rate#c.base_index])/(2*(_b[c.corporate_rate#c.corporate_rate]+base_index*_b[c.corporate_rate#c.corporate_rate#c.base_index]))

gen denom = (2*(_b[c.corporate_rate#c.corporate_rate]+base_index*_b[c.corporate_rate#c.corporate_rate#c.base_index]))

* Top rate equals 1 if quadratic term (denom) is non-negative
replace top_base = 1 if denom>=0 & top_base!=.

* Larger-than-1 top rate is coded to 1 
replace top_base = 1 if top_base>1 & top_base!= .

* Plot 
sum top_base

cdfplot top_base, ///
	xline(`top_mean', lc(gs9) lpattern(solid)) ///
	xline(`r(mean)', lc(gs9) lpattern(dash)) ///
	yline(0, lc(cranberry) lpattern(solid)) ///
	xtitle("Corporate Tax Rate", size(medsmall)) ///
	ytitle("Cumulative Probability", size(medsmall)) ///
	xscale(range(0 0.28)) ///
	xlab(0(0.02)0.28, labs(small) nogrid) ylab(, labs(small) angle(90)) ///
	text(1.05 .073 "Base-independent Rate", size(vsmall)) ///
	text(1.05 .122 "Mean Base-dependent Rate", size(vsmall))
graph export "Figures/Figure11_D.svg", replace