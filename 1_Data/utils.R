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
