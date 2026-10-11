# ============================================================================
# Orellana-Corrales_2021_APP — 独立清洗脚本（Exp1 + Exp2）：重建标准 *_raw.csv
# ----------------------------------------------------------------------------
# 背景（2026-08 阶段 4 raw 追补）：本研究此前仅有 Clean/subj_info/Codebook/JSON，
# 无标准 trial 级 *_raw.csv。OSF 官方仓库（g7wrc = Exp1/Study 1 shapes，
# 4cwrv = Exp2/Study 2 nonwords）的 storage archive 已下载至输入区
# （Orellana-Corrales_2021_APP/Exp1_g7wrc-osfstorage-archive/、
#  Orellana-Corrales_2021_APP/EXP2_4cwrv-osfstorage-archive/），本脚本从
# E-Prime 文本导出（UTF-16LE 的 *_txt）解析匹配任务（matching task）trial 级
# 数据，重建标准 raw.csv。
#
# 相对原始导出的处理：
#   1. 仅提取匹配任务：每个 LogFrame 块中 Procedure == Matching 的块
#      （练习块 Procedure == Prac 不提取；论文：4 练习 + 128 实验试次）。
#   2. 字段映射（E-Prime 原始名 → raw 列）：
#        label  -> Label（Ich/Fremder，德语原文）
#        shape  -> Shape（Exp1；Kreis.png/Dreieck.png）
#        nonword-> Nonword（Exp2；非词字符串）
#        match  -> Matching（"match"/"nonmatch" -> "Matching"/"Nonmatching"，
#                          与库内 Clean 值域一致）
#        MT.ACC -> ACC（1 正确 / 0 错误，E-Prime 原始编码，最小预处理保留）
#        MT.RT  -> RT_ms（无反应时 E-Prime 留空 -> NA）
#        MT.RESP/MT.CRESP -> Resp/Cresp（实际按键/应按键）
#        bed/manipCheck/Condition（counterbalance 版本/试次内检查点）原样保留
#   3. 每被试 Trial 按 txt 中匹配块出现顺序 1..n 编号。
#   4. Exp2 nonwords-01 数据不完整（源数据问题，2026-08 核实）：匹配任务仅
#      68 试次（其余 33 名均为 128），txt 日志自然终止（无损坏）；OSF 仓库中
#      该被试亦仅有 txt（无 edat2/XML）。raw.csv 保留其 68 行（真实数据），
#      库内 Clean/subj_info 维持既有口径（33 名，不含 01）。
#   5. 论文分析样本（SPSS 脚本硬编码排除名单，供 Note 引用，raw 不过滤）：
#      Exp1 排除 {5, 6, 20, 23, 24, 27}（Tukey，N=28）；
#      Exp2 排除 {4, 33}（Tukey，N=31；nonwords-01 亦不在分析中）。
#
# 验证守卫：Exp1 raw 与现有 Clean 逐值（Subject/Trial/Shape/Label/Matching/
# RT_ms/ACC，按 Subject+Trial 对齐）全等；Exp2 raw 中 subject 2-34 与现有
# Clean 逐值全等。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Orellana-Corrales_2021_APP_clean.R
# 依赖包：无（base R）
# ============================================================================

# ---- 定位脚本目录（引导块，utils.R 依赖） ----
.args <- commandArgs(trailingOnly = FALSE)
.fa <- .args[grepl("^--file=", .args)]
.script_dir <- if (length(.fa)) {
  dirname(normalizePath(sub("^--file=", "", .fa[1])))
} else if (!is.null(sys.frame(1)$ofile)) {
  dirname(normalizePath(sys.frame(1)$ofile))
} else {
  getwd()
}
# ---- 加载通用函数（1_Data/utils.R，与脚本同库） ----
.ut <- file.path(dirname(dirname(.script_dir)), "1_Data", "utils.R")
if (!file.exists(.ut)) .ut <- file.path(.script_dir, "utils.R")
stopifnot(file.exists(.ut))
source(.ut)
rm(.args, .fa, .script_dir, .ut)

STUDY_DIR <- file.path(spe_root(), "1_Data", "Orellana-Corrales_2021_APP")
stopifnot(dir.exists(STUDY_DIR))

# 输入区实际路径为 <Folder_Name>_raw/（历史小写变体）；2026-10-08 修正原先
# 误写成嵌套同名的路径（STUDY_DIR/<Folder_Name>/...，该目录不存在，脚本此前
# 在 dir.exists() 处即中止）。
EXP1_IN  <- file.path(STUDY_DIR, "Orellana-Corrales_2021_APP_raw",
                      "Exp1_g7wrc-osfstorage-archive", "raw_data")
EXP2_IN  <- file.path(STUDY_DIR, "Orellana-Corrales_2021_APP_raw",
                      "EXP2_4cwrv-osfstorage-archive", "Exp2_rawData")
stopifnot(dir.exists(EXP1_IN), dir.exists(EXP2_IN))

# ============================================================================
# E-Prime 文本导出解析（UTF-16LE）：read_eprime_txt / parse_header /
# parse_matching_blocks 已提取至 1_Data/utils.R（2026-08 沉淀，跨研究复用），
# 由上方引导块 source 的 utils.R 提供，此处不再重复定义。
# ============================================================================

# 单个被试 txt -> trial 行列表
subject_rows <- function(path, has_shape) {
  lines <- read_eprime_txt(path)
  hdr <- parse_header(lines)
  blocks <- parse_matching_blocks(lines)
  subj <- suppressWarnings(as.integer(hdr[["Subject"]]))
  cond <- if (is.null(hdr[["Condition"]])) NA_character_ else hdr[["Condition"]]
  stopifnot(!is.na(subj))
  rows <- lapply(seq_along(blocks), function(i) {
    b <- blocks[[i]]
    acc <- if (!is.null(b[["MT.ACC"]]) && nzchar(b[["MT.ACC"]])) {
      suppressWarnings(as.integer(b[["MT.ACC"]]))
    } else NA_integer_
    rt <- if (!is.null(b[["MT.RT"]]) && nzchar(b[["MT.RT"]])) {
      suppressWarnings(as.integer(b[["MT.RT"]]))
    } else NA_integer_
    matchv <- if (!is.null(b[["match"]])) {
      if (b[["match"]] == "match") "Matching" else if (b[["match"]] == "nonmatch") "Nonmatching" else b[["match"]]
    } else NA_character_
    mc <- if (!is.null(b[["manipCheck"]]) && nzchar(b[["manipCheck"]])) {
      suppressWarnings(as.integer(b[["manipCheck"]]))
    } else NA_integer_
    base <- data.frame(
      Subject = subj, Trial = i,
      Matching = matchv,
      ACC = acc, RT_ms = rt,
      bed = if (is.null(b[["bed"]])) NA_character_ else b[["bed"]],
      manipCheck = mc,
      Resp = if (is.null(b[["MT.RESP"]])) NA_character_ else b[["MT.RESP"]],
      Cresp = if (is.null(b[["MT.CRESP"]])) NA_character_ else b[["MT.CRESP"]],
      Condition = cond,
      stringsAsFactors = FALSE
    )
    base$Label <- if (is.null(b[["label"]])) NA_character_ else b[["label"]]
    if (has_shape) {
      base$Shape <- if (is.null(b[["shape"]])) NA_character_ else b[["shape"]]
      base[, c("Subject", "Trial", "Shape", "Label", "Matching", "ACC", "RT_ms",
               "bed", "manipCheck", "Resp", "Cresp", "Condition")]
    } else {
      base$Nonword <- if (is.null(b[["nonword"]])) NA_character_ else b[["nonword"]]
      base[, c("Subject", "Trial", "Label", "Nonword", "Matching", "ACC", "RT_ms",
               "bed", "manipCheck", "Resp", "Cresp", "Condition")]
    }
  })
  do.call(rbind, rows)
}

# ============================================================================
# 生成 Exp1 raw（34 名 × 128 试次）
# ============================================================================
cat("== Exp1: 解析 targetTasks txt ...\n")
exp1_files <- sort(list.files(EXP1_IN, pattern = "^targetTasks.*\\.txt$", full.names = TRUE))
stopifnot(length(exp1_files) == 34)
raw1 <- do.call(rbind, lapply(exp1_files, subject_rows, has_shape = TRUE))
rownames(raw1) <- NULL
cat("  Exp1 raw 行数:", nrow(raw1), "(预期 4352 = 34×128)\n")
stopifnot(nrow(raw1) == 34 * 128)
stopifnot(all(table(raw1$Subject) == 128))

# ============================================================================
# 生成 Exp2 raw（34 名；nonwords-01 仅 68 试次）
# ============================================================================
cat("== Exp2: 解析 nonwords txt ...\n")
exp2_files <- sort(list.files(EXP2_IN, pattern = "^nonwords-.*\\.txt$", full.names = TRUE))
stopifnot(length(exp2_files) == 34)
raw2 <- do.call(rbind, lapply(exp2_files, subject_rows, has_shape = FALSE))
rownames(raw2) <- NULL
cat("  Exp2 raw 行数:", nrow(raw2), "(预期 4292 = 33×128 + 68)\n")
stopifnot(nrow(raw2) == 33 * 128 + 68)
stopifnot(all(table(raw2$Subject)[as.character(2:34)] == 128))
stopifnot(table(raw2$Subject)[["1"]] == 68)

# ============================================================================
# 生成 Clean（Exp1/Exp2；2026-10-08 补录，此前 Clean 仅由历史 Clean_Data.Rmd 产出）
# ----------------------------------------------------------------------------
# Exp1（几何形状版，2 身份 Self/Stranger）：
#   Shape 三级 Identity = **该形状在本被试身上学到的身份**：直接读作者 E-Prime 原始 txt 的
#   学习阶段帧（targLocation + 同侧 shape），并以「由 raw 的 Matching 结构反推」作交叉检查
#   （两者必须逐行一致，2026-10-08 起）。
#   2026-10-08 修正（用户确认）：库内 Clean 此前把该列**按形状文件名写死**
#   （Kreis.png→Fremder、Dreieck.png→Ich），而形状↔身份绑定是逐被试反平衡的
#   （本数据 17:17）→ 34 名被试中 17 名的该列与真实绑定相反，并造成「Matching
#   试次的形状身份 ≠ 标签身份」的内部矛盾。现按 raw 修正，并加一致性检查。
#   **独立佐证（2026-10-08 复核）**：作者 E-Prime 原始 txt（targetTasks[AB]-*.txt）的学习
#   阶段帧记录 targLocation（目标标签 fremder/ich）与同侧 shape，据此推出的绑定 = 作者测试帧
#   match 标志推出的绑定 = 本脚本修正后的 Shape_Origin_Identity，三者对全部 34 名被试 ×
#   2 个形状（68/68）一致；反平衡逐被试发生（A/B 文件族内亦不同），故「按文件名写死」确为历史错误。
# Exp2（伪词版）：库内 Clean 不含形状/伪词列（Nonword 未收录；Shape/Label 可读值
#   缺失为已知项），且**不含被试 1**（源数据仅 68 试次、不完整，仅保留在 raw）。
# ============================================================================
.lab_map <- c(Fremder = "Stranger", Ich = "Self")
# ---- 形状→身份绑定：直读作者学习阶段帧（2026-10-08 改；原为从 Matching 反推） ----
# 学习阶段帧（pair*/labelproc*/shape*）直接记录被教配对：targLocation = 目标标签
# （fremder/ich），目标标签同侧的 shape 即该被试学到的配对 → (Subject, Shape) → 身份。
# 这是 raw 中对绑定最直接的记录（SKILL：Origin 层 = verbatim as in the raw data）。
parse_association <- function(path) {
  lines <- read_eprime_txt(path)
  subj <- suppressWarnings(as.integer(parse_header(lines)[["Subject"]]))
  bind <- list(); cur <- list(); inframe <- FALSE
  for (ln in lines) {
    s <- trimws(ln)
    if (s == "*** LogFrame Start ***") { cur <- list(); inframe <- TRUE; next }
    if (s == "*** LogFrame End ***") {
      inframe <- FALSE
      tl <- tolower(if (is.null(cur[["targLocation"]])) "" else cur[["targLocation"]])
      if (tl %in% c("fremder", "ich") && !is.null(cur[["labelLeft"]])) {
        ident <- if (tl == "fremder") "Fremder" else "Ich"
        shp <- if (identical(tolower(cur[["labelLeft"]]), tl)) cur[["shapeLeft"]] else cur[["shapeRight"]]
        if (!is.null(shp) && nzchar(shp)) bind[[shp]] <- unique(c(bind[[shp]], ident))
      }
      next
    }
    if (inframe && grepl(":", s, fixed = TRUE)) {
      cur[[trimws(sub(":.*$", "", s))]] <- trimws(sub("^[^:]*:", "", s))
    }
  }
  list(Subject = subj, bind = bind)
}
.assoc <- lapply(exp1_files, parse_association)
.learn_bind <- lapply(.assoc, function(x) {          # 每形状绑定必须唯一
  b <- x$bind
  stopifnot(length(b) == 2, all(lengths(b) == 1))
  lapply(b, function(v) v[[1]])
})
names(.learn_bind) <- vapply(.assoc, function(x) as.character(x$Subject), character(1))
stopifnot(length(.learn_bind) == 34,
          setequal(names(.learn_bind), unique(as.character(raw1$Subject))))
.shape_origin <- vapply(seq_len(nrow(raw1)), function(i)
  .learn_bind[[as.character(raw1$Subject[i])]][[raw1$Shape[i]]], character(1))
stopifnot(!anyNA(.shape_origin))            # 每被试每形状都能从学习帧读到绑定
# ---- 交叉检查：学习帧绑定 必须等于「由 Matching 试次反推」的绑定 ----
.shape_pair <- unique(raw1[raw1$Matching == "Matching", c("Subject", "Shape", "Label")])
stopifnot(!anyDuplicated(paste(.shape_pair$Subject, .shape_pair$Shape)))   # 每被试每形状唯一
.shape_match <- unname(setNames(.shape_pair$Label,
                                paste(.shape_pair$Subject, .shape_pair$Shape))[
                       paste(raw1$Subject, raw1$Shape)])
stopifnot(identical(.shape_origin, .shape_match))

clean1 <- data.frame(
  Subject = as.character(raw1$Subject),
  Task = "self-matching",
  Trial = as.integer(raw1$Trial),
  Matching = raw1$Matching,
  Shape = raw1$Shape,
  Shape_Origin_Identity = .shape_origin,
  Shape_English_Identity = unname(.lab_map[.shape_origin]),
  Shape_Standardized_Identity = unname(.lab_map[.shape_origin]),
  Label = raw1$Label,
  Label_Origin_Identity = raw1$Label,
  Label_English_Identity = unname(.lab_map[raw1$Label]),
  Label_Standardized_Identity = unname(.lab_map[raw1$Label]),
  RT_ms = as.integer(raw1$RT_ms),
  RT_sec = as.numeric(raw1$RT_ms) / 1000,
  ACC = as.integer(raw1$ACC),
  stringsAsFactors = FALSE
)
clean1 <- clean1[order(as.integer(clean1$Subject), clean1$Trial), ]
rownames(clean1) <- NULL
stopifnot(nrow(clean1) == 34 * 128,
          !anyNA(clean1$Shape_Origin_Identity), !anyNA(clean1$Label_English_Identity),
          identical(names(clean1), c("Subject", "Task", "Trial", "Matching", "Shape",
            "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
            "Label", "Label_Origin_Identity", "Label_English_Identity",
            "Label_Standardized_Identity", "RT_ms", "RT_sec", "ACC")))
# 一致性检查：Matching ⟺ 形状身份 == 标签身份（2026-10-08 修正后应 100% 成立）
stopifnot(all((clean1$Matching == "Matching") ==
              (clean1$Shape_Standardized_Identity == clean1$Label_Standardized_Identity)))

raw2_kept <- raw2[as.character(raw2$Subject) != "1", ]   # 被试 1 数据不完整，仅存 raw
clean2 <- data.frame(
  Subject = as.character(raw2_kept$Subject),
  Task = "self-matching",
  Trial = as.integer(raw2_kept$Trial),
  Matching = raw2_kept$Matching,
  Label_Origin_Identity = raw2_kept$Label,
  Label_English_Identity = unname(.lab_map[raw2_kept$Label]),
  Label_Standardized_Identity = unname(.lab_map[raw2_kept$Label]),
  RT_ms = as.integer(raw2_kept$RT_ms),
  RT_sec = as.numeric(raw2_kept$RT_ms) / 1000,
  ACC = as.integer(raw2_kept$ACC),
  stringsAsFactors = FALSE
)
clean2 <- clean2[order(as.integer(clean2$Subject), clean2$Trial), ]
rownames(clean2) <- NULL
stopifnot(nrow(clean2) == 33 * 128,
          !anyNA(clean2$Label_English_Identity),
          identical(names(clean2), c("Subject", "Task", "Trial", "Matching",
            "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
            "RT_ms", "RT_sec", "ACC")))

out_clean1 <- file.path(STUDY_DIR, "Exp1", "Orellana-Corrales_2021_APP_Exp1_Clean.csv")
out_clean2 <- file.path(STUDY_DIR, "Exp2", "Orellana-Corrales_2021_APP_Exp2_Clean.csv")
stopifnot(!file.exists(out_clean1), !file.exists(out_clean2))   # 入库产物：目标不存在
write_clean_csv(clean1, out_clean1)
write_clean_csv(clean2, out_clean2)
cat("== Clean：Exp1", nrow(clean1), "行 / Exp2", nrow(clean2), "行（被试试次不完整者仅存 raw）\n")

# ============================================================================
# 与 Clean 交叉验证（逐值，按 Subject+Trial 对齐）
# ============================================================================
read_clean <- function(p) {
  read.csv(p, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
}
cat("== 交叉验证 ...\n")

# --- Exp1 ---
clean1 <- read_clean(file.path(STUDY_DIR, "Exp1", "Orellana-Corrales_2021_APP_Exp1_Clean.csv"))
stopifnot(nrow(clean1) == nrow(raw1))
o1 <- order(raw1$Subject, raw1$Trial)
oc <- order(clean1$Subject, clean1$Trial)
for (col in c("Subject", "Trial", "Shape", "Label", "Matching", "RT_ms", "ACC")) {
  a <- raw1[[col]][o1]; b <- clean1[[col]][oc]
  eq <- ifelse(is.na(a) & is.na(b), TRUE, !is.na(a) & !is.na(b) & a == b)
  stopifnot(all(eq))
}
cat("  Exp1: raw 与 Clean 逐值全等 ✓（Subject/Trial/Shape/Label/Matching/RT_ms/ACC）\n")
cat("  Exp1 ACC 分布:", paste(names(table(raw1$ACC)), table(raw1$ACC), sep = "=", collapse = ", "), "\n")

# --- Exp2（subject 2-34 与 Clean 全等；01 仅在 raw） ---
clean2 <- read_clean(file.path(STUDY_DIR, "Exp2", "Orellana-Corrales_2021_APP_Exp2_Clean.csv"))
stopifnot(nrow(clean2) == 33 * 128)
r2k <- raw2[raw2$Subject != 1, ]
o2 <- order(r2k$Subject, r2k$Trial)
oc2 <- order(clean2$Subject, clean2$Trial)
for (col in c("Subject", "Trial", "Label", "Matching", "RT_ms", "ACC")) {
  a <- r2k[[col]][o2]; b <- clean2[[col]][oc2]
  eq <- ifelse(is.na(a) & is.na(b), TRUE, !is.na(a) & !is.na(b) & a == b)
  stopifnot(all(eq))
}
cat("  Exp2: raw（subject 2-34）与 Clean 逐值全等 ✓\n")
cat("  Exp2 nonwords-01 保留:", table(raw2$Subject)[["1"]], "行（源数据不完整，见头部注释）\n")

# ============================================================================
# 写出 raw.csv（库内 CRLF 惯例）
# ============================================================================
out1 <- file.path(STUDY_DIR, "Exp1", "Orellana-Corrales_2021_APP_Exp1_raw.csv")
out2 <- file.path(STUDY_DIR, "Exp2", "Orellana-Corrales_2021_APP_Exp2_raw.csv")
stopifnot(!file.exists(out1), !file.exists(out2))   # 目标不存在（防覆盖）
write_clean_csv(raw1, out1)
write_clean_csv(raw2, out2)
cat("完成：\n  ", out1, "\n  ", out2, "\n")
