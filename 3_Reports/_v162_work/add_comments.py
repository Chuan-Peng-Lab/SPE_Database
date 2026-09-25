# -*- coding: utf-8 -*-
"""Step 1: add reviewer comments (author czx) to v16.2 at every substantive change."""
import os
import time

import win32com.client as win32

SRC = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2.docx'
TMP = r'D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\_v162_commented_raw.docx'

# (unique anchor text in the NEW document, comment text)
COMMENTS = [
    ("49 studies (89 experiment-level datasets, 4,875 participants",
     "【规模数字·摘要】旧稿：44 studies / 70 experiments / 3,603 participants / 1,554,083 trials。"
     "现按 Dataset_inf.csv（107 条实验×被试组）与 1_Data 下 89 个 *_Clean.csv 实测："
     "49 studies / 89 experiment-level datasets / 4,875 participants / 2,131,108 test trials。"
     "末句对三个示例的总括也一并改写（试次数不再是可靠调节变量）。"),

    ("comprising 89 experiment-level datasets, were included",
     "【规模数字·引言】同步改为 49 studies / 89 experiment-level datasets。"),

    ("Each row in this file represents one experiment-by-participant-group unit",
     "【主索引语义】旧稿：每行 = 一项研究，主键为 Paper_Id。实况：Paper_ID 列已从 Dataset_inf.csv 移除，"
     "每行 = 一个实验×被试组，唯一键为 Folder_Name + Exp + subj_Group（拼接成 ID 列）。已按实况改写。"),

    ("the theoretical background, a summary of the study, its main conclusion",
     "【paper JSON 内容】旧稿称 paper JSON 含「招募策略、招募流程、纳入与排除标准」，"
     "但现行 schema 是 11 个扁平字段（Paper_name/Summary/Year/Author/Journal/Country/City/"
     "Extra_Var/Email/DOI/Conclusion），全库无一份含招募或纳入排除字段。已改为与 schema 一致的描述。"),

    ("Amodeo_2024_CABN_Exp1_subj_info.csv",
     "【五件套命名】旧稿示例 *_Exp1_raw_Subject.csv 与 *_Exp1_Clean.xlsx 在库内 0 个文件。"
     "现行语法：人口学 = *_subj_info.csv；codebook = Codebook_*_Clean.xlsx。示例已更正。"),

    ("Ratcliff et al., 2016), and allow",
     "【拼写】Ratchliff et al., 2016 → Ratcliff et al., 2016。"),

    ("In the current release (September 2026), the database contains 49 studies",
     "【规模数字·数据概览】旧稿：4 studies with 70 datasets / 3,603 人 / 1,554,083 试次（首句「4 studies」为笔误）。"
     "现按主索引重算：49 studies、107 条实验×被试组（89 个实验级数据文件）、4,875 人、2,131,108 个测试试次。"),

    ("Note. N = number of participants retained in the minimally preprocessed",
     "【Table 1 注】Table 1 已由 Generate_Table1_v2.R 从 Dataset_inf.csv 重生成（94 行 → 107 行）。"
     "原注中的 k 在表内不存在，已改为说明 N / Trials / Exp_Implement 三个口径。"),

    ("standardized into six categories",
     "【身份类别数】旧稿写 five categories 却列了 6 个（Self/Close/Acquaintance/Celebrity/Stranger/NonPerson），已改为 six。"),

    ("Because participant identifiers are unique only within a dataset",
     "【例1 分析口径】新增说明：RT 仅用正确试次且 0 < RT ≤ 10,000 ms；ACC 仅用有效反应（0/1）；"
     "被试随机效应改为「嵌套于数据集」。原因：Subject 编号只在单个数据集内唯一"
     "（89 个 Clean 文件仅 1,441 个不同 Subject 值，却有 4,521 个数据集×被试组合），"
     "按裸 Subject 分组会把不同研究里编号相同的不同被试合并成一个人。"),

    ("Figure 4. Self-prioritization effects along the social distance continuum",
     "【图替换】已换为 v2 版本：3_Reports/Output/Pic/p_ridges_pairwise_combined_11_v2.png。"),

    ("For reaction time (RT), the SPE was positive for all five baseline conditions",
     "【例1 结果】v2 重跑后五个基线的 SPE 仍全部为正（95% CI 均不含 0），但跨引用编号已统一为 Figure 4 / 4C / 4D。"),

    ("For RT, 3 of the 10 pairwise comparisons were statistically significant",
     "【例1 结果·RT】旧稿：8/10 显著、Celebrity 最强。v2 重跑：3/10 显著，"
     "且三条全部是「某基线 > Close others」（NonPerson Δ=0.089、Celebrity Δ=0.078、Stranger Δ=0.071）；"
     "NonPerson / Stranger / Celebrity 两两之间均不显著。"),

    ("Six of the 10 pairwise comparisons reached statistical significance for accuracy",
     "【例1 结果·ACC】v2 重跑：6/10 显著，其中 NonPerson 高于其余四个基线；"
     "旧稿中 Celebrity 高于 Close/Acquaintance、Stranger 高于 Acquaintance 等结论不再成立。"),

    ("the baselines did not order themselves along a clear social-distance gradient",
     "【例1 结论】旧稿「三档梯度、Celebrity 最强（8/10 显著）」不再成立，已改写为"
     "「五基线全为正，但只有最强 vs 最弱可比」。并加入覆盖度告警：NonPerson 8 个数据集、"
     "Celebrity 3 个、Acquaintance 2 个，而 Stranger 70 个、Close 50 个。"),

    ("89 experiment-level datasets, 1,068,081 nonmatching trials, 4,520 participants",
     "【例2 数据量】旧稿：72 experiments / 853,015 nonmatch trials / 1,676 participants。"
     "现：89 datasets / 1,068,081 失配试次 / 4,520 名被试。本段还补充了 RT 窗口、ACC 口径与被试唯一键说明。"),

    ("38 datasets contributed to the conservative shape-based analysis",
     "【例2 纳入量】旧稿：63 experiments / 303,331（shape）与 199,271（label）试次。"
     "v2 重算：保守法 shape 38 个数据集 / 1,977 人 / 371,894 试次，label 27 个数据集 / 1,565 人 / 276,010 试次；"
     "并补充自由法纳入量（85 与 69 个数据集）。"),

    ("To ensure a fair comparison between shape-based and label-based SPE",
     "【跨引用】原写「see table 3」，稿件中无 Table 3，已改为 Table 2。"),

    ("Figure 5. Bootstrap estimation of the self-prioritization effect under nonmatching",
     "【图替换】已换为 v2 版本：3_Reports/Output/Pic/combined_figures_v6_v2.png。"),

    ("Note. For RT, d = (Mean_Stranger",
     "【Table 2 注】原表题为「Table / Summary of Liberal Approach Results」（无编号且只覆盖一种方法），"
     "现编号为 Table 2 并改名。注中补充「not reached」含义，图引用由 Figure 4 改为 Figure 5。"),

    ("Using the conservative approach, a robust SPE was observed",
     "【例2 保守法结果】数值全部更新：label-RT d=0.252 [0.227, 0.275]（N=1,563，N min=20）、"
     "shape-RT d=0.123 [0.103, 0.144]（N min=40）、ACC shape d=0.052 [0.035, 0.070]（N min=170）、"
     "ACC label d=0.049 [0.030, 0.069]（N min=210）。"
     "另删除了旧稿「label 与 shape 差值 0.172 [0.132, 0.214]」——该区间无法从新模型直接得到，改为描述性比较。"),

    ("When applying the liberal approach, the label-based SPE was again evident",
     "【例2 自由法结果】label-RT d=0.125 [0.112, 0.138]（N=3,192，N min=40）。"
     "**结论变化**：旧稿自由法 shape-RT 显著（d=0.023, N=964, N min=630），"
     "现 d=0.005、CI 全程含 0；ACC 两个方向也都不显著（0.009 / 0.009）。"),

    ("Collectively, the presence of a SPE on nonmatching trials depended both on",
     "【例2 总结】按新结果重写：保守法下 RT 与 ACC 都有 SPE，自由法下只剩 label-RT；"
     "并把差异归因于对照条件中残留的自我参照信息。"),

    ("Two datasets were excluded before analysis",
     "【例3 排除规则】新增说明：排除 Pan_2025_unpub 与 Wang_2016_JEPHPP，"
     "并对 Stranger 基线 Cohen's dz 做 |z|>3 离群剔除；同时明确 dz 以 Stranger 为基线。"),

    ("The association between stimulus presentation duration and SPE magnitude was negative",
     "【例3 时长】数据源改为在 89 个 Clean 文件上重跑的 Output/11。"
     "区间由 100–1,500 ms / n=40 改为 100–3,000 ms / n=54；"
     "RT ρ=−.311, CI [−.539, −.052], p_boot=.018；ACC ρ=−.335, CI [−.548, −.095], p_boot=.010。"
     "负相关结论保留。"),

    ("In contrast, the maximum number of trials in a dataset was not reliably associated",
     "【例3 试次数——本次改动最大的一处】旧稿报告显著正相关（RT ρ=.374, p=.010；ACC ρ=.389, p=.016；"
     "剔除最大 3 个数据集后仍显著）。v2 重跑后：RT ρ=.045, p=.727；ACC ρ=.174, p=.165；"
     "敏感性分析（去 3 个最大试次数）RT ρ=.077, p=.560、ACC ρ=.195, p=.132。"
     "该段原结论已删除，改为「无可靠关联」。"),

    ("Together, these exploratory findings indicate that the magnitude of the SPE varies",
     "【例3 总结】与上一段同步改写：只保留「时长与 SPE 负相关」，试次数改为「无可靠关联」，"
     "并说明无效应不等于非线性关系不存在。"),

    ("Figure 6. Exploratory moderators of the self-prioritization effect under matching",
     "【图替换】已换为 v2 版本：3_Reports/Output/Pic/Figure_Exploratory_Moderators_Main_v2.png"
     "（数据源 Datasets/8_Exploratory_Analysis/Output/11）。"),

    ("We found that the SPE was reliably positive against every baseline condition",
     "【讨论】三句总结与例1–例3 的 v2 结果对齐（例3 不再声称试次数与 SPE 相关）。"),

    ("Overview of Studies Included in the SPE Database",
     "【Table 1 重生成】94 行 → 107 行。新增：Hu_2023_psyarxiv Exp3a/3b/4a/6b、"
     "Lee_2026_BritJPsy Exp1a/1b/2、Zhao_2026_PsychonBullRev Exp1/2/3；"
     "移除：Hu_2023_psyarxiv Exp1、Sui_2015_unpub Exp2；Bukowski Exp1 由 1 行拆为 4 行（按被试组）。\n"
     "另有 41 处单元格修正，例如：Constable_2021_CogEmo Exp1 刺激 grey scale squares → face"
     "（该实验 JSON 明确为面部表情刺激）；Feldborg_2021 两组 N 48/54 → 53/49；"
     "Bukowski_2021 Exp1 语言 English → German；Smith_2024_Cortex Trials NA → 360。"),

    ("Bootstrap Estimates of the Self-Prioritization Effect Under Nonmatching Conditions",
     "【Table 2】8 行数值全部替换为 v2 重跑结果（mismatch_bootstrap_summary_v2.csv）；"
     "保守法 N max 由 667/647 改为 1,563/1,494，自由法由 964/861/952/848 改为 3,604/3,192/3,524/3,114。"),

    ("Bogacz, R., Brown, E., Moehlis",
     "【参考文献·新增】正文引用了 Bogacz et al. (2006) 但文献表里没有，已补："
     "Psychological Review, 113(4), 700–765, doi:10.1037/0033-295X.113.4.700（Crossref 核验）。"),

    ("Markus, H. R., & Kitayama, S. (1991)",
     "【参考文献·勘误】原稿列为「Rose, H. (1991). Culture and the self… 1–30.」——作者张冠李戴且缺期刊。"
     "实为 Markus & Kitayama (1991), Psychological Review, 98(2), 224–253, doi:10.1037/0033-295X.98.2.224；"
     "正文中的 (Rose, 1991) 也已同步改为 (Markus & Kitayama, 1991)。"),

    ("Inclusion of Other in the Self Scale and the structure of interpersonal closeness",
     "【参考文献·勘误】原缺期刊、页码写作 1–17。已补：Journal of Personality and Social Psychology, "
     "63(4), 596–612, doi:10.1037/0022-3514.63.4.596。"),

    ("Big-team science does not guarantee generalizability",
     "【参考文献·勘误】原缺期刊页码、DOI 重复前缀、作者不全。已改为："
     "Ghai, S., Forscher, P. S., & Hu, C.-P. (2024). Nature Human Behaviour, 8(6), 1053–1056, "
     "doi:10.1038/s41562-024-01902-y；正文引用改为 (Ghai et al., 2024)。"),

    ("Pervasive failure to report properties of visual stimuli",
     "【参考文献·勘误】原缺期刊页码。已补：Psychological Bulletin, 149(7–8), 487–505, "
     "doi:10.1037/bul0000399。"),

    ("A dataset of cognitive ontology for neuroimaging studies of self-reference",
     "【参考文献·去重】原稿有两条 Sun et al. (2023)（同一 DOI，标题/作者写法不同），已合并为一条；"
     "作者统一为 Sun, S., Wang, N., Wen, J., & Hu, C.-P.。"),
]

word = win32.gencache.EnsureDispatch('Word.Application')
word.Visible = False
word.DisplayAlerts = 0
word.UserName = 'czx'
word.UserInitials = 'czx'

doc = word.Documents.Open(SRC, False, False)
time.sleep(1)

ok, miss = 0, []
for anchor, text in COMMENTS:
    rng = doc.Content
    f = rng.Find
    f.ClearFormatting()
    f.Text = anchor
    f.Forward = True
    f.Wrap = 0            # wdFindStop
    f.MatchCase = True
    f.MatchWildcards = False
    if f.Execute():
        doc.Comments.Add(rng, text)
        ok += 1
    else:
        miss.append(anchor[:50])

print('comments added:', ok, '/', len(COMMENTS))
if miss:
    print('NOT FOUND:')
    for m in miss:
        print('   -', m)
doc.SaveAs2(TMP, 16)
doc.Close(False)
word.Quit()
print('saved ->', TMP)
