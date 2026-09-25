# -*- coding: utf-8 -*-
"""Compare v16.1 -> v16.2 with the revision author set to czx, then inspect the result."""
import os
import re
import time
import zipfile

import win32com.client as win32

WR = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing'
ORIG = os.path.join(WR, 'SPE_数据库_v16.1.docx')
REV = os.path.join(WR, 'SPE_数据库_v16.2.docx')
OUT = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\_compare_test.docx'

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
word.UserName = 'czx'
word.UserInitials = 'czx'

d1 = word.Documents.Open(ORIG, False, True)
d2 = word.Documents.Open(REV, False, True)
cmp = word.CompareDocuments(
    d1, d2, 2, 0,
    False, False, False, True, False, False, False, False, False, True,
    'czx', True,
)
print('compared; revisions =', cmp.Revisions.Count)
time.sleep(3)
cmp.SaveAs2(OUT, 16)
print('saved ->', OUT)
time.sleep(2)
try:
    cmp.Close(False)
except Exception as e:
    print('close warn:', e)
try:
    d1.Close(False)
    d2.Close(False)
except Exception as e:
    print('close warn:', e)
word.Quit()

# ---------------------------------------------------------------- inspect XML
with zipfile.ZipFile(OUT) as z:
    xml = z.read('word/document.xml').decode('utf-8')
ins = re.findall(r'<w:ins [^>]*w:author="([^"]*)"', xml)
dele = re.findall(r'<w:del [^>]*w:author="([^"]*)"', xml)
from collections import Counter
print('\nw:ins authors :', Counter(ins))
print('w:del authors :', Counter(dele))
print('total ins/del :', len(ins), len(dele))
