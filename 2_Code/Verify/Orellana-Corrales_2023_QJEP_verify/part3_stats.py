# -*- coding: utf-8 -*-
"""Part 3: reproduce paper matching-task statistics under two labelings (correct vs data_clean-swapped)."""
import pandas as pd
import numpy as np
import os, math
from scipy import stats

BASE = '/Users/hcp4715/Downloads/Collaborations/SPE_Database/SPE_Database/1_Data/Orellana-Corrales_2023_QJEP'

raw = pd.read_csv(os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_Exp1_raw.csv'))

EXCL = [2,10,12,13,27,32,33,34,37,39,54,56,58,59,64,67,82,84,86,93,94,96,100,101,109,119,132,134,136]

def tukey_all(rt_list):
    rt_list = sorted(rt_list)
    anzahl = len(rt_list)
    if anzahl % 2 == 0:
        median = ((anzahl/2) + (anzahl+1)/2) / 2
    else:
        median = (anzahl+1) / 2
    hinge = (median+1)/2
    if hinge == int(hinge):
        q1 = rt_list[int(hinge)-1]; q3 = rt_list[anzahl - int(hinge)]
    else:
        q1 = (rt_list[int(hinge)-1] + rt_list[int(hinge)])/2
        q3 = (rt_list[anzahl - int(hinge)-1] + rt_list[anzahl - int(hinge)])/2
    q1 = math.floor(q1); q3 = math.ceil(q3)
    return q3 + 1.5*(q3-q1)

# per-subject aggregation (author algorithm) from library raw
rows = []
for s in sorted(raw.Subject.unique()):
    d = raw[raw.Subject == s]
    allrt = d.RT_ms.dropna().astype(int).tolist()
    grenze = tukey_all(allrt)
    res = {'subject': s, 'grenze': grenze}
    for cond in ['i_m', 'i_n', 'f_m', 'f_n']:
        sub = d[d.bed == cond]
        q = sub[(sub.ACC == 1) & (sub.RT_ms > 200) & (sub.RT_ms < grenze)]
        res[cond + '_n'] = len(q)
        res[cond + '_sum'] = int(q.RT_ms.sum())
        res[cond + '_mean'] = round(q.RT_ms.mean()) if len(q) else np.nan
        res[cond + '_err'] = int((sub.ACC == 0).sum())   # errors incl no-response
    rows.append(res)
agg = pd.DataFrame(rows)
anal = agg[~agg.subject.isin(EXCL)].reset_index(drop=True)
print('analysis N:', len(anal))

# Correct labeling: im= i_m, in= i_n, fm= f_m, fn= f_n
def report(name, df, cols):
    m = df[cols].mean().round(1).to_dict()
    s = df[cols].std().round(1).to_dict()
    print('%s  means: %s' % (name, m))
    print('%s  SD:    %s' % (name, s))

print()
print('=== RT group stats (107 analysis sample) ===')
report('CORRECT labeling (im=self-match, in=self-nonmatch, fm=furn-match, fn=furn-nonmatch):',
       anal, ['i_m_mean', 'i_n_mean', 'f_m_mean', 'f_n_mean'])
# swapped: what SPSS actually read from data_clean: im= i_m, in= f_m, fm= i_n, fn= f_n
anal_sw = anal.rename(columns={'i_m_mean':'im', 'i_n_mean':'fn_sw', 'f_m_mean':'in', 'f_n_mean':'fn'})
report('SWAPPED labeling (im=self-match, in=furn-match, fm=self-nonmatch, fn=furn-nonmatch):',
       anal_sw, ['im', 'in', 'fn_sw', 'fn'])

# paper reference
print()
print('Paper reported (L127): self-matching M=694 SD=91; furniture-matching M=802 SD=103;')
print('                      self-nonmatching M=779 SD=106; furniture-nonmatching M=793 SD=100')

print()
print('=== F statistics via contrast/paired-t (2x2 within, N=107 -> df=(1,106)) ===')
def F_of_contrast(df, c, label):
    # c over [i_m, i_n, f_m, f_n]
    M = df[['i_m_mean','i_n_mean','f_m_mean','f_n_mean']].to_numpy()
    scores = M @ np.array(c)
    t = stats.ttest_1samp(scores, 0)
    F = t.statistic**2
    eta2 = t.statistic**2 / (t.statistic**2 + len(scores)-1)
    print('%s: F(1,106)=%.2f, t=%.3f, p=%.4f, eta2=%.3f' % (label, F, t.statistic, t.pvalue, eta2))

print('--- CORRECT labeling ---')
F_of_contrast(anal, [0.5, 0.5, -0.5, -0.5], 'shape main effect (self vs furniture)')
F_of_contrast(anal, [0.5, -0.5, 0.5, -0.5], 'trial type main effect (matching vs nonmatching)')
F_of_contrast(anal, [0.5, -0.5, -0.5, 0.5], 'interaction')
t = stats.ttest_rel(anal['i_m_mean'], anal['f_m_mean'])
print('matching-only shape: F(1,106)=%.2f, t=%.3f, p=%.4f, eta2=%.3f' % (t.statistic**2, t.statistic, t.pvalue, t.statistic**2/(t.statistic**2+106)))
t = stats.ttest_rel(anal['i_n_mean'], anal['f_n_mean'])
print('nonmatching-only shape: F(1,106)=%.2f, t=%.3f, p=%.4f, eta2=%.3f' % (t.statistic**2, t.statistic, t.pvalue, t.statistic**2/(t.statistic**2+106)))

print()
print('--- SWAPPED labeling (as SPSS read data_clean) ---')
F_of_contrast(anal_sw.rename(columns={'im':'i_m_mean','in':'i_n_mean','fn_sw':'f_m_mean','fn':'f_n_mean'}), [0.5, 0.5, -0.5, -0.5], 'factor1 [im,in]vs[fm,fn] (actual: matching vs nonmatching)')
F_of_contrast(anal_sw.rename(columns={'im':'i_m_mean','in':'i_n_mean','fn_sw':'f_m_mean','fn':'f_n_mean'}), [0.5, -0.5, 0.5, -0.5], 'factor2 [im,fm]vs[in,fn] (actual: self vs furniture)')
F_of_contrast(anal_sw.rename(columns={'im':'i_m_mean','in':'i_n_mean','fn_sw':'f_m_mean','fn':'f_n_mean'}), [0.5, -0.5, -0.5, 0.5], 'interaction')

print()
print('=== d\' (loglinear, from ER incl no-response) ===')
def calc_d(df):
    # dI: hits=35-imER, FA=inER ; dF: hits=35-fmER, FA=fnER
    import scipy.stats as st
    z = st.norm.ppf
    dI = z((35 - df['i_m_err'] + 0.5) / 36.0) - z((df['i_n_err'] + 0.5) / 36.0)
    dF = z((35 - df['f_m_err'] + 0.5) / 36.0) - z((df['f_n_err'] + 0.5) / 36.0)
    return dI, dF
dI, dF = calc_d(anal)
print('CORRECT: dI(self) M=%.2f SD=%.2f | dF(furn) M=%.2f SD=%.2f' % (dI.mean(), dI.std(), dF.mean(), dF.std()))
t = stats.ttest_rel(dI, dF)
print('CORRECT d\' ANOVA: F(1,106)=%.2f, t=%.3f, p=%.4f, eta2=%.3f' % (t.statistic**2, t.statistic, t.pvalue, t.statistic**2/(t.statistic**2+106)))
# swapped ER: imER= i_m, inER= f_m (mfe), fmER= i_n (nie), fnER= f_n
dI2 = z((35 - anal['i_m_err'] + 0.5) / 36.0) - z((anal['f_m_err'] + 0.5) / 36.0)
dF2 = z((35 - anal['i_n_err'] + 0.5) / 36.0) - z((anal['f_n_err'] + 0.5) / 36.0)
print('SWAPPED: dI M=%.2f SD=%.2f | dF M=%.2f SD=%.2f' % (dI2.mean(), dI2.std(), dF2.mean(), dF2.std()))
t2 = stats.ttest_rel(dI2, dF2)
print('SWAPPED d\' ANOVA: F(1,106)=%.2f, t=%.3f, p=%.4f, eta2=%.3f' % (t2.statistic**2, t2.statistic, t2.pvalue, t2.statistic**2/(t2.statistic**2+106)))

print()
print('Paper reported: shape F(1,106)=199.28 eta2=.65; trial F(1,106)=77.08 eta2=.42; interaction F=111.13 eta2=.51;')
print('                matching-only F=255.76 eta2=.71; nonmatching-only F=5.90 p=.017 eta2=.05; d\' F(1,106)=4.63 p=.034 eta2=.04')
print('                d\' self 2.34(1.04), furn 2.19(1.08)')

print()
print('=== sanity: mean RT by condition for subject 1-3 (correct labeling) ===')
print(anal[['subject','i_m_mean','i_n_mean','f_m_mean','f_n_mean']].head(3).to_string(index=False))
