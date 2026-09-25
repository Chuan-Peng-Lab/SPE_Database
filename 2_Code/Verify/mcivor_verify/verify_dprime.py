# Mcivor_2021_EJN d' descriptive verification (2026-09, stage-5 ingestion)
#
# Reproduces the paper's d' descriptive statistics from the library Clean file
# (McIvor et al. 2021, EJN 53(1):311-329, DOI 10.1111/ejn.14782).
#
# Paper formula (Methods, 'Discriminability'): per participant x 6 conditions
# (self/other x happy/sad/neutral), N = 80 trials per condition:
#   hit rate = correct matching trials / 80  (correct responses with RT < 200 ms
#             excluded from analysis, as stated in the paper)
#   false-alarm rate = ACC != 1 on nonmatching trials / 80  (including
#             no-response trials: no-response = failure to reject)
#   corrections: FA = 0 -> 1/(2N); hit = 1 -> 1 - 1/(2N);  d' = Z(hit) - Z(FA)
#
# Result: the two d' means reported in the paper (control happy 1.70,
# neutral 1.56, Figure 5 post-hoc) reproduce exactly (1.699 / 1.560);
# participant-level counts match on 3 of 4 (depressed 19/20 self>other;
# control 14/20 and depressed 10/20 happy>neutral); control self>other across
# all emotions = 17/20 vs paper 16/20 (boundary subject 6976, neutral d'
# difference -0.017, near tie). Direction: self > other in both groups; the
# depressed group shows higher d' for neutral than happy (paper's claim).
# RT/ACC direction: self-match faster/more accurate than other-match in both
# groups (control 627 vs 693 ms, ACC .856 vs .686; depressed 628 vs 718 ms,
# ACC .918 vs .698).
#
# The EZ drift-rate (v) means (0.17/0.15/0.15 control) are model fits, not
# descriptive statistics; not re-computed (user instruction: descriptive
# statistics only; pipeline details e.g. exact variance +/-3SD exclusion and
# PC definition are not fully specified in the paper).
import csv
from collections import defaultdict
from scipy.stats import norm

ROOT = '/Users/hcp4715/Downloads/Collaborations/SPE_Database/SPE_Database'
rows = list(csv.DictReader(open(f'{ROOT}/1_Data/Mcivor_2021_EJN/Mcivor_2021_EJN_Exp1_Clean.csv')))

per = defaultdict(lambda: dict(hit_num=0, fa_num=0))
rt200 = 0
for r in rows:
    if r['Phase'] != 'test':
        continue
    key = (r['Subject'], r['Label_Standardized_Identity'], r['Emotion'])
    if r['Matching'] == 'Matching':
        if r['ACC'] == '1':
            if r['RT_ms'] != '' and int(r['RT_ms']) < 200:
                rt200 += 1
            else:
                per[key]['hit_num'] += 1
    else:
        if r['ACC'] != '1':          # FA 含无反应（作者口径：未按键 = 未拒绝）
            per[key]['fa_num'] += 1
print('hit trials excluded (correct, onset RT<200):', rt200)

N = 80
dprime = {}
for (s, iden, emo), v in per.items():
    hr = v['hit_num'] / N
    fa = v['fa_num'] / N
    if fa == 0:
        fa = 1 / (2 * N)
    if hr == 1:
        hr = 1 - 1 / (2 * N)
    dprime[(s, iden, emo)] = norm.ppf(hr) - norm.ppf(fa)

si = list(csv.DictReader(open(f'{ROOT}/1_Data/Mcivor_2021_EJN/Mcivor_2021_EJN_Exp1_subj_info.csv')))
subj_group = {r['Subject_ID']: r['Group'] for r in si}

for g in ('control', 'depressed'):
    for emo in ('happy', 'sad', 'neutral'):
        vals = [dprime[(s, i, e)] for (s, i, e) in dprime
                if subj_group[s] == g and e == emo]
        print(f"{g} {emo}: d' mean = {sum(vals) / len(vals):.3f} (n={len(vals)})")

def cnt(g, pred):
    return sum(1 for s in subj_group if subj_group[s] == g and pred(s))

print('control self>other all emotions:',
      cnt('control', lambda s: all(dprime[(s, 'Self', e)] > dprime[(s, 'Stranger', e)]
                                   for e in ('happy', 'sad', 'neutral'))), '/20 (paper 16/20)')
print('depressed self>other all emotions:',
      cnt('depressed', lambda s: all(dprime[(s, 'Self', e)] > dprime[(s, 'Stranger', e)]
                                     for e in ('happy', 'sad', 'neutral'))), '/20 (paper 19/20)')
print('control happy>neutral (self+other):',
      cnt('control', lambda s: dprime[(s, 'Self', 'happy')] + dprime[(s, 'Stranger', 'happy')]
          > dprime[(s, 'Self', 'neutral')] + dprime[(s, 'Stranger', 'neutral')]), '/20 (paper 14/20)')
print('depressed happy>neutral (self+other):',
      cnt('depressed', lambda s: dprime[(s, 'Self', 'happy')] + dprime[(s, 'Stranger', 'happy')]
          > dprime[(s, 'Self', 'neutral')] + dprime[(s, 'Stranger', 'neutral')]), '/20 (paper 10/20)')
self_all = [dprime[(s, 'Self', e)] for (s, i, e) in dprime if i == 'Self']
other_all = [dprime[(s, 'Stranger', e)] for (s, i, e) in dprime if i == 'Stranger']
print('overall d\' self %.3f vs other %.3f'
      % (sum(self_all) / len(self_all), sum(other_all) / len(other_all)))
