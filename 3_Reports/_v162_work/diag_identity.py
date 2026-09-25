# -*- coding: utf-8 -*-
"""Diagnostics for the identity (baseline) analysis data assembly."""
import glob, os, collections
import pandas as pd
import numpy as np

ROOT = r'D:\GitHub_programe\GitHub\SPE_Database\1_Data'
IDENTITY_ORDER = ["NonPerson", "Stranger", "Celebrity", "Acquaintance", "Close"]

files = sorted(glob.glob(os.path.join(ROOT, '**', '*_Clean.csv'), recursive=True))
print(f"clean files: {len(files)}")

frames = []
for f in files:
    try:
        d = pd.read_csv(f, dtype=str)
    except Exception as e:
        print('ERR', f, e); continue
    d['Source'] = os.path.splitext(os.path.basename(f))[0]
    d['_path'] = os.path.relpath(f, ROOT)
    frames.append(d)
m = pd.concat(frames, ignore_index=True)
for c in ['Subject', 'RT_ms', 'ACC']:
    if c in m.columns:
        m[c] = pd.to_numeric(m[c], errors='coerce')
print('rows', len(m))
print('datasets', m.Source.nunique())
print('\nShape_Standardized_Identity counts:')
print(m['Shape_Standardized_Identity'].value_counts(dropna=False).to_string())

# trials per identity
print('\nACC==1 trial counts by shape identity:')
print(m[m.ACC == 1].groupby('Shape_Standardized_Identity').size().to_string())

# which datasets provide each identity as shape
print('\ndatasets per shape identity:')
for idn in IDENTITY_ORDER:
    sub = m[m['Shape_Standardized_Identity'] == idn]
    print(f"  {idn}: {sub.Source.nunique()} datasets, {sub.Subject.nunique()} subject-ids, {len(sub)} trials")
    print("     ", sorted(sub.Source.unique())[:80])

# subject-id collision
gid = m['Source'] + '|' + m['Subject'].astype(str)
print('\nrows', len(m), 'global unique Source|Subject', gid.nunique(), 'unique raw Subject', m.Subject.nunique())

# per-subject mean RT by identity (descriptives, unweighted)
sel = m[m.ACC == 1].dropna(subset=['RT_ms'])
piv = sel.pivot_table(index=['Source', 'Subject'], columns='Shape_Standardized_Identity',
                      values='RT_ms', aggfunc='mean')
print('\nper-subject mean RT by shape identity (unweighted across subjects):')
print(piv.describe().T.to_string())
