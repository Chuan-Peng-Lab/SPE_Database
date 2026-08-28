#!/usr/bin/env python3
# ============================================================================
# 2_Code/stage31_crosscheck.py — 阶段 3.1 四方机械比对（只读，2026-08）
# ----------------------------------------------------------------------------
# 对指定研究输出 CSV ↔ paper/exp JSON ↔ Clean ↔ subj_info 的字段级比对，
# 供阶段 3.1 独立复核使用。只读：绝不修改任何文件。
#
# 用法：
#   python 2_Code/stage31_crosscheck.py <Folder_Name> [--all] [--list]
#     <Folder_Name>  单个研究（如 Constable_2020_ActaPsych）
#     --all          输出 1_Data/ 全部研究
#     --list         列出所有研究 + 行数
#
# 比对内容：
#   CSV ↔ paper JSON : Year / DOI / Journal / Country / City
#   CSV ↔ exp JSON   : numTrials vs Trial_number、numBlocks vs Block_number、
#                      Practice_Trial vs Practice_trials、Stim_Type vs Modality、
#                      Environmental_Info vs Software、Setting（词表检查）
#   Clean            : 行数 / unique Subject / Shape&Label Std 枚举 / Matching / ACC / Block
#   N 口径           : CSV Sample_Size/Valid_Subj vs Clean nSubj vs subj_info 行数
#
# 注意：Trial_number 文本如 "360 total (60 per block)" 含 per-block 与 total 两个口径，
# 脚本原样显示数字，per-block/total 判定留人工。
# ============================================================================
import csv
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from read_dataset_inf import read_dataset_inf, find_rows


def study_root():
    env = os.environ.get("SPE_DATABASE_ROOT", "")
    if env and os.path.isdir(os.path.join(env, "1_Data")):
        return os.path.join(env, "1_Data")
    d = os.path.dirname(os.path.abspath(__file__))
    while True:
        cand = os.path.join(d, "1_Data")
        if os.path.isdir(cand):
            return cand
        parent = os.path.dirname(d)
        if parent == d:
            raise FileNotFoundError("1_Data not found")
        d = parent


def find_file(root, name):
    """在 study 根或 ExpN/ 子目录中找文件。"""
    cand = os.path.join(root, name)
    if os.path.isfile(cand):
        return cand
    hits = glob.glob(os.path.join(root, "*", name))
    return hits[0] if hits else None


def num_from_text(t):
    """从 JSON 文本中提取第一个数字（用于快速对照）。"""
    m = re.search(r"(\d+)", str(t))
    return m.group(1) if m else None


def check_study(data_root, fn):
    rows = find_rows(csv_rows, fn)
    if not rows:
        print(f"[SKIP] {fn}: 不在 Dataset_inf.csv")
        return
    folder = os.path.join(data_root, fn)
    if not os.path.isdir(folder):
        print(f"[SKIP] {fn}: 无数据文件夹")
        return
    print(f"\n{'='*70}\n=== {fn} ({len(rows)} CSV row(s)) ===")

    # paper JSON
    pj = find_file(folder, fn + ".json")
    if pj:
        paper = json.load(open(pj, encoding="utf-8"))
        for k in ["Year", "DOI", "Journal", "Country", "City"]:
            pv = str(paper.get(k, "")).strip()
            csvv = rows[0].get(k, "").strip()
            tag = "OK" if pv == csvv else "** DIFF **"
            print(f"  paper JSON {k}: {pv!r} | CSV {csvv!r}  {tag}")
    else:
        print("  [WARN] 无 paper JSON")

    # 逐实验
    for r in rows:
        exp = r["Exp"]
        expj = find_file(folder, f"{fn}_Exp{exp}.json")
        clean = find_file(folder, f"{fn}_Exp{exp}_Clean.csv")
        si = find_file(folder, f"{fn}_Exp{exp}_subj_info.csv")
        print(f"\n  -- Exp{exp} --")
        if expj:
            ej = json.load(open(expj, encoding="utf-8"))[f"exp{exp}"]
            bs = ej.get("Block_Structure", {})
            pe = ej.get("Physical_Environment", {})
            sp = ej.get("Stimulus_Properties", {})
            eq = pe.get("Equipment", {})
            setting = pe.get("Setting", "")
            print(f"    expJSON Block: {bs.get('Block_number')!r} | Trial: {bs.get('Trial_number')!r} | Practice: {bs.get('Practice_trials')!r}")
            print(f"    expJSON Software: {eq.get('Software')!r} | Modality: {sp.get('Modality')!r}")
            print(f"    expJSON Setting: {setting!r}  {'[词表检查: 应 Laboratory/Online]' if setting not in ('Laboratory', 'Online', 'Laboratory + Online', '/') else ''}")
            print(f"    CSV      numBlocks={r['numBlocks']} numTrials={r['numTrials']} Practice_Trial={r['Practice_Trial']}")
            print(f"    CSV      Environmental_Info={r['Environmental_Info']!r} Stim_Type={r['Stim_Type']!r}")
            print(f"    CSV      subj_Group={r['subj_Group']!r}")
        else:
            print("    [WARN] 无 exp JSON")

        if clean:
            cr = list(csv.DictReader(open(clean, encoding="utf-8-sig")))
            nsubj = len(set(x["Subject"] for x in cr))
            std_cols = {
                "Shape_Standardized_Identity": sorted(set(x.get("Shape_Standardized_Identity", "") for x in cr)),
                "Label_Standardized_Identity": sorted(set(x.get("Label_Standardized_Identity", "") for x in cr)),
            }
            match = sorted(set(x.get("Matching", "") for x in cr))
            acc = sorted(set(x.get("ACC", "") for x in cr))
            blk = sorted(set(x.get("Block", "") for x in cr)) if "Block" in cr[0] else "/"
            print(f"    Clean    rows={len(cr)} nSubj={nsubj}")
            print(f"    Clean    Shape_Std={std_cols['Shape_Standardized_Identity']}")
            print(f"    Clean    Label_Std={std_cols['Label_Standardized_Identity']}")
            print(f"    Clean    Matching={match} ACC={acc} Block={blk}")
        else:
            nsubj = "?"
            print("    [WARN] 无 Clean 文件")

        si_rows = "?"
        if si:
            srr = list(csv.DictReader(open(si, encoding="utf-8-sig")))
            si_rows = len(srr)
            print(f"    subj_info rows={si_rows} cols={list(srr[0].keys())}")
        print(f"    [N口径] CSV Sample_Size={r['Sample_Size']} Valid_Subj={r['Valid_Subj']} | Clean nSubj={nsubj} | subj_info={si_rows}  {'** 不一致 **' if str(nsubj) not in ('?',) and nsubj != int(r['Valid_Subj'] or 0) else 'OK'}")


if __name__ == "__main__":
    data_root = study_root()
    _, csv_rows = read_dataset_inf()
    args = sys.argv[1:]
    if "--list" in args:
        seen = {}
        for r in csv_rows:
            seen[r["Folder_Name"]] = seen.get(r["Folder_Name"], 0) + 1
        for fn, n in sorted(seen.items()):
            print(f"{fn}: {n} row(s)")
        sys.exit(0)
    if "--all" in args:
        targets = sorted({r["Folder_Name"] for r in csv_rows})
    else:
        targets = [a for a in args if not a.startswith("--")]
    for fn in targets:
        check_study(data_root, fn)
