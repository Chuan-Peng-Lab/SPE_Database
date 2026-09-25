# -*- coding: utf-8 -*-
"""Dump every comment in the annotated file with its anchor text, to check alignment."""
import os
import time

import win32com.client as win32

P = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2_批注版_czx.docx'

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
doc = word.Documents.Open(P, False, True)
time.sleep(1)
n = doc.Comments.Count
print('comments:', n)
for i in range(1, n + 1):
    c = doc.Comments(i)
    scope = c.Scope.Text.replace('\r', ' ').strip()
    body = c.Range.Text.replace('\r', ' ').strip()
    print(f'{i:2d} | {c.Author} | anchor={scope[:70]!r}')
    print(f'   | text = {body[:70]!r}')
doc.Close(False)
word.Quit()
