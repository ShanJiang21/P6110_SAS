***********************************************
* P6110: Statistical Computing with SAS       *
* Spring 2019                                 *
* Homework 9								  *
* Shan Jiang (Columbia University)            *
***********************************************;

* a);

* Import the dataset as chd dataset;

proc import out=CHD
	datafile="C:\Users\PubLibrary\Desktop\practice9\chd.xlsx"
	dbms=xlsx replace;
	sheet="sheet1";
	getnames=yes;
run;

* Define labels and applying formats;
Data CHD;
  set CHD; 
 	label SBP = "Systolic blood pressure"
		  LDL = "Low density lipoprotein cholesterol"
		  CHD = "Coronary heart disease"
		  BMI = "Body Mass Index"
		  BAI = "Body adiposity index"
		  Famhist = "Family history of heart disease(Present, Absent)"; 
 run; 
proc format; 
	value chdfmt   1 = 'Case'
				   0 = 'Control';
run; 

proc print data = chd (obs =5) label;
format chd chdfmt. ; 
run; 

*/b/*************************************** 
* Descriptive statistics

* i. Cross-tabular frequency family history (rows) and CHD status (columns); 

proc freq data=chd;
	table  Famhist * CHD;
run;

* ii. Distribution of systolic pressure;

	* 1). Descriptive statistics of SBP for each level of CHD status. Use two decimal points;

		proc means data = chd n mean median std min max maxdec = 2; 
		class CHD; 
		var SBP;
		format chd chdfmt.;
		run; 

	* 2). Boxplots of systolic pressure for each level of CHD status; 

		proc sgplot data=chd;
			vbox SBP / category = CHD ;
			format chd chdfmt.;
			xaxis label= "CHD status";
		run;


	* 3). Scatterplot and Pearson’s correlation coefficient;
		proc sort data = chd;
		by chd;
		run;

		proc corr data= chd plots = scatter(ellipse=prediction) pearson;
		var Tobacco SBP; 
		by chd;
		run;


* iii. Histograms of body adiposity index;
		proc sgpanel data=chd;
		panelby Famhist / rows=2 layout=rowlattice;
	    histogram BMI;
		density BMI / type=kernel; /* overlay density estimates */
		run;


*/c/ ***************************************;

%macro table(datain, var1, var2);

proc tabulate data=&datain;
class chd Famhist;
var &var1 &var2;
format chd chdfmt.;
table (chd=' ' All) * (Famhist=' ' All),
 &var1*(n*f=3. mean*f=5.1 std*f =5.2)
 &var2*(n*f=3. mean*f=comma5.1 std*f =5.2);
 keylabel n = "Freq"
		  std = 'Std Dev'
          ALL = 'Total';
run;
%mend table; 

%table(chd, alcohol, tobacco);


ods rtf file = "C:\Users\PubLibrary\Desktop\practice9\prac9d.rtf" author= "shan Jiang" title = "practice9";


* d) Hypothesis testing;
* d)-1. Is the CHD status independent of family history;
* H0: Independent vs H1: Associated;

*  Two categorical variables --> Chi-squared test

*  Check the assumptions.
	a) No more than 1/5 of the cells have expected values <5.
	b) No cell has expected value <1.

4) Report conclusion based on the test result; 

proc freq data=chd;
	table Famhist * CHD / chisq fisher;
run;

* (Chi-squared) 34.2743 p <.0001  (Fisher) <.0001;
* ->  Reject H0;
 

* Conclusion: 
* It is appropriate to reject the null hypothesis, at the significance level of 0.05, 
we can reject the null hypothesis and conclude that CHD status is not independent from family history; 



* d)-2.Is there a difference in mean type-A personality score depending on family history. 
--> Two-sample independent T test;
/* Independent two-sample t-test */
* H0: Mu_absent = Mu_present vs H1: Mu_absent is not equal to Mu_present

* Checking normality;
proc univariate data=chd normal;
	class Famhist;
	var TypeA;
	qqplot TypeA;
	histogram TypeA;
run;
* Shapiro-Wilk W 0.987295 Pr < W 0.0175 < 0.05,
* Not normal --> Non parametric test

* Independent two-sample t-test: Wilcoxon rank sum test;
proc npar1way data=chd wilcoxon;
	class Famhist;
	var TypeA;
run;
* SAS provides both one-and two-sided p-values;
* both of the P-value: 0.2254 and 0.4507 are greater than 0.05. 
* We cannot reject the null, 
* so there is no significant diffrence of median in absence group and presence group of family history.


* d)-3. Is the Pearson’s correlation coefficient of 
* alcohol and tobacco consumption equal to 0? 
* H0: Rho=0 vs H1: Rho not equal to 0;
proc corr data=chd plots=matrix;
	var alcohol tobacco;
run;
*  Check the assumptions.
	4 main assumptions:
		* The dependent variable must be continuous (interval/ratio).
		* The observations are independent of one another.
		* The dependent variable should be approximately normally distributed.
		* The dependent variable should not contain any outliers;

* Estimated rho = 0.20081 
* P-value < 0.0001 -> Reject H0;

* Conclusion:  at the significance level of 0.05, we can reject the null hypothesis and conclude that 
Pearson’s correlation coefficient of alcohol and tobacco consumption is different from 0 significantly,
indicated that there is linear relationship between these two factors.


* d)-4. Is the proportion of having family history greater than 40%.
* H0: p = 0.4 vs H1: p is not equal to 0.4

* --> One-Sample Test for Binary Proportion; 
proc freq data=chd;
	table Famhist / binomial (p=0.4); * H0:;
run;
* The z-score is 8.0912 with P-value < 0.0001, so we have can reject the null.
* Conclusion: the true proportion of having family history is significantly different from 0.4.


* e) Fitting a model

* First check the linear correlation;
proc corr data=chd plots(maxpoints=100000000)=matrix(nvar=10);
	var chd Alcohol Tobacco SBP LDL BAI TypeA BMI Age;
	run; 
* there is not severe multicollinearity problem in this problem. 
* Age, LDL, alcolhol and Tobacco can be included in the model. 
* also, family history can be a indicator as there is association proved in d-1. 

* Because the CHD status is a binary variable, meaning we need to use a logit link in GLM for fitting the model for regression. 
* ---> Model: logistic regression model, including an interaction term 

* Interaction;
proc genmod data=chd descending; 
	model chd = Alcohol | Tobacco
			/ dist = bin link = logit;
run;

* check VIF of full model (without type -- categorical variable);
proc reg data=chd;
	model chd = Alcohol Tobacco SBP LDL BAI TypeA BMI Age / vif;
run; quit;
* There is no variable has VIF > 10, so it's not problematic. 


* Model selection: PROC LOGISTIC;

proc logistic data=chd plots(only)=(roc effect) descending;
    class Famhist(ref="Absent");
	model chd  = Alcohol | Tobacco SBP LDL BAI Famhist TypeA BMI Age
			/ lackfit outroc = roc selection = stepwise; * Model selection;
run;


* Final model;
proc logistic data=chd plots(only label)=(roc effect phat leverage dpc) descending;
	class Famhist(ref="Absent");
	model chd = Alcohol | Tobacco Famhist Age /  lackfit outroc = roc;
run;

ods rtf close; 



* 1) Overall significance

* Testing Global Null Hypothesis: BETA=0
* Likelihood Ratio test: 101.3845 with P-value <.0001 
* The significance for the overall model: tells us that our model as a whole fits significantly better than an empty model.

---------------------------------------------------------------------------------------------------
* 2) ROC analysis: 
* In the stepwise procedure,we find that the final selected model 
* has an AUC value of 0.79, which is not a great progress compared with final model.
* The AUC in final model is 0.7694 and model fitting is fair. 
* The specificity and sensitivity 
---------------------------------------------------------------------------------------------------

* 3) Goodness of fit:  based on HL test, at a = 0.05 we fail to reject the hypothesis that the data fit the
model (p = 0.7910). Therefore we conclude that the model provides adequate fit.

---------------------------------------------------------------------------------------------------
 
* 4) Interpretation: 

* Tobacco: One unit increase in Tobacco increases the odds of being CHD case by 6.8% (i.e. (exp(0.0667)= 1.0689 times) 
adjusted for Famhist, tobacco and Alcohol. 

* Famhist: Adjusted for age, tobacco and Alcohol, those with Family history have 62% (p < 0.0001)increase
 (i.e. exp(0.4877)= 1.6285 times)in the odds of being in CHD case compared to those with without with Family history. 

* Age: One unit increase in Age increases the odds of being CHD case by 5.1% (i.e. (exp(0.0493)= 1.0505 times) 
adjusted for Famhist, tobacco and Alcohol. 

* Intercept has no meaning as Age cannot be 0. 

