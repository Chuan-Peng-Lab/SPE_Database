* Encoding: UTF-8.

GET 
  FILE=C:\Users\User\Desktop\studies\target_tasks\MT.sav'.
DATASET NAME DataSet1 WINDOW=FRONT. 

SORT CASES BY Subject (A).
EXECUTE.

MATCH FILES /FILE=*
 /FILE='C:\Users\User\Desktop\studies\target_tasks\DET.sav'
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

**Boxplot Dection task.
COMPUTE RTmean_DET = MEAN(liRTmean_DET, lfRTmean_DET, piRTmean_DET, pfRTmean_DET, siRTmean_DET, sfRTmean_DET).
COMPUTE ERsum_DET = SUM(liER_DET, lfER_DET, piER_DET, pfER_DET, siER_DET, sfER_DET).
EXECUTE.

EXAMINE VARIABLES=RTmean_DET ERsum_DET
  /PLOT BOXPLOT STEMLEAF
  /COMPARE GROUPS
  /STATISTICS DESCRIPTIVES
  /CINTERVAL 95
  /MISSING LISTWISE
  /NOTOTAL.

**Exclude outliers.
USE ALL.
COMPUTE filter_$=(Subject ~= 5 and Subject ~= 6 and Subject ~= 20 and Subject ~= 23 and Subject ~= 24 and Subject ~= 27).
VARIABLE LABELS filter_$ 'Subject ~= 5 and Subject ~= 6 and Subject ~= 20 and Subject ~= 23 and Subject ~= 24 and Subject ~= 27(FILTER)'.
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'.
FORMATS filter_$ (f1.0).
FILTER BY filter_$.
EXECUTE.


** ANOVA: targLocation (Ich vs. Fremder) x procedure (Pairing vs. Label vs. Shape).
GLM liRTmean_DET siRTmean_DET piRTmean_DET lfRTmean_DET sfRTmean_DET pfRTmean_DET
  /WSFACTOR=targLocation 2 Polynomial procedure 3 Polynomial 
  /METHOD=SSTYPE(3)
  /PLOT=PROFILE(procedure*targLocation)
  /PRINT=DESCRIPTIVE ETASQ 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=targLocation procedure targLocation*procedure.

COMPUTE LDETcuing_RT = lfRTmean_DET - liRTmean_DET.
COMPUTE SDETcuing_RT = sfRTmean_DET - siRTmean_DET.
COMPUTE PDETcuing_RT = pfRTmean_DET - piRTmean_DET.
EXECUTE.

COMPUTE LDETmean_RT = MEAN(lfRTmean_DET, liRTmean_DET).
COMPUTE SDETmean_RT = MEAN(sfRTmean_DET, siRTmean_DET).
COMPUTE PDETmean_RT = MEAN(pfRTmean_DET, piRTmean_DET).
EXECUTE.


T-TEST
  /TESTVAL=0
  /MISSING=ANALYSIS
  /VARIABLES= LDETcuing_RT SDETcuing_RT PDETcuing_RT
  /CRITERIA=CI(.95).

**Comparison between representation types**.
T-TEST PAIRS=LDETcuing_RT PDETcuing_RT PDETcuing_RT WITH SDETcuing_RT LDETcuing_RT SDETcuing_RT (PAIRED)
  /CRITERIA=CI(.9500)
  /MISSING=ANALYSIS.

**mean RT per representation type***.
COMPUTE LDETmean_RT = MEAN(lfRTmean_DET, liRTmean_DET).
COMPUTE SDETmean_RT = MEAN(sfRTmean_DET, siRTmean_DET).
COMPUTE PDETmean_RT = MEAN(pfRTmean_DET, piRTmean_DET).
EXECUTE.

T-TEST PAIRS=LDETmean_RT SDETmean_RT LDETmean_RT WITH PDETmean_RT PDETmean_RT SDETmean_RT (PAIRED)
  /CRITERIA=CI(.9500)
  /MISSING=ANALYSIS.


*  error data.
GLM liER_DET siER_DET piER_DET lfER_DET sfER_DET pfER_DET
  /WSFACTOR=targLocation 2 Polynomial procedure 3 Polynomial 
  /METHOD=SSTYPE(3)
  /PRINT=DESCRIPTIVE ETASQ 
  /CRITERIA=ALPHA(.05)
  /WSDESIGN=targLocation procedure targLocation*procedure.

COMPUTE LDETcuing_ER = lfER_DET - liER_DET.
COMPUTE SDETcuing_ER = sfER_DET - siER_DET.
COMPUTE PDETcuing_ER = pfER_DET - piER_DET.
EXECUTE.

T-TEST
  /TESTVAL=0
  /MISSING=ANALYSIS
  /VARIABLES= LDETcuing_ER SDETcuing_ER PDETcuing_ER
  /CRITERIA=CI(.95).

******DESCRIPTIVES******

COMPUTE gral_ich=MEAN(liRTmean_DET,piRTmean_DET,siRTmean_DET). 
EXECUTE. 
COMPUTE gral_fremder=MEAN(lfRTmean_DET,pfRTmean_DET,sfRTmean_DET). 
EXECUTE. 
COMPUTE gral_label=MEAN(lfRTmean_DET, liRTmean_DET). 
EXECUTE. 
COMPUTE gral_shape=MEAN(sfRTmean_DET, siRTmean_DET). 
EXECUTE. 
COMPUTE gral_pair=MEAN(pfRTmean_DET, piRTmean_DET). 
EXECUTE. 

DESCRIPTIVES VARIABLES=gral_ich gral_fremder gral_label gral_shape gral_pair liRTmean_DET 
    lfRTmean_DET piRTmean_DET pfRTmean_DET siRTmean_DET sfRTmean_DET 
  /STATISTICS=MEAN STDDEV MIN MAX.

CORRELATIONS
  /VARIABLES=SPErt SPEd LDETcuing_RT SDETcuing_RT PDETcuing_RT
  /PRINT=TWOTAIL NOSIG
  /MISSING=PAIRWISE.
