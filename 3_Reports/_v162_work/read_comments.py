# -*- coding: utf-8 -*-
"""Read the comments back through Word to confirm the author Word reports."""
import os

import win32com.client as win32

WRITING = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing'
FILES = [
    os.path.join(WRITING, 'SPE_数据库_v16.2_批注版_czx.docx'),
    os.path.join(WRITING, 'SPE_数据库_v16.2_修订批注版_czx.docx'),
]

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0

for path in FILES:
    print('===', os.path.basename(path))
    doc = word.Documents.Open(path, False, True)
    n = doc.Comments.Count
    authors = {}
    for i in range(1, n + 1):
        c = doc.Comments(i)
        authors[c.Author] = authors.get(c.Author, 0) + 1
    print('   comments:', n, ' reported authors:', authors)
    for i in [1, 2, n]:
        c = doc.Comments(i)
        print(f'   #{i} author={c.Author!r} initials={c.Initial!r} scope={c.Scope.Text[:45]!r}')
        print(f'        text={c.Range.Text[:90]!r}')
    doc.Close(False)

word.Quit()
print('done')
