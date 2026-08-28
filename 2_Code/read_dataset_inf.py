#!/usr/bin/env python3
# ============================================================================
# 2_Code/read_dataset_inf.py — Dataset_inf.csv 统一读取入口（2026-08）
# ----------------------------------------------------------------------------
# 主索引 1_Data/Dataset_inf.csv 的格式约束：UTF-8 BOM + CRLF + QUOTE_MINIMAL
# （仅含逗号/特殊字符字段加引号）+ 末行无换行。本脚本封装这些细节：
#   - encoding="utf-8-sig"  剥离 BOM
#   - csv.DictReader        按列名取值（键=表头），列顺序无关
# 使用：
#   from read_dataset_inf import read_dataset_inf, find_rows
#   header, rows = read_dataset_inf()          # 全部行（每行一个 dict）
#   hits = find_rows(rows, "Liang_2022_HumBrainMap")   # 按 Folder_Name 过滤
#   hits = find_rows(rows, "Liang_2022_HumBrainMap", exp="1")
# CLI：python 2_Code/read_dataset_inf.py [--folder NAME] [--exp N]
#       默认打印列名清单与行数；--folder/--exp 时打印命中行的字段值。
# 注意：本脚本只读，绝不修改 CSV；写入请遵守 AGENTS.md「CSV 字节保真编辑
# 纪律」（QUOTE_MINIMAL 往返测试 + 去末尾换行 + header.index 定位列）。
# ============================================================================
import csv
import os
import sys


def dataset_inf_path():
    """定位 1_Data/Dataset_inf.csv：env SPE_DATABASE_ROOT > 从脚本位置向上探测。"""
    env = os.environ.get("SPE_DATABASE_ROOT", "")
    if env and os.path.isfile(os.path.join(env, "1_Data", "Dataset_inf.csv")):
        return os.path.join(env, "1_Data", "Dataset_inf.csv")
    d = os.path.dirname(os.path.abspath(__file__))
    while True:
        cand = os.path.join(d, "1_Data", "Dataset_inf.csv")
        if os.path.isfile(cand):
            return cand
        parent = os.path.dirname(d)
        if parent == d:
            raise FileNotFoundError(
                "Dataset_inf.csv not found (searched from " + __file__ + " upward)")
        d = parent


def read_dataset_inf(path=None):
    """返回 (header, rows)。

    header: 列名列表（BOM 已剥离，顺序即文件列序）
    rows:   数据行列表，每行是 {列名: 值} 的 dict（键=header 列名，与顺序无关）
    """
    path = path or dataset_inf_path()
    with open(path, encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        header = reader.fieldnames
        rows = [dict(r) for r in reader]
    return header, rows


def find_rows(rows, folder_name, exp=None):
    """按 Folder_Name（+ 可选 Exp 字符串）过滤行。返回 list。"""
    hits = [r for r in rows if r.get("Folder_Name") == folder_name]
    if exp is not None:
        hits = [r for r in hits if r.get("Exp") == exp]
    return hits


if __name__ == "__main__":
    args = sys.argv[1:]
    folder = None
    exp = None
    if "--folder" in args:
        folder = args[args.index("--folder") + 1]
    if "--exp" in args:
        exp = args[args.index("--exp") + 1]

    header, rows = read_dataset_inf()
    print(f"Dataset_inf.csv: {len(rows)} rows x {len(header)} columns")
    print("Columns:", ", ".join(header))
    if folder:
        hits = find_rows(rows, folder, exp)
        print(f"\n-- {folder}" + (f"|Exp{exp}" if exp else "") +
              f": {len(hits)} row(s) --")
        for r in hits:
            for c in header:
                print(f"  {c} = {r[c]}")
            print("  ---")
    else:
        print("\nAll Folder_Name|Exp:")
        for r in rows:
            print(f"  {r['Folder_Name']}|Exp{r['Exp']}")
