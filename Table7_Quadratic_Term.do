* This do file replicates Table 7 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 16, 2023

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in 1980-2010
drop if fips_state == 11 | fips_state == 0 | fips_state > 56
keep if inrange(year, 1980, 2010)

* Gen main variables
gen r_g = rev_corptax/GDP * 100
replace corporate_rate = corporate_rate/100

* Assign variables
local i = 1 
foreach var of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed  {
	gen s`i' = `var'
	local ++i
}


********************************************************************************
**# Panel A
********************************************************************************

preserve

* Create base index
reg r_g s1-s15 i.year i.fips, vce(cluster fips_state)

*capture: drop base_index

gen base_index = _b[s1]*s1 + _b[s2]*s2 + _b[s3]*s3 + _b[s4]*s4 + _b[s5]*s5 + _b[s6]*s6 + _b[s7]*s7 + _b[s8]*s8 + _b[s9]*s9 + _b[s10]*s10 + _b[s11]*s11 + _b[s12]*s12 + _b[s13]*s13 + _b[s14]*s14 + _b[s15]*s15

sum base_index, detail
replace base_index = (base_index-r(mean))/r(sd)

* Regressions
eststo reg1: reg r_g corporate_rate c.corporate_rate#c.corporate_rate i.year, vce(cluster fips_state)
estadd local hasy "Yes"		// year FE included or not

eststo reg2: reg r_g corporate_rate c.corporate_rate#c.corporate_rate i.year i.fips_state, vce(cluster fips_state)
estadd local hasy "Yes"
estadd local hass "Yes"		// state FE included or not
	
eststo reg3: reg r_g corporate_rate c.corporate_rate#c.corporate_rate i.year base_index , vce(cluster fips_state)
 estadd local hasy "Yes"
 
eststo reg4: reg r_g corporate_rate c.corporate_rate#c.corporate_rate i.year base_index i.fips_state, vce(cluster fips_state)
estadd local hasy "Yes"
estadd local hass "Yes"

nlcom -_b[c.corporate_rate]/(2*_b[c.corporate_rate#c.corporate_rate])	// compute revenue-maximizing-tax rate
local top_mean = el(r(b),1,1)
estadd scalar top = `top_mean'
 
eststo reg5: reg r_g c.corporate_rate c.corporate_rate#c.corporate_rate i.year base_index c.base_index#(c.corporate_rate c.corporate_rate#c.corporate_rate) i.fips_state, vce(cluster fips_state)
estadd local hasy "Yes"
estadd local hass "Yes"

nlcom -_b[c.corporate_rate]/(2*_b[c.corporate_rate#c.corporate_rate]) 
local top_mean = el(r(b),1,1)
estadd scalar top = `top_mean'

esttab reg* using "Tables/Table7.tex", ///
	replace sty(tex) drop(*fips_state *year _cons) ///
	b(2) se(2) par ///
	noobs nomtitle nogaps ///
	scalars("N Observations"  "hasy Year Fixed Effects"  "hass State Fixed Effects"  "top Revenue-Maximizing Rate") sfmt(%9.0fc 1 1 3) ///
	label coeflabel(corporate_rate "State Corporate Tax Rate $\tau$ " ///
		c.base_index#c.corporate_rate "State Corporate Tax Rate $\tau$ $\times$ Base Index" ///
		c.corporate_rate#c.corporate_rate "State Corporate Tax Rate$^2$ $(\tau)^2$ " ///
		c.base_index#c.corporate_rate#c.corporate_rate "State Corporate Tax Rate$^2$ $(\tau)^2$ $\times$ Base Index" ///
		base_index "Base Index $\times$ 100 ") ///
	transform(base_index @*100 100) ///
	preh("\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" ///
		"\adjustbox{max width=\textwidth}{" ///
		"\begin{tabular}{l*{5}{l}}" "\hline") ///
	posth("\hline" ///
		"\multicolumn{6}{l}{\textit{Panel A. State corporate tax revenue-to-GDP ratio}} \\") ///
	prefoot("") postfoot("")

restore


********************************************************************************
**# Panel B
********************************************************************************

gen total_r_g = (rev_totaltaxes/GDP)*100

* Create base index
reg total_r_g s1-s15 i.year i.fips_state, vce(cluster fips_state)

gen base_index= _b[s1]*s1 + _b[s2]*s2 + _b[s3]*s3 + _b[s4]*s4 + _b[s5]*s5+_b[s6]*s6 + _b[s7]*s7 + _b[s8]*s8 + _b[s9]*s9 + _b[s10]*s10 + _b[s11]*s11 + _b[s12]*s12 + _b[s13]*s13 + _b[s14]*s14 + _b[s15]*s15

sum base_index, detail
replace base_index = (base_index-r(mean))/r(sd)

* Regressions
eststo est1: reg total_r_g corporate_rate c.corporate_rate#c.corporate_rate i.year, vce(cluster fips_state)
estadd local hasy "Yes"

eststo est2: reg total_r_g corporate_rate c.corporate_rate#c.corporate_rate i.year i.fips_state, vce(cluster fips_state) 
estadd local hasy "Yes"
estadd local hass "Yes"
	
eststo est3: reg total_r_g corporate_rate c.corporate_rate#c.corporate_rate i.year base_index, vce(cluster fips_state)
estadd local hasy "Yes"
 
eststo est4: reg total_r_g corporate_rate c.corporate_rate#c.corporate_rate i.year base_index i.fips_state, vce(cluster fips_state)
estadd local hasy "Yes"
estadd local hass "Yes"
nlcom -_b[c.corporate_rate]/(2*_b[c.corporate_rate#c.corporate_rate]) 
local top_mean = el(r(b),1,1)
estadd scalar top = `top_mean'
 
eststo est5: reg total_r_g c.corporate_rate c.corporate_rate#c.corporate_rate i.year base_index c.base_index#(c.corporate_rate c.corporate_rate#c.corporate_rate) i.fips_state, vce(cluster fips_state)
estadd local hasy "Yes"
estadd local hass "Yes"
nlcom -_b[c.corporate_rate]/(2*_b[c.corporate_rate#c.corporate_rate]) 
local top_mean = el(r(b),1,1)
estadd scalar top = `top_mean'
	
esttab est* using "Tables/Table7.tex", ///
	 append drop(*fips_state *year _cons) ///
	 b(2) se(2) par noobs nonumbers nogaps nomtitle ///
	 scalars("N Observations" "hasy Year Fixed Effects" "hass State Fixed Effects" "top Revenue-Maximizing Rate") sfmt(%9.0fc 1 1 3) ///
	 label coeflabel(corporate_rate "State Corporate Tax Rate $\tau$ " ///
		c.base_index#c.corporate_rate "State Corporate Tax Rate $\tau$ $\times$ Base Index" ///
		c.corporate_rate#c.corporate_rate "State Corporate Tax Rate$^2$ ($\tau^2$) " ///
		c.base_index#c.corporate_rate#c.corporate_rate "State Corporate Tax Rate$^2$ ($\tau^2$) $\times$ Base Index" ///
		base_index "Base Index $\times$ 100 ") ///
	transform(base_index @*100 100) ///
	preh("\addlinespace[1em]" ///
		"\multicolumn{6}{l}{\textit{Panel B. Total tax revenue-to-GDP ratio}} \\") ///
	posth("") prefoot("") postfoot("\hline" "\end{tabular}}")