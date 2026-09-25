#!/usr/bin/env python3
# =============================================================================
# split_clean_csv.py — 将单体过大的 *_Clean.csv 按「整被试」边界切分为分片
# -----------------------------------------------------------------------------
# 规则正文：.agents/skills/spe-database-curation/SKILL.md
#           §文件与文件夹规范「大文件拆分（单一 *_Clean.csv > 50 MB）」
#
#   <Folder_Name>_Exp<N>_Clean.csv  →  <...>_Clean_part1.csv, <...>_Clean_part2.csv, ...
#
# 保证：
#   1) 同一 Subject 的全部行落在同一分片（取数据中 Subject 的连续整段，保全全行序）；
#   2) 各分片表头与原件逐字节相同；各片数据行字节拼接 == 原件数据行字节（写前校验）；
#   3) 每片 ≤ --threshold（默认 50 MB 十进制 = 50,000,000 B），片数取满足条件的最小值；
#   4) 仍视为 1 个数据集：不新增 Dataset_inf.csv 行、不拆 subj_info/Codebook/exp JSON。
#
# 用法：
#   python3 2_Code/split_clean_csv.py <File>_Clean.csv            # 只报告拆分方案（不写盘）
#   python3 2_Code/split_clean_csv.py <File>_Clean.csv --apply    # 写盘并删除原件（先备份）
#   选项：--threshold 50000000  --backup-dir /tmp/xxx  --force（允许覆盖已存在的分片）
# =============================================================================
import argparse
import os
import shutil
import sys
import time
from datetime import datetime

DEFAULT_THRESHOLD = 50_000_000  # 50 MB（十进制），见 SKILL.md


def fail(msg):
    print(f"[ERROR] {msg}")
    sys.exit(1)


def detect_eol(raw):
    if b"\r\n" in raw[:4096]:
        return b"\r\n"
    if b"\n" in raw[:4096]:
        return b"\n"
    fail("找不到行结束符（既无 CRLF 也无 LF）")


def split_lines(raw, eol):
    """返回 (header_line, [data_line, ...], trailing_eol_present)"""
    trailing = raw.endswith(eol)
    body = raw[: -len(eol)] if trailing else raw
    lines = body.split(eol)
    return lines[0], lines[1:], trailing


def first_field(line):
    """取一行 CSV 的第一个字段（处理引号包裹）"""
    if line.startswith(b'"'):
        end = line.find(b'"', 1)
        while end != -1 and line[end + 1 : end + 2] == b'"':  # 转义的双引号
            end = line.find(b'"', end + 2)
        return line[1:end] if end != -1 else line
    return line.split(b",", 1)[0]


def subject_blocks(lines, eol):
    """把数据行切成 (subject, start, end) 的连续整段；同一 Subject 出现多段则报错"""
    blocks, seen = [], set()
    cur = None
    for i, line in enumerate(lines):
        s = first_field(line)
        if cur is None or s != cur[0]:
            if s in seen:
                fail(f"Subject {s.decode('utf-8', 'replace')} 在文件中不连续，无法保证整被试分片")
            if cur is not None:
                blocks.append((cur[0], cur[1], i))
            seen.add(s)
            cur = (s, i)
    if cur is not None:
        blocks.append((cur[0], cur[1], len(lines)))
    return blocks


def block_bytes(lines, blocks, eol):
    n = len(eol)
    return [(s, a, b, sum(len(lines[i]) + n for i in range(a, b))) for s, a, b in blocks]


def plan_parts(blocks, total_bytes, threshold):
    """按字节均衡切分为最小片数；返回 [(start_block_idx, end_block_idx_exclusive), ...]"""
    k = max(1, -(-total_bytes // threshold))  # ceil
    if any(b[3] > threshold for b in blocks):
        fail(f"存在单个被试的数据超过阈值 {threshold:,} B，无法按被试边界拆分，需人工处理")
    if k == 1:
        return None
    targets = [total_bytes * (j + 1) / k for j in range(k - 1)]
    parts, start, cum, j = [], 0, 0, 0
    for idx, (_, _, _, nb) in enumerate(blocks):
        cum += nb
        remaining = total_bytes - cum
        can_close = (
            j < k - 1
            and cum >= targets[j]
            and remaining <= (k - j - 1) * threshold
            and idx + 1 < len(blocks)
        )
        if can_close:
            parts.append((start, idx + 1))
            start, j = idx + 1, j + 1
    parts.append((start, len(blocks)))
    if len(parts) != k:
        fail(f"拆分规划失败（预期 {k} 片，实得 {len(parts)} 片）")
    return parts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("clean_csv")
    ap.add_argument("--threshold", type=int, default=DEFAULT_THRESHOLD)
    ap.add_argument("--apply", action="store_true", help="写盘并删除原件（先备份）")
    ap.add_argument("--backup-dir", default=None)
    ap.add_argument("--force", action="store_true", help="允许覆盖已存在的分片")
    a = ap.parse_args()

    path = a.clean_csv
    if not os.path.isfile(path):
        fail(f"文件不存在: {path}")
    if not os.path.basename(path).endswith("_Clean.csv"):
        fail(f"只处理 *_Clean.csv（分片本身不接受再拆分）: {os.path.basename(path)}")

    raw = open(path, "rb").read()
    size = len(raw)
    eol = detect_eol(raw)
    header, lines, trailing = split_lines(raw, eol)
    body_bytes = sum(len(x) + len(eol) for x in lines)
    blocks = block_bytes(lines, subject_blocks(lines, eol), eol)
    n_subj, n_rows = len(blocks), len(lines)

    print(f"文件      : {path}")
    print(f"大小      : {size:,} B ({size/1e6:.1f} MB) | 行数 {n_rows:,} | 被试 {n_subj} | "
          f"行尾 {'CRLF' if eol == b'\r\n' else 'LF'} | 末尾换行 {trailing}")
    if size <= a.threshold:
        print(f"[OK] ≤ 阈值 {a.threshold:,} B，无需拆分。")
        return

    parts = plan_parts(blocks, body_bytes, a.threshold)
    if parts is None:
        fail(f"数据行合计 {body_bytes:,} B ≤ 阈值，超出部分仅来自表头，无需拆分")
    out = []
    for pi, (bs, be) in enumerate(parts, 1):
        seg = lines[blocks[bs][1] : blocks[be - 1][2]]
        nbytes = len(header) + len(eol) + sum(len(x) + len(eol) for x in seg)
        nsub = be - bs
        out.append((pi, seg, nbytes, nsub))
        print(f"  计划 part{pi}: 被试 {nsub} | 行 {len(seg):,} | {nbytes:,} B ({nbytes/1e6:.1f} MB) "
              f"| Subject {blocks[bs][0].decode('utf-8','replace')} .. {blocks[be-1][0].decode('utf-8','replace')}")
        if nbytes > a.threshold:
            fail(f"part{pi} 超过阈值（{nbytes:,} > {a.threshold:,}），请人工检查")

    if not a.apply:
        print("[DRY-RUN] 未写盘。加 --apply 执行拆分。")
        return

    base = path[: -len(".csv")]
    targets = [f"{base}_part{pi}.csv" for pi, *_ in out]
    for t in targets:
        if os.path.exists(t) and not a.force:
            fail(f"目标已存在（加 --force 才覆盖）: {t}")

    for (pi, seg, _, _), t in zip(out, targets):
        with open(t, "wb") as fh:
            fh.write(header + eol)
            for x in seg:
                fh.write(x + eol)
        print(f"  写入 {t} : {os.path.getsize(t):,} B")

    # ---- 写后校验：分片拼接必须逐字节还原原件数据行 ----
    rebuilt = b""
    for t in targets:
        r = open(t, "rb").read()
        h, ls, _ = split_lines(r, eol)
        if h != header:
            fail(f"分片表头与原件不一致: {t}")
        rebuilt += b"".join(x + eol for x in ls)
    original_body = b"".join(x + eol for x in lines)
    if rebuilt != original_body:
        fail("分片拼接结果与原文件数据行不一致（逐字节比较失败），已中止，未删除原件")
    if sum(os.path.getsize(t) for t in targets) != size + (len(header) + len(eol)) * (len(targets) - 1):
        fail("分片总字节数与预期不符（重复表头开销之外存在差异）")
    n_rows_out = sum(sum(1 for _ in open(t, "rb")) - 1 for t in targets)
    if n_rows_out != n_rows:
        fail(f"分片行数之和 {n_rows_out} != 原件 {n_rows}")
    print(f"  校验通过：分片拼接 == 原件数据行（逐字节）；行数 {n_rows_out:,} = 原件 {n_rows:,}")

    # ---- 备份原件后删除 ----
    bdir = a.backup_dir or f"/tmp/split_clean_backup_{datetime.now():%Y%m%d_%H%M%S}"
    os.makedirs(bdir, exist_ok=True)
    shutil.copy2(path, os.path.join(bdir, os.path.basename(path)))
    os.remove(path)
    print(f"  原件已备份至 {bdir}/ 并删除：{path}")
    print(f"[DONE] {len(targets)} 片；库内数据集仍是 1 个（不新增 Dataset_inf 行、subj_info/Codebook/JSON 不变）")


if __name__ == "__main__":
    main()
