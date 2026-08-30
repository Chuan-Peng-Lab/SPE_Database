# ============================================================================
# Hobbs_2023_PsychMed — 独立清洗脚本：标准 raw/Clean/subj_info（Exp1）
# ----------------------------------------------------------------------------
# 背景（2026-08-30 阶段 5 入库）：Hobbs, Sui, Munafò, Kessler & Button,
# "Self processing in relation to emotion and reward processing in
# depression", Psychological Medicine, DOI 10.1017/s0033291721003597
# （2021 online first / 2023 print）。数据仓库 researchdata.bath.ac.uk/924/
# （CC BY 4.0，readme 声明；2018-10 至 2019-05 在 University of Bath 采集）。
#
# 任务（Associative Learning Task，Sui & Humphreys 2015b 式形状-标签匹配）：
#   三个条件任务（counterbalanced 顺序，group 列 A-F = 6 种顺序）：
#     Self    ：形状 ↔ 自己/朋友/陌生人名字
#     Valence ：形状 ↔ happy/neutral/sad 面孔（论文 "Emotion" 条件）
#     Reward  ：形状 ↔ £9/£3/£1（屏幕显示英镑符号；raw Label=9/3/1）
#   每任务 2 blocks × 60 trials = 120 试次；每被试 360 正式试次；n=144
#   （无被试级排除；论文试次级排除 RT<200 ms 0.8% + 无响应 8% 属分析口径，
#   库内最小预处理不过滤）。每任务匹配:非匹配 = 60:60（匹配组合 3×20、
#   非匹配组合 6×10）。
#
# 数据格式（输入区 xlsx 为权威——作者清洗脚本 Associative_cleaning.R 用
#   xlsx 读取；同名 csv 存在表示层差异【rt/keys/形状分配列 NA 表示不同】勿用）：
#   - 正式 trial 判定：trials.thisN 非 NA（与作者同口径；practice 及任务间
#     过渡行被剔除——practice 的 trial 数据（practice_resp.* 列）在匿名化
#     时被删除，练习试次数无法恢复，CSV Practice_Trial 留 NA）。
#   - Shape 列 = 当前 trial 呈现形状的标签类（Self/Friend/Stranger/
#     HighReward/MediumReward/LowReward/Happy/Sad/Neutral）；Target 列与之
#     完全相同（冗余，弃用）。
#   - Label 列 = 当前 trial 呈现的标签内容：Valence=情绪词（Happy/Sad/
#     Neutral）；Reward=货币数字（9/3/1）；Self=NA（真实名字被匿名化删除，
#     见 Associative_cleaning.R 注释 "Removing labels for self condition"）。
#   - CorrectAnswer = 程序判定（Yes=匹配/No=非匹配）→ Matching。
#   - 几何形状分配：每被试每任务 3 形状（Self 任务 {circle,square,triangle}、
#     Valence {star,rectangle,hexagon}、Reward {diamond,oval,pentagon}），
#     存于大写 *_shape 列（每被试恒定；小写 trial_shape_* 列在匿名化时
#     Valence/Reward 被删，勿用）。当前 trial 的几何形状 = 该 trial 标签类
#     对应任务的分配形状。
#   - 键分配：Yes/No 列 = 每被试 'm'/'n' 键映射（matching 应答键 = Yes 列值）。
#   - trial_resp.rt 单位秒、trial_resp.keys m/n（无响应 NA）、
#     trial_resp.corr 0/1。
#   - Block：论文 "Two blocks of 60 trials were completed per task"；
#     task_block.thisIndex 导出恒 0（不可用）→ Block = trials.thisN<60 ?
#     1 : 2。
#
# 身份映射（2026-08-30 用户决策）：
#   Self 条件：Self→Self、Friend→Close、Stranger→Stranger；
#   Valence 情绪面孔：→ NonPerson（非身份刺激，QJEP 家具先例）；
#   Reward 货币：£9/£3/£1 原样保留（Lee_2023 E2 先例）。
#   Shape 侧 Std = 该形状绑定的标签类身份（同 Label 侧，Zhang_2024 先例）。
#
# ACC 编码（方案 A）：1=正确 / 0=错误（范围内错键）/ NA=无反应（keys NA）。
#   无 -2/-3/-4 证据（仅 m/n 两键、无提前/超时记录）。RT_ms = round(rt*1000)
#   取整，无响应 NA。
#
# 验证守卫：总行数 51840 = 144×360；每被试 360（每任务 120 = 匹配 60 +
#   非匹配 60）；Valence/Reward 的 CorrectAnswer 与 Shape/Label 类一致性；
#   ACC 与 Response==CorrectResp 一致性（keys 非 NA）；RT 域值。
# 作者口径逐值验证（hobbs_verify/）：trial 级 vs associative_df_trial_anon
#   （Task/Shape/Matching/rt×1000/keys 有值时 ACC）、聚合级 vs
#   associative_long_matching_collapsed_anon（排除 rt<200 ms 与无响应后
#   Matching 合并的 prop_acc/mean_rt）、论文 Table 2 回归统计量复现。
#
# subj_info 人口学：来自作者聚合文件 associative_long_matching_collapsed_anon
#   （每被试 9 行重复，取首行可读值 age/gender/ethnicity/employment_status/
#   education——作者已由 qs 编码映射）；Handedness/Country/First_Language
#   数据中无 → "/"。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Hobbs_2023_PsychMed_clean.R
# 依赖包：readxl
# ============================================================================

# ---- 定位脚本目录（引导块，utils.R 依赖） ----
.args <- commandArgs(trailingOnly = FALSE)
.fa <- .args[grepl("^--file=", .args)]
.script_dir <- if (length(.fa)) dirname(sub("^--file=", "", .fa[1])) else getwd()
.ut <- file.path(dirname(.script_dir), "utils.R")   # 1_Data/utils.R
source(.ut)
ROOT <- spe_root(.script_dir)
STUDY_DIR <- file.path(ROOT, "1_Data", "Hobbs_2023_PsychMed")
RAW_DIR <- file.path(STUDY_DIR, "Hobbs_2023_PsychMed_raw")
IN_XLSX <- file.path(RAW_DIR, "Raw Anonymised Data", "Data",
                     "Associative Learning", "raw_associative_anon.xlsx")
AGG_CSV <- file.path(RAW_DIR, "Aggregated Data for Analysis", "Data",
                     "Associative Learning",
                     "associative_long_matching_collapsed_anon.csv")
stopifnot(file.exists(IN_XLSX), file.exists(AGG_CSV))

suppressMessages(library(readxl))

# ---- 读取原始数据（xlsx 权威） ----
raw <- as.data.frame(read_excel(IN_XLSX))
stopifnot(nrow(raw) == 58038)

# 正式 trial（剔除 practice 与任务间过渡行，同作者 Associative_cleaning.R）
ft <- raw[!is.na(raw$trials.thisN), ]
stopifnot(nrow(ft) == 51840)              # 144 × 360

# ---- Subject 编号：participant hash 排序 → 1..144 ----
hashes <- sort(unique(ft$participant))
stopifnot(length(hashes) == 144)
subj_no <- match(ft$participant, hashes)  # 映射表 = 排序后 hashes（脚本注释内嵌）

# ---- 几何形状分配（每被试每标签类恒定；取自对应任务行的 *_shape 列） ----
shape_cols <- list(
  Self    = c(Self = "Self_shape", Friend = "Friend_shape",
              Stranger = "Stranger_shape"),
  Valence = c(Happy = "Happy_shape", Sad = "Sad_shape",
              Neutral = "Neutral_shape"),
  Reward  = c(HighReward = "HighReward_shape",
              MediumReward = "MediumReward_Shape",
              LowReward = "LowReward_shape")
)
# 标签类 → 所属任务
class_task <- c(Self = "Self", Friend = "Self", Stranger = "Self",
                Happy = "Valence", Sad = "Valence", Neutral = "Valence",
                HighReward = "Reward", MediumReward = "Reward",
                LowReward = "Reward")
assign_shape <- vector("list", length(hashes))   # [[i]]: 标签类 -> 几何形状
for (i in seq_along(hashes)) {
  d <- ft[ft$participant == hashes[i], ]
  a <- list()
  for (task in names(shape_cols)) {
    dt <- d[d$Task == task, ]
    for (cls in names(shape_cols[[task]])) {
      v <- unique(dt[[shape_cols[[task]][[cls]]]])
      v <- v[!is.na(v)]
      stopifnot(length(v) == 1)                  # 每被试该任务该标签类形状恒定
      a[[cls]] <- as.character(v)
    }
  }
  assign_shape[[i]] <- a
}
shape_geo <- mapply(function(cls, i) assign_shape[[i]][[as.character(cls)]],
                    ft$Shape, subj_no, USE.NAMES = FALSE)

# ---- 标签映射（可读值 + Identity 三级；2026-08-30 用户决策） ----
label_eng <- c(Self = "self", Friend = "friend", Stranger = "stranger",
               Happy = "happy", Sad = "sad", Neutral = "neutral",
               HighReward = "£9", MediumReward = "£3", LowReward = "£1")
label_std <- c(Self = "Self", Friend = "Close", Stranger = "Stranger",
               Happy = "NonPerson", Sad = "NonPerson", Neutral = "NonPerson",
               HighReward = "£9", MediumReward = "£3", LowReward = "£1")
# Reward 的 raw Label 数字 → 标签类（9/3/1 ↔ High/Medium/LowReward）
reward_num_class <- c("9" = "HighReward", "3" = "MediumReward", "1" = "LowReward")

cls <- as.character(ft$Shape)                    # 标签类（raw Shape 列原值）
task <- as.character(ft$Task)
lbl_raw <- as.character(ft$Label)                # raw Label 列原值（字符）
# Label 可读值：Self 任务 = 类别名（名字被匿名化）；Valence = 情绪词小写；
# Reward = £ 值
lbl_readable <- ifelse(task == "Self", label_eng[cls],
                ifelse(task == "Valence", label_eng[cls],
                       label_eng[cls]))
# Label_Origin：Self "/"（原文不可得）；Valence = 原值；Reward = 数字原值
lbl_origin <- ifelse(task == "Self", "/", lbl_raw)
# Label_English / Label_Standardized（按标签类）
lbl_english <- unname(label_eng[cls])
lbl_std <- unname(label_std[cls])

# ---- Matching / 键 / ACC / RT ----
matching <- ifelse(ft$CorrectAnswer == "Yes", "Matching", "Nonmatching")
yes_key <- mapply(function(i) as.character(ft$Yes[subj_no == i][1]),
                  subj_no, USE.NAMES = FALSE)
# CorrectResp：Matching trial 应按 Yes 键，非匹配应按 No 键（每被试恒定）
corr_resp <- ifelse(matching == "Matching", yes_key,
                    ifelse(yes_key == "m", "n", "m"))
resp <- as.character(ft$trial_resp.keys)
resp[resp == "None"] <- NA          # PsychoPy 无响应记录为字符串 "None"
acc <- ifelse(is.na(resp), NA,
              ifelse(ft$trial_resp.corr == 1, 1, 0))
rt_ms <- ifelse(is.na(resp), NA, round(ft$trial_resp.rt * 1000))

# ---- Block / Trial ----
block <- ifelse(ft$trials.thisN < 60, 1, 2)      # 2 blocks × 60 trials
trial <- ave(seq_len(nrow(ft)), subj_no, FUN = seq_along)  # 全局 1..360

# ---- 逐被试守卫 ----
for (i in seq_along(hashes)) {
  d <- ft[ft$participant == hashes[i], ]
  stopifnot(nrow(d) == 360)
  tt <- table(d$Task);       stopifnot(all(tt == 120))
  tm <- table(d$Task, d$CorrectAnswer)
  stopifnot(all(tm == c("Yes" = 60, "No" = 60)))
}
# CorrectAnswer 与 Shape/Label 类一致性（Valence/Reward 可验证；Self Label NA）
lab_class <- ifelse(task == "Reward", reward_num_class[lbl_raw],
             ifelse(task == "Valence", lbl_raw, NA))
chk <- !is.na(lab_class)
stopifnot(all((matching[chk] == "Matching") == (cls[chk] == lab_class[chk])))
# ACC 与 Response==CorrectResp 一致性（keys 非 NA）
rchk <- !is.na(resp)
stopifnot(all((acc[rchk] == 1) == (resp[rchk] == corr_resp[rchk])))
# RT 域值：无响应外均 >= 0 且 <= 1100 ms（程序响应窗口；round 可将
# 极短 rt 取整为 0，按最小预处理保留）
stopifnot(all(rt_ms[!is.na(rt_ms)] >= 0),
          all(rt_ms[!is.na(rt_ms)] <= 1100))
# 每个 CorrectResp 值域
stopifnot(all(corr_resp %in% c("m", "n")))

# ---- 构建 raw（标准 trial 级：原始编码 + 可读值） ----
raw_out <- data.frame(
  Subject      = subj_no,
  Trial        = trial,
  Task         = task,
  Block        = block,
  Shape        = shape_geo,          # 几何形状名（由分配列恢复）
  ShapeCode    = cls,                # 标签类（raw Shape 列原值）
  Label        = lbl_readable,       # 标签可读值（self/friend/stranger,
                                     #   happy/sad/neutral, £9/£3/£1）
  LabelCode    = lbl_raw,            # raw Label 列原值（Self: NA; Valence:
                                     #   Happy/...; Reward: 9/3/1）
  Matching     = matching,
  ACC          = acc,
  RT_ms        = rt_ms,
  Response     = resp,
  CorrectResp  = corr_resp,
  stringsAsFactors = FALSE
)
stopifnot(nrow(raw_out) == 51840)

# ---- 构建 Clean（可读值 + Identity 三级） ----
clean_out <- data.frame(
  Subject = subj_no,
  Trial   = trial,
  Task    = task,
  Block   = block,
  Shape   = shape_geo,
  Label   = lbl_readable,
  Matching = matching,
  ACC      = acc,
  RT_ms    = rt_ms,
  Response = resp,
  Label_Origin_Identity        = lbl_origin,
  Label_English_Identity       = lbl_english,
  Label_Standardized_Identity  = lbl_std,
  Shape_Origin_Identity        = shape_geo,
  Shape_English_Identity       = shape_geo,
  Shape_Standardized_Identity  = unname(label_std[cls]),
  stringsAsFactors = FALSE
)
stopifnot(nrow(clean_out) == 51840)
# Clean 校验：Identity 三级完整、Std 值域合法
stopifnot(all(clean_out$Label_Standardized_Identity %in%
                c("Self", "Close", "Stranger", "NonPerson", "£9", "£3", "£1")),
          all(clean_out$Shape_Standardized_Identity ==
                clean_out$Label_Standardized_Identity))
# SPE 方向抽查（self 匹配最快，与论文 S1/S2 一致）
sp <- clean_out[clean_out$Task == "Self" & clean_out$Matching == "Matching", ]
sp_rt <- tapply(sp$RT_ms, sp$Label, mean, na.rm = TRUE)
cat("Self 条件匹配 RT (ms):", paste(names(sp_rt), round(sp_rt), collapse = " / "), "\n")
stopifnot(names(which.min(sp_rt)) == "self")     # self 最快

# ============================================================================
# subj_info（人口学自作者聚合文件可读值；Handedness/Country/First_Language 无）
# ============================================================================
agg <- read.csv(AGG_CSV, stringsAsFactors = FALSE, check.names = FALSE)
first_row <- agg[!duplicated(agg$subject), ]     # 每被试首行
demo <- first_row[match(hashes, first_row$subject), ]
stopifnot(nrow(demo) == 144)
info <- data.frame(
  Subject_ID        = seq_along(hashes),
  Exp_id            = "Hobbs_2023_PsychMed_Exp1",
  Age               = demo$age,
  Gender            = demo$gender,
  Handedness        = "/",
  Ethnicity         = demo$ethnicity,
  Employment_Status = demo$employment_status,
  Country           = "/",
  First_Language    = "/",
  Education         = demo$education,
  stringsAsFactors  = FALSE
)
cat("人口学：Male =", sum(demo$gender == "Male"), " Female =",
    sum(demo$gender == "Female"), "\n")

# ============================================================================
# 写出（单实验 → 研究根目录平放）
# ============================================================================
outs <- list(
  list(raw_out,  file.path(STUDY_DIR, "Hobbs_2023_PsychMed_Exp1_raw.csv")),
  list(clean_out,file.path(STUDY_DIR, "Hobbs_2023_PsychMed_Exp1_Clean.csv")),
  list(info,     file.path(STUDY_DIR, "Hobbs_2023_PsychMed_Exp1_subj_info.csv"))
)
for (o in outs) stopifnot(!file.exists(o[[2]]))
for (o in outs) write_clean_csv(o[[1]], o[[2]])
cat("完成：\n")
for (o in outs) cat("  ", o[[2]], "\n")
