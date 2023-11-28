* This do file replicates Table 5 in Serrato & Zidar (2018).
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

* Generate main variables
gen r_g = rev_corptax/GDP*10^4				// scaled revenue-to-GDP
gen log_rev = ln(rev_corp)					// log(Revenue)
gen log_corp = ln(1-corporate_rate/100)		// log keep rate
gen log_gdp = ln(GDP)						// log(GDP)

* Center base components around state & year FE 
local base "sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit" 
foreach var in `base' {
	reg `var' i.fips i.year 
	predict base_hat, res 
	replace `var' = base_hat
	drop base_hat
}

* Weighted by mean state GDP across years
bys fips: egen mean_GDP = mean(GDP)

* Compute the base index
local i = 1
foreach var of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	gen s`i' = `var'
	sum s`i'  [aw=mean_GDP], detail
	replace s`i' = (s`i'-r(mean))/r(sd)	
	local ++i 
}

reg r_g corporate_rate s1-s15 i.year i.fips_state [aw=mean_GDP], vce(cluster fips_state)

gen base_index = _b[s1]*s1 + _b[s2]*s2 + _b[s3]*s3 + _b[s4]*s4 + _b[s5]*s5 + _b[s6]*s6 + _b[s7]*s7 + _b[s8]*s8 + _b[s9]*s9 + _b[s10]*s10 + _b[s11]*s11 + _b[s12]*s12 + _b[s13]*s13 + _b[s14]*s14 + _b[s15]*s15

sum base_index, detail
replace base_index = (base_index-r(mean))/r(sd)

reg r_g corporate_rate i.fips i.year base_index [aw=mean_GDP], vce(cluster fips)

lincom _b[base_index]

* Store the base index
local N = 1550	// number of observations
mat temp_b = r(estimate)
mat temp_V =  r(se)^2
local base_index_2_EST = round(r(estimate),.001) 
local base_index_2_SE = round(r(se),.001)

* Convert to strings
local est = "`base_index_2_EST'"
local est_SE = "(0`base_index_2_SE')"	// add parentheses and a starting 0


********************************************************************************
**# Regressions
********************************************************************************

global base = "rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed"

eststo model1: reg r_g corporate_rate i.fips_state i.year [aw=mean_GDP], vce(cluster fips_state)
eststo model1_c: reg r_g corporate_rate i.fips_state i.year $base [aw=mean_GDP], vce(cluster fips_state)

* Recall the stored base index and its se (which are stored as strings)
estadd local est "`est'"
estadd local est_SE "`est_SE'"
	
eststo model2: reg log_rev log_corp i.fips_state i.year [aw=mean_GDP], vce(cluster fips_state)	
eststo model2_c: reg log_rev log_corp i.fips_state i.year $base [aw=mean_GDP], vce(cluster fips_state)

eststo model3: reg log_gdp log_corp i.fips_state i.year [aw=mean_GDP], vce(cluster fips_state)
eststo model3_c: reg log_gdp log_corp i.fips_state i.year $base [aw=mean_GDP], vce(cluster fips_state)

* Export as a TeX file
label var corporate_rate "$\tau$"
label var log_corp "$\ln (1-\tau)$"
label var rec_val "R\&D tax credit"
label var sales_wgt "Sales apportionment wgt"
label var Losscarryba "Loss carryback"
label var Losscarryfo "Loss carryforward"
label var FederalIncomeas "Fed income as tax base"
label var throwback "Throwback rules"
label var combined "Combined reporting"
label var incr_ma "R\&D incremental mov avg"
label var incr_fixed  "R\&D incremental fixed"

estout model1 model1_c model2 model2_c model3 model3_c using "Tables/Table5.tex", ///
	keep($base log_corp corporate_rate) order(corporate_rate log_corp $base) ///
	sty(tex) label mlab(none) coll(none) ///
	cells(b(star fmt(3)) se(par fmt(3))) starlevels(* .1 ** .05 *** .01) ///
	stats(N est est_SE, labels("Observations" "Base index" "(se)") fmt(%9.0fc 3 3)) ///
	preh("\adjustbox{max width=0.9\textwidth}{" ///
		"\begin{tabular}{l*{6}{l}}" "\hline" ///
		" & (1) & (2) & (3) & (4) & (5) & (6) \\ \cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-7}" ///
		" & \multicolumn{2}{l}{Revenue to GDP Ratio} & \multicolumn{2}{l}{Log(Revenue)} & \multicolumn{2}{l}{Log(GDP)} \\ \hline") ///
	postfoot("\hline" "\end{tabular}}" ) replace