# -*- coding: utf-8 -*-
"""
Build SPE_数据库_v16.2.docx from v16.1:
  * new Table 1 (107 rows, regenerated from Dataset_Inf.csv)
  * new Table 2 (mismatch bootstrap summary, v2 numbers)
  * three figures replaced by their _v2 versions
  * text updated to the v2 results / corrected reference list
"""
import copy
import csv
import os
import shutil

import docx
from docx.shared import Emu

WRITING = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing'
SRC = os.path.join(WRITING, 'SPE_数据库_v16.1.docx')
DST = os.path.join(WRITING, 'SPE_数据库_v16.2.docx')
TABLE1 = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Output\Table1_v2.csv'
PIC = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Output\Pic'

FIG_IDENTITY = os.path.join(PIC, 'p_ridges_pairwise_combined_11_v2.png')
FIG_MISMATCH = os.path.join(PIC, 'combined_figures_v6_v2.png')
FIG_EXPLOR = os.path.join(PIC, 'Figure_Exploratory_Moderators_Main_v2.png')

shutil.copyfile(SRC, DST)
doc = docx.Document(DST)


# ---------------------------------------------------------------- helpers
def set_text(p, text):
    if not p.runs:
        p.add_run(text)
        return
    p.runs[0].text = text
    for r in p.runs[1:]:
        r.text = ""


def set_par(i, text):
    set_text(doc.paragraphs[i], text)


def set_cell(cell, text):
    p = cell.paragraphs[0]
    set_text(p, text)
    for extra in cell.paragraphs[1:]:
        extra._element.getparent().remove(extra._element)


def replace_image(par, path):
    """Swap the picture in `par` for `path`, preserving/repairing aspect ratio."""
    blips = par._p.findall('.//' + docx.oxml.ns.qn('a:blip'))
    if not blips:
        raise RuntimeError('no image in paragraph')
    rId = blips[0].get(docx.oxml.ns.qn('r:embed'))
    part = doc.part.related_parts[rId]
    with open(path, 'rb') as f:
        part._blob = f.read()
    # fix display size to the new image aspect ratio
    from PIL import Image
    with Image.open(path) as im:
        ar = im.width / im.height
    from docx.oxml.ns import qn
    inl = par._p.findall('.//' + qn('wp:inline'))[0]
    ext = inl.find(qn('wp:extent'))
    cx, cy = int(ext.get('cx')), int(ext.get('cy'))
    if ar >= cx / cy:
        nx, ny = cx, int(round(cx / ar))
    else:
        ny, nx = cy, int(round(cy * ar))
    ext.set('cx', str(nx)); ext.set('cy', str(ny))
    # keep a:ext in sync
    for aext in inl.findall('.//' + qn('a:ext')):
        aext.set('cx', str(nx)); aext.set('cy', str(ny))
    print(f'   image -> {os.path.basename(path)}  ({ar:.3f}) display {nx}x{ny}')


# ---------------------------------------------------------------- Table 1
new_rows = list(csv.DictReader(open(TABLE1, encoding='utf-8-sig')))
t1 = doc.tables[0]
need = 1 + len(new_rows)
while len(t1.rows) < need:
    t1._tbl.append(copy.deepcopy(t1.rows[-1]._tr))
while len(t1.rows) > need:
    t1._tbl.remove(t1.rows[-1]._tr)

cols = ['Num', 'ID', 'Study', 'Exp', 'Country', 'Language',
        'N (M/F)', 'Stimulus', 'Trials', 'License', 'Exp_Implement']
for ri, rec in enumerate(new_rows, start=1):
    cells = t1.rows[ri].cells
    for ci, col in enumerate(cols):
        val = (rec.get(col) or '').strip()
        if val in ('nan', 'NA', 'None'):
            val = 'NA' if col == 'License' else ''
        set_cell(cells[ci], val)
print(f'Table 1 written: {len(new_rows)} rows')

# ---------------------------------------------------------------- Table 2
rows2 = [
    ['', 'RT', 'Shape', '3,604', '0.005', '[−0.008, 0.017]', 'not reached'],
    ['', 'RT', 'Label', '3,192', '0.125', '[0.112, 0.138]', '40'],
    ['', 'ACC', 'Shape', '3,524', '0.009', '[−0.002, 0.020]', 'not reached'],
    ['', 'ACC', 'Label', '3,114', '0.009', '[−0.003, 0.021]', 'not reached'],
    ['', 'RT', 'Shape', '1,563', '0.123', '[0.103, 0.144]', '40'],
    ['', 'RT', 'Label', '1,563', '0.252', '[0.227, 0.275]', '20'],
    ['', 'ACC', 'Shape', '1,494', '0.052', '[0.035, 0.070]', '170'],
    ['', 'ACC', 'Label', '1,494', '0.049', '[0.030, 0.069]', '210'],
]
t2 = doc.tables[1]
for ri, data in enumerate(rows2, start=1):
    cells = t2.rows[ri].cells
    for ci in range(1, len(data)):
        set_cell(cells[ci], data[ci])
# the first column is vertically merged: one cell per approach block
set_cell(t2.rows[1].cells[0], 'Liberal Approach')
set_cell(t2.rows[5].cells[0], 'Conservative Approach')

# ---------------------------------------------------------------- figures
print('replacing figures:')
replace_image(doc.paragraphs[50], FIG_IDENTITY)
replace_image(doc.paragraphs[63], FIG_MISMATCH)
replace_image(doc.paragraphs[77], FIG_EXPLOR)

doc.save(DST)
print('\nsaved ->', DST)
