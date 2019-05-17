*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Final project: Heart disease diagnosis*
* Shan Jiang (Columbia University)      *
*****************************************;


*******************
* Import datasets;*
*******************;

* Import 4 datasets using macro; 
ods rtf file = "C:\Users\Studentlab.MC\Desktop\Final\final.rtf";

libname final 'C:\Users\Studentlab.MC\Desktop\Final';

%macro dataload(sheet);
proc import out= &sheet
datafile = "C:\Users\Studentlab.MC\Desktop\Final\HD.xlsx"
dbms = xlsx replace;
sheet = "&sheet";
getnames = yes;
run;

%mend dataload;
%dataload(Us1);
%dataload(US2);
%dataload(EU1);
%dataload(EU2);
run;

* Concatenating datasets using SQL command;

* US data; 
proc sql;
 title 'US subjects data';
 	create table US as
      select * from US1
      outer union corr    
      select * from US2;
	  quit;

* EU data;
proc sql;
 title 'EU subjects data';
   create table EU as
      select * from EU1
 	  outer union corr      
      select * from EU2;
quit; 

* Concatenated HD data; 
proc sql;
 title 'HD data';
   create table HD as
      select * from US
 	  outer union corr      
      select * from EU;
quit;


/*Data Format Definition*/
proc format; 
value sex_fmt
	0 = 'Male' 					
	1 = 'Female';				/*Sex as indicator*/				
value cp_fmt
	1 = 'Typical angina'
	2 = 'Atypical angina'
	3 = 'Non-anginal pain'
	4 = 'Asymptomatic';
value fbs_fmt
	1 = 'true'
	0 = 'false';
value restecg_fmt
	0 = 'Normal'
	1 = 'Having ST-T wave abnormality(T wave inversions and/or ST elevation or depression of > 0.05 mV)'
	2 = "Showing probable or definite left ventricular hypertrophy by Estes' criteria";
value exang_fmt
	1 = 'yes'
	0 = 'no';
value slope_fmt
	1 = 'upsloping' 
	2 = 'flat'
	3 = 'downsloping';
value thal_fmt
	3 = 'normal'
	6 = 'fixed defect'
	7 = 'reversable defect';
value diag_fmt
	0 = 'No presense of heart disease'
	1-4 = 'Number of major vessels that > 50% diameter narrowing';
run; 


* Organized data;

/* Labelling */
data labelling;
	set HD;
	label cp = "Chest pain type"
	      trestbps = "Resting blood pressure"
		  chol = "serum cholestoral mg/dl"
		  fbs = "Fasting blood sugar"
		  restrcg = "Resting electrocardiographic results"
		  thalach = "Maximum heart rate achieved"
		  exang = "Exercide induced angina"
		  oldpeak = "ST depression induced by exercise relative to rest"
		  slope = "Slope of the peak exercise ST segment"
		  ca = "Number of major vessels(0-3) colored by flourosopy"
		  diag = "Heart disease response"; * New label in quotes;
run;


/*Apply formatting (variable formatname.)*/
Data HD_new;
set labelling;
format 
    sex sex_fmt. 
	Cp cp_fmt.
	fbs fbs_fmt.
	restecg restecg_fmt. 
    exang exang_fmt.
	slope slope_fmt.
	thal thal_fmt.
    diag diag_fmt.;
run; 

proc print data=HD_new(obs = 5) label; run;

/*Detect missing values */;
proc sql ;
	select sum(missing(diag), missing(age),missing(sex), 
			   missing(cp), 
			   missing(trestbps), 
			   missing(chol),
			   missing(fbs),
			   missing(thalach),
			   missing(exang),
			   missing(oldpeak),
			   missing(slope),
			   missing(ca),
			   missing(restecg),
			   missing(thal)) as NumMissing,
	count(calculated NumMissing) as Count
	from HD_new
	group by calculated NumMissing;
quit;

* We can see, there is no missing value in this data set. 


*******************
*    EDA 		  ;*
*******************;

** I. Describe the distribution of individual variables.
 	* (1) Response: Diag-Binominal random varaible;
	proc sgplot data= HD_new;
		vbar Diag;
	run;

    *(2) Continuous predictors;
	proc means data= HD_new  n nmiss max min mean mode std Q1 Q3  maxdec=2;
	* Q1: 25% quantile / Q3: 75% quantile / P20: 20% quantile;
	* MAXDEC=n: Number of decimal places to be displayed;
		var age trestbps chol thalach oldpeak;
	run;

	* The distribution also confirms there is no missing value in this dataset.;
    * Age distribution by gender; 
	proc sgpanel data= HD_new;
	   panelby sex/ novarname;
	    histogram age/  binwidth=5 transparency=0.8  scale=count;
	 	density age/ type= kernel; 
	run;
	
* The distribution of Categorical variable predictors shall not be described in numerical format,
to establish our causal link, we need to develope our analysis based on cross-variable analysis. 


** II. Associations bewteen two variables;

* Overall correlation;
	proc corr data = HD_new;
	run; quit;

* Continuous variable:
* (1) Age with Diag (r = 0.28046, p < 0.0001 );
	proc freq data = HD_new;
		table  Age * Diag / nocol norow nopercent;
	run;

* (2) Trestbps with Diag (0.21940, p <.0001);  
* (3) Chol with Diag(r = -0.09679, p < 0.0001);
* (4) oldpeak with Diag(r = 0.47246, p < 0.0001);
* (5) ca with Diag(r = 0.47476, p < 0.0001); 

* Tentative conclusion: The age, trestbps and oldpeak shall be included into the model for infering the Diag status. 

* Categorical variable:  Sex cp fbs exang restecg slope thal: 
* (1) Distribution of Response value: diag by sex;
	proc sgplot data= HD_new;
		vbar Diag/group = sex;
	run;
* This bar chart shows that there is a clear difference 
* in the percentage of heart diseased individuals, so sex shall be tested or included in the model;

* (2) By Cp (r = 0.40502, p < 0.0001);
* Cp: Graphical presentation of Response value by Chest pain type;
* report in tablular form;

	* Picture format: Print values as a format of xxx.xx%;
		proc format;
		   picture pctfmt low-high="000.00%";
		run;

		proc tabulate data= HD_new;
			class Diag Cp;
			table (CP="" ALL="All Chest pain types"),
				  (Diag ALL)*(n*f=5. colpctn*f= pctfmt.) 
				  / box="Heart disease by Chest pain Type";
			keylabel All = "All responses"
					 n = "Count"
					 colpctn = "Col Percent";
		run;

		* Visualization; 
		proc sgpanel data= HD_new;
			panelby cp;
			vbar Diag;
		run;

* (3) By fbs: fasting blood sugar;

 		* Tabular comparison; 
  		proc tabulate data= HD_new;
			class Diag fbs;
			table (fbs="" ALL="All Chest pain types"),
				  (Diag ALL)*(n*f=5. colpctn*f= pctfmt.) 
				  / box="Heart disease by Chest pain Type";
			keylabel All = "All responses"
					 n = "Count"
					 colpctn = "Col Percent";
		run;

		* Visualization; 
		proc sgpanel data= HD_new;
			panelby fbs;
			vbar Diag;
		run;

		* The difference in heart disease status is more severe in the True fasting blood sugar subgroup, 
		we need a chi-square test for finding whether it's significant or not. 

* (4) By restecg: 0.08658, low correlation;
		
	proc freq data = HD_new;
		tables restecg * Diag / out=a outpct; 
		format 
			restecg restecg_fmt.  
			Diag diag_fmt.;
	run;

	* There is an evident stratification for heart disease status among these normal subjects 
	and people who are Having ST-T wave abnormality 

* (5) By exang:(r =  0.43696, p < 0.0001);
		proc freq data = HD_new;
		tables exang * Diag / out=a outpct; 
		format 
			exang exang_fmt.  
			Diag diag_fmt.;
		run;


* (6) By slope: (r = 0.32559, p < 0.0001)
		slope of the peak exercise;
		proc freq data = HD_new;
		tables slope * Diag / out=a outpct; 
		format 
			slope slope_fmt.  
			Diag diag_fmt.;
		run;

* (7) By thal: ( r = 0.46251, p < 0.0001);
		proc freq data = HD_new;
		tables thal * diag / out=a outpct; 
		format 
			thal thal_fmt.  
			Diag diag_fmt.;
		run;


*******************
* Hyothesis testing;*
*******************;

* Based on the EDA results above, we get some hints for the predictors modelling;
* Then we need to do our HT;

 * 1. one sample t test by gender for age;

		* Check normality;
		proc univariate data=HD_new normal;
			class sex;
			var age;
			histogram age;
			qqplot age;
		run;

* Shapiro-Wilk p-value;
* (large) 0.989357  reject H0;
* -> Assuming normality is not appropriate;

** Independent two-sample t-test: Wilcoxon rank sum test;
 proc npar1way data=HD_new wilcoxon;
		class sex;
			var age;
	run;
* t-test p-value > 0.05 cannot Reject H0;
* No Strong evidence to conclude that the two means are significantly different;



*  Two categorical variables chi-square test/Fisher's exact test; 
    * Variables: Sex, Cp, fbs, restecg, slope, thal; 

		* (3.0) CP is associated with outcome heart disease status? ; 
			* H0: Independent vs H1: Associated;
			*  Two categorical variables --> Chi-squared test

			*  Check the assumptions.
				a) No more than 1/5 of the cells have expected values <5.
				b) No cell has expected value <1;

			proc freq data = HD_new;
				table Diag * cp / chisq fisher;
			run;

			* (Chi-squared) 268.3457 p <.0001  (Fisher) <.0001;
			* ->  Reject H0;

			* Conclusion: 
			* It is not appropriate to accept the null hypothesis, at the significance level of 0.05, 
			* we can conclude that The heart disease status is not independent from the chest pain type; 


		* (3.1) fbs is associated with outcome? ; 
			* H0: Independent vs H1: Associated;
			*  Two categorical variables --> Chi-squared test

			*  Check the assumptions.
				a) No more than 1/5 of the cells have expected values <5.
				b) No cell has expected value <1;

			proc freq data = HD_new;
				table Diag * fbs/ chisq fisher;
			run;

			* (Chi-squared) 15.9365 p <.0001  (Fisher) <.0001;
			* ->  Reject H0;

			* Conclusion: 
			* It is not appropriate to accept the null hypothesis, at the significance level of 0.05, 
			* we can conclude that The heart disease status is not independent from the Fasting blood sugar type; 


		* (3.2) restecg is associated with outcome? ; 
			* H0: Independent vs H1: Associated;
			*  Two categorical variables --> Chi-squared test

			*  Check the assumptions.
				a) No more than 1/5 of the cells have expected values <5.
				b) No cell has expected value <1;

			proc freq data = HD_new;
				table Diag * restecg / chisq fisher;
			run;

			* (Chi-squared) 11.9125 p <.0001  (Fisher) <.0001;
			* ->  Reject H0;

			* Conclusion: 
			* It is not appropriate to accept the null hypothesis, at the significance level of 0.05, 
			* we can conclude that The heart disease status is not independent from the Resting electrocardiographic results; 


		* (3.3) exang is associated with outcome? ; 
			* H0: Independent vs H1: Associated;
			*  Two categorical variables --> Chi-squared test

			*  Check the assumptions.
				a) No more than 1/5 of the cells have expected values <5.
				b) No cell has expected value <1;

			proc freq data = HD_new;
				table Diag * exang / chisq fisher;
			run;

			* (Chi-squared) 195.9107 p <.0001  (Fisher) <.0001;
			* ->  Reject H0;

			* Conclusion: 
			* It is not appropriate to accept the null hypothesis, at the significance level of 0.05, 
			* we can conclude that The heart disease status is not independent from the Exercide inducedangina; 

	
		* (3.4) Slope is associated with outcome? ; 
			* H0: Independent vs H1: Associated;
			*  Two categorical variables --> Chi-squared test

			*  Check the assumptions.
				a) No more than 1/5 of the cells have expected values <5.
				b) No cell has expected value <1;

			proc freq data = HD_new;
				table Diag * slope / chisq fisher;
			run;

			* (Chi-squared) 108.8917 p <.0001  (Fisher) <.0001;
			* ->  Reject H0;

			* Conclusion: 
			* It is not appropriate to accept the null hypothesis, at the significance level of 0.05, 
			* we can conclude that The heart disease status is not independent from the slope; 


		* (3.5) Slope is associated with outcome? ; 
			* H0: Independent vs H1: Associated;
			*  Two categorical variables --> Chi-squared test

			*  Check the assumptions.
				a) No more than 1/5 of the cells have expected values <5.
				b) No cell has expected value <1;

			proc freq data = HD_new;
				table Diag * slope / chisq fisher;
			run;

			* (Chi-squared) 108.8917 p <.0001  (Fisher) <.0001;
			* ->  Reject H0;

			* Conclusion: 
			* It is not appropriate to accept the null hypothesis, at the significance level of 0.05, 
			* we can conclude that The heart disease status is not independent from the slope; 


		* (3.6) thal is associated with Heart disease status?; 
			* H0: Independent vs H1: Associated;
			*  Two categorical variables --> Chi-squared test

			*  Check the assumptions.
				a) No more than 1/5 of the cells have expected values <5.
				b) No cell has expected value <1;

			proc freq data = HD_new;
				table Diag * thal  / chisq fisher;
			run;

			* (Chi-squared) 253.5810 p <.0001  (Fisher) <.0001;
			* ->  Reject H0;

			* Conclusion: 
			* It is not appropriate to accept the null hypothesis, at the significance level of 0.05, 
			* we can conclude that The heart disease status is not independent from the thal variable; 

		* (3.7) sex is associated with Heart disease status?; 
			* H0: Independent vs H1: Associated;
			*  Two categorical variables --> Chi-squared test

			*  Check the assumptions.
				a) No more than 1/5 of the cells have expected values <5.
				b) No cell has expected value <1;

			proc freq data = HD_new;
				table Diag * sex  / chisq fisher;
			run;

			* (Chi-squared) 86.8698 p <.0001  (Fisher) <.0001;
			* ->  Reject H0;
			* Conclusion: 
			* It is not appropriate to accept the null hypothesis, at the significance level of 0.05, 
			* we can conclude that The heart disease status is not independent from sex; 


*******************
* Model Building  ;*
*******************;

* (a) * (1) Multinomial: Transform the Diag into the 5-level categorical variable -->(a);

	*1.0 extract data and define the format;
	data mlogit;
	  set HD;
	run; 
	
	proc format;
		value diag_mlogit
		 0 = "No presense of heart disease"
		 1 = "1 vessel > 50% diameter narrowing"
		 2 = "2 vessels > 50% diameter narrowing"
		 3 = "3 vessels > 50% diameter narrowing"
		 4 = "4 vessels > 50% diameter narrowing";
	run; 

	proc freq data = mlogit;
	 format diag diag_mlogit. ;
	 table diag;
	run; 

	* 1.1 Analyzing and stepwise
	* Categories: more than 2 levels --> multinomial logit model; 
	* The reference group should be specified as the first group  0 = "No presense of heart disease"; 
   
	* Probit link; 
	proc  HPGENSELECT data=mlogit;
	   class Sex cp fbs exang slope thal;
	   model diag = Sex age cp fbs exang chol trestbps oldpeak slope ca thal thalach
				/dist= Multinomial link = logit;             
                selection method=stepwise;
	RUN;

    * The logit link; 
    proc  HPGENSELECT data=mlogit;
	   class Sex cp fbs exang slope thal;
	   model diag = Sex age cp fbs exang chol trestbps oldpeak slope ca thal thalach
				/dist= Multinomial link = glogit;  
				*the diag variable is ordinal, 
				so choose logit link instead of glogit which is for nominal responses;               
                selection method=stepwise;
	RUN;

	* 1.2 Interaction; 
    proc  HPGENSELECT data=mlogit;
	   class Sex cp fbs exang slope thal;
	   model diag = Sex age cp thal | chol exang oldpeak slope ca thalach
				/dist= Multinomial link = logit;  
				*the diag variable is ordinal, 
				so choose logit link instead of glogit which is for nominal responses;               
                selection method=stepwise;
	RUN;

	proc  HPGENSELECT data=mlogit;
	   class Sex cp fbs exang slope thal;
	   model diag = Sex age cp thal | chol exang oldpeak slope ca thalach
				/dist= Multinomial link = glogit;  
				*the diag variable is ordinal, 
				so choose logit link instead of glogit which is for nominal responses;               
                selection method=stepwise;
	RUN;
  * In this model, interaction term is actually significant and finally being chosen.
   
   * 1.3 Compare ordinal link with the nominal link;
	* We have 9 variables in total; 

    * Use Logit (ordinal) link; 
	  proc logistic data=mlogit plots(only)=(roc effect);
			class diag(ref = "0") Sex cp fbs exang slope thal/  param=ref;
			model diag = Sex age Cp thal | chol  exang  slope  ca thalach /  link = logit lackfit outroc = roc_final;
	   run;
     * Use generalized logit link;
	   proc logistic data=mlogit plots(only)=(roc effect);
			class diag(ref = "0") Sex cp fbs exang slope thal/  param=ref;
			model diag = Sex age Cp thal | chol  exang  slope  ca thalach /  link = glogit lackfit outroc = roc_final;
	   run;
   * The goodness of fit:
	    * the hosmer-lemeshow results is 0.2141 for nomial glogit model, we shall reject the null hypothesis, and conclude our model is not good enough;
        * The hosmer-lemeshow results is 71.6449 for ordinal logit model, implying that the model may not be a good fit. 

   * 1.4 Final model; 
     * Use generalized logit link;
	   proc logistic data=mlogit plots(only)=(roc effect);
			class diag(ref = "0") Sex cp fbs exang slope thal/  param=ref;
			model diag = Sex age Cp thal | chol  exang  slope  ca thalach /  link = glogit lackfit outroc = roc_final;
	   run;

   * 1.5 Check the assumptions
   1. Outcome follows a categorical distribution
   2. Independence of observational units

* (2) Binomial: Logistic model-->(b); 

  * 2.0 recode variable Diagnal as a binary varibale to fit a binomial logistic regression model;
	  
		data binlogit;
		  set HD_new;
			if diag = 0 then bindiag = 0;
			else if diag = 1 then bindiag = 1;
			else if diag = 2 then bindiag = 1;
			else if diag = 3 then bindiag = 1;
			else if diag = 4 then bindiag = 1;
		run; 

		data binlogit;
			set binlogit;
			label bindiag = "Binomial heart disease status";
		run; 
		* generate new format for binary variable; 
		proc format;
			value binomial_fmt
			 0 = "No presense of heart disease"
			 1 = "Presense of Heart disease";
		run; 

	    * check recoded data; 
		proc freq data = binlogit;
		 format bindiag binomial_fmt. ;
		 table bindiag;
		run; 

  * 2.1 Tentative model results: exclude restecg and detect multicollinearity; 
	 * Overall correlation;
		proc corr data = binlogit;
		run; quit;

   * From this correlation matrix, we can see no highly correlated predictor pairs in this dataset,
		thus we shall not drop variables by using this approach;


  * 2.2. Analyzing and stepwise
	* Model selection: PROC HPGENSELECT;
		 proc logistic data= binlogit;
		    class bindiag(ref ="0") Sex cp fbs exang restecg slope thal;
		    model bindiag (ref ="0")= Sex age Cp trestbps chol fbs restecg thalach exang oldpeak slope ca thal                                  
			/ lackfit outroc = roc selection = stepwise; * Set the reference baseline as "No presence of heart disease";
		run;

		
   * From this tentative model, we find that the fbs thalach and slope may not be good predictors,
     then we need to carry on with a formal model selection process; 
 

  * 2.3. Interaction terms detection;

		* Based on clinical literature review: Thal and chol may have some interaction effect; 
		proc logistic data= binlogit;
		    class bindiag(ref ="0") Sex cp fbs exang slope thal;
		    model bindiag (ref ="0")= Sex age Cp  chol | thal exang  oldpeak slope  ca                                 
			/ lackfit outroc = roc1 selection = stepwise; * Set the reference baseline as "No presence of heart disease";
		run;

		* The stepwise result shows that the interaction term is not choosen, so we may not include this in the final model.

    * Final Model: binomial; 
	   proc logistic data= binlogit plots(only)=(roc effect);
			class bindiag(ref ="0") Sex cp fbs exang slope thal/  param=ref;
			model bindiag = Sex age Cp chol thal  exang oldpeak slope ca  / lackfit outroc = roc_final;
	   run;

  * 2.4. Assumptions test

	* Predictor collinearity and ill-conditioned information matrix;
       proc reg data= binlogit;
         model bindiag = Sex age Cp chol thal  exang oldpeak slope ca   / vif;
       run; quit;
	* There is no variable has a vif > 10, so also confirms that there is no multicollinearity in the final model. 

  * 2.5 Goodness of Fit
	   * The hosmer-lemeshow statistic is 11.3453 with df = 8, 
	   * At a = 0.05 we fail to reject the hypothesis that the data fit the model (p = 0.1829). 
	   Therefore we conclude that the model provides adequate fit.




*******************************
*   Conclusion: Final Model    ;*
*******************************;

* Based on the comparison of AIC, BIC and the model interpretability, the binomial logistic model is more suitable for 
  prediction of the heart disease; 

	 proc logistic data= binlogit plots(only)=(roc effect);
			class bindiag(ref ="0") Sex cp fbs exang slope thal/  param=ref;
			model bindiag = Sex age Cp chol thal  exang oldpeak slope ca  / lackfit outroc = roc_final;
	   run;


* Final model interpretation:

* SEX: Adjusted for all other risk factors, female subjects have 161% increase
 (i.e. exp(0.9558)= 2.601 times) in the expected number of being diagnosed as heart disease
	Compared with the male subjects;

* cp: Adjusted for all other risk factors, For subjects who have cp Asymptomatic have 2.03 times increases
 (i.e. exp(1.1098)= 3.034 times) in the expected number of being diagnosed as  heart disease
	Compared with the  Typical angina subjects;

* cp: Adjusted for all other risk factors, For subjects who have cp Atypical angina have 55% times decreases
 (i.e. exp(-0.8096)= 0.445 times) in the expected number of being diagnosed as heart disease
	Compared with the  Typical angina subjects;

* cp: Adjusted for all other risk factors, For subjects who have cp Non-anginal pain have 27.1% decreases
 (i.e. exp(-0.3159)= 0.729 times) in the expected number of being diagnosed as heart disease
	Compared with the Typical angina subjects;

* thal: adjusted for all other covariates, For subjects respond fixed defect in thal, 
	 they have 45.3% decreases(i.e. exp(-0.6029)= 0.547 times) in the expected number of 
	  being diagnosed as heart disease Compared with those  reversable defect subjects; 

* thal: adjusted  for all other covariates, For subjects respond normal defect in thal, 
	 they have 81.3% decreases(i.e. exp(-1.6779)= 0.187 times) in the expected number of 
	  being diagnosed as heart disease Compared with those reversable defect subjects; 

* Slope: Adjusted for all other covariates, these with downsloping have 29.5% increases
 (i.e. exp(.2586)= 1.295 times) in the expected number of being diagnosed as heart disease
	Compared with those upsloping subjects;

* Slope: Adjusted for all other covariates, these with  downsloping  have 29.5% increases
 (i.e. exp(.2586)= 1.295 times) in the expected number of being diagnosed as heart disease
	Compared with those upsloping subjects;

* Exchg: Adjusted for all other covariates, these with no in exang have 62% decreases
 (i.e. exp(-0.9688)= 0.380 times) in the expected number of being diagnosed as heart disease
	Compared with those who gave yes to exchg subjects;

* For one unit increase in age, the odds of having heart disease increases by  
  by 2.7 % (ie:exp(0.2586) = 1.027) times adjusted for all other covariates;

* For one unit increase in chol, the odds of having heart disease decreases 
  by 0.4 % (i.e. exp(-0.00423) = 0.996) times adjusted for all other covariates;

* For one unit increase in ca, the odds of having heart disease increases by  
  by 160 % (exp(0.9562) = 2.602 times) adjusted for all other covariates;

* For one unit increase in oldpeak, the odds of having heart disease increases by  
  by 49.50 % (ie:exp(0.4023) = 1.495) times adjusted for all other covariates;


*************************************************************************************************************************
Final ANALysis: 

* From the two model comparison, we find that the binomial categorization and nomial(unordered) logit model is more suitable 
  for modelling the diagnostic results compared with the ordered multinomial model;

* This result shows that for prediction of the test results, it is hard to tell the degree of heart disease level while more 
  reasonable to compared whether or not the subject has caught up with the disease. 

* The demographical: Sex age is always included in the model and shows their significance;
* The overlapping of variables of thal chol exang slope  ca thalach Cp shows that the disease diagnosis maybe 
  highly correlated with these clinical symptoms; 

 ****Appendix*********;

	   proc sgplot data= mlogit;
		vbar Diag/group = sex;
	   run;

ods rtf close; 
