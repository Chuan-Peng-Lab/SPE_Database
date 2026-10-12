#!/usr/bin/env python3
"""Wozniak_2022_PsychRes rebuild (2026-09; Task unified 2026-10-12): per-trial Label
recovery for the standard self-matching task + ingestion of the pseudo-words task,
merged into one Clean file per experiment. Both tasks carry Task = "self-matching";
the tasks are told apart by the Label column's original stimulus (pseudo-words
Nenu/Miru/Waru = pseudo-words task; You/none/friend name = standard task), as the
Shape column holds the identity slot label in both tasks. Idempotent: standard task
rebuilt from raw.csv (V1-V16), words task parsed from per-subject .dat files.
"""
import csv, io, glob, os
from collections import Counter

ROOT = "1_Data/Wozniak_2022_PsychRes"
RAWZONE = os.path.join(ROOT, "Wozniak_2022_PsychRes_Raw/Archive of OSF Storage/Raw data")

PERSONLABEL_IDX = {1:1, 2:2, 3:3, 4:3, 5:1, 6:2, 7:2, 8:3, 9:1}
SHAPE_SLOT     = {1:1, 4:1, 7:1, 2:2, 5:2, 8:2, 3:3, 6:3, 9:3}
PSEUDO_BY_VERSION = {1: ["Nenu","Miru","Waru"], 2: ["Waru","Nenu","Miru"], 3: ["Miru","Waru","Nenu"]}

def std_identity(s):
    s = s.strip()
    if s == "You": return "Self"
    if s in ("none", "<none>"): return "NonPerson"
    return "Close"

def read_csv_rows(path):
    with open(path, encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))

def read_dat(path):
    out = []
    for line in open(path, encoding="utf-8-sig"):
        p = line.split()
        if len(p) == 16: out.append(p)
    return out

def write_csv(rows, path):
    buf = io.StringIO()
    w = csv.DictWriter(buf, fieldnames=list(rows[0].keys()), lineterminator="\r\n", quoting=csv.QUOTE_ALL)
    w.writeheader(); w.writerows(rows)
    data = buf.getvalue().encode("utf-8")
    if not data.endswith(b"\r\n"): data += b"\r\n"
    open(path, "wb").write(data)

WORDS_TASKS = {"Exp1": "SelfPriorExp_WordsMeaning", "Exp2": "SelfPriorExp_WordsPairing",
               "Exp3": "SelfPriorExp_WordsSelfPairing"}

for exp, wtask in WORDS_TASKS.items():
    # ---- standard task rebuilt from raw ----
    raw = read_csv_rows(f"{ROOT}/{exp}/Wozniak_2022_PsychRes_{exp}_raw.csv")
    new_rows = []
    for r in raw:
        obj = int(r["V6"])
        pidx = PERSONLABEL_IDX[obj]; slot = SHAPE_SLOT[obj]
        shape_label = (r["V10"], r["V11"], r["V12"])[slot - 1]
        label = (r["V10"], r["V11"], r["V12"])[pidx - 1]
        rt = r["V16"]
        new_rows.append({
            "Subject": r["V1"], "Shape": shape_label, "Label": label,
            "Task": "self-matching",
            "Matching": "Matching" if r["V14"] == "1" else "Nonmatching",
            "Label_Origin_Identity": label, "Label_English_Identity": std_identity(label),
            "Label_Standardized_Identity": std_identity(label),
            "Shape_Origin_Identity": shape_label, "Shape_English_Identity": std_identity(shape_label),
            "Shape_Standardized_Identity": std_identity(shape_label),
            "Response": r["V5"], "RT_ms": rt,
            "RT_sec": str(int(rt) / 1000) if rt.isdigit() else "NA",
            "ACC": r["V15"],
        })

    # ---- words task ----
    subj_order = []
    for row in new_rows:
        if row["Subject"] not in subj_order: subj_order.append(row["Subject"])
    words_rows = []
    for subj in subj_order:
        dat = glob.glob(f"{RAWZONE}/Data - Experiment {exp[3:]}/{wtask}_{subj}.dat")
        assert len(dat) == 1, f"{exp} {subj}: {dat}"
        for parts in read_dat(dat[0]):
            v = dict(zip(["V%d" % i for i in range(1, 17)], parts))
            obj = int(v["V6"]); pidx = PERSONLABEL_IDX[obj]; slot = SHAPE_SLOT[obj]
            version = int(v["V12"])
            pseudo = PSEUDO_BY_VERSION[version][pidx - 1]
            shape_id = v["V9"] if slot == 1 else (v["V10"] if slot == 2 else v["V11"])
            label_id = v["V9"] if pidx == 1 else (v["V10"] if pidx == 2 else v["V11"])
            shape_id_clean = "none" if shape_id == "<none>" else shape_id
            label_id_clean = "none" if label_id == "<none>" else label_id
            rt = v["V16"]
            words_rows.append({
                "Subject": subj, "Shape": shape_id_clean, "Label": pseudo,
                "Task": "self-matching",   # 2026-10-12 统一；由 Label 列原刺激区分任务
                "Matching": "Matching" if v["V14"] == "1" else "Nonmatching",
                "Label_Origin_Identity": pseudo, "Label_English_Identity": pseudo,
                "Label_Standardized_Identity": std_identity(label_id_clean),
                "Shape_Origin_Identity": shape_id_clean, "Shape_English_Identity": std_identity(shape_id_clean),
                "Shape_Standardized_Identity": std_identity(shape_id_clean),
                "Response": v["V5"], "RT_ms": rt,
                "RT_sec": str(int(rt) / 1000) if rt.isdigit() else "NA",
                "ACC": v["V15"],
            })
    assert len(words_rows) == 18 * 360, f"{exp}: words 行数 {len(words_rows)}"

    merged = new_rows + words_rows
    write_csv(merged, f"{ROOT}/{exp}/Wozniak_2022_PsychRes_{exp}_Clean.csv")

    raw_words = []
    for subj in subj_order:
        dat = glob.glob(f"{RAWZONE}/Data - Experiment {exp[3:]}/{wtask}_{subj}.dat")[0]
        for parts in read_dat(dat):
            v = dict(zip(["V%d" % i for i in range(1, 17)], parts))
            raw_words.append({"subNo": v["V1"], "hand": v["V2"], "phaselabel": v["V3"],
                "trial": v["V4"], "resp": v["V5"], "objnumber": v["V6"], "objname": v["V7"],
                "permutation": v["V8"], "slot_identity1": v["V9"], "slot_identity2": v["V10"],
                "slot_identity3": v["V11"], "version": v["V12"], "self_pseudoword": v["V13"],
                "objtype": v["V14"], "ac": v["V15"], "rt_ms": v["V16"]})
    write_csv(raw_words, f"{ROOT}/{exp}/Wozniak_2022_PsychRes_{exp}_Words_raw.csv")

    # ---- guards ----
    taskc = Counter(r["Task"] for r in merged)
    assert set(taskc) == {"self-matching"}, f"{exp}: {taskc}"
    assert sum(taskc.values()) in (12953, 12960), f"{exp}: {taskc}"
    pseudo = Counter(1 for r in merged if r["Label"] in PSEUDO_BY_VERSION[1])
    assert sum(pseudo.values()) == 6480, f"{exp}: pseudo rows {sum(pseudo.values())}"
    per = Counter(r["Subject"] for r in merged)
    assert all(v == 720 or (k == "3002" and v == 713) for k, v in per.items()), f"{exp}: {[k for k,v in per.items() if v!=720][:3]}"
    # 同一被试同一伪词 LStd 唯一
    for subj in subj_order:
        ls = {}
        for r in merged:
            if r["Subject"] == subj and r["Label"] in PSEUDO_BY_VERSION[1]:
                ls.setdefault(r["Label"], set()).add(r["Label_Standardized_Identity"])
        assert all(len(v) == 1 for v in ls.values()), f"{exp} {subj}: {ls}"
    print(f"{exp}: ✓ {len(merged)} 行 ({dict(taskc)}), guards 通过")

print("全部完成")
