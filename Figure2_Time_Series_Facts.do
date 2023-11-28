* This do file replicates Figure 2 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 16, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states after 1980
drop if fips_state == 11 | fips_state == 0 | fips_state > 56 | year < 1980

* Generate varaibles 
gen r_g = rev_corptax/GDP
replace corporate_rate = corporate_rate/100


********************************************************************************
**# Panel A: Time Series
********************************************************************************

bysort year: egen mean_rate = mean(corporate_rate)
bysort year: egen mean_R = mean(r_g)
replace mean_R = mean_R*100

egen tag = tag(year)

twoway (line mean_rate year if tag==1 & year<=2012, lc(ebblue) lwidth(medthick) yaxis(1) ylabel(0(0.01)0.07, angle(90)) yti("Mean State Corporate Tax Rate")) ///
	(line mean_R year if tag==1 & year<=2012, lc(cranberry) lwidth(medthick) lpattern(dash) yaxis(2) yscale(range(0.2 0.5) axis(2)) ylabel(0.2(0.05)0.5, axis(2) angle(90)) yti("State Corporate Tax Rev/GDP", axis(2))), ///
	title("A) Time Series") ///
	xlabel(1980(10)2010, nogrid) ///
	legend(label(1 "Mean Corp. Rate") label(2 "Mean Corp. Rev/GDP") size(*0.8) span position(6) row(1) region(lc(gs9))) ///
	name(panelA, replace)


********************************************************************************
**# Panel B: Frequency of Changes
********************************************************************************

* Generate indicators for tax rate changes
xtset fips_state year
gen ch_corporate_rate = corporate_rate - L1.corporate_rate

gen change_rate = (ch_corporate_rate!=0 & !missing(ch_corporate_rate))

* Count the number of changes in tax base
local baserules = "FedIncomeTaxDeductible FranchiseTax investment_credit Losscarryforward Losscarryback AllowFedAccDep ACRSDepreciation FederalBonusDepreciation rec_val sales_wgt FederalIncomeasStateTaxBase combined throwback"
foreach rule in `baserules' {
	gen b_it_`rule' = abs(sign(`rule' - L1.`rule'))
}

egen change_base_total = rowtotal(b_it_FedIncomeTaxDeductible-b_it_throwback)
gen change_base = change_base_total>0 & !missing(change_base_total)

collapse (sum) change_rate (sum) change_base, by(year)

* Plot
twoway (function y=x, range(0 40) lc(cranberry)) ///
	(scatter change_rate change_base if year<=2012, mc(navy) mlabel(year) mlabs(vsmall) mlabc(navy)), ///
	title("B) Frequency of Changes") ///
	xtitle("# States Changing Base") ///
	ytitle("# States Changing Corporate Tax Rate") ///
	xlab(, nogrid) ylab(, angle(90)) ///
	legend(off) name(panelB, replace)

* Combine and Export
graph combine panelA panelB, row(2) xsize(7) ysize(10)
graph export "Figures/Figure2.svg", replace