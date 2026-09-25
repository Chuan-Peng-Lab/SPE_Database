# -*- coding: utf-8 -*-
"""Extract in-text citations from the v16.1 draft dump and compare with the reference list."""
import re
from collections import Counter

DUMP = r"D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\v16.1_dump.txt"
text = open(DUMP, encoding="utf-8").read()

body, refs = text.split("[Normal (Web)] Reference", 1)

# --- reference entries -----------------------------------------------------
ref_lines = [l for l in refs.splitlines() if l.startswith("[Bibliography")]
refs_clean = [re.sub(r"^\[Bibliography1?\]\s*", "", l).strip() for l in ref_lines]
refs_clean = [r for r in refs_clean if r]
print(f"reference entries: {len(refs_clean)}")

# first author surname + year for each entry
ref_keys = []
for r in refs_clean:
    m = re.match(r"^([^,(]+)", r)
    y = re.search(r"\((\d{4}[a-z]?)\)", r)
    ref_keys.append((m.group(1).strip() if m else "?", y.group(1) if y else "?"))
c = Counter(ref_keys)
print("\nduplicate author-year keys:")
for k, v in c.items():
    if v > 1:
        print("  ", k, v)

# entries whose journal/venue looks missing (no journal-like token, page "1–n")
print("\nentries with suspicious venue/page:")
for r in refs_clean:
    if re.search(r"\b1[–-]\d{1,2}\.\s*(https|$)", r) or r.count(".") < 3:
        print("  *", r[:160])

# --- in-text citations -----------------------------------------------------
cites = re.findall(r"\(([^()]*?\d{4}[a-z]?[^()]*?)\)", body)
names = Counter()
for c in cites:
    for part in re.split(r";", c):
        part = part.strip()
        m = re.match(r"^([A-ZÄÖÜ][^,]*?)(?:\s+et al\.)?(?:,\s*&?\s*[A-ZÄÖÜ][^,]*)?,\s*(\d{4}[a-z]?)", part)
        if m:
            names[(m.group(1).strip(), m.group(2))] += 1
        else:
            m2 = re.search(r"([A-ZÄÖÜ][\w'\-]+)(?:\s+et al\.)?.*?(\d{4}[a-z]?)", part)
            if m2:
                names[(m2.group(1).strip(), m2.group(2))] += 1

print("\nin-text citation keys found:", len(names))
ref_surnames = {k[0] for k in ref_keys}
missing = []
for (n, y), cnt in sorted(names.items()):
    if n not in ref_surnames:
        missing.append((n, y, cnt))
print("\ncited in text but no reference entry with that surname:")
for m in missing:
    print("  ", m)

print("\nall in-text keys:")
for k, v in sorted(names.items()):
    print(f"   {k[0]} ({k[1]}) x{v}")
