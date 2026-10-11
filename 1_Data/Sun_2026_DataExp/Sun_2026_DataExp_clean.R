#!/usr/bin/env Rscript
# =============================================================================
# Sun_2026_DataExp_clean.R — Sun_2026_DataExp：由已入库 raw 分片生成 Clean + subj_info
# -----------------------------------------------------------------------------
# 规则正文：.agents/skills/spe-database-curation/SKILL.md
#           （模板 v2 列序 / Identity 三级标准化 / ACC 统一编码 / 大文件拆分）
# 执行依据：3_Reports/Sun_2026_DataExp_Ingestion_Plan.md（§8 交集口径为最终口径）
# 既往证据：Sun_2026_DataExp_Raw/04_code_and_reproducibility/removed_subjects_log.md
#           （§7 两来源差异与双跑个案、§8 交集口径）
#
# 脚本位置：1_Data/Sun_2026_DataExp/Sun_2026_DataExp_clean.R（库内约定：清洗脚本随研究文件夹）
# 输入（**已入库、可跟踪**的产物，唯一数据输入）：
#   1_Data/Sun_2026_DataExp/Sun_2026_DataExp_Exp1_raw_part1..4.csv
# 输出：
#   Sun_2026_DataExp_Exp1_Clean.csv        （写盘后由 2_Code/split_clean_csv.py 按被试边界分片）
#   Sun_2026_DataExp_Exp1_subj_info.csv
# Codebook 由 2_Code/make_codebooks.R 依 Clean 生成（单 Sheet1、4 列、行序 == Clean 列序）。
#
# 设计说明：raw 的来源与构建（两任务整合、并集→交集口径、双跑与幽灵记录处置）已固化在 raw
#   分片本身，并由 removed_subjects_log.md §7/§8 与 exp JSON detail 记录；本脚本只做
#   raw → Clean 的标准化，因此在没有输入区（Sun_2026_DataExp_Raw/，被 gitignore）的 clone 中
#   同样可重跑。**交集口径为本研究特例（不写入 SKILL）**：仅保留同时完成 Session 2
#   （Task1 = SMT_1 / Day 2）与 Session 3（Task2 = SMT_2 / Day 3）的 589 名被试；92 名仅-Session 2
#   被试与 1 条仅-Session 3 的空 ID 幽灵记录（phase_015_subj_ghost01）已排除，且不在 raw 分片中。
#
# Clean 列（模板 v2，20 列）与映射规则：
#   Subject, Session, Task, Phase, Matching, Shape, Shape-{Origin,English,Standardized}_Identity,
#   Label, Label-{Origin,English,Standardized}_Identity, extraIV1, extraIV2, CorrResponse,
#   Response, RT_ms, RT_sec, ACC
#     Session 2（Task1，shape-matching）：Phase = screen_id；Matching = conditionType；
#       Shape = condition（英文形状键）；Label = 程序实际呈现的中文形状词（SMT_1.js words1）；
#       Shape/Label Identity 三层 = NonPerson（该任务无身份维度）；extraIV1/2 = NA；
#       CorrResponse = 由逐被试按键 counterbalance 映射完整推出（match/nonmatch -> f/j；
#         两种映射各占一半：307 人 match=f、282 人 match=j；映射由 raw 自身答对试次判定，
#         对全部 516,864 行零矛盾，故含无反应行在内全部行均可给出）
#     Session 3（Task2，self-matching）：Phase = task_id；Matching = identity；
#       Shape = Image（去 img/ 前缀与 .png 后缀）；Label = word（中文标签，呈现词）；
#       Shape Identity 由 condition 的代词解码、Label Identity 由 word 的代词解码；
#       extraIV1 = domain（好/坏=moral，强/弱=ability）、extraIV2 = valence（好/强=positive，坏/弱=negative）
#       —— 与作者 QC 脚本 590_to_503_subject_qc.py 的 decompose_condition() 完全一致；
#       CorrResponse = correct_response
#   两侧共有：Response = f/j（其余 -> NA）；RT_ms/RT_sec 来自 rt；ACC = 1/0/NA（原 correct 逻辑值）。
# =============================================================================
suppressMessages(library(data.table))

# ---- 0. 路径自适应（Rscript --file= 场景下不依赖 cwd） ----
args <- commandArgs(trailingOnly = FALSE)
fa <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(fa)) dirname(normalizePath(sub("^--file=", "", fa[1]))) else getwd()
# 本脚本位于研究文件夹内（库内约定：1_Data/<Folder_Name>/<Folder_Name>_clean.R）；兼容从 2_Code 运行的旧布局
study_dir <- if (basename(script_dir) == "Sun_2026_DataExp") {
  normalizePath(script_dir)
} else {
  normalizePath(file.path(script_dir, "..", "1_Data", "Sun_2026_DataExp"))
}
repo_root <- normalizePath(file.path(study_dir, "..", ".."))
EOL <- "\r\n"   # 本研究 Clean/subj_info 约定：UTF-8 无 BOM + CRLF + 末行有换行

fmt_num <- function(x, digits = NULL) {
  ifelse(is.na(x), "NA",
         if (is.null(digits)) format(x, scientific = FALSE, trim = TRUE)
         else sprintf(paste0("%.", digits, "f"), x))
}

# =============================================================================
# 1. 读取 raw 分片（唯一数据输入）
# =============================================================================
parts <- file.path(study_dir, sprintf("Sun_2026_DataExp_Exp1_raw_part%d.csv", 1:4))
stopifnot(all(file.exists(parts)))
raw <- rbindlist(lapply(parts, function(p) fread(p, encoding = "UTF-8", showProgress = FALSE)),
                 use.names = TRUE)
stopifnot(names(raw)[1] == "Subject")
need <- c("Subject","Session","Task","task_id","screen_id","condition","word","response","rt",
          "correct","conditionType","identity","correct_response","Image","Sex")
stopifnot(all(need %in% names(raw)))

# ---- 1.1 结构守卫（交集口径：589 人 x 2 会话） ----
stopifnot(nrow(raw) == 1040880L, uniqueN(raw$Subject) == 589L)
stopifnot(all(raw$Session %in% c("2", "3")), all(raw$Task %in% c("shape-matching", "self-matching")))
stopifnot(sum(raw$Session == "2") == 516864L, sum(raw$Session == "3") == 524016L)
pairs <- unique(raw[, .(Subject, Session)])
stopifnot(nrow(pairs) == 1178L, all(table(pairs$Subject) == 2L))
# 交集口径下应已排除的记录不得出现
stopifnot(!any(c("phase_003_subj_14","phase_017_subj_20","phase_015_subj_ghost01") %in% raw$Subject))
stopifnot(!any(raw$Subject == "NA"), all(nzchar(raw$Subject)))

a1 <- raw[Session == "2"]; a2 <- raw[Session == "3"]
stopifnot(nrow(a1) == 516864L, nrow(a2) == 524016L)
stopifnot(all(a1$conditionType %in% c("match", "nonmatch")))
stopifnot(all(a2$identity %in% c("match", "nonmatch")))
stopifnot(uniqueN(a1$condition) == 8L, all(unique(a1$word) %in% unique(a1$condition)))
stopifnot(uniqueN(a2$Image) == 8L, all(grepl("^img/.+\\.png$", unique(a2$Image))))
stopifnot(uniqueN(a2$condition) == 12L, uniqueN(a2$word) == 12L)

# ---- 1.2 Task1 正确反应键映射（按键 counterbalance 逐被试固定） ----
# 作者 task 级文件未直接发布 correct_response 列，但该信息可由设计映射完整恢复：
# 每名被试的 match/nonmatch -> f/j 映射固定（counterbalance），且可用 raw 自身的
# conditionType/response/correct 三列无矛盾地判定。
keytab <- a1[response %in% c("f", "j") & correct == TRUE,
             .(n_keys = uniqueN(response), k = response[1]), by = .(Subject, conditionType)]
stopifnot(all(keytab$n_keys == 1L))                       # 同被试同条件下正确键唯一
stopifnot(all(keytab[, .N, by = Subject]$N == 2L))        # 每被试两种条件均可判定
km <- dcast(keytab, Subject ~ conditionType, value.var = "k")
stopifnot(nrow(km) == 589L, !anyNA(km$match), !anyNA(km$nonmatch), all(km$match != km$nonmatch))
cresp1 <- ifelse(a1$conditionType == "match",
                 km$match[match(a1$Subject, km$Subject)],
                 km$nonmatch[match(a1$Subject, km$Subject)])
stopifnot(all(cresp1 %in% c("f", "j")))
resp1 <- a1$response; has_resp <- resp1 %in% c("f", "j")
stopifnot(all((resp1[has_resp] == cresp1[has_resp]) == a1$correct[has_resp]))   # 逐行自洽（零矛盾）

# ---- 1.3 Task2 身份/领域/效价解码（与作者 QC 脚本同规则） ----
decode <- function(x) {
  lead <- substr(x, 1, 1); pron <- substr(x, 2, 2)
  stopifnot(all(lead %in% c("好","坏","强","弱")), all(pron %in% c("我","他","她")))
  list(domain  = ifelse(lead %in% c("好","坏"), "moral", "ability"),
       valence = ifelse(lead %in% c("好","强"), "positive", "negative"),
       person  = ifelse(pron == "我", "self", "friend"))
}
d_cond <- decode(a2$condition)   # 形状侧（该 trial 形状所绑定的标签）
d_word <- decode(a2$word)        # 标签侧（实际呈现的词）
std_of <- function(person) ifelse(person == "self", "Self", "Close")
eng_of <- function(pron)   ifelse(pron == "我", "Self", "Friend")
zh_shape <- c(circle = "圆形", diamond = "菱形", square = "方形", triangle = "三角",
              ellipse = "椭圆", hexagon = "六边", pentagon = "五边", trapezoid = "梯形")  # SMT_1.js words1

# =============================================================================
# 2. Clean（模板 v2 列序，20 列）
# =============================================================================
c1 <- data.table(
  Subject     = a1$Subject,
  Session     = "2",
  Task        = "shape-matching",
  Phase       = a1$screen_id,
  Matching    = ifelse(a1$conditionType == "match", "Matching", "Nonmatching"),
  Shape       = a1$condition,
  Shape_Origin_Identity = "NonPerson", Shape_English_Identity = "NonPerson",
  Shape_Standardized_Identity = "NonPerson",
  Label       = unname(zh_shape[a1$word]),
  Label_Origin_Identity = "NonPerson", Label_English_Identity = "NonPerson",
  Label_Standardized_Identity = "NonPerson",
  extraIV1    = "NA",
  extraIV2    = "NA",
  CorrResponse = cresp1,
  Response    = ifelse(a1$response %in% c("f", "j"), a1$response, "NA"),
  RT_ms       = fmt_num(a1$rt),
  RT_sec      = fmt_num(a1$rt / 1000, 3),
  ACC         = ifelse(is.na(a1$correct), "NA", ifelse(a1$correct, "1", "0"))
)
c2 <- data.table(
  Subject     = a2$Subject,
  Session     = "3",
  Task        = "self-matching",
  Phase       = a2$task_id,
  Matching    = ifelse(a2$identity == "match", "Matching", "Nonmatching"),
  Shape       = sub("\\.png$", "", sub("^img/", "", a2$Image)),
  Shape_Origin_Identity = d_cond$person,
  Shape_English_Identity = d_cond$person,
  Shape_Standardized_Identity = std_of(d_cond$person),
  Label       = a2$word,
  Label_Origin_Identity = a2$word,
  Label_English_Identity = eng_of(substr(a2$word, 2, 2)),
  Label_Standardized_Identity = std_of(d_word$person),
  extraIV1    = d_cond$domain,
  extraIV2    = d_cond$valence,
  CorrResponse = ifelse(a2$correct_response %in% c("f", "j"), a2$correct_response, "NA"),
  Response    = ifelse(a2$response %in% c("f", "j"), a2$response, "NA"),
  RT_ms       = fmt_num(a2$rt),
  RT_sec      = fmt_num(a2$rt / 1000, 3),
  ACC         = ifelse(is.na(a2$correct), "NA", ifelse(a2$correct, "1", "0"))
)
v2_order <- c("Subject","Session","Task","Phase","Matching","Shape",
              "Shape_Origin_Identity","Shape_English_Identity","Shape_Standardized_Identity",
              "Label","Label_Origin_Identity","Label_English_Identity","Label_Standardized_Identity",
              "extraIV1","extraIV2","CorrResponse","Response","RT_ms","RT_sec","ACC")
stopifnot(identical(names(c1), v2_order), identical(names(c2), v2_order))
clean <- rbindlist(list(c1, c2), use.names = TRUE)

# ---- 2.1 行序：按 Subject 字母序（同一被试内 Session 2 先于 3），保证整被试分片 ----
clean[, .row := .I]; setorder(clean, Subject, Session, .row); clean[, .row := NULL]

# ---- 2.2 内容守卫 ----
stopifnot(nrow(clean) == 1040880L, uniqueN(clean$Subject) == 589L, ncol(clean) == 20L)
stopifnot(all(clean$Matching %in% c("Matching", "Nonmatching")))
stopifnot(all(clean$ACC %in% c("0", "1", "NA")), all(clean$Response %in% c("f", "j", "NA")))
stopifnot(all(clean$CorrResponse %in% c("f", "j")))        # 两侧正确反应键均完整（无 missing）
stopifnot(uniqueN(clean$Shape) == 8L, uniqueN(clean$Label) == 20L)   # 8 形状词 + 12 身份标签
stopifnot(all(clean$Session[clean$Task == "shape-matching"] == "2"),
          all(clean$Session[clean$Task == "self-matching"] == "3"))
stopifnot(all(clean$Shape_Standardized_Identity[clean$Task == "shape-matching"] == "NonPerson"))
stopifnot(all(clean$Shape_Standardized_Identity[clean$Task == "self-matching"] %in% c("Self", "Close")))

# =============================================================================
# 3. subj_info（589 行，与 Clean 对齐；Gender 来自 raw 的 Sex 列）
# =============================================================================
sex_map <- unique(a2[!is.na(Sex) & Sex != "", .(ID = Subject, Sex)])
sex_map <- sex_map[!duplicated(ID)]
subjects <- sort(unique(clean$Subject))
subj_info <- data.table(
  Subject_ID = subjects,
  Exp_id = "Sun_2026_DataExp_Exp1",
  Age = "/",
  Gender = ifelse(subjects %in% sex_map$ID, sex_map$Sex[match(subjects, sex_map$ID)], "/"),
  Handedness = "/", Ethnicity = "/", Employment_Status = "/",
  Country = "/", First_Language = "/", Education = "/"
)
stopifnot(nrow(subj_info) == 589L, !anyDuplicated(subj_info$Subject_ID),
          sum(subj_info$Gender != "/") == 589L, all(subj_info$Gender %in% c("Male", "Female")))

# =============================================================================
# 4. 写盘（UTF-8 无 BOM + CRLF）；分片由 2_Code/split_clean_csv.py 处理
# =============================================================================
fwrite(clean, file.path(study_dir, "Sun_2026_DataExp_Exp1_Clean.csv"), eol = EOL)
fwrite(subj_info, file.path(study_dir, "Sun_2026_DataExp_Exp1_subj_info.csv"), eol = EOL)
cat("WROTE Clean rows:", nrow(clean), "| cols:", ncol(clean),
    "| subjects:", uniqueN(clean$Subject), "| subj_info rows:", nrow(subj_info), "\n")
cat("Gender:", paste(names(table(subj_info$Gender)), table(subj_info$Gender), collapse = " / "), "\n")
cat("PASS: Sun_2026_DataExp_clean.R (raw -> Clean)\n")
