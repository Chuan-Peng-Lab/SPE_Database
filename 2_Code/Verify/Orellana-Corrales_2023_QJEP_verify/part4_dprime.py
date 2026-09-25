# -*- coding: utf-8 -*-
"""Part 4: (1) grid-search paper d' means; (2) true-label follow-up effects; (3) check all NaN-cell subjects."""
import pandas as pd
import numpy as np
import os, math
from scipy import stats

BASE = '/Users/hcp4715/Downloads/Collaborations/SPE_Database/SPE_Database/1_Data/Orellana-Corrales_2023_QJEP'
ARCH = os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_raw', 'v8r2p-osfstorage-data-archive')
EXCL = [2,10,12,13,27,32,33,34,37,39,54,56,58,59,64,67,82,84,86,93,94,96,100,101,109,119,132,134,136]
z = stats.norm.ppf

dc = pd.read_csv(os.path.join(ARCH, 'data_clean.csv'), encoding='utf-8-sig')
dc['subject'] = dc['subject'].astype(int)
anal = dc[~dc.subject.isin(EXCL)].reset_index(drop=True)

print('=== grid search: dI/dF means under offset/denominator variants (data_clean ER columns as SPSS used) ===')
imER, inER, fmER, fnER = anal.imER, anal.inER, anal.fmER, anal.fnER
target = (2.34, 2.19)
for a in [0, 0.5, 1, 1.5]:
    for k in [0, 0.5, 1, 2]:
        dI = z((35 - imER + a)/(35 + k)) - z((inER + a)/(35 + k))
        dF = z((35 - fmER + a)/(35 + k)) - z((fnER + a)/(35 + k))
        if abs(dI.mean() - target[0]) < 0.05 and abs(dF.mean() - target[1]) < 0.05:
            print('  HIT a=%g k=%g: dI=%.3f dF=%.3f' % (a, k, dI.mean(), dF.mean()))
print('  baseline (a=0.5,k=1): dI=%.3f dF=%.3f' % (z((35-imER+0.5)/36).mean()-z((inER+0.5)/36).mean(), z((35-fmER+0.5)/36).mean()-z((fnER+0.5)/36).mean()))
# try hits from ACC instead of ER
for a in [0, 0.5, 1]:
    dI = z((anal.imACC + a)/(35 + a*2)) - z((anal.inACC + a)/(35 + a*2)) * -1  # placeholder no
print('  (no matches printed above unless found)')
# print exact numbers for a=0.5, k=1 and a=0, k=0
print('  a=0.5,k=1 (SPSS): dI=%.3f dF=%.3f' % (dI_.mean(), dF_.mean())) if False else None
dI = z((35 - imER + 0.5)/36) - z((inER + 0.5)/36)
dF = z((35 - fmER + 0.5)/36) - z((fnER + 0.5)/36)
print('  SPSS dI mean=%.3f SD=%.3f | dF mean=%.3f SD=%.3f' % (dI.mean(), dI.std(), dF.mean(), dF.std()))
# proportion means (before z)
ph = (35 - imER + 0.5)/36; pf = (inER + 0.5)/36
print('  mean hit-prop(im): %.4f | mean FA-prop(in): %.4f' % (ph.mean(), pf.mean()))

print()
print('=== TRUE labeling follow-ups (pairwise deletion) + full true stats ===')
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
analB = agg[~agg.subject.isin(EXCL)].reset_index(drop=True)
nan_subs = analB[analB[['i_m_mean','i_n_mean','f_m_mean','f_n_mean']].isna().any(axis=1)]
print('subjects with NaN cells (analysis sample):', nan_subs.subject.tolist())
print('per-cell NaN counts:')
print(analB[['i_m_mean','i_n_mean','f_m_mean','f_n_mean']].isna().sum().to_dict())
# pairwise follow-ups
t = stats.ttest_rel(analB['i_m_mean'], analB['f_m_mean'], nan_policy='omit')
print('TRUE matching-only shape (i_m vs f_m): n=%d F(1,%d)=%.2f p=%.4f' % (len(analB)-analB[['i_m_mean','f_m_mean']].isna().any(axis=1).sum(), t.df, t.statistic**2, t.pvalue))
t = stats.ttest_rel(analB['i_n_mean'], analB['f_n_mean'], nan_policy='omit')
print('TRUE nonmatching-only shape (i_n vs f_n): n=%d F(1,%d)=%.2f p=%.4f' % (len(analB)-analB[['i_n_mean','f_n_mean']].isna().any(axis=1).sum(), t.df, t.statistic**2, t.pvalue))
# trial-type follow-ups for each shape (the effect the paper actually computed)
t = stats.ttest_rel(analB['i_m_mean'], analB['i_n_mean'], nan_policy='omit')
print('TRUE self trial-type (i_m vs i_n): F(1,%d)=%.2f p=%.4f' % (t.df, t.statistic**2, t.pvalue))
t = stats.ttest_rel(analB['f_m_mean'], analB['f_n_mean'], nan_policy='omit')
print('TRUE furniture trial-type (f_m vs f_n): F(1,%d)=%.2f p=%.4f' % (t.df, t.statistic**2, t.pvalue))
# means with SD (true, pairwise per cell)
for c in ['i_m_mean','i_n_mean','f_m_mean','f_n_mean']:
    v = analB[c].dropna()
    print('TRUE %s: M=%.1f SD=%.1f n=%d' % (c, v.mean(), v.std(), len(v)))
