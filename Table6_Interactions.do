* This do file replicates Table 6 in Serrato & Zidar (2018).
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
gen r_g = rev_corptax/GDP*10^4				// scaled revenue-to-GDP
gen log_rev = ln(rev_corp)					// log(Revenue)
gen log_corp = ln(1-corporate_rate/100)		// log keep rate
gen log_gdp = ln(GDP)						// log(GDP)

** Center base components around state & year FE 
local base "sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit" 
foreach var in `base' { 
	reg `var' i.fips i.year 
	predict base_hat, res 
	replace `var' = base_hat
	drop base_hat
}

* Weighted by mean state GDP across years
bysort fips_state: egen mean_GDP = mean(GDP)

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
**# Regressions
********************************************************************************

gen temp_log = log_corp 
gen temp_corp = corporate_rate

foreach var in r_g log_rev log_gdp {
	if "`var'" == "r_g" { 
		replace log_corp = temp_corp
	}
	
	if "`var'" != "r_g" { 
		replace log_corp = temp_log
	}

	cap drop index2
	
	* Run an interacted regression and generate an index
	eststo inter_`var': reg `var' log_corp i.year i.fips_state rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed c.log_corp#(c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15) [aw=mean_GDP]

	gen index2 = (_b[c.log_corp#c.s1]*s1 + _b[c.log_corp#c.s2]*s2 + _b[c.log_corp#c.s3]*s3 + _b[c.log_corp#c.s4]*s4 + _b[c.log_corp#c.s5]*s5 + _b[c.log_corp#c.s6]*s6 + _b[c.log_corp#c.s7]*s7 + _b[c.log_corp#c.s8]*s8 + _b[c.log_corp#c.s9]*s9 + _b[c.log_corp#c.s10]*s10 + _b[c.log_corp#c.s11]*s11 + _b[c.log_corp#c.s12]*s12 + _b[c.log_corp#c.s13]*s13 +_b[c.log_corp#c.s14]*s14 + _b[c.log_corp#c.s15]*s15)
				
	sum index2 [aw=mean_GDP], detail
	replace index2 = (index2)/r(sd)
	
	if "`var'" == "r_g" {
		replace log_corp = temp_corp

		* Run the baseline regression 
		eststo base_`var': reg `var' corporate_rate i.year i.fips_state c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15 [aw=mean_GDP], vce(cluster fips_state)

		* Run the regression with joint interaction
		eststo joint_`var': reg `var' corporate_rate i.year i.fips_state c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15 c.log_corp#(c.index2) c.index2 [aw=mean_GDP], vce(cluster fips_state)
	}
	
	if "`var'" != "r_g" {
		replace log_corp = temp_log

		* Run the baseline regression
		eststo base_`var' : reg `var' log_corp i.year i.fips_state c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15 [aw=mean_GDP], vce(cluster fips_state)
		
		* Run the regression with joint interaction
		eststo joint_`var': reg `var' log_corp i.year i.fips_state c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15 c.log_corp#(c.index2) c.index2 [aw=mean_GDP], vce(cluster fips_state)
	}
}


********************************************************************************
**# Export as a TeX File
********************************************************************************

* Create a blank table with customized title
esttab base_r_g joint_r_g base_log_rev joint_log_rev base_log_gdp joint_log_gdp using "Tables/Table6.tex", ///
	replace sty(tex) keep(_cons) ///
	nocons noobs nomtitle nonumbers ///
	preh("\adjustbox{max width=0.8\textwidth}{" ///
		"\begin{tabular}{l*{6}{l}}" "\hline" ///
		" & (1) & (2) & (3) & (4) & (5) & (6) \\ \cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-7}" ///
		" & \multicolumn{2}{l}{Revenue to GDP Ratio} & \multicolumn{2}{l}{Log(Revenue)} & \multicolumn{2}{l}{Log(GDP)} \\") ///
	postfoot("")

* Part 1 (base and joint interactions)
estout base_r_g joint_r_g base_log_rev joint_log_rev base_log_gdp joint_log_gdp using "Tables/Table6.tex", ///
	append sty(tex) keep(corporate_rate log_corp c.log_corp#c.index2) ///
	order(corporate_rate log_corp c.log_corp#c.index2) ///
	varlabel(corporate_rate "$\tau$" log_corp "$\log(1-\tau)$" c.log_corp#c.index2 "Joint interaction") ///
	mlab(none) coll(none) cells(b(star fmt(3)) se(par fmt(3))) postfoot("")

* Part 2 (base and single interactions)
estout base_r_g inter_r_g base_log_rev inter_log_rev base_log_gdp inter_log_gdp using "Tables/Table6.tex", ///
	append sty(tex) keep(c.log_corp#c.s*) ///
	mlab(none) coll(none) ///
	cells(b(star fmt(3)) se(par fmt(3))) ///
	stats(N, labels("Observations") fmt("%9.0fc")) ///
	varlabel(c.log_corp#c.s1 "R\&D Credit" ///
		c.log_corp#c.s2 "Sales Apportionment Wgt" ///
		c.log_corp#c.s3 "Loss Carryback" ///
		c.log_corp#c.s4 "Loss Carryforward" ///
		c.log_corp#c.s5 "Franchise Tax" ///
		c.log_corp#c.s6 "Federal Inc Deductible" ///
		c.log_corp#c.s7 "Federal Inc as State Base" ///
		c.log_corp#c.s8 "Federal Accelerated Dep" ///
		c.log_corp#c.s9 "ACRS Depreciation" ///
		c.log_corp#c.s10 "Federal Bonus Dep" ///
		c.log_corp#c.s11 "Throwback Rules" ///
		c.log_corp#c.s12 "Combined Reporting" ///
		c.log_corp#c.s13 "Investment Tax Credit" ///
		c.log_corp#c.s14 "R\&D Incremental Mov Avg" ///
		c.log_corp#c.s15 "R\&D Incremental Fixed") ///
	preh("\addlinespace[1em]" ///
		"\multicolumn{7}{l}{\textit{Individual Interactions}}\\") ///
	postfoot("Base Controls & Y & Y & Y & Y & Y & Y \\" ///
		"Year Fixed Effects & Y & Y & Y & Y & Y & Y \\" ///
		"State Fixed Effects & Y & Y & Y & Y & Y & Y \\ \hline" ///
		"\end{tabular}}")