# -*- coding: utf-8 -*-
"""Debug part 2: data_clean rows for subjects 2/73; MT row counts per subject in data_merged; per-subject files."""
import pandas as pd
import numpy as np
import os, math
from collections import defaultdict

BASE = '/Users/hcp4715/Downloads/Collaborations/SPE_Database/SPE_Database/1_Data/Orellana-Corrales_2023_QJEP'
ARCH = os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_raw', 'v8r2p-osfstorage-data-archive')

rows = []
with open(os.path.join(ARCH, 'data_merged.tsv'), encoding='utf-8-sig') as f:
    header = f.readline().strip().split('\t')
    header_low = [h.lower() for h in header]
    for line in f:
        parts = [p.strip(' ') for p in line.strip('\n').split('\t')]
        rows.append(dict(zip(header_low, parts)))

data = defaultdict(list)
for r in rows:
    data[int(r['subject'])].append(r)

print('=== MT-row counts per subject in data_merged (bed in MT_BEDS) ===')
bad = []
for s in sorted(data.keys()):
    mt = [dl for dl in data[s] if dl['bed'] in ('i_m','i_n','f_m','f_n')]
    nc = [dl for dl in mt if dl['mt.corr'] != '']
    if len(mt) != 140 or len(nc) != 140:
        bad.append((s, len(mt), len(nc)))
print('subjects with MT rows != 140 or nonempty-corr != 140:', bad)

print()
print('=== data_clean rows for subjects 2 and 73 ===')
dc = pd.read_csv(os.path.join(ARCH, 'data_clean.csv'), encoding='utf-8-sig')
print(dc[dc.subject.isin([2, 73])][['subject','Tukey_MT','imRTmean','imACC','imRTsum','inRTmean','inACC','inRTsum','fmRTmean','fmACC','fmRTsum','fnRTmean','fnACC','fnRTsum','imER','inER','fmER','fnER']].to_string(index=False))

print()
print('=== per-subject files for subject 2 and 73: which files? ===')
import glob
# determine which per-subject file corresponds to subject 2 (2nd alphabetical in v1) and 73 (2nd in v6? cumulative: v1=19,v2=16(35),v3=19(54),v4=17(71),v5=15(86) -> subject 72=1st v5, 73=2nd v5)
for v, idx in [(1, 2), (5, 2)]:
    fs = sorted([f for f in os.listdir(os.path.join(ARCH, 'data_raw', 'v%d' % v)) if f.endswith('.csv')])
    print('v%d file #%d: %s' % (v, idx, fs[idx-1]))
