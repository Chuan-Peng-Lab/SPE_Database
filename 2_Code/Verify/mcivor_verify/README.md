# mcivor_verify

Mcivor_2021_EJN descriptive-statistics verification (stage-5 ingestion,
2026-09; descriptive statistics only — no statistical tests reproduced, per
user instruction).

- `verify_dprime.py` — reproduces the paper's d′ means (control happy 1.70 /
  neutral 1.56) and participant-level counts from the library Clean file.
  Author-caliber pipeline: hits = correct matching trials (correct onset-RT
  < 200 ms excluded, as stated in the paper); false alarms = ACC != 1 on
  nonmatching trials (no-response included as failure to reject); corrections
  1/2N and 1-1/2N with N = 80; d′ = Z(hit) − Z(FA).

Result: exact match on both reported d′ means and on 3 of 4 participant-level
counts (depressed 19/20 self>other; control 14/20 and depressed 10/20
happy>neutral). The 4th count is 17/20 vs paper 16/20 (control self>other
across all emotions) — boundary subject 6976 with a near-zero neutral d′
difference (−0.017). RT/ACC direction checks pass (self-match faster and more
accurate in both groups). No Issue filed in
`3_Reports/Verifying_original_results_issues.md` (the paper's reported means
reproduce exactly; the one count difference is a near-tie boundary case).

The EZ drift-rate (v) means are model fits, not descriptive statistics, and
were not re-computed (pipeline details not fully specified).
