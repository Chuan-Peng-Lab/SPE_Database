* Encoding: UTF-8.

GET 
  FILE=C:\Users\User\Desktop\studies\target_tasks\MT.sav'.
DATASET NAME DataSet1 WINDOW=FRONT. 

SORT CASES BY Subject (A).
EXECUTE.

MATCH FILES /FILE=*
 /FILE='C:\Users\User\Desktop\studies\target_tasks\DIS.sav'
 /BY Subject.
EXECUTE. 

** Boxplot Matching Task.
COMPUTE RTmean_MT = MEAN(imRTmean, inRTmean, fmRTmean, fnRTmean).
COMPUTE ERsum_MT = SUM(imER, inER, fmER, fnER).
EXECUTE.

EXAMINE VARIABLES=RTmean_MT ERsum_MT
  /PLOT BOXPLOT STEMLEAF
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

**Boxplot Discrimination task.
COMPUTE RTmean_DIS = MEAN(liRTmean_DIS, lfRTmean_DIS, piRTmean_DIS, pfRTmean_DIS, siRTmean_DIS, sfRTmean_DIS).
COMPUTE ERsum_DIS = SUM(liER_DIS, lfER_DIS, piER_DIS, pfER_DIS, siER_DIS, sfER_DIS).
EXECUTE.

EXAMINE VARIABLES=RTmean_DIS ERsum_DIS
  /PLOT BOXPLOT STEMLEAF
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

**Exclude all outliers.
USE ALL.
COMPUTE filter_$=(Subject ~= 5 and Subject ~= 6 and Subject ~= 20 and Subject ~= 23 and Subject ~= 24 and Subject ~= 27).
VARIABLE LABELS filter_$ 'Subject ~= 5 and Subject ~= 6 and Subject ~= 20 and Subject ~= 23 and Subject ~= 24 and Subject ~= 27(FILTER)'.
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'.
FORMATS filter_$ (f1.0).
FILTER BY filter_$.
EXECUTE.


*************************************
******* MATCHING TASK *******.
* overall MANOVA: association Condition (Ich vs. Fremder) x matching (matching vs. non-matching).
GLM imRTmean inRTmean fmRTmean fnRTmean
    /WSFACTOR=Condition 2 Helmert match 2 Polynomial
    /METHOD=SSTYPE(3)
    /PRINT=DESCRIPTIVE ETASQ
    /CRITERIA=ALPHA(.05)
    /WSDESIGN=Condition match Condition*match.

*only matching.
GLM imRTmean fmRTmean
    /WSFACTOR=Condition 2 Helmert
    /METHOD=SSTYPE(3)
    /PRINT=DESCRIPTIVE ETASQ
    /CRITERIA=ALPHA(.05)
    /WSDESIGN=Condition.

*only non-matching.
GLM inRTmean fnRTmean
    /WSFACTOR=Condition 2 Helmert
    /METHOD=SSTYPE(3)
    /PRINT=DESCRIPTIVE ETASQ
    /CRITERIA=ALPHA(.05)
    /WSDESIGN=Condition.

*computation of the SPE.
COMPUTE SPErt=fmRTmean-imRTmean.
EXECUTE.

*SPE sign > 0?.
T-TEST
    /TESTVAL=0
    /MISSING=ANALYSIS
    /VARIABLES=SPErt
    /CRITERIA=CI(.95).

* overall MANOVA to depict error data pattern for table.
GLM imER inER fmER fnER
    /WSFACTOR=Condition 2 Helmert match 2 Polynomial
    /METHOD=SSTYPE(3)
    /PRINT=DESCRIPTIVE ETASQ
    /CRITERIA=ALPHA(.05)
    /WSDESIGN=Condition match Condition*match.

* computation of sensitivity, d' (!! for 32 trials in each condition!!).
*** Ich ***.
* hits.
COMPUTE dIH=32-imER+0.5.
EXECUTE.
* missings.
COMPUTE dIM=imER+0.5.
EXECUTE.
* false alarms.
compute dIFA=inER+0.5.
EXECUTE.
* correct rejections.
COMPUTE dIZ=32-inER+0.5.
EXECUTE.

*** Fremder ***.
COMPUTE dFH=32-fmER+0.5.
COMPUTE dFM=fmER+0.5.
COMPUTE dFFA=fnER+0.5.
COMPUTE dFZ=32-fnER+0.5.
EXECUTE.

* relative quotas.
* added 1 on sum of squares.
COMPUTE dIHrel=dIH/33.
COMPUTE dIFArel=dIFA/33.

COMPUTE dFHrel=dFH/33.
COMPUTE dFFArel=dFFA/33.
EXECUTE.

* z-transformation.
COMPUTE zdIHrel = idf.normal(dIHrel,0,1).
COMPUTE zdIFArel = idf.normal(dIFArel,0,1).
COMPUTE dI = zdIHrel - zdIFArel.

COMPUTE zdFHrel = idf.normal(dFHrel,0,1).
COMPUTE zdFFArel = idf.normal(dFFArel,0,1).
COMPUTE dF = zdFHrel - zdFFArel.
EXECUTE.

**** DATA ANALYSES: SENSITIVITY ****.
* overall ANOVA with d' to analyze data pattern.
GLM dI dF
  /WSFACTOR=Form 2 Helmert 
  /METHOD=SSTYPE(3)
  /PRINT=DESCRIPTIVE ETASQ 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=Form.

* computation of the hypothesized SPE.
COMPUTE SPEd = dI - dF.
EXECUTE.

* SPE sign. > 0?.
T-TEST
  /TESTVAL=0
  /MISSING=ANALYSIS
  /VARIABLES=SPEd
  /CRITERIA=CI(.95).

************************************
************************************
***** DISCRIMINATION TASK ******

** ANOVA: targLocation (Ich vs. Fremder) x procedure (Pairing vs. Label vs. Shape).
GLM liRTmean_DIS siRTmean_DIS piRTmean_DIS lfRTmean_DIS sfRTmean_DIS pfRTmean_DIS
  /WSFACTOR=targLocation 2 Polynomial procedure 3 Polynomial 
  /METHOD=SSTYPE(3)
  /PLOT=PROFILE(procedure*targLocation)
  /PRINT=DESCRIPTIVE ETASQ 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=targLocation procedure targLocation*procedure.

COMPUTE LDIScuing_RT = lfRTmean_DIS - liRTmean_DIS.
COMPUTE SDIScuing_RT = sfRTmean_DIS - siRTmean_DIS.
COMPUTE PDIScuing_RT = pfRTmean_DIS - piRTmean_DIS.
EXECUTE.

COMPUTE LDISmean_RT = MEAN(lfRTmean_DIS, liRTmean_DIS).
COMPUTE SDISmean_RT = MEAN(sfRTmean_DIS, siRTmean_DIS).
COMPUTE PDISmean_RT = MEAN(pfRTmean_DIS, piRTmean_DIS).
EXECUTE.


T-TEST
  /TESTVAL=0
  /MISSING=ANALYSIS
  /VARIABLES= LDIScuing_RT SDIScuing_RT PDIScuing_RT
  /CRITERIA=CI(.95).

**Comparison between representation types**.
T-TEST PAIRS=LDIScuing_RT PDIScuing_RT PDIScuing_RT WITH SDIScuing_RT LDIScuing_RT SDIScuing_RT (PAIRED)
  /CRITERIA=CI(.9500)
  /MISSING=ANALYSIS.

**mean RT per representation type***.
COMPUTE LDISmean_RT = MEAN(lfRTmean_DIS, liRTmean_DIS).
COMPUTE SDISmean_RT = MEAN(sfRTmean_DIS, siRTmean_DIS).
COMPUTE PDISmean_RT = MEAN(pfRTmean_DIS, piRTmean_DIS).
EXECUTE.

T-TEST PAIRS=LDISmean_RT SDISmean_RT LDISmean_RT WITH PDISmean_RT PDISmean_RT SDISmean_RT (PAIRED)
  /CRITERIA=CI(.9500)
  /MISSING=ANALYSIS.


*  error data.
GLM liER_DIS siER_DIS piER_DIS lfER_DIS sfER_DIS pfER_DIS
  /WSFACTOR=targLocation 2 Polynomial procedure 3 Polynomial 
  /METHOD=SSTYPE(3)
  /PRINT=DESCRIPTIVE ETASQ 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=targLocation procedure targLocation*procedure.

COMPUTE LDIScuing_ER = lfER_DIS - liER_DIS.
COMPUTE SDIScuing_ER = sfER_DIS - siER_DIS.
COMPUTE PDIScuing_ER = pfER_DIS - piER_DIS.
EXECUTE.

T-TEST
  /TESTVAL=0
  /MISSING=ANALYSIS
  /VARIABLES= LDIScuing_ER SDIScuing_ER PDIScuing_ER
  /CRITERIA=CI(.95).

******DESCRIPTIVES******

COMPUTE gral_ich=MEAN(liRTmean_DIS,piRTmean_DIS,siRTmean_DIS). 
EXECUTE. 
COMPUTE gral_fremder=MEAN(lfRTmean_DIS,pfRTmean_DIS,sfRTmean_DIS). 
EXECUTE. 
COMPUTE gral_label=MEAN(lfRTmean_DIS, liRTmean_DIS). 
EXECUTE. 
COMPUTE gral_shape=MEAN(sfRTmean_DIS, siRTmean_DIS). 
EXECUTE. 
COMPUTE gral_pair=MEAN(pfRTmean_DIS, piRTmean_DIS). 
EXECUTE. 

DESCRIPTIVES VARIABLES=gral_ich gral_fremder gral_label gral_shape gral_pair liRTmean_DIS 
    lfRTmean_DIS piRTmean_DIS pfRTmean_DIS siRTmean_DIS sfRTmean_DIS 
  /STATISTICS=MEAN STDDEV MIN MAX.

