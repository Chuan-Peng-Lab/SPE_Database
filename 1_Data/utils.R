# ============================================================================
# 1_Data/utils.R — SPE 数据库独立清洗脚本通用函数（2026-08）
# ----------------------------------------------------------------------------
# 由 1_Data/<Study>/<Study>_clean.R 通过 source() 加载（引导块见各脚本头部；
# 与清洗脚本同库 1_Data/ 下，避免跨文件夹引用）。
# 提供：
#   spe_root(start)      项目根定位：env SPE_DATABASE_ROOT > 从 start 向上
#                        探测含 1_Data 与 2_Code 的目录
#   write_clean_csv()    统一写出 *_Clean.csv（默认 CRLF 行尾，库内惯例；
#                        write.csv 默认 quote/NA/数值格式）
#   read_dataset_inf()   统一读取主索引 1_Data/Dataset_inf.csv（UTF-8 BOM、
#                        CRLF、QUOTE_MINIMAL；返回 data.frame，列名原样保留）
# 用法示例：
#   .ut <- file.path(dirname(dirname(.script_dir)), "2_Code", "utils.R")
#   source(.ut)
# ============================================================================

# ---- 项目根定位 ----
spe_root <- function(start = getwd()) {
  env <- Sys.getenv("SPE_DATABASE_ROOT", unset = "")
  if (nzchar(env) &&
      dir.exists(file.path(env, "1_Data")) &&
      dir.exists(file.path(env, "2_Code"))) {
    return(normalizePath(env))
  }
  d <- normalizePath(start)
  repeat {
    if (dir.exists(file.path(d, "1_Data")) &&
        dir.exists(file.path(d, "2_Code"))) {
      return(d)
    }
    p <- dirname(d)
    if (identical(p, d)) {
      stop("spe_root: 未找到含 1_Data 与 2_Code 的仓库根（起点: ", start, "）")
    }
    d <- p
  }
}

# ---- 统一写出 *_Clean.csv（默认 CRLF；数值/引号格式与 write.csv 一致） ----
write_clean_csv <- function(df, path, crlf = TRUE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (crlf) {
    tmp <- tempfile(fileext = ".csv")
    write.csv(df, tmp, row.names = FALSE)
    txt <- readLines(tmp, warn = FALSE)
    con <- file(path, open = "wb")
    writeLines(txt, con, sep = "\r\n", useBytes = TRUE)
    close(con)
    unlink(tmp)
  } else {
    write.csv(df, path, row.names = FALSE)
  }
  cat("  written:", path, "rows =", nrow(df), "\n")
  invisible(df)
}

# ---- 统一读取主索引 Dataset_inf.csv（UTF-8 BOM、CRLF、QUOTE_MINIMAL） ----
# fileEncoding="UTF-8-BOM" 剥离 BOM（否则第一列名 ID 带 \ufeff 前缀）；
# check.names=FALSE 保留原列名（含空格/斜杠，如 "EEG/fMRI Data"）。
read_dataset_inf <- function(root = NULL) {
  root <- if (is.null(root)) spe_root() else root
  path <- file.path(root, "1_Data", "Dataset_inf.csv")
  if (!file.exists(path)) {
    stop("read_dataset_inf: 未找到主索引 ", path)
  }
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
           fileEncoding = "UTF-8-BOM", na.strings = c("", "NA"))
}

# ============================================================================
# E-Prime 文本导出（*.txt，UTF-16LE）解析函数（2026-08 沉淀）
# ----------------------------------------------------------------------------
# 先例：Orellana-Corrales_2021_APP_clean.R（g7wrc/4cwrv E-Prime 导出重建 raw）；
# 适用：E-Prime 的 .txt 日志（每被试一个文件，UTF-16LE 含 BOM）。
# 要点：readLines(encoding="UTF-16LE") 直接读取（rawToChar 会因内嵌 nul 报错）；
# 按 "*** LogFrame Start/End ***" 切块；中断被试（会话中途退出）末尾可有
# 未闭合块（无 End 标记）——parse_matching_blocks 允许 start 比 end 多 1，
# 且无 MT.ACC 记录的未完成试次块不产出 trial 行。
# ============================================================================

# 读取 UTF-16LE 文本（E-Prime 导出，含 BOM），返回行向量
read_eprime_txt <- function(path) {
  con <- file(path, open = "r", encoding = "UTF-16LE")
  on.exit(close(con))
  readLines(con, warn = FALSE)
}

# Header Start/End 之间的键值对（Subject/Age/Sex/Handedness/Condition 等）
parse_header <- function(lines) {
  i0 <- grep("\\*\\*\\* Header Start", lines)
  i1 <- grep("\\*\\*\\* Header End", lines)
  stopifnot(length(i0) == 1, length(i1) == 1, i1 > i0)
  kv <- list()
  for (ln in lines[(i0 + 1):(i1 - 1)]) {
    m <- regexec("^\\s*([^:]+):\\s*(.*)$", ln)
    if (length(m[[1]]) == 3 && m[[1]][1] != -1) {
      parts <- regmatches(ln, m)[[1]]
      kv[[trimws(parts[2])]] <- trimws(parts[3])
    }
  }
  kv
}

# LogFrame 块中 Procedure == Matching 的块（每个返回一个具名列表）。
# 中断被试（如 Orellana-Corrales_2021_APP Exp2 nonwords-01）末尾可有未闭合块
# （无 LogFrame End），且未完成试次无 MT.ACC 记录——这类块不产出 trial 行。
parse_matching_blocks <- function(lines) {
  starts <- grep("\\*\\*\\* LogFrame Start", lines)
  ends <- grep("\\*\\*\\* LogFrame End", lines)
  stopifnot(length(ends) == length(starts) || length(ends) == length(starts) - 1)
  out <- list()
  for (i in seq_along(starts)) {
    block_end <- if (i <= length(ends)) ends[i] - 1 else length(lines)
    block <- lines[(starts[i] + 1):block_end]
    if (!any(grepl("^\\s*Procedure:\\s*Matching", block))) next
    kv <- list()
    for (ln in block) {
      m <- regexec("^\\s*([^:]+):\\s*(.*)$", ln)
      if (length(m[[1]]) == 3 && m[[1]][1] != -1) {
        parts <- regmatches(ln, m)[[1]]
        kv[[trimws(parts[2])]] <- trimws(parts[3])
      }
    }
    if (is.null(kv[["MT.ACC"]])) next   # 未完成试次（中断时无记录）
    out[[length(out) + 1]] <- kv
  }
  out
}
