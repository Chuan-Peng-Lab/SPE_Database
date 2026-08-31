# REF/ HTML → MD 转换管线使用说明

两个脚本把 `REF/` 下的期刊全文 HTML 批量转换为结构化 JSON，再渲染为 Markdown（规则遵循
`html2md_PROMPT.md`）：

- `html2Json.py`：HTML → 同名 `.json`（统一学术结构 + shadow_web 通用解析备份）
- `json2md.py`：JSON → 同名 `.md`（YAML frontmatter + 正文 + 图 + 表 + 参考文献 + 脚注）

另有 `pdf2md.py`：仅 PDF 全文的论文 → 同名 `.md`（pymupdf 词级提取 + 字号/加粗标题启发式 +
双栏自动检测；**跳过已有 md 的 PDF**，html 版优先）。注意 PDF 版 md 是"可用但非完美"：
双栏排版（APA 期刊）可能有行级交错，标题层级为启发式近似；单栏 PDF（psyarxiv/SAGE）质量优秀。

已适配模板：**Springer**（`c-article-body`）、**Elsevier 新旧版**（`div#body`）、**Wiley**
（`article-section__content`）、**eLife**（`captioned-asset` + `reference__authors_list`，
2026-08-28 新增：元数据取 `dc.*` meta、图取 IIIF 大图链接、跳过 assessment/下载链接/版权等 UI 区块）、
**MDPI**（`html-bibr`/`html-p`，2026-08-28 新增）、**UC Press/Collabra**（`article-section-wrapper`，
2026-08-28 新增）、**SAGE**（`biblioentry`，2026-08-28 新增，页面 meta 不全时用 METADATA_OVERRIDES）、
**PLOS**（`ref-tip`/`toc-section`，2026-08-28 新增）、**PeerJ**（`peerj.com` + `article-item-section-content`，
2026-08-30 新增，元数据取 citation_* meta，正文取 main 内 `section/div.sec`，行内引用 `a.xref-bibr`
由 inline() 兜底保留作者-年份文字）。**nature.com / Scientific Data**（2026-08-31 首例 Qi_2025_SciData：
命中现有 Springer 模板——`c-article-body` 为 Springer Nature 共用框架，JSON-LD 元数据齐全，
无需新模板）。Wiley 模板 2026-08-30 起在无 METADATA_OVERRIDES 时回退读页面
citation_* meta（Kirk/Haciahmet 的 override 仍优先）。
PsycNet（Wang_2016_JEPHPP）未适配——其 md 为人工转换，勿用本管线覆盖。

## 最快流程（新 HTML 进来时）

```bash
cd REF
python3 html2Json.py        # 1. 只处理尚无 .md 的 html（新文件自动识别模板）
python3 json2md.py          # 2. 渲染为新 md
```

两条命令跑完即完成。**验收只看脚本打印的摘要**，不要读 HTML/JSON 全文（省 token）：

```
✅ Sui_2014_APP.html → Sui_2014_APP.json
   标题: The automatic and the expected self: ...
   作者: Jie Sui, ... | DOI: 10.3758/s13414-014-0631-5 | 卷/期/页: 76/4/1176-1184
   body: heading10 | paragraph44 | table2 | figure2 | 图: 2 | 参考文献: 27 | 脚注: 1
```

验收清单（全部满足即视为成功）：
1. 标题/作者/DOI/卷期页非 `?`；
2. body 摘要含 `heading`+`paragraph`（有正文字数），图/表/参考文献数量与论文大致相符；
3. 无 `⚠️缺本地图`（Springer 走 CDN 的 http 链接除外，属正常）；
4. json2md 输出 `refs=N` 与 html2Json 摘要一致。

抽查（可选，低 token 方式）：
```bash
grep -c '^\[[0-9]*\] ' REF/xxx.md        # 参考文献条数
sed -n '1,20p' REF/xxx.md                # 只看 frontmatter + Abstract
grep -n '^## \|^### ' REF/xxx.md | head  # 只看章节结构
```

## 常用参数

| 命令 | 行为 |
|---|---|
| `python3 html2Json.py` | 默认：跳过已有 `.md` 的 html（保护已转换文件；Wang 不会被碰） |
| `python3 html2Json.py --force` | 全部重处理（含 Wang → 会生成空 json，json2md 会自动跳过，事后可删） |
| `python3 json2md.py` | 默认：跳过已有 `.md` 的 json |
| `python3 json2md.py --force` | 全部重渲染 |

日常流程**不要**用 `--force`；仅在改了提取逻辑需要重跑时用，且跑完 `rm -f Wang_2016_JEPHPP.json`。

## 新出版商模板适配（很少发生）

1. 在 `process_html_file` 的 `if/elif` 分支中加一行识别（用页面独有特征字符串，如
   `'c-article-body' in html_content`）；
2. 写一个 `extract_xxx(soup, raw_html)` 函数，输出**统一 JSON schema**：

```jsonc
{
  "title": "", "authors": [""], "affiliations": [""], "abstract": "",
  "keywords": [""], "doi": "", "journal": "", "volume": "", "issue": "",
  "pages": "", "published_date": "",
  "body": [                       // 按阅读顺序
    {"type": "heading", "level": 2, "text": ""},
    {"type": "paragraph", "text": ""},        // 行内已含 *斜体*、[n] 引用、^上标^、\\(...\\) 公式
    {"type": "figure", "caption": "", "src": ""},
    {"type": "table", "caption": "", "rows": [["列", "列"], ["值", "值"]]}
  ],
  "references": [""], "footnotes": [""],
  "acknowledgements": "", "correspondence": "",
  "source_html": "", "_base_dir": "", "_images": [], "_shadow_web": {}
}
```

3. 行内转换复用 `inline(el, refmap)`：只需在 `a` 分支补你模板的引用链接规则
   （如 `#bibN` → `[n]`），`em/sup/strong/math` 等已通用；
4. 跑 `python3 html2Json.py --force && python3 json2md.py --force`，按上面验收清单核对。

## 已知边界（勿当新问题报告）

- **PDF 版 md**：6 个无 html 的正文 PDF（Constable_2019/2021、Navon、Qian、Schaefer、Vicovaro）
  的 md 现为 `*_DS.md`（**DeepSeek 在线对话生成**，2026-08-28 对比后质量全面优于 pdf2md.py 原版，
  原版已删）；`pdf2md.py`（pymupdf 词级提取 + 字号/加粗标题启发式 + 双栏检测）**保留备用**——
  已知局限：标题/作者区可能被加粗误判为标题、APA 双栏页有行级交错、结果表格文本可能重复。
  全文可读可检索，但精度低于 html 版。**html 存在时永远优先 html（pdf2md 自动跳过已有 md）。**
- **Elsevier 复杂表格**：rowspan/colspan 按行展平，表头可能错位，但数据完整；
- **Springer 表格**：页面不含表格数据（独立链接提供），md 中只保留标题 + `> **表注：**` 说明；
- **Orellana 图片**：2026-08-28 用户重新保存页面后已本地化（`Orellana-Corrales_2021_APP_files/13414_2021_2367_Fig*.png`）；
- **Kirk 元数据**：页头缺失，作者/期刊/卷期页取自脚本内 `METADATA_OVERRIDES`（Crossref 核对过）；
- **eLife**：图注尾部折叠按钮文本（“see more”）已去除；无本地图片目录时图用 IIIF 远程 URL（正常）；
  主节标题的 h2 包在 `a.article-section__toggle` 内（脚本已处理）；
- **eLife 图片**：图按出现顺序映射到本地 `_files/default.jpg, default(1).jpg, ...`（Chrome 保存命名）；
  本地不足时（懒加载未缓存）脚本自动退回 IIIF 远程 URL 兜底，可手动下载补齐；
  json2md 渲染时对含括号的文件名自动转义（`default(1).jpg` → `default%281%29.jpg`），否则 `)` 会截断 Markdown 链接；
- **Wang_2016_JEPHPP**：PsycNet 模板未适配，md 为人工转换，勿用本管线处理。

## 省 token 要点（给后续 agent）

1. **绝不整读** html / json / md 文件进上下文——以脚本摘要 + `grep`/`sed` 抽查为准；
2. 转换本身不消耗模型 token（脚本离线运行）；模型的 token 只花在摘要解读与抽查；
3. 一次会话内多个 html 一起转（脚本本身就是批量），不要逐个转逐个看；
4. 提取逻辑有改动时，先 `--force` 重跑看摘要 diff，再决定是否抽查正文；
5. 本说明已沉淀于 PROJ_STATE.md（"REF/ 全文 HTML → MD 批量转换管线"条目）。
