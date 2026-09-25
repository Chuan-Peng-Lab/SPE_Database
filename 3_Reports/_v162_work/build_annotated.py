# -*- coding: utf-8 -*-
"""Rebuild the two annotated deliverables with a safe, targeted author rewrite."""
import os
import re
import time
import zipfile
import xml.etree.ElementTree as ET

import win32com.client as win32

WD = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work'
WRITING = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing'
V161 = os.path.join(WRITING, 'SPE_数据库_v16.1.docx')
RAW_COMMENTED = os.path.join(WD, '_v162_commented_raw.docx')
OUT_COMMENTED = os.path.join(WRITING, 'SPE_数据库_v16.2_批注版_czx.docx')
OUT_REVISED = os.path.join(WRITING, 'SPE_数据库_v16.2_修订批注版_czx.docx')

AUTHOR = 'czx'
COMMENT_PARTS = ('word/comments.xml', 'word/commentsExtended.xml',
                 'word/commentsIds.xml', 'word/people.xml')
ALL_PARTS = COMMENT_PARTS + ('word/document.xml',)


def rewrite(src, dst, parts):
    with zipfile.ZipFile(src) as zin:
        infos = zin.infolist()
        data = {i.filename: zin.read(i.filename) for i in infos}
    touched = []
    for part in parts:
        if part not in data:
            continue
        xml = data[part].decode('utf-8')
        new = re.sub(r'(w:author|w:initials|w15:author|w15:initials)="[^"]*"',
                     lambda m: f'{m.group(1)}="{AUTHOR}"', xml)
        if new != xml:
            touched.append(part)
        data[part] = new.encode('utf-8')
    with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zout:
        for zi in infos:
            zout.writestr(zi, data[zi.filename])
    return touched


def validate(path):
    """Parse every XML part; report the reviewer names actually present."""
    with zipfile.ZipFile(path) as z:
        bad = []
        for n in z.namelist():
            if n.endswith('.xml') or n.endswith('.rels'):
                try:
                    ET.fromstring(z.read(n))
                except ET.ParseError as e:
                    bad.append((n, str(e)))
        doc = z.read('word/document.xml').decode('utf-8')
        authors = sorted(set(re.findall(r'w:author="([^"]*)"', doc)))
        cmt_authors = []
        if 'word/comments.xml' in z.namelist():
            c = z.read('word/comments.xml').decode('utf-8')
            cmt_authors = sorted(set(re.findall(r'w:author="([^"]*)"', c)))
            # duplicate-attribute guard
            dup = re.findall(r'<w:comment [^>]*?(w:initials="[^"]*")[^>]*?\1', c)
        n_comments = len(re.findall(r'<w:comment ', z.read('word/comments.xml').decode('utf-8'))) \
            if 'word/comments.xml' in z.namelist() else 0
    return dict(bad_xml=bad, rev_authors=authors, comment_authors=cmt_authors,
                comments=n_comments,
                ins=len(re.findall(r'<w:ins ', doc)),
                dele=len(re.findall(r'<w:del ', doc)))


# ---------------------------------------------------------------- 1) comments only
print('[1] comment-only version (document revisions keep their original author)')
t = rewrite(RAW_COMMENTED, OUT_COMMENTED, COMMENT_PARTS)
print('   rewritten parts:', t)
print('   ', validate(OUT_COMMENTED))

# ---------------------------------------------------------------- 2) compare
print('\n[2] compare v16.1 -> commented v16.2 (RevisedAuthor = czx)')
word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
word.UserName = AUTHOR
word.UserInitials = AUTHOR
d1 = word.Documents.Open(V161, False, True)
d2 = word.Documents.Open(RAW_COMMENTED, False, True)
cmp = word.CompareDocuments(d1, d2, 2, 0,
                            False, False, False, True, False, False, False, False,
                            False, True, AUTHOR, True)
print('   revisions:', cmp.Revisions.Count)
time.sleep(2)
tmp_rev = os.path.join(WD, '_v162_rev_raw.docx')
cmp.SaveAs2(tmp_rev, 16)
time.sleep(1)
try:
    cmp.Close(False)
except Exception as e:
    print('   close warn:', e)
d1.Close(False)
d2.Close(False)
word.Quit()

print('\n[3] force author on the compared document')
t = rewrite(tmp_rev, OUT_REVISED, ALL_PARTS)
print('   rewritten parts:', t)
info = validate(OUT_REVISED)
print('   ', info)
print('\ndone')
