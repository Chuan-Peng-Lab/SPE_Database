# -*- coding: utf-8 -*-
"""Per-dataset RT sanity diagnostics."""
import glob, os
import pandas as pd, numpy as np

ROOT = r'D:\GitHub_programe\GitHub\SPE_Database\1_Data'
files = sorted(glob.glob(os.path.join(ROOT, '**', '*_Clean.csv'), recursive=True))
rows = []
for f in files:
    head = pd.read_csv(f, nrows=0)
    cols = [c for c in ['RT_ms'] if c in head.columns]
    if not cols:
        rows.append((os.path.splitext(os.path.basename(f))[0], -1, np.nan, np.nan, np.nan, np.nan, -1, -1))
        continue
    d = pd.read_csv(f, usecols=['RT_ms'])
    r = pd.to_numeric(d['RT_ms'], errors='coerce')
    rows.append((os.path.splitext(os.path.basename(f))[0], len(r), r.min(), r.median(),
                 r.quantile(.99), r.max(), int((r > 5000).sum()), int((r > 60000).sum())))
df = pd.DataFrame(rows, columns=['file', 'n', 'min', 'med', 'p99', 'max', 'gt5000', 'gt60000'])
pd.set_option('display.width', 250)
print(df.sort_values('max', ascending=False).to_string())
print()
print("datasets with max > 10000:", (df['max'] > 10000).sum())
print(df[df['max'] > 10000].to_string())
