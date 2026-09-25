# -*- coding: utf-8 -*-
"""Inspect caption paragraphs for Word field codes."""
import re
import docx

DST = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2.docx'
d = docx.Document(DST)
for i in [20, 28, 37, 38, 45, 51, 64, 65, 66, 78]:
    p = d.paragraphs[i]
    xml = p._p.xml
    fld = re.findall(r'<w:fldSimple[^>]*w:instr="([^"]*)"', xml)
    instr = re.findall(r'<w:instrText[^>]*>([^<]*)</w:instrText>', xml)
    print(f"[{i}] style={p.style.name!r} text={p.text[:70]!r}")
    print(f"     fldSimple={fld} instrText={instr}")
