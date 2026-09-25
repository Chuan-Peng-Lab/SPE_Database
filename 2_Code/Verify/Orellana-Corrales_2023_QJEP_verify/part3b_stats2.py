# -*- coding: utf-8 -*-
"""Part 3b: paper stats reproduction — (A) SPSS actual input = data_clean columns as-is; (B) correct labeling, listwise."""
import pandas as pd
import numpy as np
import os, math
from scipy import stats

BASE = '/Users/hcp4715/Downloads/Collaborations/SPE_Database/SPE_Database/1_Data/Orellana-Corrales_2023_QJEP'
ARCH = os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_raw', 'v8r2p-osfstorage-data-archive')

EXCL = [2,10,12,13,27,32,33,34,37,39,54,56,58,59,64,67,82,84,86,93,94,96,100,101,109,119,132,134,136]

def F_and_eta(t, n):
    F = t.statistic**2
    return F, t.pvalue, t.statistic, F/(F + n - 1)

def anova2x2(df, a, b, c, d, label):
    """2x2 within ANOVA from four columns; factor1=[a,b]vs[c,d], factor2=[a,c]vs[b,d], interaction."""
    M = df[[a, b, c, d]].dropna()
    n = len(M)
    def contrast(cols_sign):
        return (M[a]*cols_sign[0] + M[b]*cols_sign[1] + M[c]*cols_sign[2] + M[d]*cols_sign[3]) / 2.0
    s1 = contrast([1, 1, -1, -1]); t1 = stats.ttest_1samp(s1, 0)
    s2 = contrast([1, -1, 1, -1]); t2 = stats.ttest_1samp(s2, 0)
    s3 = contrast([1, -1, -1, 1]); t3 = stats.ttest_1samp(s3, 0)
    print('%s (N=%d):' % (label, n))
    F1, p1, t1v, e1 = F_and_eta(t1, n)
    F2, p2, t2v, e2 = F_and_eta(t2, n)
    F3, p3, t3v, e3 = F_and_eta(t3, n)
    print('  factor1: F(1,%d)=%.2f p=%.4f eta2=%.3f' % (n-1, F1, p1, e1))
    print('  factor2: F(1,%d)=%.2f p=%.4f eta2=%.3f' % (n-1, F2, p2, e2))
    print('  inter :  F(1,%d)=%.2f p=%.4f eta2=%.3f' % (n-1, F3, p3, e3))
    return n

dc = pd.read_csv(os.path.join(ARCH, 'data_clean.csv'), encoding='utf-8-sig')
dc['subject'] = dc['subject'].astype(int)
anal_dc = dc[~dc.subject.isin(EXCL)].reset_index(drop=True)
print('SPSS input N (data_clean, excl 29):', len(anal_dc))

print()
print('============ (A) SPSS actual input: data_clean columns as-is (swapped in*/fm* + stale subj 73) ============')
# SPSS GLM imRTmean inRTmean fmRTmean fnRTmean: factor1 (Condition) = [im,in] vs [fm,fn]; factor2 (match) = [im,fm] vs [in,fn]
nA = anova2x2(anal_dc, 'imRTmean', 'inRTmean', 'fmRTmean', 'fnRTmean', 'A: GLM on data_clean columns')
# follow-ups
t = stats.ttest_rel(anal_dc['imRTmean'], anal_dc['fmRTmean']); F,p,_,e = F_and_eta(t, nA)
print('  [im vs fm] (called "matching-only shape" in SPSS): F(1,%d)=%.2f p=%.4f eta2=%.3f' % (nA-1, F, p, e))
t = stats.ttest_rel(anal_dc['inRTmean'], anal_dc['fnRTmean']); F,p,_,e = F_and_eta(t, nA)
print('  [in vs fn] (called "nonmatching-only shape"): F(1,%d)=%.2f p=%.4f eta2=%.3f' % (nA-1, F, p, e))
# d'
z = stats.norm.ppf
dI_A = z((35 - anal_dc['imER'] + 0.5)/36) - z((anal_dc['inER'] + 0.5)/36)
dF_A = z((35 - anal_dc['fmER'] + 0.5)/36) - z((anal_dc['fnER'] + 0.5)/36)
t = stats.ttest_rel(dI_A, dF_A); F,p,_,e = F_and_eta(t, nA)
print('  d\' (data_clean ER): dI M=%.2f SD=%.2f | dF M=%.2f SD=%.2f' % (dI_A.mean(), dI_A.std(), dF_A.mean(), dF_A.std()))
print('  d\' ANOVA: F(1,%d)=%.2f p=%.4f eta2=%.3f' % (nA-1, F, p, e))
# descriptive means SPSS would see
print('  descriptive RT means (data_clean): im=%.1f in=%.1f fm=%.1f fn=%.1f' % (anal_dc.imRTmean.mean(), anal_dc.inRTmean.mean(), anal_dc.fmRTmean.mean(), anal_dc.fnRTmean.mean()))

print()
print('============ (B) Correct labeling from trial data (author algorithm), listwise deletion ============')
# rebuild per-subject aggregation
raw = pd.read_csv(os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_Exp1_raw.csv'))
def tukey_all(rt_list):
    rt_list = sorted(rt_list); anzahl = len(rt_list)
    if anzahl % 2 == 0: median = ((anzahl/2)+(anzahl+1)/2)/2
    else: median = (anzahl+1)/2
    hinge = (median+1)/2
    if hinge == int(hinge):
        q1 = rt_list[int(hinge)-1]; q3 = rt_list[anzahl - int(hinge)]
    else:
        q1 = (rt_list[int(hinge)-1]+rt_list[int(hinge)])/2
        q3 = (rt_list[anzahl-int(hinge)-1]+rt_list[anzahl-int(hinge)])/2
    q1 = math.floor(q1); q3 = math.ceil(q3)
    return q3 + 1.5*(q3-q1)
rows = []
for s in sorted(raw.Subject.unique()):
    d = raw[raw.Subject == s]
    g = tukey_all(d.RT_ms.dropna().astype(int).tolist())
    rec = {'subject': s}
    for cond in ['i_m','i_n','f_m','f_n']:
        sub = d[d.bed == cond]
        q = sub[(sub.ACC == 1) & (sub.RT_ms > 200) & (sub.RT_ms < g)]
        rec[cond+'_mean'] = round(q.RT_ms.mean()) if len(q) else np.nan
        rec[cond+'_err'] = int((sub.ACC == 0).sum())
    rows.append(rec)
agg = pd.DataFrame(rows)
anal_b = agg[~agg.subject.isin(EXCL)].reset_index(drop=True)
print('subjects with any NaN cell in analysis sample:', anal_b.subject[anal_b[['i_m_mean','i_n_mean','f_m_mean','f_n_mean']].isna().any(axis=1)].tolist())
nB = anova2x2(anal_b, 'i_m_mean', 'i_n_mean', 'f_m_mean', 'f_n_mean', 'B: correct labeling (listwise)')
t = stats.ttest_rel(anal_b['i_m_mean'], anal_b['f_m_mean']); F,p,_,e = F_and_eta(t, nB)
print('  matching-only shape (i_m vs f_m): F(1,%d)=%.2f p=%.4f eta2=%.3f' % (nB-1, F, p, e))
t = stats.ttest_rel(anal_b['i_n_mean'], anal_b['f_n_mean']); F,p,_,e = F_and_eta(t, nB)
print('  nonmatching-only shape (i_n vs f_n): F(1,%d)=%.2f p=%.4f eta2=%.3f' % (nB-1, F, p, e))
dI_B = z((35-anal_b['i_m_err']+0.5)/36) - z((anal_b['i_n_err']+0.5)/36)
dF_B = z((35-anal_b['f_m_err']+0.5)/36) - z((anal_b['f_n_err']+0.5)/36)
t = stats.ttest_rel(dI_B, dF_B); F,p,_,e = F_and_eta(t, nB)
print('  d\' correct: dI M=%.2f SD=%.2f | dF M=%.2f SD=%.2f' % (dI_B.mean(), dI_B.std(), dF_B.mean(), dF_B.std()))
print('  d\' ANOVA: F(1,%d)=%.2f p=%.4f eta2=%.3f' % (nB-1, F, p, e))
print('  RT means (correct): im=%.1f in=%.1f fm=%.1f fn=%.1f' % (anal_b.i_m_mean.mean(), anal_b.i_n_mean.mean(), anal_b.f_m_mean.mean(), anal_b.f_n_mean.mean()))

print()
print('Paper: shape F(1,106)=199.28 eta2=.65 | trial F(1,106)=77.08 eta2=.42 | inter F=111.13 eta2=.51')
print('       matching-only F=255.76 eta2=.71 | nonmatching-only F=5.90 p=.017 eta2=.05')
print('       d\' self 2.34(1.04) furn 2.19(1.08) F(1,106)=4.63 p=.034 eta2=.04')
print('       RT means: self-match 694(91) furn-match 802(103) self-nonmatch 779(106) furn-nonmatch 793(100)')
