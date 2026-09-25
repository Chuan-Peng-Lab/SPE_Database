# -*- coding: utf-8 -*-
"""True visible text of every paragraph (includes <w:ins>, <w:hyperlink>, field results).
Then: rebuild the caption paragraphs so Word's leftover auto-number runs disappear,
and re-scan for stale values."""
import copy
import sys

import docx
from docx.oxml.ns import qn

DST = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2.docx'


def visible(p):
    """Concatenate every <w:t> in document order, skipping instrText."""
    out = []
    for t in p._p.iter(qn('w:t')):
        out.append(t.text or '')
    return ''.join(out)


def dump(path):
    d = docx.Document(path)
    return d, [visible(p) for p in d.paragraphs]


if __name__ == '__main__':
    d, vis = dump(DST)
    print('== caption paragraphs (visible text) ==')
    for i in [20, 28, 37, 45, 51, 64, 65, 78]:
        print(f'  [{i}] {vis[i]!r}')
    print()
    print('== stale scan on visible text ==')
    full = "\n".join(vis)
    STALE = ["44 studies", "70 experiments", "3,603", "1,554,083", "1.55 million",
             "0.298", "0.126", "0.066", "0.061", "0.182", "0.023", "0.028",
             "8 of the 10", "\u2212.493", "table 3", "Ratchliff", "Rose, H.",
             "4 studies with", "1, 676", "853,015", "303, 331", "199,271",
             "Paper_Id", "_raw_Subject.csv"]
    bad = 0
    for s in STALE:
        n = full.count(s)
        if n:
            bad += 1
            print(f'  !! {s!r}: {n}')
    print('  clean' if not bad else f'  {bad} stale markers')

    print()
    print('== paragraphs whose visible text differs from python-docx .text ==')
    for i, p in enumerate(d.paragraphs):
        if p.text.strip() != vis[i].strip():
            print(f'  [{i}] .text={p.text[:60]!r}')
            print(f'        visible={vis[i][:80]!r}')
