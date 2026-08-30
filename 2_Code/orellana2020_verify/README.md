# ============================================================================
# Orellana-Corrales_2020_ExpPsych — 入库四方核对脚本（2026-08-30）
# ----------------------------------------------------------------------------
# 目标：以作者上传产物（OSF 3ke4f / umv5p）逐值核对库内重建数据，并复现论文
# 匹配任务全部统计量。
#
# 文件：
#   verify_lst.R   —— 用作者 exp1_MT.lst（整数均值）复现 Exp1（Study 1）2×2
#                     RM 分析：shape 52.48 / trial 15.00 / 交互 18.99（论文
#                     F(1,33)，精确复现）；matching 单因素 50.73（686/874）。
#   exp1_rest.R    —— Exp1 nonmatching F=7.68（806.88/858.12）与 d' F=28.95
#                     （论文精确值）。
#   exp2_full.R    —— 排除 Subject 24/30 后复现 Exp2（Study 2）2×2：
#                     shape 40.58 / trial 6.02 / 交互 6.42（论文精确值）。
#                     排除名单（24/30）为暴力枚举 33 选 2 组合、按论文
#                     match/nonmatch/d' 三统计量总差最小确定（论文未公开）。
#   verify_exp23.R —— Exp2 排除枚举（输出 best）+ Exp3 复现尝试（失败，
#                     见下方说明与 3_Reports/Orellana-Corrales_2020_ExpPsych_
#                     Author_DataIssue.md）。
#
# 口径（与作者 data_preparation_mt.py / util.py 一致）：
#   - label 分组 im/fm/in/fn（im = match & label==Ich 等）；
#   - RT 过滤：>200 ms 且 < per-VP Tukey 上限（hinge 法 q3+k×IQR，k 视 LST
#     而定：exp1/exp2_MT.lst 用 1.5，mt_data.lst 用 3）且 ACC==1；
#   - 格均值 = round(sum/n)（整数，与作者一致）；ER = 非正确试次计数。
#   - d'：loglinear（hits+0.5 与 FA+0.5，分母 33 = 32 试次 + 1），z 差。
#
# 复现结果（库内数据 = 作者聚合 = 论文统计量）：
#   Exp1：2×2 F(1,33) = 52.48 / 15.00 / 18.99；matching 50.73（686/874）；
#         nonmatching 7.68（806.88/858.12）；d' 28.95 —— 全部精确。
#   Exp2：排除 24/30 后 F(1,30) = 40.58 / 6.02 / 6.42；matching 29.72
#         （765.45/934.10）；nonmatching 2.67；d' 13.95 —— 全部精确。
#   Exp3：未能复现（论文 F(1,33) = 22.97 / 4.819 / 28.88 等）。原因：
#         ① OSF 上传的 mt_data.lst 为未修正编号的中间产物（17 行，Subject 1
#           行 = 20 个 session 合并聚合，imACC=560 等），16 行版分析给出
#           18.4/3.26/32.84（df=15）与论文不符；② 库内修正编号 36 人数据中
#           Subject 7/9/14 存在某格 0 个正确试次（低表现，任何过滤口径下均
#           缺格），使"36-2=34 人无缺格分析"不可能；③ 作者 mt_data.sav
#           （SPSS 分析文件）未上传，实际分析数据版本不可考。详见
#           3_Reports/3_Reports/Verifying_original_results_issues.md（Issue 2）。
# ============================================================================
