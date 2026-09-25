# -*- coding: utf-8 -*-
"""Diagnose the six reference-list comments: is Scope.Start correct even though
Scope.Text reports the first bibliography paragraph?"""
import os
import time

import win32com.client as win32

P = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2_批注版_czx.docx'

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
doc = word.Documents.Open(P, False, True)
time.sleep(1)

# locate the reference paragraphs by start offset
n = doc.Paragraphs.Count
refs = {}
t0 = time.time()
for i in range(n - 80, n + 1):
    if i < 1:
        continue
    r = doc.Paragraphs(i).Range
    t = r.Text.replace('\r', ' ').strip()
    for key in ['Appelbaum', 'Aron, A.', 'Bogacz', 'Ghai, S., Forscher', 'Lin, Z.',
                'Markus, H. R.', 'Sun, S.']:
        if t.startswith(key[:12]):
            refs.setdefault(key, (i, r.Start, r.End, t[:40]))
print('reference paragraphs:')
for k, v in refs.items():
    print(f'   {k:18s} para={v[0]:5d} start={v[1]:6d} end={v[2]:6d} {v[3]!r}')

print('\ncomments 31-37:')
for i in range(31, doc.Comments.Count + 1):
    c = doc.Comments(i)
    print(f'  #{i} scopeStart={c.Scope.Start:6d} scopeEnd={c.Scope.End:6d} '
          f'text={c.Range.Text.replace(chr(13), " ")[:34]!r}')
    print(f'       scopeText={c.Scope.Text.replace(chr(13), " ")[:70]!r}')

doc.Close(False)
word.Quit()
