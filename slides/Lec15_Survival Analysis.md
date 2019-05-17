## Survival Analysis

Chapter 12:

Y | X ~ N($\mu, \sigma^2$)

Y |X ~ Bin($\pi$)

Y |X ~ Piosson($\lambda$)

### Chapter 16

#### **Time-to-Event**

​						**Origin** —— —— —— —— **Event**

​						     <—— —————————>

​									T $\geq$ 0

- In many clinical/medical researches, the ‘time to event’ *T* is a variable of primary interest. - *T*: None-negative random variable
   \- Event: Death, failure, equipment breakdown, development of some disease, etc.
   \- Clinical endpoint, survival time, of failure time 
- Generally, not symmetrically distributed.
   \- Only few subjects survive longer compared to the majority. 
- Survival time is right censored.
   \- At the end of the study, some subjects may not have reached the endpoint of interest. - Assumption: Time-to-event is independent of the censoring mechanism. 

#### **Incomplete Data: Censoring**

<u>Censoring:</u> When an observation is incomplete due to some random cause.

Right censoring: O —— —— X……... **E**

* drop out of the study, lost to follow up 
* Description: The individual is still alive or has not experienced the event of interest at the end of the study.
* $\Lambda(t) = -logS(t)$
* Treatment v.s Placebo curves 

------

​								**Why not  a T test?**

------

1 O —— —— *…….... | t = 4  Trt = 1     E = 1

2 O —— —X…………… | t = 3  Trt = 1 **+**   E = 0 

3      O —— —X………  | t = 4  Trt = 0 **+ **  E = 0 (biased, so also not for logistic regression)

4        O ——X…………  | t = 2  Trt = 0    E = 1



#### SAS Code

```SAS
Proc lifetest data = dataset plots = (Survival);
 time time-variable * censoring -indicator(0); 
run; 
```

* Lukemia Data 

  | obs| day |treatment | status

  ```SAS
  Proc lifetest data =lukemia plots =(survival(cl)) logsurv OutsurV = est; 
  *confidence interval- logsurv is for cumulative hazards 
   time day * status(0);
  run; 
  ```

  Interpretation: 

  * Median survival time: Survival probability = 0.5, at what time point.
  * Q1- 25, Q2- 50, Q3 - 75: 
  * OutsurV has the censoring indicator, extract the exact instantaneous failure rate. 

```SAS
* + is for censored data 
Proc lifetest data =lukemia plots =(survival(cl));
 strata treatment /test = (all);
 time day * status(0);
run;
```

+ Remission: The lower, the better. 
+ The Life table / kaplan-Meier 

#### Hypothesis testing 

In the whole time domain, we need to compare different survival curves. 

$H_0 : S_1(t)  = … = S_j(t) $ for all t

The weighting strategy are not the same, let's first focus on log-rank. 

Three curves, and df =2.  

P > 0.05 —> Fail to reject the null, so the 2 curves are not quite different 

Probably because of the beginning similarity; 

Thus, we need some adjustment. 

```SAS
proc lifetest data =lukemia plots =(survival(cl));
 strata treatment / test = logrank adjust = dunnett diff = control("1");
run; 
```

The corrected p-value, was higher than the raw value. 

#### Proportional Hazards (PH) Model 

Also known as **Cox's regression** 

Link the survival functions to multiple covariates (explantory variables)

Quantify the effect of a certain predictor on survival function; 

Allow to predict survival functions; 

$h(t)  = h_0(t) e^{\beta_0 \times Male + \beta2 \times Age + \beta_3 \times BMI}​$

Cancel the $h_0(t)​$. 

$h(t) | Male $ having Age and BMI fixed 

$h(t) | Female ​$ having Age and BMI fixed  

Hazard Ratio =$ \frac{ h_0(t) e^{\beta_0 \times Male + \beta2 \times Age + \beta_3 \times BMI}}{ h_0(t) e^{ \beta2 \times Age + \beta_3 \times BMI}}​$ = $e^{\beta_{0}}​$

HR > 1 —> Male Hazards is bigger;

HR < 1 —> Female Hazards is bigger;

**Assumption**: 

the hazards rate is $ \frac{ h_0(t) }{ h_1(t)}$  = C, 

so the $h_1(t) = c\times h_0(t)​$,

then integrate $H_1(t) = c\times H_0(t)​$, constant C

If we take log of both sides:

$log(H_1(t))= logC +  log(H_0(t))$, no longer proportional,  just the additive.

Then the survive rate curve, it will not cross. 

----

#### SAS Code 

<u>Analysis steps</u> 

1. Start by checking the K-M estimates. 

2. Fit the Cox proportional hazard (PH) model and get the hazard ratio (HR). 

3. Test the proportionality assumption. 

   ⇒ For each covariate,
    i) Plot survival functions / cumulative hazard functions / log(cumulative hazard). ii) Include an interaction term with time (usually log(time)). 

   Proportionality condition is met if the interaction terms are not significant

   

   4. * If the proportionality assumption is not satisfied, 

1. Check the functional form of continuous variables. (e.g. Linear, quadratic, categorized form) 
2. Look at the residuals. (Random pattern of residuals evenly distributed around zero) 

```SAS
rl =  risk limits;
* Confidence limit of Hazards Ratio 
```

Multiple predictors : Treatment, age and race 

```SAS
proc phreg 
loglogs: log of cumulative hazards = difference in the intercept 
```

* The continuous: Assess-`Age` variable  
* We don't want to reject the null hypothesis 

The range of residual 

K-M Check 

PH model check

Functionality 

interaction 

Numeric varibale 

residuals check 

Give appropirate interpretation of the hazards ratio 