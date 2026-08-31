#!/usr/bin/env python3
"""wozniak2020_verify/verify_massive.py — Wozniak_2020_PLOS 四方核对（步骤 1）

复刻作者 MATLAB 聚合脚本（DATA/Massive_SelfBoost_Avg1subject_MAD_full.m +
SelfBoost_Avg1subject_MAD_full.m）的每被试条件均值，与作者 xlsx 聚合文件
（"Raw data - SelfBoostExp.xlsx"）逐值对比。

作者过滤口径（脚本实现，注意与论文文字 "2.5 MAD" 不同——脚本实际为
硬编码 highestRT=1500）：仅正确试次且 200 < RT < 1500 ms。

作者 xlsx 身份编号体系（关键发现，2026-09 验证）：
  - cue（label）编号 = 固定内部码：1=You, 2=Neutral, 3=AntiYou
  - face 编号 = 槽号（每被试 permutation 决定），即 xlsx 的 face 列 j
    对应内部码 σ(j)，其中 σ(j) = "码 j 在 labelsREAL 排列中的槽号"：
      perm 0: labelsREAL={Neutral,You,AntiYou}   → σ=[2,1,3]
      perm 1: labelsREAL={You,Neutral,AntiYou}   → σ=[1,2,3]
      perm 2: labelsREAL={AntiYou,You,Neutral}   → σ=[2,3,1]
      perm 3: labelsREAL={Neutral,AntiYou,You}   → σ=[3,1,2]
  - 因此 xlsx 9 组合区 RT_ij = 我的 RT_{i,σ(j)}；RT_0i = RT_0σ(i)；
    派生区（作者脚本语义 + 同一错位）：RT_M_i = RT_{i,σ(i)}（对 perm≠1
    不是真实匹配组合）、RT_NM1_i = label 码 i & face 码≠σ(i)、
    RT_NM2_i = face 码 σ(i) & label 码≠i。
  - xlsx 的 "ER_" 列实际是**正确率**（作者命名误导；ERR_TOTAL=0.9815
    = 265/270 正确），比较时取 1-错误率。
  该编号不对称（cue 用码、face 用槽号）是作者聚合产物的历史编码，
  不影响 .dat 原始数据；论文统计量影响见 Verifying_original_results_issues.md。

列对照（xlsx 75 列）：
  RT_ij/ER_ij = 组合 (label=i, face=σ(j))；RT_10/20/30 = cue 主效应；
  RT_01/02/03 = face 主效应（face=σ(i)）；RT_M/NM1/NM2 如上；
  ER 区 = 正确率。

用法：python3 verify_massive.py
退出码 0 = 全部一致（RT ±0.01 ms / 正确率 ±0.001 容差）。
"""
import glob
import os
import re
import sys

import numpy as np
import openpyxl

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, "1_Data", "Wozniak_2020_PLOS",
                    "Wozniak_2020_PLOS_raw", "DATA")
XLSX = os.path.join(ROOT, "1_Data", "Wozniak_2020_PLOS",
                    "Wozniak_2020_PLOS_raw", "Raw data - SelfBoostExp.xlsx")
RT_TOL, ACC_TOL = 0.01, 0.001

# permutation -> labelsREAL（槽 1-3 的内部码）
PERM_REAL = {
    0: (2, 1, 3),   # Neutral, You, AntiYou
    1: (1, 2, 3),   # You, Neutral, AntiYou
    2: (3, 1, 2),   # AntiYou, You, Neutral
    3: (2, 3, 1),   # Neutral, AntiYou, You
}


def sigma(perm):
    """σ(j) = 码 j 在 labelsREAL 中的槽号（xlsx face 列 j 对应的内部码）。"""
    real = PERM_REAL[perm]
    return {code: slot for slot, code in enumerate(real, start=1)}


def load_dat():
    """返回 {subject: dict}；Subject = 文件名 ID（xlsx 同口径）。"""
    subs = {}
    for f in sorted(glob.glob(os.path.join(DATA, "SelfBoostExp_*.dat"))):
        subj = re.search(r"(\d+)\.dat$", f).group(1)
        arr = np.array([l.split() for l in open(f).read().splitlines()])
        subs[subj] = {
            "perm": int(arr[0, 10]),
            "label": np.where(arr[:, 7] == "You", 1,
                     np.where(arr[:, 7] == "Neutral", 2, 3)).astype(int),
            "shape": np.where(arr[:, 9] == "shape1.jpg", 1,
                     np.where(arr[:, 9] == "shape2.jpg", 2, 3)).astype(int),
            "acc": arr[:, 20].astype(int),
            "rt": arr[:, 21].astype(float),
        }
    return subs


def author_aggregate(subs):
    """按作者 xlsx 的编号体系生成每被试聚合值（对齐后的 key）。"""
    out = {}
    for subj, d in subs.items():
        ok = d["acc"] == 1
        good = ok & (d["rt"] > 200) & (d["rt"] < 1500)
        L, F, RT = d["label"][good], d["shape"][good], d["rt"][good]
        s = sigma(d["perm"])
        row = {}
        # 9 组合区：xlsx (i, j) = label 码 i × face 码 s[j]
        for i in (1, 2, 3):
            for j in (1, 2, 3):
                fj = s[j]
                sel = (L == i) & (F == fj)
                row[f"RT_{i}{j}"] = RT[sel].mean() if sel.any() else np.nan
                allc = (d["label"] == i) & (d["shape"] == fj)
                row[f"ER_{i}{j}"] = (allc & good).sum() / 30  # xlsx=正确率(RT有效)
        # cue / face 主效应
        for i in (1, 2, 3):
            row[f"RT_{i}0"] = RT[L == i].mean() if (L == i).any() else np.nan
            row[f"ER_{i}0"] = (good & (d["label"] == i)).sum() / 90
            fi = s[i]
            row[f"RT_0{i}"] = RT[F == fi].mean() if (F == fi).any() else np.nan
            row[f"ER_0{i}"] = (good & (d["shape"] == fi)).sum() / 90
            # 派生区（作者脚本语义 + face 槽号错位）
            m = (L == i) & (F == s[i])
            row[f"RT_M_{i}"] = RT[m].mean() if m.any() else np.nan
            nm1 = (L == i) & (F != s[i])
            nm2 = (F == s[i]) & (L != i)
            row[f"RT_NM1_{i}"] = RT[nm1].mean() if nm1.any() else np.nan
            row[f"RT_NM2_{i}"] = RT[nm2].mean() if nm2.any() else np.nan
            row[f"ER_NM1_{i}"] = (good & (d["label"] == i) & (d["shape"] != s[i])).sum() / 60
            row[f"ER_NM2_{i}"] = (good & (d["shape"] == s[i]) & (d["label"] != i)).sum() / 60
        row["ERR_TOTAL"] = good.sum() / 270
        out[subj] = row
    return out


def main():
    subs = load_dat()
    assert len(subs) == 72, f"expected 72 dat files, got {len(subs)}"
    agg = author_aggregate(subs)

    wb = openpyxl.load_workbook(XLSX, read_only=True, data_only=True)
    n_bad = n_cmp = 0
    for sheet in ("Experiment 1", "Experiment 2", "Experiment 3"):
        rows = list(wb[sheet].iter_rows(values_only=True))
        hdr = [str(h) if h else "" for h in rows[1]]
        exp_cols = {h: i for i, h in enumerate(hdr) if h.startswith(
            ("RT_", "ER_", "ERR_"))}
        for r in rows[2:]:
            if r[1] is None or not str(r[1]).isdigit():
                continue
            subj = str(r[1])
            if subj not in agg:
                print(f"  MISSING in dat: {subj}"); n_bad += 1; continue
            for col, i in exp_cols.items():
                xl = r[i]
                if xl is None or (isinstance(xl, str) and not xl.strip()):
                    continue  # 空单元格（无合格试次）
                xl = float(xl)
                mine = agg[subj].get(col, np.nan)
                n_cmp += 1
                if np.isnan(mine):
                    if abs(xl) > ACC_TOL:
                        print(f"  {subj} {col}: xlsx={xl} mine=NaN"); n_bad += 1
                    continue
                tol = ACC_TOL if col.startswith(("ER_", "ERR_")) else RT_TOL
                if abs(xl - mine) > tol:
                    print(f"  {subj} {col}: xlsx={xl:.4f} mine={mine:.4f} "
                          f"diff={xl-mine:+.4f}")
                    n_bad += 1
    print(f"compared {n_cmp} cells across {len(agg)} subjects; "
          f"mismatches: {n_bad}")
    sys.exit(1 if n_bad else 0)


if __name__ == "__main__":
    main()
