#!/usr/bin/env python3
"""scan_raw.py — 原始 trial 级数据快速扫描 — 2026-08 阶段 4 工具

用途：阶段 4 判定 raw 数据完整性/结构（P5 沉淀模式）：
  * 每被试行数统计 → 整除性/缺失判定（如 Smith raw 48 vs 59 导出不全）
  * 列值分布 → 任务/条件结构还原（如 Schaefer Bed 8 条件码）
  * 两列交叉表 → 实验设计还原（Block × 条件等）

输出（对每个文件）：
  * 列名、总行数
  * Subject 列（自动识别常见名或 --subject）：被试数、每被试行数 min/max、
    是否全部相同（整除）
  * 每列值分布：unique 数 + 最常见值 top N（含空串计数）
  * --cross A B：两列交叉表 top 12

大文件（>10 MB）建议 --sample N：行数/被试统计仍全量流式，值分布只取前 N 行。

用法：
  python3 2_Code/scan_raw.py FILE [FILE...] [--sample 100000] [--cross Block Bed]
"""
import argparse
import collections
import csv
import sys

SUBJECT_CANDIDATES = ("subject", "subject_id", "participant", "participant_id",
                      "vp", "id", "subid")


def scan(path, sample, cross):
    print(f"===== {path} =====")
    with open(path, encoding="utf-8-sig", newline="") as fh:
        rd = csv.DictReader(fh)
        if rd.fieldnames is None:
            print("  (empty file)")
            return
        cols = rd.fieldnames
        print(f"  cols ({len(cols)}): {cols}")
        subj_col = next((c for c in cols if c.lower() in SUBJECT_CANDIDATES), None)
        if cross:
            if cross[0] not in cols or cross[1] not in cols:
                sys.exit(f"--cross 列 {cross} 不在文件中")
        n = 0
        per_subj = collections.Counter() if subj_col else None
        val_counters = collections.defaultdict(collections.Counter)
        cross_ct = collections.Counter() if cross else None
        for r in rd:
            n += 1
            if per_subj is not None:
                per_subj[r[subj_col]] += 1
            if cross_ct is not None and (sample is None or n <= sample):
                cross_ct[(r[cross[0]], r[cross[1]])] += 1
            if sample is None or n <= sample:
                for c in cols:
                    val_counters[c][r[c]] += 1
            if sample is not None and n >= sample:
                break
        print(f"  rows: {n}")
        if per_subj is not None:
            vals = per_subj.values()
            print(f"  Subject col '{subj_col}': n={len(per_subj)} "
                  f"rows/subj min={min(vals)} max={max(vals)} "
                  f"uniform={len(set(vals)) == 1}")
        for c in cols:
            vc = val_counters[c]
            if not vc:
                print(f"    {c}: (no values in sampled rows)")
                continue
            top = vc.most_common(8)
            s = "; ".join(f"{k!r}:{v}" for k, v in top)
            others = sum(v for k, v in vc.items()) - sum(v for _, v in top)
            uniq = len(vc)
            print(f"    {c}: unique={uniq} | {s}" + (f" | ...+{others}" if others else ""))
        if cross_ct:
            print(f"  cross {cross[0]} x {cross[1]}:")
            for (a, b), v in cross_ct.most_common(12):
                print(f"    {a!r} x {b!r}: {v}")


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("files", nargs="+", help="raw CSV 文件路径（可多个）")
    p.add_argument("--sample", type=int, default=None,
                   help="值分布/交叉表最多统计前 N 行（行数与被试统计仍全量）")
    p.add_argument("--cross", nargs=2, metavar=("A", "B"),
                   help="输出两列交叉表（top 12）")
    args = p.parse_args()
    for f in args.files:
        scan(f, args.sample, args.cross)


if __name__ == "__main__":
    main()
