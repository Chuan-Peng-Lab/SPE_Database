# -*- coding: utf-8 -*-
"""Consolidate every number needed for the v16.2 manuscript."""
import glob
import os
import numpy as np
import pandas as pd

DOC = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Output\data'
PIC = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Output\Pic'
EXP = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\8_Exploratory_Analysis\Output\11'
ROOT = r'D:\GitHub_programe\GitHub\SPE_Database\1_Data'

out = []
def p(*a):
    s = " ".join(str(x) for x in a)
    out.append(s)
    print(s)

p("################ 1. IDENTITY / BASELINE ANALYSIS (v2) ################")
ids = pd.read_csv(os.path.join(DOC, 'identity_baseline_summary_v2.csv'))
p(ids.round(4).to_string(index=False))
for m in ['RT', 'ACC']:
    d = pd.read_csv(os.path.join(DOC, f'use_example_pairwise_differences_{m}_11_v2.csv'))
    p(f"\n--- {m} pairwise (v2) ---")
    p(d.round(4).to_string(index=False))
    p(f"{m}: {int(d.significant.sum())}/10 significant")

p("\n################ 2. MISMATCH ANALYSIS (v2) ################")
mm = pd.read_csv(os.path.join(DOC, 'mismatch_bootstrap_summary_v2.csv'))
p(mm.round(4).to_string(index=False))

p("\n################ 3. EXPLORATORY (v11 pipeline + v2 figure) ################")
cap = pd.read_csv(os.path.join(DOC, 'exploratory_figure_captions_v2.csv'))
p(cap[['panel', 'moderator', 'measure', 'n_datasets', 'spearman_rho', 'spearman_p',
       'spearman_rho_boot_ci_lower', 'spearman_rho_boot_ci_upper',
       'spearman_rho_boot_p']].round(4).to_string(index=False))
sens = pd.read_csv(os.path.join(DOC, 'exploratory_sensitivity_v2.csv'))
p("\nsensitivity (drop 3 largest trial numbers):")
p(sens.round(4).to_string(index=False))
res = pd.read_csv(os.path.join(EXP, 'visualization_numeric_results.csv'))
p("\nrange of x:")
p(res[['moderator', 'measure', 'n_datasets', 'x_min', 'x_max']].to_string(index=False))

p("\n################ 4. DATABASE SCALE ################")
inf = pd.read_csv(os.path.join(ROOT, 'Dataset_inf.csv'), encoding='utf-8-sig', dtype=str)
folders = {d for d in os.listdir(ROOT) if os.path.isdir(os.path.join(ROOT, d))}
inf = inf[inf.Folder_Name.isin(folders)]
num = pd.to_numeric(inf.Sample_Size, errors='coerce')
p("studies (Folder_Name with data):", inf.Folder_Name.nunique())
p("index rows (Exp x group)       :", len(inf))
p("unique (Folder_Name, Exp)      :", inf[['Folder_Name', 'Exp']].drop_duplicates().shape[0])
p("sum Sample_Size                :", int(num.sum()))
files = sorted(glob.glob(os.path.join(ROOT, '**', '*_Clean.csv'), recursive=True))
p("Clean files (= datasets)       :", len(files))
tot = tm = tn = 0
subs = set()
for f in files:
    d = pd.read_csv(f, dtype=str, usecols=lambda c: c in ('Matching', 'Subject'))
    mmk = d['Matching'].astype(str)
    tot += len(d)
    tm += int((mmk == 'Matching').sum())
    tn += int((mmk == 'Nonmatching').sum())
    s = pd.to_numeric(d['Subject'], errors='coerce')
    for v in set(s.dropna().tolist()):
        subs.add((os.path.basename(os.path.dirname(f)), v))
p("Clean rows total               :", tot)
p("  matching                     :", tm)
p("  nonmatching                  :", tn)
p("unique dataset x subject       :", len(subs))

# conservative experiment count (>=3 distinct shape identities per participant)
p("\n################ 5. CONSERVATIVE ELIGIBILITY ################")
elig = []
for f in files:
    d = pd.read_csv(f, dtype=str, low_memory=False)
    if 'Shape_Standardized_Identity' not in d.columns or 'Matching' not in d.columns:
        continue
    d = d[d['Matching'] == 'Nonmatching']
    if d.empty:
        continue
    bys = d.groupby('Subject')['Shape_Standardized_Identity'].apply(
        lambda s: set(s.dropna()) >= {'Self', 'Stranger'} and len(set(s.dropna())) >= 3)
    if bys.any():
        elig.append(os.path.basename(f))
p("datasets with >=1 eligible participant (conservative):", len(elig))
p("datasets excluded:", len(files) - len(elig))
for e in sorted(set(os.path.basename(f) for f in files) - set(elig)):
    p("   -", e)

open(r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\v2_results_consolidated.txt',
     'w', encoding='utf-8').write("\n".join(out))
print("\nsaved -> _v162_work/v2_results_consolidated.txt")
