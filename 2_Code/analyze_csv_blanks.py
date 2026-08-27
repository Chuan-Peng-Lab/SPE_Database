#!/usr/bin/env python3
# Blank-field scanner for Dataset_inf.csv (stage-2 prerequisite).
# Reports which rows are blank per field (Country/City/Journal/Year/License/Stim_language/Exp),
# cross-referenced with folder presence and standard *_raw.csv existence.
# USAGE: python3 analyze_csv_blanks.py  (paths hardcoded at top)
"""Analyze blank fields in Dataset_inf.csv, cross-reference with folder/raw existence."""
import csv, os

CSV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "1_Data", "Dataset_inf.csv")
DATA_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "1_Data")

# Read CSV (BOM + CRLF tolerant)
with open(CSV_PATH, encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))

FIELDS = ["Exp", "Country", "City", "Journal", "Year", "License", "Stim_language"]

# Folder + raw existence map
folders = set(d for d in os.listdir(DATA_ROOT) if os.path.isdir(os.path.join(DATA_ROOT, d)))

def has_raw(folder):
    """Check if folder has any *_raw.csv (standard trial-level product)."""
    if folder not in folders:
        return None  # no folder
    for root, dirs, files in os.walk(os.path.join(DATA_ROOT, folder)):
        if "_Raw" in root or "Source" in root:
            continue
        for fn in files:
            if fn.endswith("_raw.csv"):
                return True
    return False

# Per-field blank report, grouped by Folder_Name
from collections import OrderedDict
report = OrderedDict()
for r in rows:
    fn = r["Folder_Name"]
    blanks = [f for f in FIELDS if not r.get(f, "").strip()]
    if blanks:
        report.setdefault(fn, []).append((r.get("Exp", ""), blanks))

print("=== Blank-field rows by Folder_Name (with folder/raw status) ===\n")
for fn, items in report.items():
    has_f = fn in folders
    raw = has_raw(fn)
    raw_str = {None: "N/A(no folder)", True: "YES", False: "NO"}[raw]
    print(f"[{fn}] folder={'Y' if has_f else 'N'} raw={raw_str}")
    for exp, blanks in items:
        print(f"    Exp={exp or '<blank>'} -> {', '.join(blanks)}")
    print()

# Summary counts
print("=== Summary: blank counts by field (all rows) ===")
from collections import Counter
c = Counter()
for r in rows:
    for f in FIELDS:
        if not r.get(f, "").strip():
            c[f] += 1
print(dict(c))
