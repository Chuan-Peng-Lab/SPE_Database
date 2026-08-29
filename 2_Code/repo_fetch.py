#!/usr/bin/env python3
"""repo_fetch.py — 数据仓库下载辅助（OSF / PsychArchives）— 2026-08 阶段 4 工具

用途：阶段 4 raw 追补时，先从数据仓库列出文件清单（名称 + 大小），再下载
到本地（/tmp 或目标研究文件夹的 *_Raw/ 输入区）。P5（Schaefer Exp2）沉淀：
先 --list 看仓库文件清单再决定下载，可发现重复上传/缺失（如 psycharchives
group1=group2 重复、Exp2 无仓库版），避免白下载。

纪律（AGENTS.md §防坑）：
  * 目标文件已存在时拒绝覆盖（报错退出，不静默覆盖）
  * 建议先 --list 看清单，再 --get/--pa-get 精确下载
  * 下载后核对大小与（可选）MD5

子命令：
  osf-list <node_guid>            列出 OSF 项目全部文件（递归，含文件夹）
  osf-get <node_guid> <substr>    按文件名子串匹配并下载（--out 指定目录，
                                  默认当前目录；--md5 打印 MD5）
  pa-search <query>               搜索 PsychArchives 条目（DOI/关键词）
  pa-files <item_uuid>            列出条目 bitstreams（名称 + 大小）
  pa-get <bitstream_uuid>         下载 bitstream（--out 指定目录，默认当前目录）

示例：
  python3 2_Code/repo_fetch.py osf-list 4n6j7
  python3 2_Code/repo_fetch.py osf-get 4n6j7 "raw" --out /tmp
  python3 2_Code/repo_fetch.py pa-search "10.23668/psycharchives.2642"
  python3 2_Code/repo_fetch.py pa-files 33ba6307-4828-4ca9-9132-f7f776f06462
  python3 2_Code/repo_fetch.py pa-get 2773c56d-4456-4826-9375-032ddb58191e --out /tmp
"""
import argparse
import hashlib
import json
import os
import sys
import urllib.request
import urllib.parse

PA_BASE = "https://www.psycharchives.org/rest"
OSF_BASE = "https://api.osf.io/v2"


def http_get_json(url):
    with urllib.request.urlopen(url, timeout=60) as resp:
        return json.load(resp)


def download(url, out_path):
    if os.path.exists(out_path):
        sys.exit(f"[repo_fetch] 目标已存在，拒绝覆盖: {out_path}（请先确认或改 --out）")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=600) as resp:
        data = resp.read()
    tmp = out_path + ".part"
    with open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, out_path)
    print(f"[repo_fetch] saved {out_path} ({len(data)} bytes)")
    return data


def cmd_osf_list(node):
    """递归列出 OSF 项目 osfstorage 文件。"""
    def walk(folder_id, prefix=""):
        url = f"{OSF_BASE}/nodes/{node}/files/osfstorage/"
        if folder_id:
            url += folder_id + "/"
        d = http_get_json(url)
        for item in d.get("data", []):
            name = item["attributes"]["name"]
            kind = item["attributes"].get("kind", "file")
            full = os.path.join(prefix, name)
            if kind == "folder":
                print(f"[dir ] {full}/")
                walk(item["id"], full)
            else:
                size = item["attributes"].get("size", "?")
                fid = item["id"]
                print(f"[file] {full}  ({size} bytes)  id={fid}")
    walk(None)


def cmd_osf_get(node, substr, out_dir):
    """按文件名子串匹配下载（只匹配顶层与递归层文件名）。"""
    hits = []

    def walk(folder_id, prefix=""):
        url = f"{OSF_BASE}/nodes/{node}/files/osfstorage/"
        if folder_id:
            url += folder_id + "/"
        d = http_get_json(url)
        for item in d.get("data", []):
            name = item["attributes"]["name"]
            kind = item["attributes"].get("kind", "file")
            if kind == "folder":
                walk(item["id"], os.path.join(prefix, name))
            elif substr.lower() in name.lower():
                hits.append((os.path.join(prefix, name), item["id"]))
    walk(None)
    if not hits:
        sys.exit(f"[repo_fetch] OSF 项目 {node} 无文件名含 {substr!r} 的文件")
    for full, fid in hits:
        print(f"[repo_fetch] 下载 {full} ...")
        url = f"{OSF_BASE}/files/{fid}/download"
        out_path = os.path.join(out_dir, os.path.basename(full))
        data = download(url, out_path)
        if args.md5:
            print(f"  md5={hashlib.md5(data).hexdigest()}")


def cmd_pa_search(query):
    d = http_get_json(f"{PA_BASE}/items?search={urllib.parse.quote(query)}")
    for it in d:
        print(f"{it['uuid']}  {it.get('name','')}  handle={it.get('handle','')}")


def cmd_pa_files(uuid):
    d = http_get_json(f"{PA_BASE}/items/{uuid}/bitstreams")
    for b in d:
        print(f"{b['name']}  ({b.get('sizeBytes','?')} bytes)  id={b['uuid']}")


def cmd_pa_get(uuid, out_dir):
    url = f"{PA_BASE}/bitstreams/{uuid}/retrieve"
    # 先查名称（bitstream 元数据端点）
    try:
        meta = http_get_json(f"{PA_BASE}/bitstreams/{uuid}")
        name = meta.get("name", f"{uuid}.bin")
    except Exception:
        name = f"{uuid}.bin"
    out_path = os.path.join(out_dir, name)
    data = download(url, out_path)
    if args.md5:
        print(f"  md5={hashlib.md5(data).hexdigest()}")


def main():
    global args
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    p1 = sub.add_parser("osf-list"); p1.add_argument("node")
    p2 = sub.add_parser("osf-get"); p2.add_argument("node"); p2.add_argument("substr")
    p3 = sub.add_parser("pa-search"); p3.add_argument("query")
    p4 = sub.add_parser("pa-files"); p4.add_argument("uuid")
    p5 = sub.add_parser("pa-get"); p5.add_argument("uuid")
    for sp in (p2, p5):
        sp.add_argument("--out", default=".")
        sp.add_argument("--md5", action="store_true")
    args = p.parse_args()

    if args.cmd == "osf-list":
        cmd_osf_list(args.node)
    elif args.cmd == "osf-get":
        cmd_osf_get(args.node, args.substr, args.out)
    elif args.cmd == "pa-search":
        cmd_pa_search(args.query)
    elif args.cmd == "pa-files":
        cmd_pa_files(args.uuid)
    elif args.cmd == "pa-get":
        cmd_pa_get(args.uuid, args.out)


if __name__ == "__main__":
    main()
