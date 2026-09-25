# -*- coding: utf-8 -*-
"""Recompute the database scale numbers (studies / datasets / participants / trials)."""
import glob
import os
import pandas as pd

ROOT = r'D:\GitHub_programe\GitHub\SPE_Database\1_Data'
files = sorted(glob.glob(os.path.join(ROOT, '**', '*_Clean.csv'), recursive=True))

rows = []
tot_rows = 0
tot_test_trials = 0
tot_match = 0
tot_nonmatch = 0
for f in files:
    d = pd.read_csv(f, dtype=str, low_memory=False)
    n = len(d)
    tot_rows += n
    if 'Matching' in d.columns:
        m = d['Matching'].astype(str)
        test = m.isin(['Matching', 'Nonmatching'])
        tot_test_trials += int(test.sum())
        tot_match += int((m == 'Matching').sum())
        tot_nonmatch += int((m == 'Nonmatching').sum())
        n_test = int(test.sum())
        n_prac = n - n_test
    else:
        n_test, n_prac = 0, n
    subj = pd.to_numeric(d.get('Subject'), errors='coerce')
    rows.append(dict(file=os.path.relpath(f, ROOT), rows=n, test_trials=n_test,
                     other_rows=n_prac, n_subject_ids=subj.nunique()))

df = pd.DataFrame(rows)
df['study'] = df['file'].str.split('\\').str[0]
print('Clean files            :', len(df))
print('unique study folders   :', df.study.nunique())
print('total Clean rows       :', tot_rows)
print('test trials (Match/Non):', tot_test_trials)
print('  matching             :', tot_match)
print('  nonmatching          :', tot_nonmatch)
print('non-test rows (prac/other):', tot_rows - tot_test_trials)

# --- from the master index -------------------------------------------------
inf = pd.read_csv(os.path.join(ROOT, 'Dataset_inf.csv'), encoding='utf-8-sig', dtype=str)
folders = {d for d in os.listdir(ROOT) if os.path.isdir(os.path.join(ROOT, d))}
inf = inf[inf.Folder_Name.isin(folders)]
num = pd.to_numeric(inf.Sample_Size, errors='coerce')
tr = pd.to_numeric(inf.numTrials.str.extract(r'^(\d+)')[0], errors='coerce')
print()
print('index rows (with folder)      :', len(inf))
print('unique Folder_Name            :', inf.Folder_Name.nunique())
print('unique (Folder_Name, Exp)     :', inf[['Folder_Name', 'Exp']].drop_duplicates().shape[0])
print('sum Sample_Size               :', int(num.sum()))
print('sum numTrials*Sample_Size     :', int((tr * num).sum()))
print('unique Clean files on disk    :', len(df))
print('unique (folder, Exp) in files :', len(set(
    f.replace('\\', '/').split('/')[0] + '|' + os.path.basename(f).split('_Exp')[-1].split('_')[0]
    for f in df.file)))
print()
print('per-study file counts:')
print(df.groupby('study').size().to_string())
