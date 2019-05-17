*****************************************
* P6110: Statistical Computing with SAS *
* Spring 2019                           *
* Practice3 SAS Reporting               *
* Shan Jiang(Columbia University)       *
*****************************************;

**Problem 1**;

**a) Import the dataset**;
libname prac3 "C:\Users\PubLibrary\Desktop\practice";

	*respiratory dataset*;

/**import data**/ 

proc import out= prac3.respiratory
datafile ="C:\Users\PubLibrary\Desktop\practice\respiratory.xlsx"
dbms = xlsx replace;
sheet = "respiratory";
getnames = yes;
run;
** There are in total 555 rows and 7 variables in this dataset;

** Save the pdf document; 

ods pdf file= "C:\Users\PubLibrary\Desktop\practice\hw3.pdf"; /* PDF format */

**b) subset the dataset at baseline;
data prac3.baseline;
	set  prac3.respiratory; 
	if month  < 1; /*baseline month is 0*/
run; 
proc print data = prac3.baseline (obs = 5);
title "b.Baseline subset data with obs = 5";
run;

**c). Create format and apply it to the subset; 
proc format; 
value centerfmt  1 = "Center A"
				 2 = "Center B";
run; 
data prac3.format;
set prac3.baseline;
format center centerfmt.;
run;
proc print data = prac3.format(obs = 5);
title "c. formatted data center";
run; 

**d)Descriptive statistics; 
** i. Distribution of age at each study center; 
** 1) Provide descriptive statistics (n, mean, median, standard deviation, min, max);
PROC MEANS DATA = prac3.format n mean median std min max MaxDec = 2; **\specify the digit numbers = 2;
  class center;
  var age;
  title "d)i.1 Descriptive statistics of age by center";
RUN;

** 2) Create a histogram. (Hint: Use proc sgpanel.); 
proc sgpanel data = prac3.format;
	panelby center/ novarname;
	histogram age;
	title "d)i.2 Histogram of age by center";
run;

** ii. Frequency table;
** 1) PROC FREQ (nocol norow nopercent); 
PROC FREQ data= prac3.format;
		  title1"d)ii.1  Frequency table";
          tables status * treatment / nocol norow nopercent; 
run;

** 2) PROC TABULATE (Add total counts for both columns and rows);
Proc tabulate data= prac3.format;
	title1"d)ii.2  Frequency table adding sums";
	class status treatment; /*categorical variables*/
	table status all, treatment all;   /*2 dimensional (1 comma)*/
run; /*All -- calculate row or column totals*/


**e).Produce the following report; 
**ACROSS and GROUP appropriately**;
 proc report data= prac3.format nowindows;
      title1 "e) produce the following report";
      column center N treatment, sex, age, (mean std);
      define center / group;
      define sex/ across;
      define treatment/ across;
	  define mean /"mean" center;
	  define std / "std" center;
	  define age/ format = 4.2;  **Specify 2 decimal points; 
  run;

**f). Produce the following table;
**Use ALL option appropriately. Rename N, ALL, mean and std;
proc tabulate data= prac3.format;
title1"f)  two center Report";
	class treatment status center;
	var age;
	table (treatment = "" ALL) * (status = "" ALL), age * (center = "" ALL)* (N mean std)
	/box= 'Treatment and Respiratory status';
	keylabel all = 'Total'
			 n = 'Freq'
			 mean = 'Average'
			 std = 'DV';
run; 

ods pdf close;
