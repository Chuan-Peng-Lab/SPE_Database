# -*- coding: utf-8 -*-
"""Open both annotated deliverables in Word and export a markup PDF for visual checking."""
import os
import time

import win32com.client as win32

WRITING = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing'
WD = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work'
FILES = [
    os.path.join(WRITING, 'SPE_数据库_v16.2_批注版_czx.docx'),
    os.path.join(WRITING, 'SPE_数据库_v16.2_修订批注版_czx.docx'),
]

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0

for i, path in enumerate(FILES, 1):
    print('===', os.path.basename(path))
    doc = word.Documents.Open(path, False, False)
    time.sleep(1)
    try:
        print('   pages:', doc.ComputeStatistics(2),
              '| comments:', doc.Comments.Count,
              '| revisions:', doc.Revisions.Count)
    except Exception as e:
        print('   stats warn:', e)
    # show all markup, then export a markup PDF
    try:
        doc.ActiveWindow.View.ShowRevisionsAndComments = True
        doc.ActiveWindow.View.RevisionsFilter.Markup = 2   # wdRevisionsMarkupAll
    except Exception as e:
        print('   markup warn:', e)
    pdf = os.path.join(WD, f'annotated_{i}.pdf')
    doc.ExportAsFixedFormat(pdf, 17)
    print('   pdf ->', pdf)
    doc.Close(False)

word.Quit()
print('done')
