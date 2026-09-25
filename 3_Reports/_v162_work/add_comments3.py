# -*- coding: utf-8 -*-
"""Anchor the czx comments at paragraph level (robust against citation field codes)."""
import os
import time

import win32com.client as win32

from add_comments_data import COMMENTS

SRC = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2.docx'
TMP = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\_v162_commented_raw.docx'

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
word.UserName = 'czx'
word.UserInitials = 'czx'

doc = word.Documents.Open(SRC, False, False)
time.sleep(1)

n = doc.Paragraphs.Count
print('word paragraphs:', n)
texts = []
t0 = time.time()
for i in range(1, n + 1):
    texts.append(doc.Paragraphs(i).Range.Text)
    if i % 300 == 0:
        print(f'   ... {i}/{n}  ({time.time()-t0:.0f}s)')
print('enumerated in %.0fs' % (time.time() - t0))

# map each anchor to the first paragraph containing it
# (the single-character-exact case: the "Reference" heading, to avoid matching
#  ordinary sentences that merely contain the word)
EXACT = {'Reference'}
placed, missing = [], []
used = set()
for anchor, body in COMMENTS:
    hit = None
    for i, t in enumerate(texts, 1):
        tt = t.replace('\r', '').strip()
        if (tt == anchor) if anchor in EXACT else (anchor in t):
            hit = i
            break
    if hit is None:
        missing.append(anchor[:60])
    else:
        placed.append((hit, anchor, body))
        used.add(hit)
print('anchors found:', len(placed), '/', len(COMMENTS))
for m in missing:
    print('   !! not found:', m)

# add comments in document order
placed.sort(key=lambda x: x[0])
for idx, anchor, body in placed:
    doc.Comments.Add(doc.Paragraphs(idx).Range, body)

print('\ncomments now:', doc.Comments.Count)
fails = 0
for i in range(1, doc.Comments.Count + 1):
    c = doc.Comments(i)
    scope = c.Scope.Text.replace('\r', ' ').strip()[:60]
    body = c.Range.Text.replace('\r', ' ').strip()[:24]
    ok = any(a in c.Scope.Text for a, _ in COMMENTS)
    if not ok:
        fails += 1
        print(f'  {i:2d} MISPLACED {body!r} <- {scope!r}')
print('misplaced:', fails)

doc.SaveAs2(TMP, 16)
doc.Close(False)
word.Quit()
print('saved ->', TMP)
