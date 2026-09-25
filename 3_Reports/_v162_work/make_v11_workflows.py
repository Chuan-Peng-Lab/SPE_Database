# -*- coding: utf-8 -*-
"""Create additive v11 copies of the exploratory pipeline (no file is overwritten).

- exploratory_workflow_v11.py                       -> writes Output/11
- exploratory_visualization_workflow_v11.py         -> reads Output/11, writes Output/11 + Pic/11
"""
from pathlib import Path

ROOT = Path(r"D:\GitHub_programe\GitHub\SPE_Database")
AN = ROOT / "Datasets" / "8_Exploratory_Analysis"

# --- 1) upstream workflow -------------------------------------------------
src = (AN / "exploratory_workflow.py").read_text(encoding="utf-8")
old = 'OUTPUT_DIR = ANALYSIS_ROOT / "Output"'
new = 'OUTPUT_DIR = ANALYSIS_ROOT / "Output" / "11"'
assert src.count(old) == 1, src.count(old)
src2 = src.replace(old, new)
(AN / "exploratory_workflow_v11.py").write_text(src2, encoding="utf-8")
print("wrote exploratory_workflow_v11.py")

# --- 2) visualization workflow -------------------------------------------
src = (AN / "exploratory_visualization_workflow_v10.py").read_text(encoding="utf-8")
reps = [
    ('OUTPUT_DIR = ANALYSIS_ROOT / "Output" / "10"',
     'OUTPUT_DIR = ANALYSIS_ROOT / "Output" / "11"'),
    ('PIC_DIR = ANALYSIS_ROOT / "Pic" / "10"',
     'PIC_DIR = ANALYSIS_ROOT / "Pic" / "11"'),
    ('INPUT_DIR = ANALYSIS_ROOT / "Output"',
     'INPUT_DIR = ANALYSIS_ROOT / "Output" / "11"'),
    ('Version 10 (Spearman-Only Bootstrap)', 'Version 11 = v10 logic re-run on the 2026-09 database (89 Clean files)'),
    ('Changes from v09:', 'Changes from v10:'),
]
for o, n in reps:
    assert src.count(o) == 1, (o, src.count(o))
    src = src.replace(o, n)
(AN / "exploratory_visualization_workflow_v11.py").write_text(src, encoding="utf-8")
print("wrote exploratory_visualization_workflow_v11.py")
print("done")
