# -*- coding: utf-8 -*-
"""Compare the figures embedded in the v16.1 docx with candidate source PNGs."""
import os
from PIL import Image
import numpy as np

DOCX_MEDIA = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\docx_media'
PIC = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Output\Pic'
PIC2 = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\Pic'

cands = []
for d in (PIC, PIC2, r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\8_Exploratory_Analysis\Pic\10',
          r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\8_Exploratory_Analysis\Pic\02'):
    if os.path.isdir(d):
        for r, _, fs in os.walk(d):
            for f in fs:
                if f.lower().endswith(('.png', '.jpg')):
                    cands.append(os.path.join(r, f))


def sig(path, size=(64, 64)):
    try:
        im = Image.open(path).convert('L').resize(size)
    except Exception:
        return None
    a = np.asarray(im, dtype=float)
    a = (a - a.mean()) / (a.std() + 1e-9)
    return a


for em in sorted(os.listdir(DOCX_MEDIA)):
    e = sig(os.path.join(DOCX_MEDIA, em))
    if e is None:
        continue
    best = []
    for c in cands:
        s = sig(c)
        if s is None:
            continue
        best.append((float((e * s).mean()), c))
    best.sort(reverse=True)
    print(f"\n=== {em} (docx) ===")
    for sc, c in best[:4]:
        print(f"   r={sc:.3f}  {os.path.relpath(c, r'D:\GitHub_programe\GitHub\SPE_Database')}")
