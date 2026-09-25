# -*- coding: utf-8 -*-
"""Inspect the compared document: revision types, tables, and comment API behaviour."""
import os
import time

import pythoncom
import win32com.client as win32

OUT = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\_compare_test.docx'

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
print('UserName before:', repr(word.UserName))
word.UserName = 'czx'
word.UserInitials = 'czx'
print('UserName after :', repr(word.UserName))

doc = word.Documents.Open(OUT, False, False)
time.sleep(2)
print('revisions:', doc.Revisions.Count, ' comments:', doc.Comments.Count,
      ' paragraphs:', doc.Paragraphs.Count, ' tables:', doc.Tables.Count)

# revision type histogram + a few samples
from collections import Counter
types = Counter()
samples = []
for i in range(1, doc.Revisions.Count + 1):
    r = doc.Revisions(i)
    types[r.Type] += 1
    if len(samples) < 12 and i % 200 == 0:
        samples.append((r.Type, r.Author, r.Range.Text[:60]))
print('types:', dict(types))
for s in samples:
    print('  sample:', s)

# paragraph text samples
for i in [1, 20, 40, 60]:
    if i <= doc.Paragraphs.Count:
        print(f'  para {i}: {doc.Paragraphs(i).Range.Text[:90]!r}')

# try adding a comment on a known paragraph
target = None
for i in range(1, doc.Paragraphs.Count + 1):
    t = doc.Paragraphs(i).Range.Text
    if '49 studies (89 experiment-level datasets' in t:
        target = doc.Paragraphs(i).Range
        print(f'  found anchor at paragraph {i}')
        break
if target is not None:
    c = doc.Comments.Add(target, '测试批注：作者应为 czx')
    print('added comment; author =', c.Author, ' initials =', c.Initial)
    doc.Save()
print('saved')

doc.Close(False)
word.Quit()
