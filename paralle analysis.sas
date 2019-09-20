**Load the macro first**;
ods listing close;
%macro parallel(data=_LAST_, var=_NUMERIC_,niter=1000, statistic=Median);
/*--------------------------------------*
| Macro Parallel |
| Parameters |
| data = dataset to be analyzed |
| (default: _LAST_) |
| var = variables to be analyzed |
| (default: _NUMERIC_) |
| niter= number of simulated datasets |
| to create (default: 1000) |
| statistic = statistic used to |
| summarized eigenvalues |
| (default: Median. Other |
| possible values: P90, |
| P95, P99) |
| Output |
| Graph of actual vs. simulated |
| eigenvalues |
*--------------------------------------*/
data _temp;
set &data;
keep &var;
run;
/* obtain number of observations and
variables in dataset */
ods output Attributes=Params;
ods listing close;
proc contents data=_temp ;
run;
ods listing;
data _NULL_;
set Params;
if Label2 eq 'Observations' then
call
symput('Nobs',Trim(Left(nValue2)));
else if Label2 eq 'Variables' then
call
symput('NVar',Trim(Left(nValue2)));
run;
/* obtain eigenvalues for actual data */
proc factor data=_temp nfact=&nvar noprint
outstat=E1(where=(_TYPE_ = 'EIGENVAL'));
var &var;
run;
data E1;
set E1;
array A1{&nvar} &var;
array A2{&nvar} X1-X&nvar;
do J = 1 to &nvar;
A2{J} = A1{J};
end;
keep X1-X&nvar;
run;
/* generate simulated datasets and obtain eigenvalues */
%DO K = 1 %TO &niter;
data raw;
array X {&nvar} X1-X&nvar;
keep X1-X&nvar;
do N = 1 to &nobs;
do I = 1 to &nvar;
X{I} = rannor(-1);
end;
output;
6
end;
run;
proc factor data=raw nfact=&nvar noprint
outstat=E(where=(_TYPE_ =
'EIGENVAL'));
var X1-X&nvar;
proc append base=Eigen
data=E(keep=X1-X&nvar);
run;
%END;
/* summarize eigenvalues for simulated datasets */
proc means data=Eigen noprint;
var X1-X&nvar;
output out=Simulated(keep=X1-X&nvar)
&statistic=;
proc datasets nolist;
delete Eigen;
proc transpose data=E1 out=E1;
run;
proc transpose data=Simulated out=Simulated;
run;
/* plot actual vs. simulated eigenvalues */
data plotdata;
length Type $ 9;
Position+1;
if Position eq (&nvar + 1)
then Position = 1;
set E1(IN=A)
Simulated(IN=B);
if A then Type = 'Actual';
if B then Type = 'Simulated';
rename Col1 = Eigenvalue;
run;
title height=1.5 "Parallel Analysis -
&statistic Simulated Eigenvalues";
title2 height=1 "&nvar Variables, &niter
Iterations, &nobs Observations";
proc print data = plotdata;
run;
symbol1 interpol = join value=diamond height=1 line=1 color=blue;
symbol2 interpol = join value=circle height=1 line=3 color=red
;
proc gplot data = plotdata;
plot Eigenvalue * Position = Type;
run;
quit;
%mend parallel;
 
**Import data**;
PROC IMPORT 
OUT = WORK.A 
DATAFILE= "C:\Users\PubLibrary\Desktop\hw2\genetictestingrawdata.csv"
DBMS = csv REPLACE;
GETNAMES = YES; 
RUN;

options nocenter;
%parallel(data=a, var= c7 c10 c12 c13 c16 c20, niter=100, statistic = P95);

** Use SAS to calculate Alpha;
ods graphics on;
ods rtf file="C:\Users\PubLibrary\Desktop\hw2\table.rtf"; /* MS-Word format */
proc corr data = WORK.A  nomiss alpha plots;
title 'Genetics Testing Data';
var c7 c10 c12 c13 c16 c20;
run;
ods rtf close; /* cannot be viewed until closed */
ods graphics off;
