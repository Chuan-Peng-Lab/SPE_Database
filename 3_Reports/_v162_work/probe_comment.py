# -*- coding: utf-8 -*-
"""Minimal check: can we set the Word user name, and do comments pick it up?"""
import os
import time

import win32com.client as win32

SRC = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2.docx'
TMP = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\_comment_probe.docx'

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
print('UserName before:', repr(word.UserName))
word.UserName = 'czx'
word.UserInitials = 'czx'
print('UserName after :', repr(word.UserName))

doc = word.Documents.Open(SRC, False, False)
p = doc.Paragraphs(7).Range
c = doc.Comments.Add(p, 'czx 批注测试')
print('comment author:', repr(c.Author), 'initial:', repr(c.Initial))
doc.SaveAs2(TMP, 16)
doc.Close(False)
word.Quit()
print('ok ->', TMP)
