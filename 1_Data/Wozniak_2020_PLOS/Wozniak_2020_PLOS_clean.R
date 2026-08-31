# ============================================================================
# Wozniak_2020_PLOS — 独立清洗脚本：标准 raw/Clean/subj_info（Exp1-3）
# ----------------------------------------------------------------------------
# 背景（2026-08-31 阶段 5 入库）：Woźniak & Hohwy (2020), "Stranger to my face:
# top-down and bottom-up effects underlying prioritization of images of one's
# face", PLOS ONE 15(7), DOI 10.1371/journal.pone.0235627. 数据 OSF 2q9w7
# （2021-04-27 上传；OSF 无 License 声明）。
#
# 任务（sequential match-non-match task，MATLAB + Psychtoolbox 3.0.10）：
#   学习阶段（3 对 标签-面孔 配对各呈现 20 s）→ 匹配任务：先呈现标签
#   （200 ms）→ 1 s 延迟 → 呈现面孔，被试按 z/m 判断配对匹配与否
#   （键映射 counterbalanced；无反应 2000 ms 记 'x'）。
#   24 练习 + 3 blocks × 90 = 270 正式试次/被试；每 cue 后 3 面孔等概率
#   （33.3%）；身份编码 You/Neutral/AntiYou（作者内部码，语义按实验而定，
#   见下）。每实验 24 名被试（Exp1: 24 全部；Exp2: 29 测 5 照片技术问题
#   排除；Exp3: 25 测 1 刺激问题排除——被排除者无 .dat 文件）。
#   实验结构（论文）：
#     Exp1: 陌生人脸 ↔ 标签 "You"（自关联）；另 2 张陌生脸 ↔ 陌生人名
#           （Pam/Meg 或 Rob/Sam）→ 身份 1=You(Self), 2/3=陌生人(Stranger)
#     Exp2: 本人真实面孔 ↔ 陌生人名（如 Meg/Rob）；另 2 张陌生脸 ↔ 陌生
#           人名 → 身份 3=AntiYou(本人脸, Self), 1/2=陌生人(Stranger)
#     Exp3: "You" ↔ 陌生脸（自关联）+ 本人真实面孔 ↔ 陌生人名 同时建立 →
#           身份 1=You(自关联陌生脸, Self), 3=AntiYou(本人脸, Self),
#           2=陌生人(Stranger)
#   （语义映射依据作者 MATLAB 脚本 Massive_SelfBoost_Avg1subject_MAD_full.m
#   头注释 "In Experiment X: ..." 逐条核对。）
#
# 数据格式（输入区 DATA/SelfBoostExp_XXXX.dat，空格分隔 22 列）：
#   1 SubNum 2 Exp 3 Hand(1:z=匹配键,2:m=匹配键) 4 Phase(test) 5 Trial(1-270)
#   6 Resp(z/m/x) 7 LabelName 8 LabelCode(You/Neutral/AntiYou)
#   9 ShapeNo(1-9=testlist objnumber) 10 ShapeFile(shape1-3.jpg)
#   11 Permutation 12 Permutation2 13 Gender(0=F,1=M)
#   14-16 身份槽 1-3 的标签名 17-19 身份槽 1-3 的 REAL 码 20 ObjType
#   (1=匹配,2=非匹配) 21 ACC(1/0) 22 RT(ms；无反应行为伪值 ~2000)
#   shape→槽映射固定（testlist.txt：shape1↔槽1, shape2↔槽2, shape3↔槽3），
#   槽→身份码由 17-19 列给出（每被试恒定）。
#   ACC 复现规则：ac==1 ⟺ (objtype==1 & resp==匹配键) | (objtype==2 &
#   resp==非匹配键)；resp='x'=无反应 → 库内 ACC=NA（作者记为 0）。
#
# 清洗 = 最小预处理：不过滤（作者分析口径 RT>200 且 <1500 ms 仅作
# 描述性统计核对，见 2_Code/wozniak2020_verify/）；无反应行 Clean 的
# RT_ms/ACC 置 NA（raw 保留伪 RT 原值）；身份三级列按上表映射。
# ============================================================================

# ---- 引导块：定位脚本目录与项目根，加载 utils.R ----
.args <- commandArgs(trailingOnly = FALSE)
.script_dir <- sub("--file=", "", .args[grep("^--file=", .args)])
if (length(.script_dir) == 0) .script_dir <- getwd()
.script_dir <- normalizePath(dirname(.script_dir))
.ut <- file.path(.script_dir, "..", "utils.R")
if (!file.exists(.ut)) stop("utils.R not found next to clean script")
source(.ut)
.root <- spe_root(.script_dir)
.study_dir <- file.path(.root, "1_Data", "Wozniak_2020_PLOS")
.dat_dir <- file.path(.study_dir, "Wozniak_2020_PLOS_raw", "DATA")
.xlsx <- file.path(.study_dir, "Wozniak_2020_PLOS_raw",
                   "Raw data - SelfBoostExp.xlsx")
stopifnot(dir.exists(.dat_dir), file.exists(.xlsx))

# ---- 读入全部 .dat ----
.col_names <- c("SubNum", "Exp", "Hand", "Phase", "Trial", "Resp",
                "LabelName", "LabelCode", "ShapeNo", "ShapeFile",
                "Permutation", "Permutation2", "Gender",
                "Slot1Name", "Slot2Name", "Slot3Name",
                "Slot1Code", "Slot2Code", "Slot3Code",
                "ObjType", "ACC_raw", "RT_raw")
.files <- sort(list.files(.dat_dir, pattern = "^SelfBoostExp_[0-9]+\\.dat$"))
stopifnot(length(.files) == 72)   # 3 实验 × 24 被试
cat("reading", length(.files), "dat files\n")
.dl <- lapply(.files, function(f) {
  d <- read.table(file.path(.dat_dir, f), sep = "", header = FALSE,
                  stringsAsFactors = FALSE, colClasses = "character",
                  comment.char = "", fill = TRUE)
  stopifnot(ncol(d) == 22, nrow(d) == 270)          # 270 正式试次
  names(d) <- .col_names
  stopifnot(all(d$Phase == "test"))                 # 练习不写入 .dat
  d$Subject <- sub("[.]dat$", "", sub("^SelfBoostExp_", "", f)) # 文件名 = 被试 ID
  d
})
dat <- do.call(rbind, .dl)
dat$Subject <- as.character(dat$Subject)
rm(.dl); gc()

# ---- 身份语义映射（按实验 + 作者 REAL 码） ----
# 作者内部码语义（依据 MATLAB 头注释；码→(Shape 侧 English, Label 侧
# English, Std)）：
.sem_shape <- list(
  "1" = c(You = "Self-associated face", Neutral = "Stranger face",
          AntiYou = "Stranger face"),
  "2" = c(You = "Stranger face", Neutral = "Stranger face",
          AntiYou = "Own face"),
  "3" = c(You = "Self-associated face", Neutral = "Stranger face",
          AntiYou = "Own face")
)
.sem_label <- list(
  "1" = c(You = "Self label (You)", Neutral = "Stranger name",
          AntiYou = "Stranger name"),
  "2" = c(You = "Stranger name", Neutral = "Stranger name",
          AntiYou = "Own-face name"),
  "3" = c(You = "Self label (You)", Neutral = "Stranger name",
          AntiYou = "Own-face name")
)
.sem_std <- c(Self = "Self", Stranger = "Stranger")
# 每被试：shape 文件 → 槽 → REAL 码（Slot1Code..Slot3Code 对应 shape1-3）
.slot_of_shape <- c("shape1.jpg" = "Slot1Code", "shape2.jpg" = "Slot2Code",
                    "shape3.jpg" = "Slot3Code")
dat$ShapeCode <- mapply(function(f, s1, s2, s3) {
  switch(.slot_of_shape[[f]], Slot1Code = s1, Slot2Code = s2, Slot3Code = s3)
}, dat$ShapeFile, dat$Slot1Code, dat$Slot2Code, dat$Slot3Code)
dat$ShapeName <- mapply(function(f, s1, s2, s3) {
  switch(.slot_of_shape[[f]], Slot1Code = s1, Slot2Code = s2, Slot3Code = s3)
}, dat$ShapeFile, dat$Slot1Name, dat$Slot2Name, dat$Slot3Name)

dat$Shape_English_Identity <- mapply(
  function(exp, code) unname(.sem_shape[[exp]][code]), dat$Exp, dat$ShapeCode)
dat$Label_English_Identity <- mapply(
  function(exp, code) unname(.sem_label[[exp]][code]), dat$Exp, dat$LabelCode)
.sem_std_map <- list(
  "1" = c(You = "Self", Neutral = "Stranger", AntiYou = "Stranger"),
  "2" = c(You = "Stranger", Neutral = "Stranger", AntiYou = "Self"),
  "3" = c(You = "Self", Neutral = "Stranger", AntiYou = "Self")
)
dat$Shape_Standardized_Identity <- mapply(
  function(exp, code) unname(.sem_std_map[[exp]][code]), dat$Exp, dat$ShapeCode)
dat$Label_Standardized_Identity <- mapply(
  function(exp, code) unname(.sem_std_map[[exp]][code]), dat$Exp, dat$LabelCode)

# ---- 守卫 1：ObjType(匹配/非匹配) 与 身份码一致性 ----
stopifnot(all((dat$ObjType == "1") == (dat$LabelCode == dat$ShapeCode)))
cat("guard 1 OK: ObjType == (LabelCode == ShapeCode) for all",
    nrow(dat), "trials\n")

# ---- 守卫 2：ACC 复现（z/m 键映射按 Hand） ----
.correct_key <- ifelse(dat$Hand == "1", "z", "m")
.wrong_key   <- ifelse(dat$Hand == "1", "m", "z")
.acc_expect <- ((dat$ObjType == "1" & dat$Resp == .correct_key) |
                (dat$ObjType == "2" & dat$Resp == .wrong_key)) &
               dat$Resp != "x"
stopifnot(all(.acc_expect == (dat$ACC_raw == "1")))
cat("guard 2 OK: ACC_raw reproduces (objtype, resp, hand) rule for all",
    nrow(dat), "trials\n")

# ---- 派生列 ----
dat$Matching <- ifelse(dat$ObjType == "1", "Matching", "Nonmatching")
dat$Block <- ceiling(as.integer(dat$Trial) / 90)
dat$ACC <- ifelse(dat$Resp == "x", NA_integer_,
                  as.integer(dat$ACC_raw))          # 无反应 → NA
dat$RT_ms <- ifelse(dat$Resp == "x", NA_integer_,
                    as.integer(dat$RT_raw))         # 无反应 → NA
dat$RT_sec <- dat$RT_ms / 1000
dat$Label_Origin_Identity <- dat$LabelName          # 实际标签文字（原样）
dat$Shape_Origin_Identity <- dat$ShapeCode          # 作者 REAL 码（原样）

# ---- 每实验产出 ----
.exp_subs <- tapply(dat$Subject, dat$Exp, function(x) unique(x))
stopifnot(lengths(.exp_subs) == c(24, 24, 24))      # 3 实验各 24 人
.exp_names <- c("1" = "Exp1", "2" = "Exp2", "3" = "Exp3")

for (.e in names(.exp_names)) {
  .d <- dat[dat$Exp == .e, ]
  .d <- .d[order(.d$Subject, as.integer(.d$Trial)), ]
  .outdir <- file.path(.study_dir, .exp_names[[.e]])
  dir.create(.outdir, showWarnings = FALSE)

  # ---- raw：保留原始 22 列（行内 SubNum 与文件名不一致处为作者输入
  #      历史错误：1010/2008/2011 三个文件行内 SubNum=1110/2004/2010，
  #      xlsx 与文件名口径一致，以文件名为准）+ 推导的身份码/名 ----
  .raw <- .d[, c("Subject", "SubNum", "Exp", "Hand", "Phase", "Trial", "Resp",
                 "LabelName", "LabelCode", "ShapeNo", "ShapeFile",
                 "Permutation", "Permutation2", "Gender",
                 "Slot1Name", "Slot2Name", "Slot3Name",
                 "Slot1Code", "Slot2Code", "Slot3Code",
                 "ObjType", "ACC_raw", "RT_raw",
                 "ShapeCode", "ShapeName", "Label_Origin_Identity",
                 "Shape_Origin_Identity")]
  write.csv(.raw, file.path(.outdir, paste0("Wozniak_2020_PLOS_", .exp_names[[.e]],
                                            "_raw.csv")),
            row.names = FALSE)

  # ---- Clean：标准列 ----
  .cl <- .d[, c("Subject", "Block", "Trial", "ShapeFile", "LabelName",
                "Matching",
                "Label_Origin_Identity", "Label_English_Identity",
                "Label_Standardized_Identity",
                "Shape_Origin_Identity", "Shape_English_Identity",
                "Shape_Standardized_Identity",
                "RT_ms", "RT_sec", "ACC")]
  names(.cl) <- c("Subject", "Block", "Trial", "Shape", "Label", "Matching",
                  "Label_Origin_Identity", "Label_English_Identity",
                  "Label_Standardized_Identity",
                  "Shape_Origin_Identity", "Shape_English_Identity",
                  "Shape_Standardized_Identity",
                  "RT_ms", "RT_sec", "ACC")
  write_clean_csv(.cl, file.path(.outdir, paste0("Wozniak_2020_PLOS_",
                                                 .exp_names[[.e]], "_Clean.csv")))
  stopifnot(nrow(.cl) == 6480, length(unique(.cl$Subject)) == 24)
  cat("  ", .exp_names[[.e]], ":", nrow(.cl), "rows /",
      length(unique(.cl$Subject)), "subjects;",
      "self-match RT mean =", round(mean(.cl$RT_ms[.cl$Label_Standardized_Identity == "Self" &
                                                   .cl$Matching == "Matching"], na.rm = TRUE), 1),
      "ms\n")
}

# ---- subj_info（人口学：xlsx 字面值/缓存值；3 个 sheet 各 24 行；
#      Gender 由 .dat 第 13 列回填/校验） ----
.subj <- do.call(rbind, lapply(1:3, function(.s) {
  .info <- readxl::read_excel(.xlsx, sheet = .s, skip = 1)
  .fr <- if ("FaceRaceVersion" %in% names(.info)) .info$FaceRaceVersion
         else .info$FaceRace
  data.frame(Subject_ID = as.character(.info$Participant),
             Exp = as.character(.info$`Exp. Version`),
             Age = as.character(.info$Age),
             Gender_x = as.character(.info$Gender),
             Handedness = as.character(.info$Handedness),
             FaceRace = as.character(.fr),
             stringsAsFactors = FALSE)
}))
.subj <- .subj[grepl("^[0-9]+$", .subj$Subject_ID), ]
# 合并 Exp2/Exp3 的 Gender（.dat）并校验与 xlsx 一致
.g_from_dat <- dat[!duplicated(dat$Subject), c("Subject", "Exp", "Gender")]
.g_from_dat$Gender_dat <- ifelse(.g_from_dat$Gender == "1", "1", "0")
.subj <- merge(.subj, .g_from_dat[, c("Subject", "Gender_dat")],
               by.x = "Subject_ID", by.y = "Subject", all.x = TRUE)
.subj$Gender <- ifelse(is.na(.subj$Gender_x), .subj$Gender_dat, .subj$Gender_x)
.subj$Gender[.subj$Gender == "1"] <- "Male"
.subj$Gender[.subj$Gender == "0"] <- "Female"
stopifnot(all(.subj$Gender_x[!is.na(.subj$Gender_x)] ==
                .subj$Gender_dat[!is.na(.subj$Gender_x)]))  # xlsx↔dat 一致
.subj$Age[is.na(.subj$Age) | !grepl("^[0-9]+$", .subj$Age)] <- "/"
.subj$Handedness[is.na(.subj$Handedness)] <- "/"
.subj$FaceRace[is.na(.subj$FaceRace)] <- "/"
.subj$Handedness <- sub("R", "Right", sub("L", "Left", .subj$Handedness))
stopifnot(nrow(.subj) == 72, all(table(.subj$Exp) == 24))
for (.e in names(.exp_names)) {
  .s <- .subj[.subj$Exp == .e, ]
  .s <- .s[order(.s$Subject_ID), ]
  .out <- data.frame(
    Subject_ID = .s$Subject_ID,
    Exp_id = paste0("Wozniak_2020_PLOS_", .exp_names[[.e]]),
    Age = .s$Age, Gender = .s$Gender, Handedness = .s$Handedness,
    Ethnicity = rep("/", nrow(.s)),
    Employment_Status = rep("/", nrow(.s)),
    Country = rep("/", nrow(.s)),
    First_Language = rep("/", nrow(.s)),
    Education = rep("/", nrow(.s)),
    FaceRace = .s$FaceRace, stringsAsFactors = FALSE)
  write_clean_csv(.out, file.path(.study_dir, .exp_names[[.e]],
                                  paste0("Wozniak_2020_PLOS_", .exp_names[[.e]],
                                         "_subj_info.csv")))
  cat("  subj_info", .exp_names[[.e]], ":", nrow(.s), "rows;",
      "M/F =", sum(.s$Gender == "Male"), "/", sum(.s$Gender == "Female"),
      "; Age known:", sum(.s$Age != "/"), "\n")
}

cat("DONE. 72 subjects x 270 trials; ACC/RT guards passed.\n")
