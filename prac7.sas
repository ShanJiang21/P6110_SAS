*************************************
* Statistical Computing with SAS	*
* Practice 7					    *
* Shan Jiang (Columbia University) 	*
*									*
*************************************



/a/***************************************

1. Import dataset, name as Wage;
libname prac7 "C:\Users\PubLibrary\Desktop\Practice7";

proc import out = wage
		   	datafile= "C:\Users\PubLibrary\Desktop\Practice7\Wage.xlsx"
		   	dbms = xlsx replace;
		   	sheet = "Wage"; 
		   	getnames=yes;
run; 

proc print data=wage (obs=5) label;run;

*/b/*************************************** 
* Descriptive statistics

* i. Frequency table and bar chart of race;

proc freq data = wage;
	table Race; 
run;

* Bar chart;
proc sgplot data=wage;
	vbar Race;
	xaxis label="Race";
run;
***************************************
From the frequency table, we find that white people takes the majority of the total sample while Asian, Black and other races 
only accounts for a small portition in this dataset. 
*****************************************;

* ii. Distribution of age

* 1) Descriptive statistics (n, mean, median, standard deviation, min, max);

proc means data=wage n mean median std min max maxdec=2;
	var age;
run;

* 2) Histogram (binwidth = 10);

proc sgplot data=wage;
	histogram age;
	density age/ type=kernel;/*I also add a density curve*/
run;
***************************************
From the descriptive statistics, we find that mean age for the whole sample is 42.4, while the median is also around this value, it approximates to
symmetry while there are some extreme values at the right hand side which may biase the mean age. 
*****************************************;


* iii. Distribution of wage depending on education level;

* 1) Descriptive statistics (n, mean, median, standard deviation, min, max);

proc means data=wage n mean median std min max maxdec=2;
	var Wage ;
    class Education;
run;

* 2) Boxplots;
proc sgplot data=wage;
	vbox Wage / group = Education;
run;


***************************************

From the descriptive statistics, we find that the higher education level one is, the higher mean wage is for people on average. Also, with 
the education level rises, within-group variance grows more than lower-level educated individuals since the standard deviation varies.
There are also many outliers in the Wage variable in the high-educated groups, so this may also affects the mean distribution for group comparison.  

*****************************************;

*/c/ ***************************************;

*  Produce the following report;
proc report data=wage nowindows;
	column Education N Jobclass, (age Wage),(mean std);
	define Education / group;
	define Jobclass / across;
	define Age / format = 5.2;
	define Wage / format = 5.2;
run;

*/d/***************************************;
proc tabulate data= wage;
	class Education Marital Jobclass;
	table (Jobclass="" ) * (Education ="" All), (Marital All)*(n)
			/ box = "Job class and education level" printmiss;
	keylabel N = "Freq"
			 All = "Total"; 		  
run;

*/e/***************************************;

* i. Is the mean age different from 40; 
 	* H0: mu_age = 40 vs H1: mu_age not equal to 40;
	* -> Independent Two-sample t-test;
 
* Check Assumptions: normality;

proc univariate data=Wage mu0 = 40 normal;
	var Age;
	histogram Age;
	qqplot Age;
run;

* Shapiro-Wilk p-value;
* (: Fail to reject H0;
* -> Assuming normality is appropriate;

* Student's t t = 11.45833, then we have P-value as of <.0001.





ii. Is there a difference in mean wage depending on education level;
 
	* H0: mu_<HS = mu_HS = mu_somecol = mu_ColGrad = mu_Adv
	* vs H1: Not H0 (At least one pair has different means.);	
	* -> More than 2 categories: ANOVA; 

* Check the normality;
proc univariate data=wage normal;
	class Education;
	var Wage;
	histogram Wage;
	qqplot Wage;
run;

* Shapiro-Wilk p-value;
* (<HS ) 0.980066  (Hs grad)0.895972  (Some College)  0.883032 (College Grad) 0.910937 (Advanced)0.895648 (< 0.0001) ;
* -> Normality assumption is NOT appropriate;






* iii. Is the proportion of having health insurance less than 70%; 

* One-sample test for binary proportion;
proc freq data= wage;
table Insurance / binomial(p =.70); * H0: p=0.7;
run;



* iv. Among those who were never married, is job class independent of education level; 

proc freq data= wage;
table Jobclass * Marital / binomial(p =.70); * H0: p=0.7;
run;

* McNemar's Test;* AGREE: Paired sample;
procfreqdata=Paired;tablesDr1*Dr2 / agree;weightcount;run;

ods rtf close; 
