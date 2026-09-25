#!/usr/bin/env python3
# ============================================================================
# 2_Code/hobbs_verify/verify_trial.py — Hobbs_2023_PsychMed 入库四方核对
# ----------------------------------------------------------------------------
# 目的（2026-08-30 阶段 5 入库，Hobbs_2023_PsychMed）：
#   1) trial 级逐值对比：库内 Hobbs_2023_PsychMed_Exp1_raw.csv vs 作者
#      associative_df_trial_anon.csv（51840 行，Associative_cleaning.R 产物）
#   2) 聚合级对比：库内数据按作者 collapsed 口径重算 vs 作者
#      associative_long_matching_collapsed_anon.csv（144×9 = 1296 行）
# 口径（Associative_cleaning.R）：
#   - 正式 trial = trials.thisN 非 NA（库内同口径）
#   - Matching：CorrectAnswer Yes→1 / No→0
#   - 作者 acc：trial_resp.corr，但 rt<200 ms 或无响应 → 0（分析口径；
#     库内 ACC 按方案 A：keys NA → NA）
#   - mean_rt_mult = rt×1000（未取整；库内 RT_ms = round(rt×1000)）
#   - stimuli 映射：Task×Shape(标签类) → Self/Friend/Stranger/£9/£3/£1/
#     Happy/Neutral/Sad
#   - collapsed：排除 rt<0.2 或无响应后，group_by(subject, Task, Shape,
#     Matching) 求 prop_acc=mean(corr)×100 与 mean_rt=mean(rt)×1000，
#     再 group_by(subject, Task, stimuli) 对 Matching 两水平求均值
# 用法：python3 verify_trial.py [--root DIR]
# ============================================================================
import argparse
import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def read_csv(path, key_cols):
    with open(path, newline="", encoding="utf-8-sig") as f:
        return list(csv.DictReader(f))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=ROOT)
    args = ap.parse_args()
    study = os.path.join(args.root, "1_Data", "Hobbs_2023_PsychMed")
    raw_dir = os.path.join(study, "Hobbs_2023_PsychMed_raw",
                           "Aggregated Data for Analysis", "Data",
                           "Associative Learning")
    mine = os.path.join(study, "Hobbs_2023_PsychMed_Exp1_raw.csv")
    auth_trial = os.path.join(raw_dir, "associative_df_trial_anon.csv")
    auth_coll = os.path.join(raw_dir, "associative_long_matching_collapsed_anon.csv")
    for p in (mine, auth_trial, auth_coll):
        assert os.path.exists(p), p

    # ---- hash 映射（clean.R 同款：排序） ----
    rows = read_csv(mine, None)
    hashes = sorted({r["Subject"] for r in rows})  # 占位，实际从 raw 不可得 hash
    # 从作者 trial 文件取 hash 集合
    at = read_csv(auth_trial, None)
    auth_hashes = [r["subject"] for r in at]
    uniq = sorted(set(auth_hashes))
    assert len(uniq) == 144, len(uniq)
    num2hash = dict(enumerate(uniq, start=1))
    # 库内 Subject 编号 → hash（clean.R：sorted hash → 1..144）
    # 注意：clean.R 的 hashes = sort(unique(ft$participant))，与此处 uniq 一致
    assert list(num2hash.values()) == uniq

    # ---- 1) trial 级逐值对比 ----
    # 双方均保持 xlsx 原始行序；按 (hash, 行序) 对齐
    mine_by_subj = {}
    for r in rows:
        mine_by_subj.setdefault(num2hash[int(r["Subject"])], []).append(r)
    auth_by_subj = {}
    for r in at:
        auth_by_subj.setdefault(r["subject"], []).append(r)
    assert set(mine_by_subj) == set(auth_by_subj)
    n_rt = n_acc = n_match = n_task = n_shape = n_stim = 0
    acc_mismatch = 0
    for h in uniq:
        m = mine_by_subj[h]
        a = auth_by_subj[h]
        assert len(m) == len(a) == 360, (h, len(m), len(a))
        for mr, ar in zip(m, a):
            # Task / Shape(标签类) / Matching
            n_task += mr["Task"] == ar["Task"]
            n_shape += mr["ShapeCode"] == ar["Shape"]
            n_match += (mr["Matching"] == "Matching") == (ar["Matching"] == "1")
            # RT：库内 round(rt×1000) vs 作者 rt×1000（无响应双方均缺失）
            if mr["RT_ms"] == "NA":
                rt_ok = ar["mean_rt_mult"] in ("", "NaN", "NA")
            else:
                rt_ok = abs(float(mr["RT_ms"]) - float(ar["mean_rt_mult"])) < 1.0
            n_rt += rt_ok
            if not rt_ok:
                print("RT mismatch", h, mr["Trial"], mr["RT_ms"], ar["mean_rt_mult"])
            # ACC：作者 acc = corr，但 rt<200 ms 或无响应时被改为 0（分析
            # 口径，Associative_cleaning.R）。库内保留原值（最小预处理）：
            #   - 作者 acc==1 → 库内必须 1
            #   - 作者 acc==0 → 库内 0（真实错误）或 1 且 RT_ms<200（作者改
            #     值）或 NA（无响应）
            aacc = int(ar["acc"])
            macc = mr["ACC"]
            if aacc == 1:
                ok = macc == "1"
            else:
                ok = macc == "0" or (macc == "1" and int(mr["RT_ms"]) < 200) \
                     or macc == "NA"
            n_acc += ok
            if not ok:
                acc_mismatch += 1
                print("ACC mismatch", h, mr["Trial"], macc, ar["acc"])
            # stimuli
            n_stim += mr["Label"] == ar["stimuli"].replace("£", "£")
    N = 51840
    print(f"trial 级对比（{N} 行）:")
    print(f"  Task 一致      {n_task}/{N}")
    print(f"  ShapeCode 一致 {n_shape}/{N}")
    print(f"  Matching 一致  {n_match}/{N}")
    print(f"  RT_ms 一致     {n_rt}/{N}（|diff|<1 ms）")
    print(f"  ACC 一致       {n_acc}/{N}（作者 acc=1 必为 1；acc=0 可为 0/NA）")
    assert n_task == n_shape == n_match == n_rt == n_acc == N, "trial 级存在不一致！"

    # ---- 2) 聚合级对比（库内 raw 按作者 collapsed 口径重算） ----
    import collections
    # 作者口径（Associative_cleaning.R）：排除 rt<0.2 秒或无响应
    # （invalid_trials==2 子集）后，group_by(subject, Task, Shape, Matching)
    # → prop_acc=mean(corr)×100、mean_rt_mult=mean(rt)×1000；再按
    # group_by(subject, Task, stimuli) 对 Matching 两水平求均值。
    # 库内等价：RT_ms>=200 且 ACC 非 NA；RT_ms==200 的 round 边界行以作者
    # 精确 mean_rt_mult（<200 则作者排除）为准——round 显示差异（<0.5 ms）
    # 非数据差异，隔离后验证数据内容一致性。
    # mean_rt 用库内 RT_ms（round）→ 与作者未取整值均值差 <=0.5 ms。
    groups = collections.defaultdict(lambda: collections.defaultdict(list))
    for h in uniq:
        for mr, ar in zip(mine_by_subj[h], auth_by_subj[h]):
            if mr["RT_ms"] == "NA":
                continue
            rt = int(mr["RT_ms"])
            if rt < 200:
                continue
            if rt == 200 and ar["mean_rt_mult"] not in ("", "NaN", "NA") \
                    and float(ar["mean_rt_mult"]) < 200:
                continue
            groups[(h, mr["Task"], mr["ShapeCode"], mr["Matching"])]["rt"].append(rt)
            groups[(h, mr["Task"], mr["ShapeCode"], mr["Matching"])]["acc"].append(int(mr["ACC"]))
    long_rows = []
    for (h, task, shape, match), d in groups.items():
        long_rows.append((h, task, shape, match,
                          sum(d["acc"]) / len(d["acc"]) * 100.0,
                          sum(d["rt"]) / len(d["rt"])))
    coll = {}
    for h, task, shape, match, pa, rt in long_rows:
        stim = {"Self": "Self", "Friend": "Friend", "Stranger": "Stranger",
                "HighReward": "£9", "MediumReward": "£3", "LowReward": "£1",
                "Happy": "Happy", "Neutral": "Neutral", "Sad": "Sad"}[shape]
        coll.setdefault((h, task, stim), {"pa": [], "rt": []})
        coll[(h, task, stim)]["pa"].append(pa)
        coll[(h, task, stim)]["rt"].append(rt)
    ac = read_csv(auth_coll, None)
    auth_map = {}
    for r in ac:
        auth_map[(r["subject"], r["Task"], r["stimuli"])] = (r["prop_acc"], r["mean_rt_mult"])
    bad = 0
    for k, v in coll.items():
        if k not in auth_map:
            print("key missing in author collapsed:", k); bad += 1; continue
        pa_mine = sum(v["pa"]) / len(v["pa"])
        rt_mine = sum(v["rt"]) / len(v["rt"])
        pa_auth, rt_auth = float(auth_map[k][0]), float(auth_map[k][1])
        if abs(pa_mine - pa_auth) > 1e-6 or abs(rt_mine - rt_auth) > 1.0:
            bad += 1
            print("collapsed mismatch", k, pa_mine, pa_auth, rt_mine, rt_auth)
    print(f"聚合级对比（{len(coll)} 个 subject×Task×stimuli 组合）: 不一致 {bad}")
    assert bad == 0
    print("OK：库内数据与作者 trial 级及 collapsed 聚合逐值一致。")

if __name__ == "__main__":
    main()
