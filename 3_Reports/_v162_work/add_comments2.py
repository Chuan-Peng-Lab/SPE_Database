# -*- coding: utf-8 -*-
"""Add the czx comments again, this time anchoring by exact character offset
(Find-based anchoring silently mis-placed the six reference-list comments)."""
import os
import time

import win32com.client as win32

SRC = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2.docx'
TMP = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\_v162_commented_raw.docx'

from add_comments_data import COMMENTS  # anchor, text  (kept in one place)

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
word.UserName = 'czx'
word.UserInitials = 'czx'

doc = word.Documents.Open(SRC, False, False)
time.sleep(1)

full = doc.Content.Text
base = doc.Content.Start
print('document chars:', len(full), 'content start:', base)

ok, bad = 0, []
for idx, (anchor, text) in enumerate(COMMENTS, 1):
    pos = full.find(anchor)
    if pos < 0:
        bad.append((idx, anchor[:50], 'NOT FOUND'))
        continue
    rng = doc.Range(base + pos, base + pos + len(anchor))
    if anchor not in rng.Text:
        bad.append((idx, anchor[:50], f'RANGE MISMATCH: {rng.Text[:50]!r}'))
        continue
    c = doc.Comments.Add(rng, text)
    ok += 1

print('comments added:', ok, '/', len(COMMENTS))
for b in bad:
    print('  !!', b)

# ---- read back and verify each anchor -----------------------------------
print('\nverify:')
fails = 0
for i in range(1, doc.Comments.Count + 1):
    c = doc.Comments(i)
    scope = c.Scope.Text.replace('\r', ' ').strip()
    body = c.Range.Text.replace('\r', ' ').strip()
    tag = body[:26]
    hit = any(a[:40] in scope for a, _ in COMMENTS)
    if not hit:
        fails += 1
        print(f'  {i:2d} MISPLACED  anchor={scope[:60]!r}  text={tag!r}')
    else:
        print(f'  {i:2d} ok  {tag}  <- {scope[:60]!r}')
print('misplaced:', fails)

doc.SaveAs2(TMP, 16)
doc.Close(False)
word.Quit()
print('saved ->', TMP)
