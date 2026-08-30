# ============================================================================
# Orellana-Corrales_2020_ExpPsych — 独立清洗脚本（Exp1/2/3 = 论文 Study 1/2/3）
# ----------------------------------------------------------------------------
# 背景（2026-08-30 阶段 5 入库）：论文 Orellana-Corrales, Matschke & Wesslein
# (2020), "Does Self-Associating a Geometric Shape Immediately Cause
# Attentional Prioritization? ... Dot-Probe Task", Experimental Psychology,
# 67(6), DOI 10.1027/1618-3169/a000502（dot-probe 短 SOA 提示效应 + 长 SOA
# IOR 研究；匹配任务为 manipulation check）。数据库口径：只收录 self-matching
# task trial 级数据（dot-probe 数据不入库）。三个 study 各 4 练习 + 128 正式
# 试次，德语标签 Ich/Fremder，形状 Kreis.png/Dreieck.png，E-Prime 2.0。
#
# 数据来源（输入区，2026-08-30 用户下载 + agent 追补）：
#   Study 1/2（osf.io/3ke4f "Impact of self-association on attention: Cuing
#     & IOR"）：3ke4f-osfstorage-archive/exp1_rawData.zip（38 名 txt）、
#     exp2_rawData.zip（32 名 txt；作者 exp2_MT.lst 33 名，Subject 34 仅有
#     edat2 无 txt/XML → 本库 raw 不含 Subject 34，Note 记录）
#   Study 3（osf.io/umv5p，论文正文链接）：umv5p-osfstorage-archive/
#     rawDataMerge.tsv（作者 E-Merge 合并文件，36 session）
#
# 编号修正（仅 Study 3 需要；作者 participantSession.txt 声明 "Correct
# subject numbers entered as session numbers"）：E-Prime Subject 号被误填为
# Session 号，真实被试号 = Subject + Session - 1 → 1..36（论文 "36 completed"；
# 文件 dplocation_IOR-01-1 → 被试 1，dplocation_IOR-1-2..1-21 → 被试 2..21，
# dplocation_IOR-15-1 等 → 15, 22..36）。Study 1/2 文件名内 Subject 已唯一
# （Study 1: 01-01..38-38；Study 2: 1-13, 15-33），无需修正。
#
# 已知作者产物问题（2026-08-30 核对发现，不影响库内数据，详见
# 3_Reports/3_Reports/Verifying_original_results_issues.md（Issue 2））：
#   a) OSF mt_data.lst 以未修正编号聚合（Subject 1 的 20 个 session 被合并为
#      1 行，imACC=560 等），为中间产物上传错误（正确聚合应为 36 行）；
#   b) 作者分析代码（util.py）RT 离群上限用 grenze3_oben = q3 + 3*IQR，
#      论文 Methods 写 "one and a half interquartile ranges"（1.5*IQR）——
#      论文文本与代码不一致；
#   c) Study 2 的 SPSS 分析语法未上传（3ke4f 仅有 exp1_analysis.sps），
#      Study 2 被排除的 2 名被试编号未公开（论文 33 完成 → 31 分析）。
# 论文分析排除（SPSS FILTER，库内 raw/Clean 不过滤，仅记 CSV Note）：
#   Study 1: Subject 19/20/23/28（dot-probe RT 离群，38 → 34，df=33 吻合）；
#   Study 3: Subject 6/33（1 名参加过 Study 1/2 + 1 名 dot-probe RT 离群，
#     36 → 34，df=33 吻合）；摘要 N=35 疑为笔误（Participants 段 36-2=34）。
#
# 清洗口径：与 Clean_Data.Rmd 历史段 "Orellana-Corrales_2021_EP"
# （Exp1/2/3，本文旧命名）一致：仅 manipCheck 行（练习 MatchPrac 排除）；
# Identity 三级：Ich→Self、Fremder→Stranger。Shape 身份：Study 1/2 txt 无
# S1/S2/ID1/ID2 列 → 用匹配试次的 shape-label 对应推导（每被试 counterbalance
# 自洽，nonmatch 试次身份相反为强约束验证）；Study 3 有 S1/S2/ID1/ID2 列，
# 按 match 约束判定映射方向后与推导结果交叉验证。
#
# 验证守卫：① 每被试 128 行；② identity 自洽（match 一致 / nonmatch 相反）；
# ③ 与作者聚合表逐值核对（label 分组 im/fm/in/fn，口径 = RT>200 &
# <per-VP q3+3IQR(Tukey hinges) & ACC==1，mean=round(sum/n)，ER=ACC==0 计数）：
# exp1_MT.lst 38 行、exp2_MT.lst 32 行（跳过 Subject 34）、mt_data.lst 16 行
# （跳过合并行 Subject 1）。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Orellana-Corrales_2020_ExpPsych_clean.R
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

STUDY_DIR <- file.path(spe_root(), "1_Data", "Orellana-Corrales_2020_ExpPsych")
stopifnot(dir.exists(STUDY_DIR))
IN <- file.path(STUDY_DIR, "Orellana-Corrales_2020_ExpPsych_Raw")
Z1 <- file.path(IN, "3ke4f-osfstorage-archive", "exp1_rawData.zip")
Z2 <- file.path(IN, "3ke4f-osfstorage-archive", "exp2_rawData.zip")
TSV3 <- file.path(IN, "umv5p-osfstorage-archive", "rawDataMerge.tsv")
stopifnot(file.exists(Z1), file.exists(Z2), file.exists(TSV3))

# ============================================================================
# 通用函数
# ============================================================================

# 作者 util.py tukey_all 口径的 per-VP 上限（Tukey hinges 分位数，q1 floor /
# q3 ceil）。k 默认 1.5（论文 Methods 口径）。2026-08-30 逐值核对实证：三份
# 作者 LST 产物的 Tukey 上限口径不一致——exp1/exp2_MT.lst 用 q3+1.5*IQR
# （与论文一致），mt_data.lst 用 q3+3*IQR（与上传脚本 data_preparation_mt.py
# 的 grenze_type="grenze3_oben" 一致）；核对按各产物实际口径传 k。
tukey_upper <- function(x, k = 1.5) {
  x <- sort(as.numeric(x))
  n <- length(x)
  med_pos <- if (n %% 2 == 0) ((n / 2) + (n + 1) / 2) / 2 else (n + 1) / 2
  hinge <- (med_pos + 1) / 2
  if (hinge == floor(hinge)) {
    q1 <- x[hinge]
    q3 <- x[n - hinge + 1]
  } else {
    h <- floor(hinge)
    q1 <- (x[h] + x[h + 1]) / 2
    q3 <- (x[n - h] + x[n - h + 1]) / 2
  }
  q1 <- floor(q1)
  q3 <- ceiling(q3)
  q3 + k * (q3 - q1)
}

# 作者 data_preparation_mt.py 口径的每被试聚合（label 分组）：
#   im/fm/in/fn = Matching/Nonmatching × Ich/Fremder（按 Label 列分组）；
#   RT 过滤：非空 & >200 & < per-VP tukey 上限 & ACC==1；
#   mean = round(sum/n)（与作者一致）；ER = 该格非正确试次计数
#   （!(ACC==1)，含无反应 NA——作者 E-Merge tsv 口径无反应即 ACC=0）。
author_agg <- function(raw, tukey_k = 1.5) {
  subs <- sort(unique(raw$Subject))
  do.call(rbind, lapply(subs, function(s) {
    d <- raw[raw$Subject == s, ]
    lim <- tukey_upper(d$RT_ms[!is.na(d$RT_ms)], k = tukey_k)
    sel <- !is.na(d$RT_ms) & d$RT_ms > 200 & d$RT_ms < lim & d$ACC %in% 1
    cell <- function(cond) {
      v <- d$RT_ms[sel & cond]
      n <- length(v)
      c(mean = if (n) round(sum(v) / n) else NA_real_,
        n = n,
        sum = if (n) sum(v) else NA_real_,
        er = sum(!(d$ACC %in% 1) & cond))
    }
    im <- cell(d$Matching == "Matching" & d$Label == "Ich")
    fm <- cell(d$Matching == "Matching" & d$Label == "Fremder")
    in_ <- cell(d$Matching == "Nonmatching" & d$Label == "Ich")
    fn <- cell(d$Matching == "Nonmatching" & d$Label == "Fremder")
    data.frame(Subject = s,
               imRTmean = im["mean"], imACC = im["n"], imRTsum = im["sum"], imER = im["er"],
               fmRTmean = fm["mean"], fmACC = fm["n"], fmRTsum = fm["sum"], fmER = fm["er"],
               inRTmean = in_["mean"], inACC = in_["n"], inRTsum = in_["sum"], inER = in_["er"],
               fnRTmean = fn["mean"], fnACC = fn["n"], fnRTsum = fn["sum"], fnER = fn["er"],
               row.names = NULL)
  }))
}

# 与作者 LST 聚合表逐值核对（skip_mine/skip_author = 本库/作者侧不参与比对的
# Subject；ignore_cells = 作者端矛盾残值格，格式 list(`Subject` = c("列名", ...))，
# 2026-08-30 核对发现：exp2_MT.lst 的 Subject 10/16/30 im 格与 Subject 16
# fn 格出现 mean 有值但 n=0/sum=0 的矛盾值（与数据不符，作者产物问题））
check_agg <- function(raw, lst_path, skip_mine = integer(0),
                      skip_author = integer(0), label = "",
                      ignore_cells = list(), tukey_k = 1.5) {
  agg <- author_agg(raw, tukey_k = tukey_k)
  lst <- read.table(lst_path, header = TRUE, stringsAsFactors = FALSE,
                    comment.char = "")
  agg <- agg[!agg$Subject %in% skip_mine, ]
  lst <- lst[!lst$Subject %in% skip_author, ]
  stopifnot(setequal(agg$Subject, lst$Subject))
  m <- merge(agg, lst, by = "Subject", suffixes = c(".mine", ".author"))
  cols <- c("imRTmean", "imACC", "imRTsum", "imER",
            "fmRTmean", "fmACC", "fmRTsum", "fmER",
            "inRTmean", "inACC", "inRTsum", "inER",
            "fnRTmean", "fnACC", "fnRTsum", "fnER")
  bad <- 0
  for (cc in cols) {
    a <- m[[paste0(cc, ".mine")]]
    b <- m[[paste0(cc, ".author")]]
    d <- which(!(is.na(a) & is.na(b)) & (is.na(a) | is.na(b) | a != b))
    for (s in names(ignore_cells)) {
      if (cc %in% ignore_cells[[s]]) d <- d[m$Subject[d] != as.integer(s)]
    }
    if (length(d)) {
      bad <- bad + length(d)
      cat("  [", label, "] 差异", cc, "@Subject", m$Subject[d],
          "| 本库:", a[d], "作者:", b[d], "\n")
    }
  }
  cat("  [", label, "] 聚合核对完成，差异单元格:", bad, "\n")
  stopifnot(bad == 0)
}

# 单个被试 txt -> trial 行（Study 1/2 共用；字段映射同 rawDataMerge 列名）
subject_rows_txt <- function(path) {
  lines <- read_eprime_txt(path)
  hdr <- parse_header(lines)
  blocks <- parse_matching_blocks(lines, acc_field = "match03.ACC")
  subj <- suppressWarnings(as.integer(hdr[["Subject"]]))
  stopifnot(!is.na(subj))
  cond <- if (is.null(hdr[["Condition"]])) NA_character_ else hdr[["Condition"]]
  rows <- lapply(seq_along(blocks), function(i) {
    b <- blocks[[i]]
    acc <- if (!is.null(b[["match03.ACC"]]) && nzchar(b[["match03.ACC"]])) {
      suppressWarnings(as.integer(b[["match03.ACC"]]))
    } else NA_integer_
    rt <- if (!is.null(b[["match03.RT"]]) && nzchar(b[["match03.RT"]])) {
      suppressWarnings(as.integer(b[["match03.RT"]]))
    } else NA_integer_
    data.frame(
      Subject = subj,
      Trial = suppressWarnings(as.integer(b[["manipCheck.Sample"]])),
      Block = suppressWarnings(as.integer(b[["manipCheck.Cycle"]])),
      Shape = if (is.null(b[["shape"]])) NA_character_ else b[["shape"]],
      Label = if (is.null(b[["label"]])) NA_character_ else b[["label"]],
      Matching = if (!is.null(b[["match"]])) {
        if (b[["match"]] == "match") "Matching" else if (b[["match"]] == "nonmatch") "Nonmatching" else b[["match"]]
      } else NA_character_,
      ACC = acc, RT_ms = rt,
      Resp = if (is.null(b[["match03.RESP"]])) NA_character_ else b[["match03.RESP"]],
      Cresp = if (is.null(b[["match03.CRESP"]])) NA_character_ else b[["match03.CRESP"]],
      bed = if (is.null(b[["bed"]])) NA_character_ else b[["bed"]],
      Condition = cond,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

# 单个被试 txt -> 人口学（subj_info 用）
subject_demo_txt <- function(path) {
  hdr <- parse_header(read_eprime_txt(path))
  data.frame(Subject = suppressWarnings(as.integer(hdr[["Subject"]])),
             Age = if (is.null(hdr[["Age"]])) NA_character_ else hdr[["Age"]],
             Sex = if (is.null(hdr[["Sex"]])) NA_character_ else hdr[["Sex"]],
             Handedness = if (is.null(hdr[["Handedness"]])) NA_character_ else hdr[["Handedness"]],
             stringsAsFactors = FALSE)
}

# Shape 身份推导：匹配试次的 shape-label 对应（每被试 counterbalance 自洽）
derive_shape_identity <- function(raw) {
  m <- raw[raw$Matching == "Matching", ]
  pairs <- unique(m[, c("Subject", "Shape", "Label")])
  nper <- table(pairs$Subject)
  stopifnot(all(nper == 2))                       # 每被试恰好 2 个配对
  maps <- split(pairs, pairs$Subject)
  lut <- new.env(hash = TRUE)
  for (s in names(maps)) {
    pp <- maps[[s]]
    stopifnot(length(unique(pp$Label)) == 2)      # Ich 与 Fremder 各匹配一种 shape
    for (k in seq_len(nrow(pp))) lut[[paste(s, pp$Shape[k], sep = "|")]] <- pp$Label[k]
  }
  vapply(seq_len(nrow(raw)), function(i) {
    key <- paste(raw$Subject[i], raw$Shape[i], sep = "|")
    if (exists(key, envir = lut, inherits = FALSE)) get(key, envir = lut) else NA_character_
  }, "")
}

# identity 自洽强约束：match 试次 shape 身份 == label 身份；nonmatch 相反
verify_identity <- function(raw, sid, label = "") {
  m <- raw$Matching == "Matching"
  nm <- !m
  ok1 <- all(sid[m] == raw$Label[m], na.rm = TRUE)
  ok2 <- all(sid[nm] != raw$Label[nm], na.rm = TRUE)
  cat("  [", label, "] identity 自洽：match 一致率", mean(sid[m] == raw$Label[m]),
      "| nonmatch 相反率", mean(sid[nm] != raw$Label[nm]), "\n")
  stopifnot(ok1, ok2)
}

# Clean 标准列 + Identity 三级（与 Clean_Data.Rmd 2021_EP 段一致）
make_clean <- function(raw, sid) {
  data.frame(
    Subject = raw$Subject,
    Block = raw$Block,
    Trial = raw$Trial,
    Shape = raw$Shape,
    Label = raw$Label,
    Matching = raw$Matching,
    Label_Origin_Identity = raw$Label,
    Label_English_Identity = ifelse(raw$Label == "Ich", "Self", "Stranger"),
    Label_Standardized_Identity = ifelse(raw$Label == "Ich", "Self", "Stranger"),
    Shape_Origin_Identity = sid,
    Shape_English_Identity = ifelse(sid == "Ich", "Self", "Stranger"),
    Shape_Standardized_Identity = ifelse(sid == "Ich", "Self", "Stranger"),
    Response = raw$Resp,
    RT_ms = raw$RT_ms,
    RT_sec = raw$RT_ms / 1000,
    ACC = raw$ACC,
    stringsAsFactors = FALSE
  )
}

# subj_info 标准格式（与 Orellana-Corrales_2021_APP 一致；缺项填 /）
make_subj_info <- function(demo, exp_id) {
  data.frame(Subject_ID = demo$Subject,
             Exp_id = exp_id,
             Age = ifelse(is.na(demo$Age), "/", demo$Age),
             Gender = ifelse(is.na(demo$Sex), "/", ifelse(demo$Sex == "male", "Male", "Female")),
             Handedness = ifelse(is.na(demo$Handedness), "/", demo$Handedness),
             Ethnicity = "/", Employment_Status = "/", Country = "/",
             First_Language = "/", Education = "/",
             stringsAsFactors = FALSE)
}

# ============================================================================
# Exp1（论文 Study 1）：38 名 txt（conjunctSPE_short-XX-XX，Subject=Session）
# ============================================================================
cat("== Exp1: 解析 exp1_rawData.zip txt ...\n")
td <- tempfile("oc20_exp1_")
dir.create(td)
unzip(Z1, exdir = td)
exp1_files <- sort(list.files(td, pattern = "\\.txt$", full.names = TRUE))
stopifnot(length(exp1_files) == 38)
raw1 <- do.call(rbind, lapply(exp1_files, subject_rows_txt))
rownames(raw1) <- NULL
demo1 <- do.call(rbind, lapply(exp1_files, subject_demo_txt))
rownames(demo1) <- NULL
stopifnot(nrow(raw1) == 38 * 128)
stopifnot(setequal(unique(raw1$Subject), 1:38))
stopifnot(all(table(raw1$Subject) == 128))
cat("  Exp1 raw 行数:", nrow(raw1), "(预期 4864 = 38×128)\n")

# ============================================================================
# Exp2（论文 Study 2）：32 名 txt（Subject 1-13, 15-33；Subject 34 仅 edat2）
# ============================================================================
cat("== Exp2: 解析 exp2_rawData.zip txt ...\n")
td2 <- tempfile("oc20_exp2_")
dir.create(td2)
unzip(Z2, exdir = td2)
exp2_files <- sort(list.files(td2, pattern = "\\.txt$", full.names = TRUE))
stopifnot(length(exp2_files) == 32)
raw2 <- do.call(rbind, lapply(exp2_files, subject_rows_txt))
rownames(raw2) <- NULL
demo2 <- do.call(rbind, lapply(exp2_files, subject_demo_txt))
rownames(demo2) <- NULL
stopifnot(nrow(raw2) == 32 * 128)
stopifnot(setequal(unique(raw2$Subject), c(1:13, 15:33)))
stopifnot(all(table(raw2$Subject) == 128))
cat("  Exp2 raw 行数:", nrow(raw2), "(预期 4096 = 32×128；Subject 34 无 txt 导出)\n")

# ============================================================================
# Exp3（论文 Study 3）：rawDataMerge.tsv（36 session → 修正编号 1-36）
# ============================================================================
cat("== Exp3: 解析 rawDataMerge.tsv ...\n")
tsv <- read.delim(TSV3, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)
stopifnot("manipCheck" %in% names(tsv), "Running" %in% names(tsv))
mc <- tsv[tsv$Running == "manipCheck", ]
stopifnot(nrow(mc) == 36 * 128)
mc$Subject_real <- as.integer(mc$Subject) + as.integer(mc$Session) - 1
stopifnot(setequal(unique(mc$Subject_real), 1:36))
# ACC 统一编码（全库方案 A，2026-08 P21）：1=正确、0=错键、NA=无反应。
# 来源差异：Study 1/2 的 txt 无反应试次 match03.ACC 为空（→NA，天然正确）；
# Study 3 的 E-Merge tsv 无反应被记作 ACC=0 且 RESP={CONTROL}（E-Prime 超时
# 标记）→ 依 RESP 判别转 NA。raw 即统一编码（与 2021 APP raw 口径一致）。
resp_nr <- mc$`match03.RESP` == "{CONTROL}"
raw3 <- data.frame(
  Subject = mc$Subject_real,
  Trial = as.integer(mc$`manipCheck.Sample`),
  Block = as.integer(mc$`manipCheck.Cycle`),
  Shape = mc$shape,
  Label = mc$label,
  Matching = ifelse(mc$match == "match", "Matching", "Nonmatching"),
  ACC = ifelse(resp_nr, NA_integer_,
               suppressWarnings(as.integer(mc$`match03.ACC`))),
  RT_ms = suppressWarnings(as.integer(mc$`match03.RT`)),
  Resp = mc$`match03.RESP`,
  Cresp = mc$`match03.CRESP`,
  bed = mc$bed,
  Condition = mc$Condition,
  stringsAsFactors = FALSE
)
demo3 <- unique(mc[, c("Subject_real", "Age", "Sex", "Handedness")])
names(demo3)[1] <- "Subject"
stopifnot(nrow(demo3) == 36)
stopifnot(all(table(raw3$Subject) == 128))
cat("  Exp3 raw 行数:", nrow(raw3), "(预期 4608 = 36×128；编号已修正 1-36)\n")

# ============================================================================
# Shape 身份推导 + identity 自洽验证（全部三个 Exp）
# ============================================================================
sid1 <- derive_shape_identity(raw1)
verify_identity(raw1, sid1, "Exp1")
sid2 <- derive_shape_identity(raw2)
verify_identity(raw2, sid2, "Exp2")
sid3 <- derive_shape_identity(raw3)
verify_identity(raw3, sid3, "Exp3")

# Exp3 另有 S1/S2/ID1/ID2 列：按 match 约束判定每被试映射方向，与推导交叉验证
exp3_dirA <- ifelse(mc$shape == mc$S1, mc$ID1, mc$ID2)   # 方向 A: S1→ID1
exp3_dirB <- ifelse(mc$shape == mc$S1, mc$ID2, mc$ID1)   # 方向 B: S1→ID2
mask <- mc$match == "match"
subs3 <- sort(unique(mc$Subject_real))
okA <- vapply(subs3, function(s) {
  k <- mask & mc$Subject_real == s
  all(exp3_dirA[k] == mc$label[k])
}, TRUE)
okB <- vapply(subs3, function(s) {
  k <- mask & mc$Subject_real == s
  all(exp3_dirB[k] == mc$label[k])
}, TRUE)
names(okA) <- subs3
names(okB) <- subs3
stopifnot(all(okA | okB))   # 每被试至少一个方向完全自洽
dir3 <- ifelse(okA[as.character(raw3$Subject)], exp3_dirA, exp3_dirB)
stopifnot(all(dir3 == sid3))   # S1/S2/ID1/ID2 映射与 match 约束推导一致
cat("  Exp3 S1/S2↔ID1/ID2 映射方向：", sum(okA), "名方向A /", sum(okB),
    "名方向B，与推导一致 ✓\n")

# ============================================================================
# 与作者聚合表逐值核对
# ============================================================================
check_agg(raw1, file.path(IN, "3ke4f-osfstorage-archive", "exp1_MT.lst"),
          label = "Exp1 vs exp1_MT.lst")
check_agg(raw2, file.path(IN, "3ke4f-osfstorage-archive", "exp2_MT.lst"),
          skip_author = 34, label = "Exp2 vs exp2_MT.lst（跳过 Subject 34）",
          ignore_cells = list(`10` = c("imRTmean", "imACC", "imRTsum"),
                              `16` = c("imRTmean", "imACC", "imRTsum", "fnRTmean", "fnACC", "fnRTsum"),
                              `30` = c("imRTmean", "imACC", "imRTsum")))
# mt_data.lst 的 Subject 1 行 = 未修正编号的 20 个 session 合并
# （真实被试 1-14,16-21），本库侧跳过对应 20 人；Subject 15、22-36 两侧可比。
check_agg(raw3, file.path(IN, "umv5p-osfstorage-archive", "mt_data.lst"),
          skip_mine = c(1:14, 16:21), skip_author = 1,
          label = "Exp3 vs mt_data.lst（跳过合并行 Subject 1 对应的 20 人；k=3）",
          tukey_k = 3)

# ============================================================================
# 写出 raw / Clean / subj_info（Exp1/2/3 子文件夹，与 2021 APP 布局一致）
# ============================================================================
clean1 <- make_clean(raw1, sid1)
clean2 <- make_clean(raw2, sid2)
clean3 <- make_clean(raw3, sid3)
info1 <- make_subj_info(demo1, "Orellana-Corrales_2020_ExpPsych_Exp1")
info2 <- make_subj_info(demo2, "Orellana-Corrales_2020_ExpPsych_Exp2")
info3 <- make_subj_info(demo3, "Orellana-Corrales_2020_ExpPsych_Exp3")

out <- list(
  list(raw1, file.path(STUDY_DIR, "Exp1", "Orellana-Corrales_2020_ExpPsych_Exp1_raw.csv")),
  list(clean1, file.path(STUDY_DIR, "Exp1", "Orellana-Corrales_2020_ExpPsych_Exp1_Clean.csv")),
  list(info1, file.path(STUDY_DIR, "Exp1", "Orellana-Corrales_2020_ExpPsych_Exp1_subj_info.csv")),
  list(raw2, file.path(STUDY_DIR, "Exp2", "Orellana-Corrales_2020_ExpPsych_Exp2_raw.csv")),
  list(clean2, file.path(STUDY_DIR, "Exp2", "Orellana-Corrales_2020_ExpPsych_Exp2_Clean.csv")),
  list(info2, file.path(STUDY_DIR, "Exp2", "Orellana-Corrales_2020_ExpPsych_Exp2_subj_info.csv")),
  list(raw3, file.path(STUDY_DIR, "Exp3", "Orellana-Corrales_2020_ExpPsych_Exp3_raw.csv")),
  list(clean3, file.path(STUDY_DIR, "Exp3", "Orellana-Corrales_2020_ExpPsych_Exp3_Clean.csv")),
  list(info3, file.path(STUDY_DIR, "Exp3", "Orellana-Corrales_2020_ExpPsych_Exp3_subj_info.csv"))
)
for (o in out) stopifnot(!file.exists(o[[2]]))   # 目标不存在（防覆盖）
for (o in out) write_clean_csv(o[[1]], o[[2]])

cat("完成：\n")
for (o in out) cat("  ", o[[2]], "\n")
