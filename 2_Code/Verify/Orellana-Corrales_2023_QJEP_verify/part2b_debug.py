# -*- coding: utf-8 -*-
"""Debug: YoB mismatches and NaN mi_mean subjects."""
import pandas as pd
import numpy as np
import os, math
from collections import defaultdict

BASE = '/Users/hcp4715/Downloads/Collaborations/SPE_Database/SPE_Database/1_Data/Orellana-Corrales_2023_QJEP'
ARCH = os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_raw', 'v8r2p-osfstorage-data-archive')

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

dc = pd.read_csv(os.path.join(ARCH, 'data_clean.csv'), encoding='utf-8-sig')
dc['subject'] = dc['subject'].astype(int)

# YoB mismatches
print('=== YoB (data_clean) vs age (data_merged last line) mismatches ===')
for s in sorted(data.keys()):
    last = data[s][-1]
    yob_dc = dc.loc[dc.subject == s, 'YoB'].iloc[0]
    age_mg = last['age']
    if str(yob_dc) != str(age_mg):
        # gather all non-empty age values for this subject
        ages = sorted(set(dl['age'] for dl in data[s] if dl['age'] != ''))
        print('subject %d: data_clean YoB=%r | data_merged unique ages=%r' % (s, yob_dc, ages))

print()
print('=== NaN mi_mean subjects: inspect their i_m trials ===')
for s in sorted(data.keys()):
    grenze = tukey_all([int(dl['mt.rt']) for dl in data[s] if dl['mt.rt'] != ''])
    im_rows = [dl for dl in data[s] if dl['bed'] == 'i_m']
    qual = [dl for dl in im_rows if dl['mt.rt'] != '' and int(dl['mt.rt']) > 200 and int(dl['mt.rt']) < grenze and dl['mt.corr'] == '1']
    if len(qual) == 0:
        corr1 = sum(1 for dl in im_rows if dl['mt.corr'] == '1')
        print('subject %d: grenze=%g | i_m rows=%d, corr==1: %d' % (s, grenze, len(im_rows), corr1))
        for dl in im_rows:
            print('   bed=%s corr=%r rt=%r' % (dl['bed'], dl['mt.corr'], dl['mt.rt']))
