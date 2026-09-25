# -*- coding: utf-8 -*-
"""Dump raw XML of the caption paragraphs to find the auto-numbering fields."""
import sys
import docx

path = sys.argv[1]
idxs = [int(x) for x in sys.argv[2:]]
d = docx.Document(path)
for i in idxs:
    print(f"================ paragraph {i} ================")
    print(d.paragraphs[i]._p.xml)
    print()
