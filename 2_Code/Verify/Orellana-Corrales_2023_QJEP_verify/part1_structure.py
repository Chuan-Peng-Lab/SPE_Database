# -*- coding: utf-8 -*-
"""Part 1: structural checks of library CSV files + spot checks vs OSF raw + data_clean alignment."""
import pandas as pd
import numpy as np
import os, math, sys

BASE = '/Users/hcp4715/Downloads/Collaborations/SPE_Database/SPE_Database/1_Data/Orellana-Corrales_2023_QJEP'
ARCH = os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_raw', 'v8r2p-osfstorage-data-archive')

clean = pd.read_csv(os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_Exp1_Clean.csv'))
raw   = pd.read_csv(os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_Exp1_raw.csv'))
subj  = pd.read_csv(os.path.join(BASE, 'Orellana-Corrales_2023_QJEP_Exp1_subj_info.csv'))
dclean = pd.read_csv(os.path.join(ARCH, 'data_clean.csv'))  # author aggregated
merged = pd.read_csv(os.path.join(ARCH, 'data_merged.tsv'), sep='\t', dtype=str, keep_default_na=False)

print('='*80)
print('CHECK 2: Clean structure')
print('='*80)
print('Clean rows:', len(clean), '(expect 19040)')
print('Clean subjects:', clean.Subject.nunique(), '(expect 136)')
per = clean.groupby('Subject').size()
print('trials/subject: min=%d max=%d (expect 140/140)' % (per.min(), per.max()))
# condition counts per subject
cc = clean.groupby(['Subject', 'Shape_Standardized_Identity', 'Matching']).size().unstack(fill_value=0)
print('condition counts per subject min/max:')
print(cc.describe().loc[['min','max']])
# Identity 3-level
print('Shape_Origin values:', sorted(clean.Shape_Origin_Identity.unique()))
print('Shape_English values:', sorted(clean.Shape_English_Identity.unique()))
print('Shape_Standardized values:', sorted(clean.Shape_Standardized_Identity.unique()))
print('Label_Origin values:', sorted(clean.Label_Origin_Identity.unique()))
print('Label_English values:', sorted(clean.Label_English_Identity.unique()))
print('Label_Standardized values:', sorted(clean.Label_Standardized_Identity.unique()))
print('Matching values:', sorted(clean.Matching.unique()))
print('RT_ms dtype/range:', clean.RT_ms.dtype, clean.RT_ms.min(), clean.RT_ms.max())
print('RT_sec check (== RT_ms/1000):', np.allclose(clean.RT_sec.dropna(), clean.RT_ms.dropna()/1000.0))
acc_counts = clean.ACC.value_counts(dropna=False)
print('ACC value counts:', dict(acc_counts))
print('ACC NA rows (no-response):', int(clean.ACC.isna().sum()), '(expect 549)')
# Shape<->Label consistency: Shape std identity should equal Label std identity per row? No - shape side is bed-derived, label side is actual word.
# For matching trials the shape identity and label identity coincide; for nonmatching they differ. Verify:
same = (clean.Shape_Standardized_Identity == clean.Label_Standardized_Identity)
print('identity agree rows (should be matching rows = 19040/2):', int(same.sum()))

print()
print('='*80)
print('CHECK 2b: raw structure')
print('='*80)
print('raw rows:', len(raw), '(expect 19040)')
print('raw subjects:', raw.Subject.nunique())
print('bed values:', sorted(raw.bed.unique()))
print('bed counts per subject (min/max):', raw.groupby('Subject').bed.size().min(), raw.groupby('Subject').bed.size().max())
print('ACC values raw:', sorted(raw.ACC.dropna().unique()))
print('Group values:', sorted(raw.Group.unique()))
print('Group counts:', raw.groupby('Group').Subject.nunique().to_dict())
print('Ass values:', sorted(raw.Ass.dropna().unique()))
print('RT_ms NA rows:', int(raw.RT_ms.isna().sum()), '(expect 549 = no-response)')
print('ACC==0 rows (errors incl no-response):', int((raw.ACC==0).sum()))
print('ACC==1 rows:', int((raw.ACC==1).sum()))
# raw ACC==0 but RT present (wrong key responses) vs ACC==0 & RT NA (no response)
print('raw ACC==0 & RT not NA:', int(((raw.ACC==0) & raw.RT_ms.notna()).sum()))
print('raw ACC==0 & RT NA:', int(((raw.ACC==0) & raw.RT_ms.isna()).sum()))

print()
print('='*80)
print('CHECK 3a: spot check raw vs data_raw per-subject csv (subject 1 = first file v1)')
print('='*80)
files_v1 = sorted([f for f in os.listdir(os.path.join(ARCH, 'data_raw', 'v1')) if f.endswith('.csv')])
print('first file v1:', files_v1[0])
ps = pd.read_csv(os.path.join(ARCH, 'data_raw', 'v1', files_v1[0]))
mt = ps[(ps['MT.corr'].notna()) & (ps['MT.corr'].astype(str).str.strip() != '')]
print('MT rows in per-subject file:', len(mt))
r1 = raw[raw.Subject == 1].reset_index(drop=True)
print('library raw rows for subject 1:', len(r1))
# compare bed, MT.corr, MT.rt*1000
mb = mt['bed'].tolist()
mc = mt['MT.corr'].astype(int).tolist()
mr = [round(float(x)*1000) if str(x).strip() != '' and str(x).strip().lower() != 'nan' else np.nan for x in mt['MT.rt']]
print('bed match:', mb == r1['bed'].tolist())
print('corr match:', mc == r1['ACC'].tolist())
rt_na_lib = r1['RT_ms'].isna()
rt_na_ps = [np.isnan(x) for x in mr]
print('RT NA pattern match:', rt_na_lib.tolist() == rt_na_ps)
mm = [a == b for a, b in zip(mr, r1['RT_ms']) if not (isinstance(a,float) and np.isnan(a))]
print('RT_ms values match on non-NA:', all(mm), '| compared', len(mm))
print('label/bild from per-subject vs library raw (first 5):')
for i in range(5):
    print('  ps: label=%r bild=%r  lib: Label=%r Shape=%r' % (mt.iloc[i]['label'], mt.iloc[i]['bild'], r1.iloc[i]['Label'], r1.iloc[i]['Shape']))
print('label match all:', (mt['label'].tolist() == r1['Label'].tolist()))
print('bild match all:', (mt['bild'].tolist() == r1['Shape'].tolist()))
print('Ass match all:', (mt['Ass'].tolist() == r1['Ass'].tolist()))
print('Group (type col) subject1:', r1['Group'].iloc[0], '| per-subject type:', mt['type'].iloc[0] if mt['type'].iloc[0] else '(blank in MT rows)')

print()
print('='*80)
print('CHECK 3b: subject 72 (first file v5) spot check + Group boundary')
print('='*80)
files_v5 = sorted([f for f in os.listdir(os.path.join(ARCH, 'data_raw', 'v5')) if f.endswith('.csv')])
print('first file v5:', files_v5[0])
ps5 = pd.read_csv(os.path.join(ARCH, 'data_raw', 'v5', files_v5[0]))
mt5 = ps5[(ps5['MT.corr'].notna()) & (ps5['MT.corr'].astype(str).str.strip() != '')]
r72 = raw[raw.Subject == 72].reset_index(drop=True)
print('MT rows:', len(mt5), '| library raw rows subject 72:', len(r72))
print('bed match:', mt5['bed'].tolist() == r72['bed'].tolist())
print('corr match:', mt5['MT.corr'].astype(int).tolist() == r72['ACC'].tolist())
print('label match:', mt5['label'].tolist() == r72['Label'].tolist())
print('bild match:', mt5['bild'].tolist() == r72['Shape'].tolist())
print('Group subject 72:', r72['Group'].iloc[0])
print('Group subject 71:', raw[raw.Subject==71]['Group'].iloc[0])
# full Group mapping subject->type via per-subject files
grp_by_subj = raw.groupby('Subject')['Group'].first()
print('words subjects count:', int((grp_by_subj=='words').sum()), '| shapes:', int((grp_by_subj=='shapes').sum()))
print('first shape-subject:', grp_by_subj[grp_by_subj=='shapes'].index.min(), '| last words-subject:', grp_by_subj[grp_by_subj=='words'].index.max())

print()
print('='*80)
print('CHECK 3c: subj_info Gender/Handedness/Age vs author data_clean (Sex/YoB/Handedness) + type mapping')
print('='*80)
print('subj_info rows:', len(subj))
print('Age missing:', int(subj.Age.isna().sum()), '| subjects:', subj.loc[subj.Age.isna(), 'Subject_ID'].tolist())
print('Gender missing:', int(subj.Gender.isna().sum()), '| Handedness missing:', int(subj.Handedness.isna().sum()))
print('Gender counts:', subj.Gender.value_counts().to_dict())
print('Handedness counts:', subj.Handedness.value_counts().to_dict())
print('Group counts:', subj.Group.value_counts().to_dict())
dclean['subject'] = dclean['subject'].astype(int)
m = pd.merge(subj, dclean[['subject','Sex','YoB','Handedness','type']], left_on='Subject_ID', right_on='subject', how='left')
print('merge coverage:', int(m.Sex.notna().sum()), '/136')
sex_map = {'female':0, 'male':1}
sex_match = [sex_map[g] == s for g, s in zip(m.Gender, m.Sex) if pd.notna(g)]
print('Gender vs data_clean Sex match:', all(sex_match), len(sex_match))
# handedness mapping: subj_info left/right/both vs data_clean rechts/links
hm = {'left':'links','right':'rechts','both':'beides'}
print('Handedness vs data_clean:', all(hm[g] == s for g, s in zip(m.Handedness, m.Handedness if False else dclean['Handedness']) if pd.notna(g)) if False else 'see below')
hh = pd.merge(subj, dclean[['subject','Handedness']], left_on='Subject_ID', right_on='subject')
print('  pairs (left->links):', sorted(set(zip(hh.Handedness_x, hh['Handedness_y']))))
# type mapping: 0=words 1=shapes
type_map = {'familiar (words)':0, 'new (shapes)':1}
tm = [type_map[g] == t for g, t in zip(subj.Group, dclean['type'])]
print('Group vs data_clean type (0=words/1=shapes):', all(tm))
# Sex distribution full sample
print('data_clean Sex counts (all 136):', dclean.Sex.value_counts().to_dict())
# male count among 107 analysis sample
excl = [2,10,12,13,27,32,33,34,37,39,54,56,58,59,64,67,82,84,86,93,94,96,100,101,109,119,132,134,136]
anal = dclean[~dclean.subject.isin(excl)]
print('analysis sample N:', len(anal), '| male:', int((anal.Sex==1).sum()), '| female:', int((anal.Sex==0).sum()))
print('analysis words (type=0):', int((anal.type==0).sum()), '| shapes (type=1):', int((anal.type==1).sum()))
print('excluded words:', int(dclean[dclean.subject.isin(excl) & (dclean.type==0)].subject.nunique()), '| excluded shapes:', int(dclean[dclean.subject.isin(excl) & (dclean.type==1)].subject.nunique()))
