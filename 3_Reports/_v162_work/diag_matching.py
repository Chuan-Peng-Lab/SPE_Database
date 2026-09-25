# -*- coding: utf-8 -*-
"""Check Matching column values and per-dataset coverage."""
import glob, os, collections
import pandas as pd

ROOT = r'D:\GitHub_programe\GitHub\SPE_Database\1_Data'
files = sorted(glob.glob(os.path.join(ROOT, '**', '*_Clean.csv'), recursive=True))
vals = collections.Counter()
per_ds = {}
for f in files:
    d = pd.read_csv(f, dtype=str, usecols=lambda c: c in ('Matching', 'Subject'))
    name = os.path.relpath(f, ROOT)
    if 'Matching' not in d.columns:
        per_ds[name] = 'NO-COL'
        continue
    vc = d['Matching'].value_counts(dropna=False)
    per_ds[name] = dict(vc)
    vals.update(d['Matching'].dropna().unique().tolist())
print('Matching unique values:', dict(vals))
print()
for k, v in per_ds.items():
    if v == 'NO-COL' or (isinstance(v, dict) and not any(str(x).lower().startswith('nonmatch') for x in v)):
        print('NO NONMATCHING:', k, v)
print()
nm = [k for k, v in per_ds.items() if isinstance(v, dict) and any(str(x).lower().startswith('nonmatch') for x in v)]
print('datasets with Nonmatching:', len(nm))
import re
weird = {k: v for k, v in per_ds.items() if isinstance(v, dict) and set(map(str, v)) - {'Matching', 'Nonmatching', 'nan'}}
print('\nweird value sets:')
for k, v in weird.items():
    print('  ', k, v)
