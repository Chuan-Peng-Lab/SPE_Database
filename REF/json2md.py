#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
json2md.py — 将 html2Json.py 产出的结构化 JSON 渲染为 Markdown。

规则遵循 REF/html2md_PROMPT.md：
  - YAML frontmatter（title/authors/affiliations/abstract/doi/journal/published_date/Volume/Issue/Page）
  - 标题层级、段落、图（图注 + ![](src)）、表（Markdown 表格 + 表注）、参考文献 [n]、脚注
用法：python3 json2md.py [--force]
  （默认跳过已有 .md 的文件；--force 重新生成）
"""
import os
import re
import sys
import json


def clean(s):
    return re.sub(r'\s+', ' ', (s or '')).strip()


def fig_lead(caption):
    """把 'Fig. 1. xxx' / 'FIGURE 1 xxx' 的编号部分加粗。"""
    m = re.match(r'^(Fig(?:ure)?\.?\s*\d+[A-Z]?)(\.?)\s*(.*)$', caption, re.S | re.I)
    if m:
        lead = m.group(1) + (m.group(2) or '.')
        rest = m.group(3)
        return f'**{lead}** {rest}'.strip()
    return caption


def render_md(data):
    L = []
    # ---------- frontmatter ----------
    def yq(s):
        s = clean(s)
        if not s:
            return '""'
        if ': ' in s or any(c in s for c in ':#[]{}&,*!|>\'"'):
            return '"' + s.replace('"', "'") + '"'
        return s

    L.append('---')
    L.append(f'title: {yq(data.get("title"))}')
    L.append('authors:')
    for a in data.get('authors') or []:
        L.append(f'  - {yq(a)}')
    L.append('affiliations:')
    for a in data.get('affiliations') or []:
        L.append(f'  - {yq(a)}')
    L.append(f'abstract: {yq(data.get("abstract"))}')
    if data.get('doi'):
        L.append(f'doi: {clean(data.get("doi"))}')
    if data.get('journal'):
        L.append(f'journal: {yq(data.get("journal"))}')
    if data.get('published_date'):
        L.append(f'published_date: {clean(data.get("published_date"))}')
    if data.get('volume'):
        L.append(f'Volume: {clean(data.get("volume"))}')
    if data.get('issue'):
        L.append(f'Issue: {clean(data.get("issue"))}')
    if data.get('pages'):
        L.append(f'Page: {clean(data.get("pages"))}')
    kws = [k for k in (data.get('keywords') or []) if clean(k)]
    if kws:
        L.append('keywords:')
        for k in kws:
            L.append(f'  - {yq(k)}')
    L.append('---')
    L.append('')
    if data.get('title'):
        L.append(f'# {clean(data["title"])}')
        L.append('')
    if data.get('authors'):
        L.append(', '.join(clean(a) for a in data['authors']))
        L.append('')

    # ---------- abstract ----------
    if data.get('abstract'):
        L.append('## Abstract')
        L.append('')
        L.append(clean(data['abstract']))
        L.append('')
    if kws:
        L.append('**Keywords:** ' + ', '.join(kws))
        L.append('')

    # ---------- body ----------
    for b in data.get('body') or []:
        t = b.get('type')
        if t == 'heading':
            lvl = min(max(int(b.get('level') or 2), 1), 6)
            L.append('#' * lvl + ' ' + clean(b.get('text')))
            L.append('')
        elif t == 'paragraph':
            txt = clean(b.get('text'))
            if txt:
                L.append(txt)
                L.append('')
        elif t == 'figure':
            cap = clean(b.get('caption'))
            src = (b.get('src') or '').lstrip('./')
            if cap:
                L.append(fig_lead(cap))
                L.append('')
            if src:
                # 文件名含括号（如 default(1).jpg）会截断 Markdown 链接，须 URL 转义
                esc = src.replace('(', '%28').replace(')', '%29')
                L.append(f'![{cap or "Figure"}]({esc})')
                L.append('')
        elif t == 'table':
            cap = clean(b.get('caption'))
            rows = b.get('rows') or []
            if cap:
                L.append(fig_lead(cap.replace('Table', 'Table', 1)))
                L.append('')
            if rows:
                ncol = max(len(r) for r in rows)
                for i, r in enumerate(rows):
                    r = r + [''] * (ncol - len(r))
                    cells = [c.replace('|', '\\|').replace('\n', ' ') for c in r]
                    L.append('| ' + ' | '.join(cells) + ' |')
                    if i == 0:
                        L.append('|' + '---|' * ncol)
                L.append('')
            else:
                L.append('> **表注：** 表格数据未包含在保存的网页中（原文以独立链接提供）。')
                L.append('')

    # ---------- references ----------
    refs = data.get('references') or []
    if refs:
        L.append('## References')
        L.append('')
        for i, r in enumerate(refs, 1):
            L.append(f'[{i}] {clean(r)}')
            L.append('')

    # ---------- footnotes / ack / correspondence ----------
    fns = data.get('footnotes') or []
    if fns:
        L.append('## Footnotes')
        L.append('')
        for i, f in enumerate(fns, 1):
            L.append(f'{i}. {clean(f)}')
            L.append('')
    ack = clean(data.get('acknowledgements'))
    if ack:
        L.append('## Acknowledgements')
        L.append('')
        L.append(ack)
        L.append('')
    corr = clean(data.get('correspondence'))
    if corr:
        L.append('## Correspondence')
        L.append('')
        L.append(corr)
        L.append('')

    return '\n'.join(L).rstrip() + '\n'


def main():
    force = '--force' in sys.argv
    folder = os.getcwd()
    print(f"📂 扫描目录：{folder}")
    json_files = [f for f in os.listdir(folder) if f.lower().endswith('.json')]
    json_files = [f for f in json_files if not f.startswith('html2')]
    if not json_files:
        print("⚠️ 未找到任何 JSON 文件。")
        return
    n = 0
    for jf in sorted(json_files):
        md_path = os.path.splitext(jf)[0] + '.md'
        if os.path.exists(md_path) and not force:
            print(f"⏭️  跳过（md 已存在）：{md_path}")
            continue
        try:
            with open(jf, encoding='utf-8') as f:
                data = json.load(f)
            if 'body' not in data or not (data.get('title') or data.get('body')):
                print(f"⏭️  跳过（结构未识别/提取失败）：{jf}")
                continue
            with open(md_path, 'w', encoding='utf-8') as f:
                f.write(render_md(data))
            body = data.get('body') or []
            kinds = {}
            for b in body:
                kinds[b.get('type')] = kinds.get(b.get('type'), 0) + 1
            figs = [b.get('src') for b in body if b.get('type') == 'figure' and b.get('src')]
            missing = [p for p in figs if not p.startswith('http') and not os.path.exists(os.path.join(folder, p))]
            stats = ' | '.join(f'{k}{v}' for k, v in kinds.items()) if kinds else '空'
            print(f"✅ {os.path.splitext(jf)[0]}.md | refs={len(data.get('references') or [])} | body: {stats} | 图={len(figs)}" +
                  (f" | ⚠️缺本地图: {missing}" if missing else ''))
            n += 1
        except Exception as e:
            print(f"❌ {jf} 失败：{e}")
    print(f"\n🎉 完成，共生成 {n} 个 md 文件。")


if __name__ == '__main__':
    main()
