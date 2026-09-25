# -*- coding: utf-8 -*-
"""Extra counts for the Methods/Results text: conservative trial counts and dataset counts."""
import glob
import os
import pandas as pd

ROOT = r'D:\GitHub_programe\GitHub\SPE_Database\1_Data'
files = sorted(glob.glob(os.path.join(ROOT, '**', '*_Clean.csv'), recursive=True))
KEYS = ('Subject', 'Matching', 'RT_ms', 'ACC',
        'Shape_Standardized_Identity', 'Label_Standardized_Identity')

res = []
for f in files:
    d = pd.read_csv(f, dtype=str, usecols=lambda c: c in KEYS, low_memory=False)
    if 'Matching' not in d.columns:
        continue
    d = d[d['Matching'] == 'Nonmatching'].copy()
    if d.empty:
        continue
    d['ds'] = os.path.basename(f)
    d['key'] = d['ds'] + '|' + d['Subject'].astype(str)
    res.append(d)
mm = pd.concat(res, ignore_index=True)
print('nonmatching rows:', len(mm), 'datasets:', mm.ds.nunique(), 'unique ds x subject:', mm.key.nunique())

for prim, sec in [('Shape_Standardized_Identity', 'Label_Standardized_Identity'),
                  ('Label_Standardized_Identity', 'Shape_Standardized_Identity')]:
    d = mm.copy()
    d['Primary'] = d[prim].where(d[prim].isin(['Self', 'Stranger']), 'Other')
    d['Secondary'] = d[sec].where(d[sec].isin(['Self', 'Stranger']), 'Other')
    # eligible participants: >=3 distinct identities incl. Self and Stranger
    g = d.groupby('key')[prim].apply(lambda s: len(set(s.dropna())) >= 3 and {'Self', 'Stranger'} <= set(s.dropna()))
    d = d[d.key.isin(g[g].index)]
    d = d[(d.Primary == 'Self') | ((d.Primary == 'Stranger') & (d.Secondary != 'Self')) | (d.Primary == 'Other')]
    print(f'\n[{prim.split("_")[0]}-based conservative]')
    print('  datasets:', d.ds.nunique(), ' participants:', d.key.nunique(),
          ' trials:', len(d), ' (Self:', int((d.Primary == "Self").sum()),
          ' Stranger:', int((d.Primary == "Stranger").sum()),
          ' Other:', int((d.Primary == "Other").sum()), ')')

print('\n--- liberal ---')
for prim in ['Shape_Standardized_Identity', 'Label_Standardized_Identity']:
    d = mm.copy()
    d['Primary'] = d[prim].where(d[prim].isin(['Self', 'Stranger']), 'Other')
    d = d[d.Primary.isin(['Self', 'Stranger'])]
    print(f'  [{prim.split("_")[0]}-based liberal] datasets:', d.ds.nunique(),
          ' participants:', d.key.nunique(), ' trials:', len(d))

print('\n--- identity analysis: datasets contributing per shape identity ---')
allrows = []
for f in files:
    d = pd.read_csv(f, dtype=str, usecols=lambda c: c in KEYS, low_memory=False)
    if 'Shape_Standardized_Identity' not in d.columns:
        continue
    d['ds'] = os.path.basename(f)
    allrows.append(d[['ds', 'Subject', 'Shape_Standardized_Identity', 'ACC', 'RT_ms']])
al = pd.concat(allrows, ignore_index=True)
al['ACC'] = pd.to_numeric(al['ACC'], errors='coerce')
al['RT_ms'] = pd.to_numeric(al['RT_ms'], errors='coerce')
for idn in ['NonPerson', 'Stranger', 'Celebrity', 'Acquaintance', 'Close']:
    sub = al[al.Shape_Standardized_Identity == idn]
    subrt = sub[(sub.ACC == 1) & (sub.RT_ms > 0) & (sub.RT_ms <= 10000)]
    print(f'  {idn:13s} datasets={sub.ds.nunique():3d}  subjects={sub.Subject.nunique():5d}  RT trials={len(subrt)}')
