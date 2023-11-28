* This do file replicates Figure 5 in Serrato & Zidar (2018).
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

* Generate 5-year period indicators
gen period = 0
replace period = 1 if year >= 1980 & year <= 1985
replace period = 2 if year >= 1986 & year <= 1990
replace period = 3 if year >= 1991 & year <= 1995
replace period = 4 if year >= 1996 & year <= 2000
replace period = 5 if year >= 2001 & year <= 2005
replace period = 6 if year >= 2006 & year <= 2010

* Generate the outcome variable
gen r_g = rev_corptax/GDP*100

* Assign variables
g x0  = corporate_rate
g x1  = FederalIncomeasStateTaxBase
g x2  = FedIncomeTaxDeductible 
g x3  = throwback 
g x4  = sales_wgt 
g x5  = Losscarryforward 
g x6  = Losscarryback 
g x7  = combined 
g x8  = investment_credit 
g x9  = rec_val
g x10 = ACRSDepreciation 
g x11 = AllowFedAccDep 
g x12 = FederalBonusDepreciation 
g x13 = FranchiseTax
g x14 = incr_ma 
g x15 = incr_fixed


* Run a regression
bysort fips_state: egen mean_GDP = mean(GDP)

reg r_g x0-x15 i.period [aw=mean_GDP]

* Save the explained/unexplained variation
g explained = e(r2)
g unexplained = 1 - e(r2)

* 
forvalues j = 0/15 {
	qui {
		local beta = _b[x`j']
		sum x`j'
		local var = (r(sd))^2
		gen bsqXx`j' = (`beta')^2 * `var'
	}
}

* Assuming the covariance is 0, the variance of sum is the sum of variances.
* Y = b0 + x1 b1 + ...  x15 b15 + e
* Var(Y) = Var(x1) b1^2 + ... + Var(x15) b15 + var(e)
gen sum_corprate = bsqXx0
egen sum_base = rowtotal(bsqXx1-bsqXx15)

gen corp = sum_corprate/(sum_base+sum_corprate)
gen base = 1-corp

* Calculate the ratio of explanation by each base rule
ds bsqXx1-bsqXx15	// get a list of variable names
foreach var in `r(varlist)' {
	replace `var' = 100*(`var'/sum_base)
}


********************************************************************************
**# Panel A
********************************************************************************

preserve

keep if _n == 1

set obs 2
gen corprate_exp = corp[1] in 2
gen other = base[1] in 2
keep explained unexplained other corprate_exp

g id = ""
replace id = " R{sub:s}{sup:corp}/GDP{sub:s}" in 1 // The space ensures this appears first.
replace id = "Base vs Rate" in 2

graph bar explained unexplained corprate_exp other, stack over(id) ///
	bar(1, color(dknavy)) bar(2, color(maroon)) bar(3, color(dknavy*.7)) bar(4, color(dknavy*.4)) ///
	ytitle("% of Explained Variation", size(medsmall)) ///
	legend(label(1 "Explained") label(2 "Unexplained") label(3 "Corporate Rate") label(4 "Base Rules") cols(2) size(*0.7) span position(6) region(lc(black)))
graph export "Figures/Figure5_A.svg", replace

restore


********************************************************************************
**# Panel B
********************************************************************************

preserve

keep bsqXx1-bsqXx15

graph hbar (mean) bsqXx1-bsqXx15, ///
	ytitle("% Explained Among Base Rules", size(medsmall)) ///
	bargap(20) legend(off) showyvars ///
	yvaroptions(relabel(1 "Federal Inc as State Base" 2 "Federal Inc Tax Deductible" 3 "Throwback Rules" 4 "Sales Apportionment Weight" 5 "Loss Carryforward" 6 "Loss Carryback" 7 "Combined Reporting" 8 "Investment Tax Credit" 9 "R&D Tax Credit" 10 "ACRS Depreciation" 11 "Federal Accelerated Depreciation" 12 "Federal Bonus Depreciation" 13 "Franchise Tax" 14 "Incr R&D, Moving Avg Base" 15 "Incr R&D, Fixed Base") label(labsize(small))) ///
	bar(1, color(dknavy*.4)) bar(2, color(dknavy*.4)) bar(3, color(dknavy*.4)) bar(4, color(dknavy*.4)) bar(5, color(dknavy*.4)) bar(6, color(dknavy*.4)) bar(7, color(dknavy*.4)) bar(8, color(dknavy*.4)) bar(9, color(dknavy*.4)) bar(10, color(dknavy*.4)) bar(11, color(dknavy*.4)) bar(12, color(dknavy*.4)) bar(13, color(dknavy*.4)) bar(14, color(dknavy*.4)) bar(15, color(dknavy*.4))
graph export "Figures/Figure5_B.svg", replace

restore


********************************************************************************
**# Panel C
********************************************************************************

preserve

gen ln_keeprate = ln(1-(corporate_rate)/100)
replace sales_wgt = sales_wgt/100

* Run a regression 
areg r_g FederalIncomeasStateTaxBase FedIncomeTaxDeductible throwback combined c.sales_wgt c.Losscarryforward c.Losscarryback c.investment_credit c.rec_val ACRSDepreciation AllowFedAccDep FederalBonusDepreciation FranchiseTax incr_ma incr_fixed [aw = mean_GDP], absorb(year)

predict r_hat

* Normalization 
foreach var of varlist r_g FederalIncomeasStateTaxBase FedIncomeTaxDeductible throwback sales_wgt Losscarryforward Losscarryback combined investment_credit rec_val ACRSDepreciation AllowFedAccDep FederalBonusDepreciation FranchiseTax incr_ma incr_fixed {
	sum `var'  [aw=mean_GDP], detail
	replace `var' = (`var'-r(mean))/r(sd)
}

* Express revenue-to-GDP ratio in basis points (currently it is in %)
replace r_g = 100*r_g

* Run a regression
areg r_g FederalIncomeasStateTaxBase FedIncomeTaxDeductible throwback combined c.sales_wgt c.Losscarryforward c.Losscarryback c.investment_credit c.rec_val ACRSDepreciation AllowFedAccDep FederalBonusDepreciation FranchiseTax incr_ma incr_fixed [aw = mean_GDP], absorb(year)

* Plot
label var throwback "Throwback Rules"
label var combined "Combined Reporting Rules"
label var sales_wgt "Sales Apportionment Weight"
label var Losscarryforward "Loss Carryforward"
label var Losscarryback "Loss Carryback"
label var investment_credit "Investment Tax Credit"
label var rec_val "R&D Tax Credit"
label var AllowFedAccDep "Allows Federal Accelerated Depreciation"
label var FranchiseTax "Franchise Tax"
label var incr_ma "Incremental R&D, Moving Avg Base"
label var incr_fixed "Incremental R&D, Fixed Base"

coefplot, ///
	drop(_cons) xline(0, lc(maroon) lpattern(solid)) ///
	mc(navy) ciopts(lc(navy)) ///
	xtitle("Basis Points") ///
	xlab(, nogrid labs(small)) ylab(, labs(small))
graph export "Figures/Figure5_C.svg", replace

restore