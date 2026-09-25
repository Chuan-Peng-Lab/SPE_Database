# -*- coding: utf-8 -*-
"""Final integrity check of the three deliverables."""
import os
import time

import win32com.client as win32

WRITING = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing'
FILES = [
    'SPE_数据库_v16.2.docx',
    'SPE_数据库_v16.2_批注版_czx.docx',
    'SPE_数据库_v16.2_修订批注版_czx.docx',
]

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
for name in FILES:
    p = os.path.join(WRITING, name)
    doc = word.Documents.Open(p, False, True)
    time.sleep(1)
    print(f'{name}')
    print(f'   pages={doc.ComputeStatistics(2)} words={doc.ComputeStatistics(0)} '
          f'comments={doc.Comments.Count} revisions={doc.Revisions.Count} '
          f'tables={doc.Tables.Count} shapes={doc.InlineShapes.Count}')
    doc.Close(False)
word.Quit()
print('all three open cleanly')
