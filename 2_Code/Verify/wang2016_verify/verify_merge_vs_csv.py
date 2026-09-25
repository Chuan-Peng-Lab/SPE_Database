#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
wang2016_verify/verify_merge_vs_csv.py
=======================================
Wang, Humphreys & Sui (2016, JEPHPP) — 阶段 4 txt 转换后核对（§7-1/§7-2/§7-3 主脚本）。

目的：
  1. 将 6 份 E-Merge txt（UTF-16LE，E-DataAid 文本导出）解析为 trial 级表；
  2. 与 4 份作者聚合 CSV 逐值对比（Subject / Identity / Label / Shape /
     Target.ACC / Target.RESP / Target.RT），确认聚合导出无损失；
  3. 输出每被试 practice / block 结构统计（§7-1 重点：Exp2 practice 行是否
     真不存在；Exp1 practice 前 9 行判定）；
  4. 用 txt 的 CorrectAnswer / YesNoResp 逐试次验证规则 B（§7-3）并核对
     9 条件 × 72 试次结构与 8 blocks 划分。

口径说明（2026-09-01 核对确认）：
  - txt 为 E-Merge 扁平导出：每行一个事件；列名按行 3（第 4 行）表头。
  - Exp1/Exp2 Association（SelfAssociate）：trial 行 = Procedure[LogLevel5] 非空
    （正式，含 CorrectAnswer[LogLevel5] / T1-T3[LogLevel5] / Target.ACC[LogLevel5] 等）；
    practice 行 = Procedure[SubTrial] 非空（TR1PracTrialList，每被试 6 行）。
    任务实为 3AFC：形状 + 三个标签（T1/T2/T3 位置），键 b/n/m = 位置 1/2/3，
    CorrectAnswer = 正确标签（=形状初始指派身份）所在位置键。
  - Exp1 Breaking：程序两版本（breaking=TR4*，被试 3-10,24；breaking_mn=TR5*，
    被试 11-22）。trial 行 = Procedure[SubTrial] 非空；Trial==1 → practice
    （TRxPracTrialList，9 行/被试）；Trial 2-9 → 8 个正式 block
    （TRxBlockList.Sample = 1-8，每 block 81 行）。2 键 n/m（YesNoResp 指示
    match 键 = Yes；Yes 键随被试 counterbalance）。
  - Exp2 Breaking：程序 TR1*；practice 行用 Target1.ACC/RESP/RT 列（正式行用
    Target.*）；Trial==1 为 practice（9 行/被试），Trial 2-9 为 8 block × 81。
    作者聚合 CSV 未含 practice（648 行/被试），txt 含之 —— §7-1 结论：
    Exp2 practice 行真实存在（9/被试），聚合导出丢弃。
  - 聚合 CSV 的 Label = txt Label 的英文映射（你→Self、朋友→Friend、生人→Stranger）；
    CSV Identity = txt Shape（形状 Part-1 身份，stranger 大小写归一）；
    CSV Shape = txt Target（bmp 文件名）。

运行：
  python3 2_Code/wang2016_verify/verify_merge_vs_csv.py
退出码 0 = 全部一致。
"""
import csv
import io
import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW = os.path.join(ROOT, "1_Data", "Wang_2016_JEPHPP", "Wang_2016_JEPHPP_Raw")

LABEL_EN = {"你": "Self", "朋友": "Friend", "生人": "Stranger",
            "self": "Self", "friend": "Friend", "stranger": "Stranger",
            "Self": "Self", "Friend": "Friend", "Stranger": "Stranger"}
LABEL_NORM = lambda v: LABEL_EN.get(v, v)
ID_NORM = {"self": "Self", "friend": "Friend", "stranger": "Stranger", "none": "Stranger"}
KEYPOS = {"b": 1, "n": 2, "m": 3}  # 键 → 标签位置（association 3AFC）


def read_txt(path):
    with open(path, "rb") as f:
        raw = f.read()
    txt = raw.decode("utf-16-le")
    lines = txt.split("\r\n")
    hdr = lines[3].split("\t")
    idx = {c: i for i, c in enumerate(hdr)}
    rows = []
    for ln in lines[4:]:
        parts = ln.split("\t")
        if len(parts) <= 2 or not parts[1]:
            continue
        rows.append(parts)
    return idx, rows


def get(row, idx, col):
    i = idx.get(col)
    if i is None or i >= len(row):
        return ""
    return row[i]


def empty(v):
    return v == "" or v == "NULL"


def intv(v):
    return None if empty(v) else int(v)


def norm_id(v):
    if empty(v):
        return v
    return ID_NORM.get(v.lower(), v)


def parse_assoc(path):
    """Association txt → (practice_rows, formal_rows, header_info) per subject."""
    idx, rows = read_txt(path)
    out = {}  # subject -> dict(practice=[...], formal=[...], header={})
    for r in rows:
        subj = get(r, idx, "Subject")
        d = out.setdefault(subj, {"practice": [], "formal": [], "header": {}})
        d["header"] = {
            "Age": get(r, idx, "Age"),
            "Sex": get(r, idx, "Sex"),
            "Handedness": get(r, idx, "Handedness"),
            "Group": get(r, idx, "Group"),
            "Name": get(r, idx, "Name"),
            "SessionDate": get(r, idx, "SessionDate"),
            "SubjCounterblance": get(r, idx, "SubjCounterblance"),
        }
        if "Prac" in get(r, idx, "Running[SubTrial]"):
            d["practice"].append({
                "Identity": norm_id(get(r, idx, "Shape[SubTrial]")),
                "Shape": get(r, idx, "Target[SubTrial]"),
                "ACC": intv(get(r, idx, "Target.ACC[SubTrial]")),
                "RESP": get(r, idx, "Target.RESP[SubTrial]"),
                "RT": intv(get(r, idx, "Target.RT[SubTrial]")),
                "CA": get(r, idx, "CorrectAnswer[SubTrial]"),
                "T1": get(r, idx, "T1[SubTrial]"),
                "T2": get(r, idx, "T2[SubTrial]"),
                "T3": get(r, idx, "T3[SubTrial]"),
                "Trial": get(r, idx, "Trial"),
            })
        elif get(r, idx, "Procedure[LogLevel5]"):
            d["formal"].append({
                "Identity": norm_id(get(r, idx, "Shape[LogLevel5]")),
                "Shape": get(r, idx, "Target[LogLevel5]"),
                "ACC": intv(get(r, idx, "Target.ACC[LogLevel5]")),
                "RESP": get(r, idx, "Target.RESP[LogLevel5]"),
                "RT": intv(get(r, idx, "Target.RT[LogLevel5]")),
                "CA": get(r, idx, "CorrectAnswer[LogLevel5]"),
                "T1": get(r, idx, "T1[LogLevel5]"),
                "T2": get(r, idx, "T2[LogLevel5]"),
                "T3": get(r, idx, "T3[LogLevel5]"),
                "Trial": get(r, idx, "Trial"),
            })
    return out


def parse_switch(path, use_target1_for_prac=False):
    """Breaking txt → per subject: rows (practice + formal in file order)."""
    idx, rows = read_txt(path)
    out = {}
    for r in rows:
        if not get(r, idx, "Procedure[SubTrial]"):
            continue
        subj = get(r, idx, "Subject")
        d = out.setdefault(subj, {"rows": [], "header": {}})
        d["header"] = {
            "Age": get(r, idx, "Age"),
            "Sex": get(r, idx, "Sex"),
            "Handedness": get(r, idx, "Handedness"),
            "Group": get(r, idx, "Group"),
            "Name": get(r, idx, "Name"),
            "SessionDate": get(r, idx, "SessionDate"),
            "SubjCounterblance": get(r, idx, "SubjCounterblance"),
            "Yes": get(r, idx, "Yes"),
            "No": get(r, idx, "No"),
        }
        trial = get(r, idx, "Trial")
        is_prac = trial == "1"
        acc_col = "Target1.ACC" if (is_prac and use_target1_for_prac) else "Target.ACC"
        resp_col = "Target1.RESP" if (is_prac and use_target1_for_prac) else "Target.RESP"
        rt_col = "Target1.RT" if (is_prac and use_target1_for_prac) else "Target.RT"
        d["rows"].append({
            "Label": get(r, idx, "Label"),
            "Identity": norm_id(get(r, idx, "Shape")),
            "Shape": get(r, idx, "Target"),
            "ACC": intv(get(r, idx, acc_col)),
            "RESP": get(r, idx, resp_col),
            "RT": intv(get(r, idx, rt_col)),
            "CA": get(r, idx, "CorrectAnswer"),
            "CRESP": get(r, idx, acc_col.replace(".ACC", ".CRESP")),
            "YesNoResp": get(r, idx, "YesNoResp"),
            "Trial": trial,
            "SubTrial": get(r, idx, "SubTrial"),
            "Block": None,
            "is_prac": is_prac,
        })
        # block: TRxBlockList.Sample where x = program variant (from Procedure[Block])
        if d["rows"][-1]["Block"] is None:
            m = re.match(r"TR(\\d+)", get(r, idx, "Procedure[Block]"))
            if m:
                v = get(r, idx, "TR" + m.group(1) + "BlockList.Sample")
                if v and v != "NULL":
                    d["rows"][-1]["Block"] = int(v)
        if d["rows"][-1]["Block"] is None and not is_prac:
            d["rows"][-1]["Block"] = int(trial) - 1  # Trial 2-9 -> Block 1-8
    return out


def load_csv(fname):
    path = os.path.join(RAW, fname)
    with open(path, newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))


def compare_switch(exp, txt_files, csv_file, use_target1_for_prac, label_map, csv_includes_practice):
    print(f"\n===== Exp{exp} Switch: txt vs CSV =====")
    csv_rows = load_csv(csv_file)
    csv_by_subj = defaultdict(list)
    for r in csv_rows:
        csv_by_subj[r["Subject"]].append(r)
    problems = []
    for f in txt_files:
        parsed = parse_switch(os.path.join(RAW, f), use_target1_for_prac)
        for subj, d in sorted(parsed.items(), key=lambda kv: int(kv[0])):
            trows = d["rows"] if csv_includes_practice else [t for t in d["rows"] if not t["is_prac"]]
            crows = csv_by_subj.get(subj, [])
            if len(crows) != len(trows):
                problems.append(
                    f"{f} subj {subj}: txt formal={len(trows)} (practice in txt: {sum(1 for t in d['rows'] if t['is_prac'])}) "
                    f"vs CSV rows={len(crows)}")
                continue
            for i, (t, c) in enumerate(zip(trows, crows)):
                if t["Identity"] != c["Identity"]:
                    problems.append(f"{f} subj {subj} row {i}: Identity txt={t['Identity']!r} vs CSV={c['Identity']!r}")
                if LABEL_NORM(t["Label"]).lower() != c["Label"].lower():
                    problems.append(f"{f} subj {subj} row {i}: Label(EN) txt={LABEL_NORM(t['Label'])!r} vs CSV={c['Label']!r}")
                if t["Shape"] != c["Shape"]:
                    problems.append(f"{f} subj {subj} row {i}: Shape txt={t['Shape']!r} vs CSV={c['Shape']!r}")
                if t["ACC"] != intv(c["Target.ACC"]):
                    problems.append(f"{f} subj {subj} row {i}: ACC txt={t['ACC']} vs CSV={c['Target.ACC']!r}")
                if (t["RESP"] or "") != (c["Target.RESP"] or ""):
                    problems.append(f"{f} subj {subj} row {i}: RESP txt={t['RESP']!r} vs CSV={c['Target.RESP']!r}")
                if t["RT"] != intv(c["Target.RT"]):
                    problems.append(f"{f} subj {subj} row {i}: RT txt={t['RT']} vs CSV={c['Target.RT']!r}")
    # practice structure: 9 rows, 9 distinct (Label,Identity) combos
    prac_bad = []
    for f in txt_files:
        parsed = parse_switch(os.path.join(RAW, f), use_target1_for_prac)
        for subj, d in sorted(parsed.items(), key=lambda kv: int(kv[0])):
            prac = [t for t in d["rows"] if t["is_prac"]]
            if len(prac) != 9:
                prac_bad.append(f"{f} subj {subj}: practice rows={len(prac)}")
                continue
            conds = Counter((LABEL_NORM(t["Label"]), t["Identity"]) for t in prac)
            if len(conds) != 9 or any(v != 1 for v in conds.values()):
                prac_bad.append(f"{f} subj {subj}: practice combos={dict(sorted(conds.items()))}")
    # rule B + block structure
    ruleB_bad = []
    block_bad = []
    for f in txt_files:
        parsed = parse_switch(os.path.join(RAW, f), use_target1_for_prac)
        for subj, d in sorted(parsed.items(), key=lambda kv: int(kv[0])):
            yeskey = None
            for t in d["rows"]:
                if t["YesNoResp"] in ("yes", "Yes"):
                    if yeskey is None:
                        yeskey = t["CA"]
                    elif yeskey != t["CA"]:
                        ruleB_bad.append(f"{f} subj {subj}: inconsistent yes-key {yeskey} vs {t['CA']}")
            # rule B: Match = (Label == f(Identity))
            fmap = {"Self": "Stranger", "Friend": "Self", "Stranger": "Friend"} if exp == 1 else \
                   {"Self": "Friend", "Friend": "Stranger", "Stranger": "Self"}
            for i, t in enumerate(d["rows"]):
                pred = LABEL_NORM(t["Label"]) == fmap[t["Identity"]]
                is_match_ans = (t["CA"] == yeskey)
                if pred != is_match_ans:
                    ruleB_bad.append(f"{f} subj {subj} row {i}: ruleB pred={pred} vs CA={t['CA']} yeskey={yeskey}")
            # block structure: formal rows: 8 blocks × 81
            blocks = Counter(t["Block"] for t in d["rows"] if not t["is_prac"])
            if sorted(blocks) != list(range(1, 9)) or any(v != 81 for v in blocks.values()):
                block_bad.append(f"{f} subj {subj}: blocks={dict(blocks)}")
            # 9 conditions × 72: (Label, Identity) combos
            conds = Counter((LABEL_NORM(t["Label"]), t["Identity"]) for t in d["rows"] if not t["is_prac"])
            if len(conds) != 9 or any(v != 72 for v in conds.values()):
                block_bad.append(f"{f} subj {subj}: 9-condition counts={dict(sorted(conds.items()))}")
    print(f"  txt subjects: {sum(len(parse_switch(os.path.join(RAW, f), use_target1_for_prac)) for f in txt_files)}")
    print(f"  CSV subjects: {len(csv_by_subj)}, CSV rows: {len(csv_rows)}")
    print(f"  value-mismatch problems: {len(problems)}")
    for p in problems[:20]:
        print("   -", p)
    print(f"  practice structure problems: {len(prac_bad)}")
    for p in prac_bad[:10]:
        print("   -", p)
    print(f"  rule-B violations: {len(ruleB_bad)}")
    for p in ruleB_bad[:10]:
        print("   -", p)
    print(f"  block/condition structure problems: {len(block_bad)}")
    for p in block_bad[:10]:
        print("   -", p)
    return len(problems) + len(ruleB_bad) + len(block_bad) + len(prac_bad)


def compare_assoc(exp, txt_file, csv_file):
    print(f"\n===== Exp{exp} Association: txt vs CSV =====")
    parsed = parse_assoc(os.path.join(RAW, txt_file))
    csv_rows = load_csv(csv_file)
    csv_by_subj = defaultdict(list)
    for r in csv_rows:
        csv_by_subj[r["Subject"]].append(r)
    problems = []
    for subj, d in sorted(parsed.items(), key=lambda kv: int(kv[0])):
        formal = d["formal"]
        crows = csv_by_subj.get(subj, [])
        if len(crows) != len(formal):
            problems.append(
                f"{txt_file} subj {subj}: txt formal={len(formal)} (practice={len(d['practice'])}) "
                f"vs CSV rows={len(crows)}")
            continue
        for i, (t, c) in enumerate(zip(formal, crows)):
            if t["Identity"] != c["Identity"]:
                problems.append(f"{txt_file} subj {subj} row {i}: Identity txt={t['Identity']!r} vs CSV={c['Identity']!r}")
            if t["Shape"] != c["Shape"]:
                problems.append(f"{txt_file} subj {subj} row {i}: Shape txt={t['Shape']!r} vs CSV={c['Shape']!r}")
            if t["ACC"] != intv(c["Target.ACC"]):
                problems.append(f"{txt_file} subj {subj} row {i}: ACC txt={t['ACC']} vs CSV={c['Target.ACC']!r}")
            if (t["RESP"] or "") != (c["Target.RESP"] or ""):
                problems.append(f"{txt_file} subj {subj} row {i}: RESP txt={t['RESP']!r} vs CSV={c['Target.RESP']!r}")
            if t["RT"] != intv(c["Target.RT"]):
                problems.append(f"{txt_file} subj {subj} row {i}: RT txt={t['RT']} vs CSV={c['Target.RT']!r}")
        # label recovery: text at CA-key position; must equal shape's assigned label (constant per shape)
        assigned = {}
        for t in formal + d["practice"]:
            pos = KEYPOS.get(t["CA"])
            if pos is None:
                problems.append(f"{txt_file} subj {subj}: unknown CA key {t['CA']!r}")
                continue
            texts = {1: t["T1"], 2: t["T2"], 3: t["T3"]}
            lab = texts.get(pos)
            if lab is None or lab == "":
                problems.append(f"{txt_file} subj {subj}: no label at CA position")
                continue
            if assigned.setdefault(t["Identity"], lab) != lab:
                problems.append(f"{txt_file} subj {subj}: assigned label for {t['Identity']} inconsistent "
                                f"({assigned[t['Identity']]} vs {lab})")
        print(f"  subj {subj}: practice={len(d['practice'])} formal={len(formal)} "
              f"assigned={ {k: v for k, v in sorted(assigned.items())} }")
    print(f"  txt subjects: {len(parsed)}, CSV rows: {len(csv_rows)}")
    print(f"  problems: {len(problems)}")
    for p in problems[:20]:
        print("   -", p)
    return len(problems)


def main():
    nerr = 0
    # Exp1 switch: two program txts; CSV includes practice (657/subj)
    nerr += compare_switch(
        1,
        ["RawData_Exp1/breaking_merge_20260831.txt", "RawData_Exp1/breaking_mn_merge_20260831.txt"],
        "Wang_2016_JEPHPP_Exp1_Switch.csv", use_target1_for_prac=False, label_map=LABEL_EN,
        csv_includes_practice=True)
    # Exp2 switch: CSV excludes practice (648/subj); txt has 657 incl practice
    nerr += compare_switch(
        2,
        ["RawData_Exp2/breaking_merge_20260831.txt"],
        "Wang_2016_JEPHPP_Exp2_Switch.csv", use_target1_for_prac=True, label_map=LABEL_EN,
        csv_includes_practice=False)
    nerr += compare_assoc(1, "RawData_Exp1/SelfAssociate_merge_20260831.txt",
                          "Wang_2016_JEPHPP_Exp1_Association.csv")
    nerr += compare_assoc(2, "RawData_Exp2/SelfAssociate_merge_20260831.txt",
                          "Wang_2016_JEPHPP_Exp2_Association.csv")
    print("\n===== TOTAL PROBLEMS:", nerr, "=====")
    sys.exit(0 if nerr == 0 else 1)


if __name__ == "__main__":
    main()
