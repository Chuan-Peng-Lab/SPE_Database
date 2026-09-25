# -*- coding: utf-8 -*-
"""Part 2: reproduce author 2-dataprep_mt.py exactly from data_merged.tsv, compare with data_clean.csv columns."""
import pandas as pd
import numpy as np
import os, math

BASE = '/Users/hcp4715/Downloads/Collaborations/SPE_Database/SPE_Database/1_Data/Orellana-Corrales_2023_QJEP'
ARCH = os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_raw', 'v8r2p-osfstorage-data-archive')

def tukey_all(rt_list, return_val):
    """Exact port of util.py tukey_all (hinge method, floor/ceil on q1/q3)."""
    rt_list = sorted(rt_list)
    anzahl = len(rt_list)
    if anzahl % 2 == 0:
        median = ((anzahl/2) + (anzahl+1)/2) / 2
    else:
        median = (anzahl+1) / 2
    hinge = (median+1)/2
    if hinge == int(hinge):
        q1 = rt_list[int(hinge)-1]
        q3 = rt_list[anzahl - int(hinge)]
    else:
        q1 = (rt_list[int(hinge)-1] + rt_list[int(hinge)])/2
        q3 = (rt_list[anzahl - int(hinge)-1] + rt_list[anzahl - int(hinge)])/2
    q1 = math.floor(q1)
    q3 = math.ceil(q3)
    IQR = q3 - q1
    grenze = q3 + 1.5*IQR
    return grenze

# parse data_merged.tsv like parseInputData (lowercased keys, tab split)
rows = []
with open(os.path.join(ARCH, 'data_merged.tsv'), encoding='utf-8-sig') as f:
    header = f.readline().strip().split('\t')
    header_low = [h.lower() for h in header]
    for line in f:
        parts = line.strip('\n').split('\t')
        parts = [p.strip(' ') for p in parts]
        rows.append(dict(zip(header_low, parts)))

from collections import defaultdict
data = defaultdict(list)
for r in rows:
    data[int(r['subject'])].append(r)

print('subjects in data_merged:', len(data))

def reproduce(subj):
    VPrto = []
    for dl in data[subj]:
        if dl['mt.rt'] != '':
            VPrto.append(int(dl['mt.rt']))
    grenze = tukey_all(VPrto, 'grenze1_5_oben')
    mi, ni, mf, nf = [], [], [], []
    for dl in data[subj]:
        if dl['mt.rt'] != '' and int(dl['mt.rt']) > 200 and int(dl['mt.rt']) < grenze and dl['mt.corr'] == '1':
            if dl['bed'] == 'i_m': mi.append(int(dl['mt.rt']))
            if dl['bed'] == 'i_n': ni.append(int(dl['mt.rt']))
            if dl['bed'] == 'f_m': mf.append(int(dl['mt.rt']))
            if dl['bed'] == 'f_n': nf.append(int(dl['mt.rt']))
    def mean(l):
        return round(sum(l)/len(l)) if l else np.nan
    mie = sum(1 for dl in data[subj] if dl['bed'] == 'i_m' and dl['mt.corr'] == '0')
    nie = sum(1 for dl in data[subj] if dl['bed'] == 'i_n' and dl['mt.corr'] == '0')
    mfe = sum(1 for dl in data[subj] if dl['bed'] == 'f_m' and dl['mt.corr'] == '0')
    nfe = sum(1 for dl in data[subj] if dl['bed'] == 'f_n' and dl['mt.corr'] == '0')
    # age/sex/handedness taken from last line (as in author code)
    last = data[subj][-1]
    age = last['age']
    sex = 0 if last['sex'] == 'Weiblich' else 1
    hand = last['handedness']
    return dict(subject=subj, grenze=grenze, age=age, sex=sex, hand=hand,
                mi_mean=mean(mi), mi_n=len(mi), mi_sum=sum(mi),
                mf_mean=mean(mf), mf_n=len(mf), mf_sum=sum(mf),
                ni_mean=mean(ni), ni_n=len(ni), ni_sum=sum(ni),
                nf_mean=mean(nf), nf_n=len(nf), nf_sum=sum(nf),
                mie=mie, mfe=mfe, nie=nie, nfe=nfe)

repro = pd.DataFrame([reproduce(s) for s in sorted(data.keys())])

dc = pd.read_csv(os.path.join(ARCH, 'data_clean.csv'), encoding='utf-8-sig')
dc['subject'] = dc['subject'].astype(int)
dc = dc.sort_values('subject').reset_index(drop=True)
repro = repro.sort_values('subject').reset_index(drop=True)

print('data_clean rows:', len(dc))
print()
print('--- Tukey_MT (grenze) compare ---')
print('Tukey_MT equal:', int((dc.Tukey_MT == repro.grenze).sum()), '/136; mismatches:', dc.loc[dc.Tukey_MT != repro.grenze, 'subject'].tolist())
print('YoB vs age:', int((dc.YoB.astype(str) == repro.age.astype(str)).sum()), '/136')
print('Sex vs sex:', int((dc.Sex == repro.sex).sum()), '/136')
print('Handedness vs hand:', int((dc.Handedness == repro.hand).sum()), '/136')
print()
print('--- column alignment: which reproduced condition does each data_clean RT column match? ---')
for col, key in [('imRTmean','mi_mean'), ('inRTmean','ni_mean'), ('fmRTmean','mf_mean'), ('fnRTmean','nf_mean')]:
    eq = int((dc[col] == repro[key]).sum())
    print('%s vs %s: %d/136' % (col, key, eq))
print('cross-check (alternative labeling):')
for col, key in [('imRTmean','mi_mean'), ('inRTmean','mf_mean'), ('fmRTmean','ni_mean'), ('fnRTmean','nf_mean')]:
    eq = int((dc[col] == repro[key]).sum())
    print('%s vs %s(swapped): %d/136' % (col, key, eq))
print()
print('--- ACC (n correct) compare ---')
for col, key in [('imACC','mi_n'), ('inACC','ni_n'), ('fmACC','mf_n'), ('fnACC','nf_n')]:
    eq = int((dc[col] == repro[key]).sum())
    print('%s vs %s: %d/136' % (col, key, eq))
for col, key in [('imACC','mi_n'), ('inACC','mf_n'), ('fmACC','ni_n'), ('fnACC','nf_n')]:
    eq = int((dc[col] == repro[key]).sum())
    print('%s vs %s(swapped): %d/136' % (col, key, eq))
print()
print('--- RTsum compare ---')
for col, key in [('imRTsum','mi_sum'), ('inRTsum','ni_sum'), ('fmRTsum','mf_sum'), ('fnRTsum','nf_sum')]:
    eq = int((dc[col] == repro[key]).sum())
    print('%s vs %s: %d/136' % (col, key, eq))
for col, key in [('imRTsum','mi_sum'), ('inRTsum','mf_sum'), ('fmRTsum','ni_sum'), ('fnRTsum','nf_sum')]:
    eq = int((dc[col] == repro[key]).sum())
    print('%s vs %s(swapped): %d/136' % (col, key, eq))
print()
print('--- ER compare ---')
for col, key in [('imER','mie'), ('inER','nie'), ('fmER','mfe'), ('fnER','nfe')]:
    eq = int((dc[col] == repro[key]).sum())
    print('%s vs %s: %d/136' % (col, key, eq))
for col, key in [('imER','mie'), ('inER','mfe'), ('fmER','nie'), ('fnER','nfe')]:
    eq = int((dc[col] == repro[key]).sum())
    print('%s vs %s(swapped): %d/136' % (col, key, eq))

# show a sample of values for visual inspection
print()
print('--- sample rows (subject 1-5): data_clean im/in/fm/fn RT means ---')
print(dc[['subject','imRTmean','inRTmean','fmRTmean','fnRTmean']].head(5).to_string(index=False))
print('--- reproduced mi/mf/ni/nf means ---')
print(repro[['subject','mi_mean','mf_mean','ni_mean','nf_mean']].head(5).to_string(index=False))
