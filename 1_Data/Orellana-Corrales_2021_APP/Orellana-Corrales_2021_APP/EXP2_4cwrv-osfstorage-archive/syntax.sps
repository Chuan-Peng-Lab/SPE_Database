* Encoding: UTF-8.

GET FILE ='C:\Users\User\Desktop\data\nonwords\matching_3.sav'.

SORT CASES BY Subject (A).
EXECUTE.

MATCH FILES /FILE=*
 /FILE='C:\Users\User\Desktop\data\nonwords\dotprobe_3.sav'
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

**Boxplot Dot Probe.
COMPUTE RTmean_DOT = MEAN(liRTmean_DOT, lfRTmean_DOT, niRTmean_DOT, nfRTmean_DOT).
COMPUTE ERsum_DOT = SUM(liER_DOT, lfER_DOT, niER_DOT, nfER_DOT).
EXECUTE.

EXAMINE VARIABLES=RTmean_DOT ERsum_DOT
  /PLOT BOXPLOT STEMLEAF
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

**Exclude all outliers.
USE ALL.
COMPUTE filter_$=(Subject ~= 4 and Subject ~= 33).
VARIABLE LABELS filter_$ 'Subject ~= 4 and Subject ~= 33(FILTER)'.
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'.
FORMATS filter_$ (f1.0).
FILTER BY filter_$.
EXECUTE.

*************************************
******* MATCHING TASK *******.
* overall MANOVA: association Condition (Ich vs. Fremder) x matching (matching vs. non-matching).
* Multivariate tests and Tests of Within-Subjects Effects can be compared for ANOVA and MANOVA analyses results. 
GLM imRTmean inRTmean fmRTmean fnRTmean
    /WSFACTOR=Condition 2 Helmert match 2 Polynomial
    /METHOD=SSTYPE(3)
    /PLOT=PROFILE(Condition*match)
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
***** DOT PROBE TASK ******

** ANOVA: targLocation (Ich vs. Fremder) x procedure (Pairing vs. Label vs. Shape).
GLM liRTmean_DOT niRTmean_DOT lfRTmean_DOT nfRTmean_DOT
  /WSFACTOR=targLocation 2 Polynomial procedure 2 Polynomial 
  /METHOD=SSTYPE(2)
  /PLOT=PROFILE(procedure*targLocation)
  /PRINT=DESCRIPTIVE ETASQ 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=targLocation procedure targLocation*procedure.

COMPUTE Lcuing_RT = lfRTmean_DOT - liRTmean_DOT.
COMPUTE Ncuing_RT = nfRTmean_DOT - niRTmean_DOT.
EXECUTE.

T-TEST
  /TESTVAL=0
  /MISSING=ANALYSIS
  /VARIABLES= Lcuing_RT Ncuing_RT
  /CRITERIA=CI(.95).

**Comparison between representation types**.
T-TEST PAIRS=Lcuing_RT WITH Ncuing_RT (PAIRED)
  /CRITERIA=CI(.9500)
  /MISSING=ANALYSIS.

**mean RT per representation type***.
*COMPUTE Lmean_RT = MEAN(lfRTmean_DOT, liRTmean_DOT).
*COMPUTE Nmean_RT = MEAN(nfRTmean_DOT, niRTmean_DOT).
*EXECUTE.

*T-TEST PAIRS=Lmean_RT WITH Nmean_RT (PAIRED)
  /CRITERIA=CI(.9500)
  /MISSING=ANALYSIS.

COMPUTE imeanRT_DOT = MEAN(liRTmean_DOT, niRTmean_DOT).
COMPUTE fmeanRT_DOT = MEAN(lfRTmean_DOT, nfRTmean_DOT).
EXECUTE.

DESCRIPTIVES VARIABLES=imeanRT_DOT fmeanRT_DOT
  /STATISTICS=MEAN STDDEV MIN MAX.

*  error data.
GLM liER_DOT niER_DOT lfER_DOT nfER_DOT
  /WSFACTOR=targLocation 2 Polynomial procedure 2 Polynomial 
  /METHOD=SSTYPE(2)
  /PRINT=DESCRIPTIVE ETASQ
  /PLOT=PROFILE(procedure*targLocation)
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=targLocation procedure targLocation*procedure.

COMPUTE Lcuing_ER = lfER_DOT - liER_DOT.
COMPUTE Ncuing_ER = nfER_DOT - niER_DOT.
EXECUTE.



T-TEST
  /TESTVAL=0
  /MISSING=ANALYSIS
  /VARIABLES= Lcuing_ER Ncuing_ER
  /CRITERIA=CI(.95).


