# -*- coding: utf-8 -*-
"""Dump a .docx (paragraphs + tables, in document order) to a UTF-8 text file."""
import sys, io
import docx
from docx.table import Table
from docx.text.paragraph import Paragraph
from docx.oxml.ns import qn


def iter_block_items(parent):
    from docx.document import Document as _Doc
    if isinstance(parent, _Doc):
        parent_elm = parent.element.body
    else:
        parent_elm = parent._tc
    for child in parent_elm.iterchildren():
        if child.tag == qn('w:p'):
            yield Paragraph(child, parent)
        elif child.tag == qn('w:tbl'):
            yield Table(child, parent)


def cell_text(cell):
    return " / ".join(p.text.strip() for p in cell.paragraphs if p.text.strip())


def main(path, out):
    d = docx.Document(path)
    buf = io.StringIO()
    tbl_i = 0
    for blk in iter_block_items(d):
        if isinstance(blk, Paragraph):
            style = blk.style.name if blk.style is not None else ""
            txt = blk.text
            has_img = 'graphicData' in blk._p.xml
            tag = f"[{style}]"
            if has_img:
                tag += "[IMG]"
            buf.write(f"{tag} {txt}\n")
        else:
            buf.write(f"\n===TABLE {tbl_i} ({len(blk.rows)}x{len(blk.columns)})===\n")
            for r_i, row in enumerate(blk.rows):
                cells = [cell_text(c) for c in row.cells]
                buf.write(f"T{tbl_i}R{r_i}\t" + "\t".join(cells) + "\n")
            buf.write(f"===END TABLE {tbl_i}===\n\n")
            tbl_i += 1
    with open(out, "w", encoding="utf-8") as f:
        f.write(buf.getvalue())
    print("wrote", out, len(buf.getvalue()), "chars")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
