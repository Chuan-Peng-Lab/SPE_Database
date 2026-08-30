import os
import re
import glob
import json
from bs4 import BeautifulSoup, Comment
from shadow_web.compressor import process_html
from shadow_web.schema_snap import parse_page


# ============================================================
# 元数据兜底（页面本身缺失时使用；数据来自 Crossref / 已知文献信息）
# ============================================================
METADATA_OVERRIDES = {
    '10.1111/bjop.12741': {  # Kirk_2025_BritJPsy：页面头部未被保存，元数据取自 Crossref
        'title': 'Listen to yourself! Prioritization of self‐associated and own voice cues',
        'authors': ['Neil W. Kirk', 'Sheila J. Cunningham'],
        'journal': 'British Journal of Psychology',
        'volume': '116', 'issue': '1', 'pages': '131-148',
        'published_date': '2025-02',
    },
    '10.1111/psyp.14396': {  # Haciahmet_2023_Psychophysiol：Wiley 页面 meta 缺失，取自 Crossref
        'title': 'The oscillatory fingerprints of self-prioritization: Novel markers in spectral EEG for self-relevant processing',
        'authors': ['Céline C. Haciahmet', 'Marius Golubickis', 'Sarah Schäfer', 'Christian Frings', 'Bernhard Pastötter'],
        'journal': 'Psychophysiology',
        'volume': '60', 'issue': '12', 'pages': '',
        'published_date': '2023-12',
    },
    '10.1002/hbm.25129': {  # Kolvoort_2020_HumBrainMap：同上，取自 Crossref
        'title': 'Temporal integration as "common currency" of brain and self: Scale-free activity in resting-state EEG correlates with temporal delay effects on self-relatedness',
        'authors': ['Ivar R. Kolvoort', 'Soren Wainio-Theberge', 'Annemarie Wolff', 'Georg Northoff'],
        'journal': 'Human Brain Mapping',
        'volume': '41', 'issue': '15', 'pages': '4355-4374',
        'published_date': '2020-10-15',
    },
    '10.1002/hbm.25730': {  # Liang_2022_HumBrainMap：同上，取自 Crossref
        'title': 'The roles of the LpSTS and DLPFC in self-prioritization: A transcranial magnetic stimulation study',
        'authors': ['Qiongdan Liang', 'Bozhen Zhang', 'Sinan Fu', 'Jie Sui', 'Fei Wang'],
        'journal': 'Human Brain Mapping',
        'volume': '43', 'issue': '4', 'pages': '1381-1393',
        'published_date': '2022-03',
    },
    '10.1177/17470218221112238': {  # Svensson_2023_QJEP：SAGE 页面仅保存 journal meta，其余取自 Crossref
        'title': 'Self-relevance and the activation of attentional networks',
        'authors': ['Saga Svensson', 'Marius Golubickis', 'Sam Johnson', 'Johanna K. Falbén', 'C. Neil Macrae'],
        'journal': 'Quarterly Journal of Experimental Psychology',
        'volume': '76', 'issue': '5', 'pages': '1120-1130',
        'published_date': '2023-05',
    },
    '10.1111/ejn.14782': {  # Mcivor_2021_EJN：Wiley 页面 meta 缺失，取自 Crossref
        'title': 'Self-referential processing and emotion context insensitivity in major depressive disorder',
        'authors': ['Lucy McIvor', 'Jie Sui', 'Tina Malhotra', 'David Drury', 'Sanjay Kumar'],
        'journal': 'European Journal of Neuroscience',
        'volume': '53', 'issue': '1', 'pages': '311-329',
        'published_date': '2021-01',
    },
    '10.1177/17470218221124928': {  # Orellana-Corrales_2023_QJEP：SAGE 页面 meta 缺失，取自 Crossref
        'title': 'Does an experimentally induced self-association elicit affective self-prioritisation?',
        'authors': ['Gabriela Orellana-Corrales', 'Christina Matschke', 'Sarah Schäfer', 'Ann-Katrin Wesslein'],
        'journal': 'Quarterly Journal of Experimental Psychology',
        'volume': '76', 'issue': '6', 'pages': '1379-1390',
        'published_date': '2023-06',
    },
}


# ============================================================
# MathML → LaTeX（论文中少量公式）
# ============================================================
def mathml2latex(el):
    tag = el.name
    if tag is None:
        return el
    if tag == 'mrow':
        return ''.join(mathml2latex(c) for c in el.children)
    if tag == 'mtext':
        return re.sub(r'\s+', ' ', el.get_text())
    if tag == 'mspace':
        return ' '
    if tag in ('mi', 'mn', 'mo'):
        t = el.get_text()
        if tag == 'mo' and t == '−':
            return '-'
        return t
    if tag == 'mfrac':
        num = mathml2latex(el.find('mrow', recursive=False) or list(el.children)[0])
        return r'\frac{' + num + '}{' + den(el) + '}'
    if tag == 'msup':
        base = mathml2latex(el.contents[0])
        exp = mathml2latex(el.contents[1])
        return '{' + base + '}^{' + exp + '}'
    if tag == 'msub':
        base = mathml2latex(el.contents[0])
        sub = mathml2latex(el.contents[1])
        return '{' + base + '}_{' + sub + '}'
    if tag == 'msubsup':
        base = mathml2latex(el.contents[0])
        sub = mathml2latex(el.contents[1])
        sup = mathml2latex(el.contents[2])
        return '{' + base + '}_{' + sub + '}^{' + sup + '}'
    if tag == 'msqrt':
        return r'\sqrt{' + ''.join(mathml2latex(c) for c in el.children) + '}'
    if tag == 'mroot':
        base = mathml2latex(el.contents[0])
        idx = mathml2latex(el.contents[1])
        return r'\sqrt[' + idx + ']{' + base + '}'
    if tag in ('munder', 'mover'):
        base = mathml2latex(el.contents[0])
        acc = mathml2latex(el.contents[1])
        return '{' + base + '}_{' + acc + '}' if tag == 'munder' else '\\overline{' + base + '}'
    if tag == 'mfenced':
        inner = ''.join(mathml2latex(c) for c in el.children)
        return '(' + inner + ')'
    if tag == 'mstyle':
        return ''.join(mathml2latex(c) for c in el.children)
    if tag in ('semantics', 'annotation', 'annotation-xml', 'mpadded', 'menclose', 'mphantom', 'merror'):
        return ''.join(mathml2latex(c) for c in el.children)
    if tag == 'math':
        return ''.join(mathml2latex(c) for c in el.children)
    return ''.join(mathml2latex(c) for c in el.children)


def den(frac_el):
    kids = list(frac_el.children)
    for k in kids:
        if getattr(k, 'name', None) and k.name != 'mrow':
            return mathml2latex(k)
    return ''.join(mathml2latex(k) for k in kids)


# ============================================================
# 行内内容 → Markdown（引用转 [n]）
# ============================================================
def inline(el, refmap):
    if isinstance(el, Comment):
        return ''
    if not getattr(el, 'name', None):
        return el
    name = el.name
    cls = ' '.join(el.get('class') or [])
    if name in ('script', 'style', 'nav', 'form', 'button', 'aside', 'svg', 'source', 'picture'):
        return ''
    if name == 'br':
        return ' '
    if name == 'img':
        return ''
    if name == 'mjx-container' or name == 'mjx-assistive-mml':
        mml = el.find('math')
        if mml is None:
            return ''
        latex = mathml2latex(mml).strip()
        if not latex:
            return ''
        display = 'true' in (el.get('display') or '') or (el.get('jax') and el.name == 'mjx-container' and (el.get('display') or '').lower() == 'true')
        return '$$' + latex + '$$' if display else r'\(' + latex + r'\)'
    if name == 'math':
        return '$$' + mathml2latex(el).strip() + '$$' if (el.get('display') in ('block', 'true')) else r'\(' + mathml2latex(el).strip() + r'\)'
    if name == 'a':
        href = el.get('href') or ''
        # Springer: 脚注 #FnN
        m = re.search(r'#Fn(\d+)', href)
        if m:
            return '^' + m.group(1) + '^'
        # Springer: #ref-CRn
        m = re.search(r'#ref-CR(\d+)', href)
        if m:
            n = int(m.group(1))
            return f'[{n}]'
        # Elsevier: ...#bibN / name=bbibN / id=ref-id-bibN
        m = re.search(r'#bib(\d+)', href)
        if m:
            n = refmap.get('bib' + m.group(1))
            return f'[{n}]' if n else ''.join(inline(c, refmap) for c in el.children)
        if 'bibLink' in cls:
            m = re.search(r'#([a-z0-9]+-bib-\d+)', href)
            if m:
                n = refmap.get(m.group(1))
                return f'[{n}]' if n else ''.join(inline(c, refmap) for c in el.children)
        # SAGE: #bibrN-xxx / data-xml-rid="bibrN-xxx" → [n]
        m = re.search(r'#bibr(\d+)', href) or re.search(r'bibr(\d+)-', el.get('data-xml-rid') or '')
        if m:
            n = refmap.get('bibr' + m.group(1))
            return f'[{n}]' if n else ''.join(inline(c, refmap) for c in el.children)
        # SAGE: 脚注 #fnN-xxx → 上标
        m = re.search(r'#fn(\d+)', href)
        if m:
            return f'^{m.group(1)}^'
        # MDPI: #BN-xxx（html-bibr）→ [n]
        m = re.search(r'#(B\d+)-', href)
        if m and 'html-bibr' in cls:
            n = refmap.get(m.group(1))
            return f'[{n}]' if n else ''.join(inline(c, refmap) for c in el.children)
        # PLOS: #xxx.refNNN → [n]
        m = re.search(r'\.ref(\d+)', href)
        if m:
            return f'[{int(m.group(1))}]'
        # 其余链接：只保留文字
        return ''.join(inline(c, refmap) for c in el.children)
    if name in ('em', 'i', 'cite'):
        t = ''.join(inline(c, refmap) for c in el.children).strip()
        return f'*{t}*' if t else ''
    if name in ('strong', 'b'):
        t = ''.join(inline(c, refmap) for c in el.children).strip()
        return f'**{t}**' if t else ''
    if name == 'sup':
        t = ''.join(inline(c, refmap) for c in el.children).strip()
        if not t:
            return ''
        if t.startswith('^') and t.endswith('^'):
            return t
        return f'^{t}^'
    if name in ('sub',):
        t = ''.join(inline(c, refmap) for c in el.children).strip()
        return f'~{t}~' if t else ''
    if name == 'span' and ('dictionary-definition' in cls or 'u-visually-hidden' in cls or 'screen-reader-only' in cls):
        return ''
    return ''.join(inline(c, refmap) for c in el.children)


def norm_date(s):
    if not s:
        return s
    s = s.replace('/', '-')
    return re.sub(r'T00:00:00Z$', '', s)


def clean_text(s):
    import html as htmlmod
    s = htmlmod.unescape(s)
    s = s.replace('\xa0', ' ')
    s = re.sub(r'\s+', ' ', s)
    s = re.sub(r'\s+([,.;:!?])(?!\d)', r'\1', s)
    s = re.sub(r'\(\s+', '(', s)
    s = re.sub(r'\s+\)', ')', s)
    s = re.sub(r'([?!])(?=[A-Z][a-z])', r'\1 ', s)
    s = re.sub(r'([?!])\*(?=\S)', r'\1 *', s)
    return s.strip()


# ============================================================
# Elsevier（ScienceDirect，Smith / Martinez-Perez 共用模板）
# ============================================================
def extract_elsevier(soup, raw_html):
    data = {}
    # 元数据：citation_* meta
    meta = {m.get('name'): m.get('content') for m in soup.find_all('meta') if (m.get('name') or '').startswith('citation_')}
    data['title'] = meta.get('citation_title')
    data['authors'] = []
    for ag in soup.select('.author-group'):
        for link in ag.select('.react-xocs-alternative-link'):
            g = link.select_one('.given-name')
            s = link.select_one('.surname')
            if g and s:
                nm = (g.get_text(strip=True) + ' ' + s.get_text(strip=True)).strip()
                if nm and nm not in data['authors']:
                    data['authors'].append(nm)
    if not data['authors'] and meta.get('citation_author'):
        data['authors'] = [a.strip() for a in meta['citation_author'].split(';') if a.strip()]
    # 机构（ScienceDirect 序列化 JSON 中）
    data['affiliations'] = []
    for m in re.finditer(r'"#name":"(?:organization|institution)","_":"([^"]+)"', raw_html):
        a = m.group(1)
        if a and a not in data['affiliations']:
            data['affiliations'].append(a)
    data['journal'] = meta.get('citation_journal_title')
    data['volume'] = meta.get('citation_volume')
    data['issue'] = meta.get('citation_issue')
    p1, p2 = meta.get('citation_firstpage'), meta.get('citation_lastpage')
    data['pages'] = f'{p1}-{p2}' if p1 and p2 else None
    data['doi'] = meta.get('citation_doi')
    data['published_date'] = norm_date(meta.get('citation_publication_date'))
    # 摘要（取 "Abstract" 小节，排除 Highlights）
    ab_el = None
    for a in soup.select('#abstracts .abstract'):
        h = a.find('h2', recursive=False)
        if h and h.get_text(strip=True).lower() == 'abstract':
            ab_el = a
            break
    if ab_el:
        h = ab_el.find('h2', recursive=False)
        if h:
            h.decompose()
        data['abstract'] = clean_text(ab_el.get_text(' '))
    else:
        ab = soup.find(id='abstracts') or soup.select_one('.abstract')
        data['abstract'] = clean_text(ab.get_text(' ')) if ab else ''
    data['keywords'] = []
    for m in re.finditer(r'\{"#name":"keyword".*?"_":"([^"]+)"\}', raw_html):
        k = m.group(1)
        if k and k not in data['keywords']:
            data['keywords'].append(k)
    if not data['keywords']:
        kw_el = soup.select_one('.keywords') or soup.find(id='kwlist')
        if kw_el:
            for span in kw_el.select('span'):
                t = span.get_text(strip=True)
                if t and t.lower() != 'keywords':
                    data['keywords'].append(t)
    # 参考文献
    refs = []
    refmap = {}
    ol = soup.select_one('ol.references')
    if ol:
        for i, li in enumerate(ol.find_all('li', recursive=False), 1):
            aid = li.select_one('a[id^="ref-id-bib"]')
            if aid:
                refmap['bib' + aid.get('id').replace('ref-id-bib', '')] = i
            refs.append(clean_text(li.get_text(' ')))
    data['references'] = refs
    # 正文：从 #body 顶层开始单次递归（section 可嵌套，避免重复处理）
    body_el = soup.find(id='body')
    data['body'] = []
    if body_el:
        for el in body_el.children:
            data['body'].extend(block_elsevier(el, refmap))
    # 脚注
    fns = soup.select('.footnote, .footnotes li, [id^="fn"]')
    data['footnotes'] = []
    for f in fns:
        t = clean_text(f.get_text(' '))
        if t and len(t) > 5:
            t = re.sub(r'^\d+\s+', '', t)
            data['footnotes'].append(t)
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    return data


def block_elsevier(el, refmap):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name == 'div' and (el.get('id') or '').startswith('p'):
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name in ('h2', 'h3', 'h4', 'h5') and 'section-title' in cls or (name in ('h2', 'h3', 'h4', 'h5') and el.find_parent('section') is not None):
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'heading', 'level': int(name[1]), 'text': t})
        return out
    if name == 'figure':
        img = el.find('img')
        cap = el.select_one('.captions') or el.select_one('figcaption')
        cap_txt = clean_text(''.join(inline(c, refmap) for c in cap.children)) if cap else ''
        src = img.get('src') if img else None
        if src:
            out.append({'type': 'figure', 'caption': cap_txt, 'src': src})
        return out
    if name == 'table':
        cap = el.find_previous('span', class_='captions')
        tb = table_block(el, refmap)
        if cap:
            tb['caption'] = clean_text(cap.get_text(' '))
        out.append(tb)
        return out
    if name == 'ul':
        for li in el.find_all('li', recursive=False):
            t = clean_text(''.join(inline(c, refmap) for c in li.children))
            if t:
                out.append({'type': 'paragraph', 'text': t})
        return out
    # 其他容器：递归
    for c in el.children:
        out.extend(block_elsevier(c, refmap))
    return out


def table_block(el, refmap):
    rows = []
    for tr in el.find_all('tr'):
        cells = []
        for cell in tr.find_all(['th', 'td']):
            cells.append(clean_text(''.join(inline(c, refmap) for c in cell.children)))
        if cells:
            rows.append(cells)
    return {'type': 'table', 'caption': '', 'rows': rows}


# ============================================================
# Springer（Sui / Orellana-Corrales / Wozniak 共用模板）
# ============================================================
def extract_springer(soup, raw_html):
    data = {}
    # JSON-LD 元数据
    ld = None
    for s in soup.find_all('script', type='application/ld+json'):
        try:
            ld = json.loads(s.string or s.get_text())
            if isinstance(ld, dict) and ld.get('mainEntity'):
                break
        except Exception:
            continue
    main = ld.get('mainEntity', {}) if isinstance(ld, dict) else {}
    data['title'] = main.get('headline')
    data['doi'] = main.get('identifier') or (ld or {}).get('identifier')
    authors = main.get('author') or []
    data['authors'] = [a.get('name') for a in authors if isinstance(a, dict) and a.get('name')]
    data['affiliations'] = []
    for a in authors:
        affs = a.get('affiliation') or [] if isinstance(a, dict) else []
        if isinstance(affs, dict):
            affs = [affs]
        names = [x.get('name') for x in affs if isinstance(x, dict) and x.get('name')]
        data['affiliations'].append('; '.join(names))
    data['abstract'] = clean_text(main.get('description') or '')
    part = main.get('isPartOf') or {}
    data['journal'] = part.get('name')
    data['volume'] = part.get('volumeNumber')
    data['issue'] = part.get('issueNumber')
    pg = part.get('pagination') or {}
    p1, p2 = pg.get('startPage'), pg.get('endPage')
    data['pages'] = f'{p1}-{p2}' if p1 and p2 else None
    dp = norm_date(main.get('datePublished') or '')
    data['published_date'] = dp
    data['keywords'] = [k.get('name') for k in (main.get('keywords') or []) if isinstance(k, dict) and k.get('name')]
    # 兜底：citation_* meta（DOI / 卷期页 / 日期）
    meta = {m.get('name'): m.get('content') for m in soup.find_all('meta') if (m.get('name') or '').startswith('citation_')}
    if not data['doi']:
        data['doi'] = meta.get('citation_doi')
    if not data['volume']:
        data['volume'] = meta.get('citation_volume')
    if not data['issue']:
        data['issue'] = meta.get('citation_issue')
    if not data['pages'] and meta.get('citation_firstpage') and meta.get('citation_lastpage'):
        data['pages'] = f"{meta['citation_firstpage']}-{meta['citation_lastpage']}"
    if not data['published_date']:
        data['published_date'] = norm_date(meta.get('citation_publication_date'))
    # 参考文献（id=ref-CRn → 编号 n）
    refs = []
    for li in soup.select('ul.c-article-references li.c-article-references__item, ol.c-article-references li.c-article-references__item'):
        p = li.select_one('p.c-article-references__text') or li
        refs.append(clean_text(p.get_text(' ')))
    data['references'] = refs
    # 正文（section 可嵌套，直接递归；Abstract 小节跳过——已在元数据中）
    data['body'] = []
    body_el = soup.select_one('div.c-article-body')
    if body_el:
        for el in body_el.children:
            data['body'].extend(block_springer(el))
    fns = soup.select('ol.c-article-footnote li.c-article-footnote--listed__item')
    data['footnotes'] = [clean_text(fn.get_text(' ')) for fn in fns if fn.get_text(' ').strip()]
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    for b in data['body']:
        if b.get('type') == 'paragraph' and b['text'].startswith('Correspondence to'):
            data['correspondence'] = b['text']
            break
    # 合并独立的图注块到前一个 figure
    merged = []
    for b in data['body']:
        if b.get('type') == 'figdesc' and merged and merged[-1].get('type') == 'figure':
            merged[-1]['caption'] = (merged[-1]['caption'] + ' ' + b['text']).strip()
        elif b.get('type') == 'figdesc':
            merged.append({'type': 'figure', 'caption': b['text'], 'src': ''})
        else:
            merged.append(b)
    data['body'] = merged
    return data


def block_springer(el):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name == 'section' and el.get('data-title') in ('Abstract', 'Notes'):
        return []
    if name == 'h2' and 'c-article-section__title' in cls:
        t = clean_text(el.get_text(' '))
        if t:
            out.append({'type': 'heading', 'level': 2, 'text': t})
        return out
    if name == 'div' and 'c-article-section__content' in cls:
        for c in el.children:
            out.extend(block_springer(c))
        return out
    if name == 'p':
        # 跳过引用列表项（它们在 c-article-references 里，不在正文）
        if el.find_parent('ul', class_='c-article-references'):
            return []
        t = clean_text(''.join(inline(c, {}) for c in el.children))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name == 'figure':
        cap = el.find('figcaption')
        cap_cls = ' '.join(cap.get('class') or []) if cap else ''
        desc = el.select_one('.c-article-section__figure-description')
        if 'table' in cap_cls:
            # 表格（Springer 页面不含表格数据，仅保留标题；正文渲染时注明）
            out.append({'type': 'table', 'caption': clean_text(cap.get_text(' ')) if cap else '', 'rows': []})
            return out
        # 图
        img = el.find('img')
        src = img.get('src') if img else None
        if src and src.startswith('//'):
            src = 'https:' + src
        cap_txt = ''
        if cap:
            cap_txt = clean_text(cap.get_text(' '))
        if desc:
            d = clean_text(''.join(inline(c, {}) for c in desc.children))
            if d:
                sep = '. ' if cap_txt and not cap_txt.endswith(('.', ':')) else ' '
                cap_txt = (cap_txt + sep + d).strip()
        if src:
            out.append({'type': 'figure', 'caption': cap_txt, 'src': src})
        return out
    if name == 'div' and 'c-article-section__figure-description' in cls:
        # 图注文字（可能在 <figure> 之外）；返回独立块，稍后合并到前一个 figure
        d = clean_text(''.join(inline(c, {}) for c in el.children))
        return [{'type': 'figdesc', 'text': d}] if d else []
    if name in ('div', 'section'):
        for c in el.children:
            out.extend(block_springer(c))
        return out
    return []



# ============================================================
# eLife（Scheller 2026）
# ============================================================
def extract_elife(soup, raw_html, base_dir=None, html_name=None):
    data = {}
    # 本地图文件（Chrome 保存时按出现顺序命名为 default.jpg, default(1).jpg, ...）
    fig_files = []
    if base_dir and html_name:
        fig_dir = os.path.join(base_dir, os.path.splitext(html_name)[0] + '_files')
        if os.path.isdir(fig_dir):
            def _fig_key(p):
                m = re.search(r'default(?:\((\d+)\))?\.', os.path.basename(p))
                return int(m.group(1)) if m and m.group(1) else 0
            fig_files = sorted(glob.glob(os.path.join(fig_dir, 'default*.jpg')), key=_fig_key)
    data['_fig_files'] = [os.path.basename(f) for f in fig_files]
    fig_counter = [0]
    meta = {m.get('name') or m.get('property'): m.get('content') for m in soup.find_all('meta') if m.get('content')}
    data['title'] = meta.get('dc.title')
    data['authors'] = [m.get('content') for m in soup.find_all('meta') if (m.get('name') or m.get('property')) == 'dc.contributor']
    doi = meta.get('dc.identifier') or ''
    if doi.lower().startswith('doi:'):
        doi = doi[4:]
    data['doi'] = doi
    data['journal'] = 'eLife'
    data['volume'] = ''
    data['issue'] = ''
    data['pages'] = ''
    data['published_date'] = meta.get('dc.date')
    data['keywords'] = []
    abs_sec = soup.find('section', id='abstract')
    data['abstract'] = clean_text(abs_sec.get_text(' ')) if abs_sec else ''
    data['abstract'] = re.sub(r'^Abstract\b\s*', '', data['abstract'])
    # 参考文献（id=bibN，N 即编号；去掉 PubMed/Google Scholar 链接）
    refs, refmap = [], {}
    for i, div in enumerate(soup.select('section#references div.reference'), 1):
        for ul in div.select('ul.reference__abstracts'):
            ul.decompose()
        refs.append(clean_text(div.get_text(' ')))
        refmap['bib' + str(i)] = i
    data['references'] = refs
    # 正文：顶层 article-section（跳过 assessment/UI 区块；references 之后只保留 info/data）
    data['body'] = []
    top_secs = [s for s in soup.find_all('section', class_='article-section')
                if not s.find_parent('section', class_='article-section')]
    for sec in top_secs:
        sid = sec.get('id') or ''
        cls = ' '.join(sec.get('class') or [])
        if 'visuallyhidden' in cls or sid in ('elife-assessment', 'abstract', 'copyright', 'metrics', 'share'):
            continue
        if sid == 'references':
            break
        data['body'].extend(block_elife(sec, refmap, fig_files, fig_counter))
    data['footnotes'] = []
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    return data


def block_elife(el, refmap, fig_files=(), fig_counter=None):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name in ('h2', 'h3', 'h4', 'h5') and 'article-section__header_text' in cls:
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'heading', 'level': int(name[1]), 'text': t})
        return out
    if name == 'p':
        if el.find_parent('figure') or el.find_parent('figcaption'):
            return []
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name == 'figure' and 'captioned-asset' in cls:
        # 优先本地文件（按出现顺序 default.jpg, default(1).jpg, ...），IIIF 远程链接兜底
        src = None
        idx = fig_counter[0] if fig_counter else 0
        if fig_counter is not None:
            fig_counter[0] += 1
        if idx < len(fig_files):
            src = os.path.basename(os.path.dirname(fig_files[idx])) + '/' + os.path.basename(fig_files[idx])
        if not src:
            link = el.select_one('a.captioned-asset__link')
            if link and link.get('href'):
                src = link['href']
        if not src:
            for s in el.select('picture source[srcset]'):
                if 'image/jpeg' in (s.get('type') or ''):
                    entries = [e.split()[0] for e in (s.get('srcset') or '').split(',') if e.strip()]
                    src = entries[-1] if entries else None
                    break
        if not src:
            img = el.find('img')
            src = img.get('src') if img else None
        cap = el.select_one('figcaption.captioned-asset__caption')
        cap_txt = clean_text(cap.get_text(' ')) if cap else ''
        cap_txt = re.sub(r'\s*[…·]?\s*see more\s*$', '', cap_txt, flags=re.I).strip()
        if src:
            out.append({'type': 'figure', 'caption': cap_txt, 'src': src})
        return out
    if name in ('section', 'div', 'header'):
        for c in el.children:
            out.extend(block_elife(c, refmap, fig_files, fig_counter))
        return out
    if name == 'a' and 'article-section__toggle' in cls:
        # eLife 主节标题的 h2 包在 <a class=article-section__toggle> 里
        for c in el.children:
            out.extend(block_elife(c, refmap, fig_files, fig_counter))
        return out
    return []


# ============================================================
# Wiley（Kirk）
# ============================================================
def extract_wiley(soup, raw_html):
    data = {}
    doi = None
    m = re.search(r'10\.\d{4,9}/[a-zA-Z0-9.\-]+', raw_html)
    if m:
        doi = m.group(0).rstrip('.')
    ov = METADATA_OVERRIDES.get(doi, {}) if doi else {}
    # 页面 citation_* meta 作为缺省源（2026-08-30：Zhang2024_PsychJ 无 override 但 meta 齐全；
    # Kirk/Haciahmet 的 override 优先，Kirk 页面无 meta 故输出不变）
    meta = {m.get('name'): m.get('content') for m in soup.find_all('meta') if (m.get('name') or '').startswith('citation_')}
    data['title'] = ov.get('title') or meta.get('citation_title')
    data['authors'] = ov.get('authors') or [m.get('content') for m in soup.find_all('meta', attrs={'name': 'citation_author'}) if m.get('content')]
    data['affiliations'] = ov.get('affiliations') or list(dict.fromkeys(
        m.get('content') for m in soup.find_all('meta', attrs={'name': 'citation_author_institution'}) if m.get('content')))
    data['journal'] = ov.get('journal') or meta.get('citation_journal_title')
    data['volume'] = ov.get('volume') or meta.get('citation_volume')
    data['issue'] = ov.get('issue') or meta.get('citation_issue')
    p1, p2 = meta.get('citation_firstpage'), meta.get('citation_lastpage')
    data['pages'] = ov.get('pages') or (f'{p1}-{p2}' if p1 and p2 else (p1 or None))
    data['published_date'] = ov.get('published_date') or norm_date(meta.get('citation_publication_date') or meta.get('citation_date'))
    data['doi'] = doi
    ab = soup.select_one('div.abstract-group p')
    data['abstract'] = clean_text(ab.get_text(' ')) if ab else ''
    data['keywords'] = [k.strip() for k in (meta.get('citation_keywords') or '').split(';') if k.strip()]
    # 参考文献（ul.rlist.separator > li[data-bib-id]）
    refs, refmap = [], {}
    for i, li in enumerate(soup.select('ul.rlist.separator > li[data-bib-id]'), 1):
        bid = li.get('data-bib-id')
        refmap[bid] = i
        refs.append(clean_text(li.get_text(' ')))
    data['references'] = refs
    # 正文
    data['body'] = []
    for sec in soup.select('section.article-section__content'):
        for el in sec.children:
            data['body'].extend(block_wiley(el, refmap))
    # 脚注
    fns = soup.select('li.footNotePopup__item')
    data['footnotes'] = [clean_text(fn.get_text(' ')) for fn in fns if fn.get_text(' ').strip()]
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    return data


def block_wiley(el, refmap):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name == 'p':
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name in ('h2', 'h3', 'h4', 'h5') and 'article-section__' in cls:
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'heading', 'level': int(name[1]), 'text': t})
        return out
    if name == 'figure' and 'figure' in cls:
        img = el.select_one('img.figure__image')
        ttl = el.select_one('.figure__title')
        cap = el.select_one('.figure__caption-text')
        cap_txt = ''
        if ttl:
            cap_txt = clean_text(ttl.get_text(' '))
        if cap:
            c = clean_text(cap.get_text(' '))
            cap_txt = (cap_txt + '. ' + c).strip() if cap_txt and c else cap_txt or c
        src = img.get('src') if img else None
        if src:
            out.append({'type': 'figure', 'caption': cap_txt, 'src': src})
        return out
    if name == 'table':
        cap = el.find_previous(['p', 'div'], class_=re.compile('caption', re.I))
        tbl = table_block(el, refmap)
        if cap:
            tbl['caption'] = clean_text(cap.get_text(' '))
        out.append(tbl)
        return out
    if name in ('div', 'section', 'span'):
        if 'paragraph-element' in cls:
            t = clean_text(''.join(inline(c, refmap) for c in el.children))
            if t:
                out.append({'type': 'paragraph', 'text': t})
            return out
        for c in el.children:
            out.extend(block_wiley(c, refmap))
        return out
    return []


# ============================================================
# MDPI（Feldborg_2021_IJERPH）
# ============================================================
def extract_mdpi(soup, raw_html):
    data = {}
    meta = {m.get('name'): m.get('content') for m in soup.find_all('meta') if (m.get('name') or '').startswith('citation_')}
    data['title'] = meta.get('citation_title')
    data['authors'] = [m.get('content') for m in soup.find_all('meta', attrs={'name': 'citation_author'}) if m.get('content')]
    data['affiliations'] = []
    data['journal'] = meta.get('citation_journal_title')
    data['volume'] = meta.get('citation_volume')
    data['issue'] = meta.get('citation_issue')
    p1, p2 = meta.get('citation_firstpage'), meta.get('citation_lastpage')
    data['pages'] = f'{p1}-{p2}' if p1 and p2 else None
    data['doi'] = meta.get('citation_doi')
    data['published_date'] = norm_date(meta.get('citation_publication_date') or meta.get('citation_online_date'))
    # 摘要（MDPI 无 citation_abstract，从页面 .html-abstract 取）
    ab = soup.select_one('.html-abstract')
    if ab:
        h = ab.find(['h2', 'h3'])
        if h:
            h.decompose()
        data['abstract'] = clean_text(ab.get_text(' '))
    else:
        data['abstract'] = ''
    data['keywords'] = []
    # 参考文献（section#html-references_list 内 ol.html-xx > li）
    refs = []
    refmap = {}
    ref_ol = soup.select_one('section#html-references_list ol.html-xx')
    if ref_ol:
        for i, li in enumerate(ref_ol.find_all('li', recursive=False), 1):
            aid = li.get('id')
            if aid:
                refmap[aid] = i
            refs.append(clean_text(li.get_text(' ')))
    data['references'] = refs
    # 正文（div.html-body 内顶层递归）
    data['body'] = []
    body_el = soup.select_one('div.html-body')
    if body_el:
        for el in body_el.children:
            data['body'].extend(block_mdpi(el, refmap))
    # 脚注/致谢等 html-notes 小节保留在正文中（heading + paragraph 形式）
    data['footnotes'] = []
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    return data


def block_mdpi(el, refmap):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name in ('h2', 'h3') and 'html-italic' in cls or (name in ('h2', 'h3') and 'html-' not in cls):
        t = clean_text(el.get_text(' '))
        # MDPI 编号如 "1. " / "2.1. " / "2.1.1. " → 用点号数定级别
        lvl = 2
        m = re.match(r'^([\d.]+)\s+', t)
        if m:
            lvl = min(2 + m.group(1).strip('.').count('.'), 6)
            t = re.sub(r'^[\d.]+\s*', '', t)
        if t:
            out.append({'type': 'heading', 'level': lvl, 'text': t})
        return out
    if name == 'div' and 'html-p' in cls:
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name == 'div' and 'html-caption' in cls:
        # 图注（紧邻的 img 在前一个 figure 中，或独立成块）
        t = clean_text(el.get_text(' '))
        if t:
            if re.match(r'^\s*Table\b', t, re.I):
                out.append({'type': 'figdesc', 'text': t})
            else:
                out.append({'type': 'figdesc', 'text': t})
        return out
    if name == 'img' and el.get('src'):
        out.append({'type': 'figure', 'caption': '', 'src': el['src']})
        return out
    if name == 'div' and 'html-table_show' in cls:
        tbl = el.find('table')
        if tbl:
            cap = el.select_one('.html-caption')
            t = table_block(tbl, refmap)
            t['caption'] = clean_text(cap.get_text(' ')) if cap else ''
            out.append(t)
        return out
    if name in ('div', 'section'):
        if 'html-notes' in cls:
            # 致谢/资助/声明等：标题 + 段落
            h = el.find(['h2', 'h3'])
            if h:
                ht = clean_text(h.get_text(' '))
                if ht:
                    out.append({'type': 'heading', 'level': 2, 'text': ht})
            for p in el.find_all('div', class_='html-p'):
                t = clean_text(''.join(inline(c, refmap) for c in p.children))
                if t:
                    out.append({'type': 'paragraph', 'text': t})
            return out
        for c in el.children:
            out.extend(block_mdpi(c, refmap))
        return out
    return []


# ============================================================
# UC Press / Collabra（Hu_2020_CollabraPsy）
# ============================================================
def extract_collabra(soup, raw_html):
    data = {}
    meta = {m.get('name'): m.get('content') for m in soup.find_all('meta') if (m.get('name') or '').startswith('citation_')}
    data['title'] = meta.get('citation_title')
    data['authors'] = []
    for m in soup.find_all('meta', attrs={'name': 'citation_author'}):
        nm = (m.get('content') or '').strip()
        if nm and nm not in data['authors']:
            data['authors'].append(nm)
    data['affiliations'] = []
    data['journal'] = meta.get('citation_journal_title')
    data['volume'] = meta.get('citation_volume')
    data['issue'] = meta.get('citation_issue')
    data['pages'] = None
    data['doi'] = meta.get('citation_doi')
    data['published_date'] = norm_date(meta.get('citation_publication_date'))
    ab = soup.select_one('section.abstract')
    data['abstract'] = clean_text(ab.get_text(' ')) if ab else ''
    data['keywords'] = []
    # 参考文献（ref-list > .ref > .ref-body）
    refs = []
    for r in soup.select('.ref-list .ref .ref-body'):
        t = clean_text(r.get_text(' '))
        if t:
            refs.append(t)
    data['references'] = refs
    # 正文：article-body 内顶层递归（section-title h2 前置于其后的 content wrapper）
    data['body'] = []
    body_el = soup.select_one('div.article-body')
    if body_el:
        for el in body_el.children:
            data['body'].extend(block_collabra(el, {}))
    data['footnotes'] = []
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    return data


def block_collabra(el, refmap):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name == 'h2' and 'section-title' in cls:
        t = clean_text(el.get('data-section-title') or el.get_text(' '))
        if t:
            out.append({'type': 'heading', 'level': 2, 'text': t})
        return out
    if name == 'div' and 'article-section-wrapper' in cls:
        for c in el.children:
            out.extend(block_collabra(c, refmap))
        return out
    if name == 'section' and 'abstract' in cls:
        t = clean_text(el.get_text(' '))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name == 'p':
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name == 'div' and 'fig' in cls:
        # 图：fig-label + graphic-wrap img
        lab = el.select_one('.fig-label')
        cap = clean_text(lab.get_text(' ')) if lab else ''
        img = el.select_one('.graphic-wrap img')
        src = img.get('src') if img else None
        if src:
            out.append({'type': 'figure', 'caption': cap, 'src': src})
        elif cap:
            out.append({'type': 'figdesc', 'text': cap})
        return out
    if name == 'div' and 'table-wrap' in cls:
        cap = el.select_one('.table-wrap-title')
        tbl = el.find('table')
        if tbl:
            t = table_block(tbl, refmap)
            t['caption'] = clean_text(cap.get_text(' ')) if cap else ''
            out.append(t)
        return out
    if name in ('div', 'section'):
        for c in el.children:
            out.extend(block_collabra(c, refmap))
        return out
    return []


# ============================================================
# SAGE（Svensson_2023_QJEP）
# ============================================================
def extract_sage(soup, raw_html):
    data = {}
    doi = None
    m = re.search(r'10\.\d{4,9}/[a-zA-Z0-9.\-]+', raw_html)
    if m:
        doi = m.group(0).rstrip('.')
    ov = METADATA_OVERRIDES.get(doi, {}) if doi else {}
    data['title'] = ov.get('title') or (soup.find('h1').get_text(' ').strip() if soup.find('h1') else '')
    data['authors'] = ov.get('authors', [])
    data['affiliations'] = []
    data['journal'] = ov.get('journal')
    data['volume'] = ov.get('volume')
    data['issue'] = ov.get('issue')
    data['pages'] = ov.get('pages')
    data['published_date'] = ov.get('published_date')
    data['doi'] = doi
    ab = soup.select_one('section[data-type="abstract"]')
    data['abstract'] = clean_text(ab.get_text(' ')) if ab else ''
    data['keywords'] = []
    # 参考文献（div.biblioentry > .citation-content）
    refs = []
    for b in soup.select('div.biblioentry'):
        c = b.select_one('.citation-content')
        t = clean_text(c.get_text(' ')) if c else ''
        if t:
            refs.append(t)
    data['references'] = refs
    # 正文（article 内顶层 section，跳过 teaser 推荐区块）
    data['body'] = []
    art = soup.find('article')
    scope = art if art else soup
    for sec in scope.find_all('section', recursive=True):
        if sec.find_parent('section') is not None:
            continue  # 只取顶层 section，避免嵌套重复
        sid = sec.get('id') or ''
        if 'teaser' in ' '.join(sec.get('class') or []) or sid.startswith('tab-'):
            continue
        for el in sec.children:
            data['body'].extend(block_sage(el, {}))
    data['footnotes'] = []
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    return data


def block_sage(el, refmap):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name in ('h1', 'h2', 'h3', 'h4'):
        t = clean_text(el.get_text(' '))
        if t:
            lvl = {'h1': 1, 'h2': 2, 'h3': 3, 'h4': 4}[name]
            out.append({'type': 'heading', 'level': lvl, 'text': t})
        return out
    if name == 'div' and 'paragraph' in (el.get('role') or ''):
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name == 'figure':
        is_table = 'table' in cls
        if is_table:
            tbl = el.find('table')
            cap = el.find('figcaption')
            if tbl:
                t = table_block(tbl, refmap)
                t['caption'] = clean_text(cap.get_text(' ')) if cap else ''
                out.append(t)
            return out
        img = el.find('img')
        cap = el.find('figcaption')
        src = img.get('src') if img else None
        cap_txt = clean_text(cap.get_text(' ')) if cap else ''
        if src:
            out.append({'type': 'figure', 'caption': cap_txt, 'src': src})
        elif cap_txt:
            out.append({'type': 'figdesc', 'text': cap_txt})
        return out
    if name in ('div', 'section', 'p'):
        for c in el.children:
            out.extend(block_sage(c, refmap))
        return out
    return []


# ============================================================
# PLOS（Wozniak_2018_PLOS）
# ============================================================
def extract_plos(soup, raw_html):
    data = {}
    meta = {m.get('name'): m.get('content') for m in soup.find_all('meta') if (m.get('name') or '').startswith('citation_')}
    data['title'] = meta.get('citation_title')
    data['authors'] = [m.get('content') for m in soup.find_all('meta', attrs={'name': 'citation_author'}) if m.get('content')]
    data['affiliations'] = []
    data['journal'] = meta.get('citation_journal_title')
    data['volume'] = meta.get('citation_volume')
    data['issue'] = meta.get('citation_issue')
    p1, p2 = meta.get('citation_firstpage'), meta.get('citation_lastpage')
    data['pages'] = f'{p1}-{p2}' if p1 and p2 else None
    data['doi'] = meta.get('citation_doi')
    data['published_date'] = norm_date(meta.get('citation_date') or meta.get('citation_publication_date'))
    data['abstract'] = meta.get('citation_abstract') or ''
    data['keywords'] = []
    # 参考文献（ol.references）
    refs = []
    ref_ol = soup.select_one('ol.references')
    if ref_ol:
        for li in ref_ol.find_all('li', recursive=False):
            t = clean_text(li.get_text(' '))
            if t:
                refs.append(t)
    data['references'] = refs
    # 正文（div.section.toc-section，跳过 id=references 等元区块）
    data['body'] = []
    for sec in soup.select('div.section.toc-section'):
        sid = sec.get('id') or ''
        if sid in ('references',) or 'subjInfo' in sid:
            continue
        for el in sec.children:
            data['body'].extend(block_plos(el, {}))
    data['footnotes'] = []
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    return data


def block_plos(el, refmap):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name in ('h2', 'h3', 'h4', 'h5'):
        t = clean_text(el.get_text(' '))
        if t:
            lvl = {'h2': 2, 'h3': 3, 'h4': 4, 'h5': 5}[name]
            out.append({'type': 'heading', 'level': lvl, 'text': t})
        return out
    if name == 'p':
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t and 'caption_' not in cls:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name == 'div' and 'figure' in cls:
        img = el.select_one('.img-box img')
        cap = el.select_one('.figcaption')
        src = img.get('src') if img else None
        cap_txt = clean_text(cap.get_text(' ')) if cap else ''
        if src:
            out.append({'type': 'figure', 'caption': cap_txt, 'src': src})
        elif cap_txt:
            out.append({'type': 'figdesc', 'text': cap_txt})
        return out
    if name == 'div' and 'table' in cls and 'toc' not in cls:
        tbl = el.find('table')
        if tbl:
            cap = el.select_one('.caption') or el.find('caption')
            t = table_block(tbl, refmap)
            t['caption'] = clean_text(cap.get_text(' ')) if cap else ''
            out.append(t)
        return out
    if name in ('div', 'section'):
        for c in el.children:
            out.extend(block_plos(c, refmap))
        return out
    return []


# ============================================================
# PeerJ（Vicovaro2024PeerJ，JATS 风格，2026-08-30 新增）
#   页面特征：peerj.com 域名 + article-item-section-content
#   元数据取 citation_* meta；正文 main > div > div.row-article-item-section
#   > div.article-item-section-content > div > section/div.sec；
#   行内引用 a.xref-bibr 的 href 为外部 DOI URL，inline() 兜底分支保留作者-年份文字；
#   脚注仅取正文区外的 div.fn.article-footnote（fn-group 内的 div.fn 属声明区块，留正文）
# ============================================================
def extract_peerj(soup, raw_html):
    data = {}
    meta = {m.get('name'): m.get('content') for m in soup.find_all('meta') if (m.get('name') or '').startswith('citation_')}
    data['title'] = meta.get('citation_title')
    data['authors'] = [m.get('content') for m in soup.find_all('meta', attrs={'name': 'citation_author'}) if m.get('content')]
    data['affiliations'] = [m.get('content') for m in soup.find_all('meta', attrs={'name': 'citation_author_institution'}) if m.get('content')]
    data['journal'] = meta.get('citation_journal_title')
    data['volume'] = meta.get('citation_volume')
    data['issue'] = meta.get('citation_issue') or ''
    data['pages'] = meta.get('citation_firstpage')
    data['doi'] = meta.get('citation_doi')
    data['published_date'] = norm_date(meta.get('citation_date'))
    ab = soup.select_one('div.abstract')
    data['abstract'] = clean_text(ab.get_text(' ')) if ab else ''
    data['keywords'] = [k.strip() for k in (meta.get('citation_keywords') or '').split(';') if k.strip()]
    # 参考文献（ul.ref-list > li.ref）
    refs = []
    for li in soup.select('ul.ref-list > li.ref'):
        t = clean_text(li.get_text(' '))
        if t:
            refs.append(t)
    data['references'] = refs
    # 正文
    data['body'] = []
    content = soup.select_one('main div.row-article-item-section div.article-item-section-content')
    if content is not None:
        div0 = content.find('div', recursive=False)
        if div0 is not None:
            for sec in div0.find_all(['section', 'div'], class_='sec', recursive=False):
                for el in sec.children:
                    data['body'].extend(block_peerj(el, {}))
    # 脚注（仅正文区外的 article-footnote；fn-group 内的 div.fn 已随声明区块入正文）
    fns = soup.select('div.fn.article-footnote')
    data['footnotes'] = [clean_text(fn.get_text(' ')) for fn in fns if fn.get_text(' ').strip()]
    data['acknowledgements'] = ''
    data['correspondence'] = ''
    return data


def block_peerj(el, refmap):
    if not getattr(el, 'name', None):
        return []
    name = el.name
    cls = ' '.join(el.get('class') or [])
    out = []
    if name in ('h2', 'h3', 'h4', 'h5') and 'heading' in cls:
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'heading', 'level': int(name[1]), 'text': t})
        return out
    if name == 'p':
        t = clean_text(''.join(inline(c, refmap) for c in el.children))
        if t:
            out.append({'type': 'paragraph', 'text': t})
        return out
    if name == 'figure' and 'fig' in cls:
        img = el.select_one('img')
        src = img.get('src') if img else None
        cap = el.select_one('figcaption')
        cap_txt = clean_text(cap.get_text(' ')) if cap else ''
        if src:
            out.append({'type': 'figure', 'caption': cap_txt, 'src': src})
        elif cap_txt:
            out.append({'type': 'figdesc', 'text': cap_txt})
        return out
    if name == 'figure' and 'table-wrap' in cls:
        cap = el.select_one('div.caption')
        tbl = el.find('table')
        if tbl:
            t = table_block(tbl, refmap)
            t['caption'] = clean_text(cap.get_text(' ')) if cap else ''
            out.append(t)
        return out
    if name in ('div', 'section', 'span'):
        for c in el.children:
            out.extend(block_peerj(c, refmap))
        return out
    return []


# ============================================================
# 主入口：单个 HTML → JSON（模板原结构 + 学术结构增强）
# ============================================================
def process_html_file(html_path: str):
    """
    处理单个HTML文件：
    1. 读取内容
    2. 提取所有图片的相对路径（保持原样）
    3. 用 shadow-web 清洗并提取结构化数据
    4. 用 BeautifulSoup 按出版商模板提取学术结构（标题/作者/正文/图表/参考文献）
    5. 将图片列表和基准目录合并到数据中
    6. 保存为同名的JSON文件
    """
    try:
        with open(html_path, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except Exception as e:
        print(f"❌ 读取 {html_path} 失败：{e}")
        return

    # 1. 用 BeautifulSoup 提取图片信息（不修改原HTML）
    soup = BeautifulSoup(html_content, 'html.parser')
    img_urls = []
    for img in soup.find_all('img'):
        src = img.get('src')
        if src:
            img_urls.append(src)   # 保留原始相对路径

    # 记录HTML所在目录，用于后续路径解析
    base_dir = os.path.dirname(os.path.abspath(html_path))

    # 2. 使用 shadow-web 处理（已安装）
    try:
        clean_html, actions, groups = process_html(html_content)
        page_data = parse_page(clean_html)
    except Exception as e:
        print(f"❌ shadow-web 处理 {html_path} 失败：{e}")
        page_data = {}

    # 3. 按出版商模板提取学术结构（bs4，已安装）
    name = os.path.basename(html_path)
    try:
        if 'c-article-body' in html_content:
            data = extract_springer(soup, html_content)
        elif 'article-section__content' in html_content:
            data = extract_wiley(soup, html_content)
        elif 'captioned-asset' in html_content and 'reference__authors_list' in html_content:
            data = extract_elife(soup, html_content, base_dir, name)
        elif 'id="body"' in html_content or 'class="Body' in html_content:
            data = extract_elsevier(soup, html_content)
        elif 'html-bibr' in html_content or 'html-p' in html_content:
            data = extract_mdpi(soup, html_content)
        elif 'article-section-wrapper' in html_content:
            data = extract_collabra(soup, html_content)
        elif 'biblioentry' in html_content:
            data = extract_sage(soup, html_content)
        elif 'ref-tip' in html_content or 'toc-section' in html_content:
            data = extract_plos(soup, html_content)
        elif 'peerj.com' in html_content and 'article-item-section-content' in html_content:
            data = extract_peerj(soup, html_content)
        else:
            data = {}
            print(f"⚠️ 未能识别的页面模板：{name}（仅保留基础字段）")
    except Exception as e:
        data = {}
        print(f"❌ 学术结构提取 {name} 失败：{e}")

    # 4. 合并基础字段
    data['source_html'] = name
    data['_base_dir'] = base_dir          # 基准目录（绝对路径）
    data['_images'] = img_urls            # 原始图片相对路径列表
    data['_shadow_web'] = page_data       # shadow-web 通用解析结果（备用）

    # 5. 保存为 JSON（同名，放在同一文件夹）
    json_path = os.path.splitext(html_path)[0] + '.json'
    try:
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"❌ 保存 JSON 失败：{json_path}，错误：{e}")
        return
    # 6. 紧凑摘要（验收用，避免打开文件）
    body = data.get('body') or []
    kinds = {}
    for b in body:
        kinds[b.get('type')] = kinds.get(b.get('type'), 0) + 1
    summary = ' | '.join(f'{k}{v}' for k, v in kinds.items()) if kinds else '空'
    figs = sum(1 for b in body if b.get('type') == 'figure' and b.get('src'))
    img_missing = [b['src'] for b in body if b.get('type') == 'figure' and b.get('src')
                   and not b['src'].startswith('http') and not os.path.exists(os.path.join(base_dir, b['src']))]
    warn = f' | ⚠️缺本地图: {img_missing}' if img_missing else ''
    authors = ', '.join((data.get('authors') or [])[:3])
    if len((data.get('authors') or [])) > 3:
        authors += ' 等'
    print(f"✅ {os.path.basename(html_path)} → {os.path.basename(json_path)}")
    print(f"   标题: {(data.get('title') or '?')[:80]}")
    print(f"   作者: {authors or '?'} | DOI: {data.get('doi') or '?'} | 卷/期/页: {data.get('volume') or '?'}/{data.get('issue') or '?'}/{data.get('pages') or '?'}")
    print(f"   body: {summary} | 图: {figs} | 参考文献: {len(data.get('references') or [])} | 脚注: {len(data.get('footnotes') or [])}{warn}")


def main():
    import sys
    force = '--force' in sys.argv
    # 获取脚本所在目录（或当前工作目录）
    folder = os.getcwd()
    print(f"📂 扫描目录：{folder}")

    # 遍历所有 .html 和 .htm 文件
    html_files = [f for f in os.listdir(folder)
                  if f.lower().endswith(('.html', '.htm'))]
    # 默认跳过已转换为 md 的文件（如 Wang_2016_JEPHPP，其页面模板未适配）；--force 全部重处理
    if not force:
        html_files = [f for f in html_files if not os.path.exists(os.path.splitext(f)[0] + '.md')]
    if not html_files:
        print("⚠️ 未找到任何待处理的 HTML 文件。")
        return

    print(f"📄 找到 {len(html_files)} 个 HTML 文件，开始处理...\n")
    for filename in html_files:
        html_path = os.path.join(folder, filename)
        process_html_file(html_path)

    print("\n🎉 全部处理完成！")


if __name__ == '__main__':
    main()
