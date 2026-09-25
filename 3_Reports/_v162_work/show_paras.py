# -*- coding: utf-8 -*-
"""Print the full text of the paragraphs that need rewriting."""
import sys
import docx

DOCX = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.1.docx'
IDX = [int(x) for x in sys.argv[1:]]
d = docx.Document(DOCX)
for i in IDX:
    print(f"----- [{i}] -----")
    print(d.paragraphs[i].text)
    print()
