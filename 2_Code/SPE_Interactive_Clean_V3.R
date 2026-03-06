# SPE数据库改进版自动化清理工具 v3.0
# ========================================
# 改进内容：
# 1. Shape保留原始刺激（名称/路径/图片）
# 2. 检查Matching条件
# 3. Label三级标准化
# 4. Block和Trial识别
# 5. Trial_Type识别（练习vs正式）
# ========================================

# 加载必要包
if (!require("dplyr", quietly = TRUE)) install.packages("dplyr", repos = "https://cloud.r-project.org")
if (!require("readr", quietly = TRUE)) install.packages("readr", repos = "https://cloud.r-project.org")
library(dplyr)
library(readr)

# ============================================================================
# 第一部分：Clean_Data_V3.Rmd 数据清理逻辑总结
# ============================================================================

# 根据分析，Clean_Data_V3.Rmd (5125行代码) 的清理逻辑遵循以下模式：

# 1. 变量选择（dplyr::select）- 最常见的变量映射：
# | 标准变量              | 可能的原始列名                                      |
# |----------------------|---------------------------------------------------|
# | Subject             | Subject, V1, Pair Number, participant            |
# | Shape               | Shape, V7, Stimulus (保留原始刺激)                |
# | Label               | Label, Label1, Label2, Label3                    |
# | Matching            | Matching, Condition, Match, V14                   |
# | ACC                 | ACC, corr, Target.ACC, respond3.ACC, V15         |
# | RT_ms               | RT_ms, RT, Target.RT, respond3.RT, V16           |
# | Block               | Block, block, Procedure[Block]                   |
# | Trial               | Trial, trial, TrialNumber                        |
# | Trial_Type          | Practice, Prac, Phase (练习/正式)                 |

# 2. Identity三级标准化：
# | 原始身份(Origin)     | 英语(English)    | 标准化(Standardized)      |
# |---------------------|-----------------|-------------------------|
# | Self, you, 我, Sie  | Self            | Self                    |
# | Friend, close, 朋友, Freund | Friend  | Close                   |
# | Stranger, other, 陌生人, Fremder | Stranger | Stranger         |
# | Acquaintance, 熟人 | Acquaintance    | Acquaintance            |
# | Celebrity, 名人    | Celebrity        | Celebrity                |
# | NonPerson, none    | NonPerson        | NonPerson               |

# ============================================================================
# 第二部分：改进的清理函数
# ============================================================================

#' 改进版：读取CSV文件（支持多种编码）
read_spe_file_v3 <- function(file_path) {
  encodings <- c("UTF-8-BOM", "UTF-8", "latin1", "GBK", "")
  
  for (enc in encodings) {
    tryCatch({
      if (enc == "") {
        data <- read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)
      } else {
        data <- read.csv(file_path, stringsAsFactors = FALSE, fileEncoding = enc, check.names = FALSE)
      }
      if (nrow(data) > 0) {
        return(data)
      }
    }, error = function(e) NULL)
  }
  stop("无法读取文件: ", basename(file_path))
}

#' 改进版：检测变量映射（更全面）
detect_variable_mapping_v3 <- function(data) {
  cols <- names(data)
  
  # 定义变量模式（更全面）
  patterns <- list(
    # 核心变量
    subject = c("Subject", "subject", "Participant", "participant", "Pair.Number", "V1", "Subj", "ID", "participant.Private.ID"),
    shape = c("Shape", "shape", "Stimulus", "stimulus", "Shape_Person1", "Shape_Person2", "Shape_Emotion1", "Shape_Emotion2"),
    label = c("Label", "label", "Label_Person1", "Label_Person2", "Label_Emotion1", "Label_Emotion2"),
    matching = c("Matching", "matching", "Match", "match", "Condition", "condition", "V14", "Matchness"),
    acc = c("ACC", "acc", "corr", "correct", "Target.ACC", "respond3.ACC", "V15", "PracEnd.ACC"),
    rt = c("RT_ms", "RT", "rt", "latency", "Target.RT", "respond3.RT", "V16", "RTTime", "PracEnd.RT"),
    response = c("Response", "response", "Resp", "resp", "V5", "Target.RESP"),
    
    # 额外变量
    block = c("Block", "block", "Procedure.Block.", "Running.Block.", "BlockList"),
    trial = c("Trial", "trial", "TrialNumber", "Trial.N", "SubTrial", "trialinblock", "TrialList"),
    trial_type = c("Practice", "practice", "Prac", "prac", "Phase", "phase", "Procedure.", "Running.", "PracTrial", "Training"),
    session = c("Session", "session", "Phase"),
    
    # 额外人口统计学变量
    age = c("Age", "age"),
    sex = c("Sex", "sex", "Gender", "gender"),
    handedness = c("Hand", "hand", "Handedness", "handedness")
  )
  
  # 自动检测映射
  mapping <- list()
  for (var_name in names(patterns)) {
    for (pattern in patterns[[var_name]]) {
      matches <- grep(pattern, cols, ignore.case = FALSE, value = TRUE)
      if (length(matches) > 0) {
        mapping[[var_name]] <- matches[1]
        break
      }
    }
  }
  
  return(mapping)
}

#' 改进版：变量审核（带额外变量选项）
review_variables_v3 <- function(mapping, data, file_name) {
  cat("\n")
  cat("============================================================\n")
  cat("  步骤2：变量审核\n")
  cat("============================================================\n")
  cat(sprintf("文件: %s\n", file_name))
  cat(sprintf("数据维度: %d 行 × %d 列\n", nrow(data), ncol(data)))
  cat("\n")
  
  # 标准变量列表
  std_vars <- c(
    # 核心变量
    "Subject", "Shape", "Label", "Matching", "ACC", "RT_ms", "Response",
    # 额外变量
    "Block", "Trial", "Trial_Type", "Session",
    # 人口统计学
    "Age", "Sex", "Handedness"
  )
  
  # 显示所有列供选择
  cat("可用列名 (共", length(names(data)), "列):\n")
  all_cols <- names(data)
  for (i in seq(1, length(all_cols), by = 5)) {
    end_idx <- min(i + 4, length(all_cols))
    cat(paste(sprintf("[%d] %s", i:end_idx, all_cols[i:end_idx]), collapse = "  "), "\n")
  }
  cat("\n")
  
  cat("检测到的变量映射:\n")
  cat("(直接回车确认，输入列名修改)\n")
  cat("------------------------------------------------------------\n")
  
  # 让用户确认/修改每个变量
  for (std_var in std_vars) {
    current_val <- mapping[[tolower(std_var)]]
    if (is.null(current_val)) current_val <- "[未检测到]"
    
    cat(sprintf("%-15s -> [%s]: ", std_var, current_val))
    input <- readline()
    
    if (trimws(input) != "") {
      if (input %in% names(data)) {
        mapping[[tolower(std_var)]] <- input
        cat(sprintf("  ✓ 已修改为: %s\n", input))
      } else {
        cat(sprintf("  ⚠ 列名不存在，跳过\n"))
      }
    }
  }
  
  # 添加额外变量
  cat("\n------------------------------------------------------------\n")
  cat("添加额外变量 (直接回车跳过)\n")
  cat("------------------------------------------------------------\n")
  
  while (TRUE) {
    cat("\n新变量名称 (如 Mood, Face 等): ")
    new_var_name <- trimws(readline())
    
    if (new_var_name == "") break
    
    cat(sprintf("对应原始列名: "))
    new_col_name <- trimws(readline())
    
    if (new_col_name != "" && new_col_name %in% names(data)) {
      mapping[[tolower(gsub(" ", "_", new_var_name))]] <- new_col_name
      cat(sprintf("  ✓ 已添加: %s -> %s\n", new_var_name, new_col_name))
    } else {
      cat(sprintf("  ⚠ 列名不存在\n"))
    }
  }
  
  cat("\n------------------------------------------------------------\n")
  cat("变量映射确认完成!\n")
  
  return(mapping)
}

#' 改进版：清理数据（包含所有改进）
clean_data_v3 <- function(data, mapping) {
  n <- nrow(data)
  
  # 创建输出数据框
  cleaned <- data.frame(
    Subject = numeric(n),
    stringsAsFactors = FALSE
  )
  
  # ===== 1. Subject =====
  if (!is.null(mapping$subject)) {
    cleaned$Subject <- as.numeric(as.character(data[[mapping$subject]]))
  } else {
    cleaned$Subject <- 1:n
  }
  
  # ===== 2. Shape (保留原始刺激) =====
  if (!is.null(mapping$shape)) {
    cleaned$Shape <- as.character(data[[mapping$shape]])
  } else {
    cleaned$Shape <- NA_character_
  }
  
  # ===== 3. Label =====
  if (!is.null(mapping$label)) {
    cleaned$Label <- as.character(data[[mapping$label]])
  } else {
    cleaned$Label <- NA_character_
  }
  
  # ===== 4. Matching (带验证) =====
  if (!is.null(mapping$matching)) {
    match_col <- as.character(data[[mapping$matching]])
    cleaned$Matching <- ifelse(
      grepl("match|Match|1|true|yes", match_col, ignore.case = TRUE),
      "Matching",
      "Nonmatching"
    )
  } else if (!is.null(mapping$shape) && !is.null(mapping$label)) {
    # 从Shape和Label推断
    cleaned$Matching <- ifelse(cleaned$Shape == cleaned$Label, "Matching", "Nonmatching")
  } else {
    cleaned$Matching <- "Unknown"
  }
  
  # ===== 5. ACC =====
  if (!is.null(mapping$acc)) {
    acc_col <- data[[mapping$acc]]
    acc_num <- as.numeric(as.character(acc_col))
    cleaned$ACC <- ifelse(acc_num > 0, 1, 0)
  } else {
    cleaned$ACC <- NA_real_
  }
  
  # ===== 6. RT =====
  if (!is.null(mapping$rt)) {
    rt_col <- data[[mapping$rt]]
    rt_num <- as.numeric(as.character(rt_col))
    
    rt_median <- median(rt_num, na.rm = TRUE)
    if (!is.na(rt_median) && rt_median < 10) {
      cleaned$RT_ms <- rt_num * 1000
      cleaned$RT_sec <- rt_num
    } else {
      cleaned$RT_ms <- rt_num
      cleaned$RT_sec <- rt_num / 1000
    }
  } else {
    cleaned$RT_ms <- NA_real_
    cleaned$RT_sec <- NA_real_
  }
  
  # ===== 7. Response =====
  if (!is.null(mapping$response)) {
    cleaned$Response <- as.character(data[[mapping$response]])
  } else {
    cleaned$Response <- NA_character_
  }
  
  # ===== 8. Block =====
  if (!is.null(mapping$block)) {
    block_col <- data[[mapping$block]]
    cleaned$Block <- as.numeric(as.character(block_col))
  } else {
    cleaned$Block <- NA_real_
  }
  
  # ===== 9. Trial =====
  if (!is.null(mapping$trial)) {
    trial_col <- data[[mapping$trial]]
    cleaned$Trial <- as.numeric(as.character(trial_col))
  } else {
    cleaned$Trial <- NA_real_
  }
  
  # ===== 10. Trial_Type (练习vs正式) =====
  if (!is.null(mapping$trial_type)) {
    trial_type_col <- as.character(data[[mapping$trial_type]])
    cleaned$Trial_Type <- ifelse(
      grepl("prac|practice|training", trial_type_col, ignore.case = TRUE),
      "Practice",
      "Formal"
    )
  } else {
    # 尝试从其他列推断
    if (!is.null(mapping$session)) {
      session_col <- as.character(data[[mapping$session]])
      cleaned$Trial_Type <- ifelse(
        grepl("prac|practice|training", session_col, ignore.case = TRUE),
        "Practice",
        "Formal"
      )
    } else {
      cleaned$Trial_Type <- "Unknown"
    }
  }
  
  # ===== 11. Session =====
  if (!is.null(mapping$session)) {
    cleaned$Session <- as.character(data[[mapping$session]])
  } else {
    cleaned$Session <- NA_character_
  }
  
  # ===== 12. 人口统计学变量 =====
  if (!is.null(mapping$age)) {
    cleaned$Age <- as.numeric(as.character(data[[mapping$age]]))
  } else {
    cleaned$Age <- NA_real_
  }
  
  if (!is.null(mapping$sex)) {
    cleaned$Sex <- as.character(data[[mapping$sex]])
  } else {
    cleaned$Sex <- NA_character_
  }
  
  if (!is.null(mapping$handedness)) {
    cleaned$Handedness <- as.character(data[[mapping$handedness]])
  } else {
    cleaned$Handedness <- NA_character_
  }
  
  # ===== 13. Identity标准化 - Shape =====
  cleaned$Shape_Origin_Identity <- cleaned$Shape
  
  # Shape_English_Identity
  to_english_shape <- function(x) {
    if (is.na(x) || x == "") return(NA)
    x <- tolower(x)
    if (grepl("self|you|自我|自己|Sie|你", x)) return("Self")
    if (grepl("friend|close|familiar|朋友|Freund", x)) return("Friend")
    if (grepl("stranger|other|陌生人|Fremder", x)) return("Stranger")
    if (grepl("acquaintance|熟人", x)) return("Acquaintance")
    if (grepl("celebrity|名人", x)) return("Celebrity")
    if (grepl("nonperson|object|none|物体", x)) return("NonPerson")
    if (grepl("moral", x)) return("Self")  # immoralSelf -> Self
    if (grepl("immoral", x)) return("Self")  # immoralOther -> Self
    return(x)  # 保留原始值（如Triangle, Circle等刺激名称）
  }
  cleaned$Shape_English_Identity <- sapply(cleaned$Shape, to_english_shape)
  
  # Shape_Standardized_Identity
  std_id_shape <- function(x) {
    if (is.na(x)) return(NA)
    if (x %in% c("Self", "self")) return("Self")
    if (x %in% c("Friend", "Close", "Familiar")) return("Close")
    if (x %in% c("Acquaintance")) return("Acquaintance")
    if (x %in% c("Celebrity")) return("Celebrity")
    if (x %in% c("Stranger", "Other")) return("Stranger")
    if (x %in% c("NonPerson", "None", "Object")) return("NonPerson")
    return("Unknown")  # 刺激名称（非身份）标记为Unknown
  }
  cleaned$Shape_Standardized_Identity <- sapply(cleaned$Shape_English_Identity, std_id_shape)
  
  # ===== 14. Identity标准化 - Label =====
  cleaned$Label_Origin_Identity <- cleaned$Label
  
  # Label_English_Identity
  to_english_label <- function(x) {
    if (is.na(x) || x == "") return(NA)
    x <- tolower(x)
    if (grepl("self|you|自我|自己|Sie|你", x)) return("Self")
    if (grepl("friend|close|familiar|朋友|Freund", x)) return("Friend")
    if (grepl("stranger|other|陌生人|Fremder", x)) return("Stranger")
    if (grepl("acquaintance|熟人", x)) return("Acquaintance")
    if (grepl("celebrity|名人", x)) return("Celebrity")
    if (grepl("nonperson|object|none|物体", x)) return("NonPerson")
    if (grepl("moral", x)) return("Self")
    if (grepl("immoral", x)) return("Self")
    return(x)
  }
  cleaned$Label_English_Identity <- sapply(cleaned$Label, to_english_label)
  
  # Label_Standardized_Identity
  std_id_label <- function(x) {
    if (is.na(x)) return(NA)
    if (x %in% c("Self", "self")) return("Self")
    if (x %in% c("Friend", "Close", "Familiar")) return("Close")
    if (x %in% c("Acquaintance")) return("Acquaintance")
    if (x %in% c("Celebrity")) return("Celebrity")
    if (x %in% c("Stranger", "Other")) return("Stranger")
    if (x %in% c("NonPerson", "None", "Object")) return("NonPerson")
    return("Unknown")
  }
  cleaned$Label_Standardized_Identity <- sapply(cleaned$Label_English_Identity, std_id_label)
  
  # ===== 15. 添加额外变量 =====
  extra_vars <- setdiff(names(mapping), c(
    "subject", "shape", "label", "matching", "acc", "rt", "response",
    "block", "trial", "trial_type", "session", "age", "sex", "handedness"
  ))
  
  for (var_name in extra_vars) {
    col_name <- mapping[[var_name]]
    if (!is.null(col_name) && col_name %in% names(data)) {
      # 转换变量名：mood -> Mood
      new_name <- paste0(toupper(substr(var_name, 1, 1)), substr(var_name, 2, nchar(var_name)))
      cleaned[[new_name]] <- as.character(data[[col_name]])
    }
  }
  
  # ===== 16. 设置因子 =====
  cleaned$Matching <- factor(cleaned$Matching, levels = c("Matching", "Nonmatching", "Unknown"))
  cleaned$Trial_Type <- factor(cleaned$Trial_Type, levels = c("Formal", "Practice", "Unknown"))
  cleaned$Shape_Standardized_Identity <- factor(
    cleaned$Shape_Standardized_Identity,
    levels = c("Self", "Close", "Acquaintance", "Celebrity", "Stranger", "NonPerson", "Unknown")
  )
  cleaned$Label_Standardized_Identity <- factor(
    cleaned$Label_Standardized_Identity,
    levels = c("Self", "Close", "Acquaintance", "Celebrity", "Stranger", "NonPerson", "Unknown")
  )
  
  # ===== 17. 移除无效行 =====
  cleaned <- cleaned %>% filter(!is.na(Subject))
  
  # ===== 18. Matching验证 =====
  match_table <- table(cleaned$Matching)
  if (length(match_table) == 1) {
    warning("警告: 所有试次的Matching条件相同！请检查原始数据。")
  }
  
  return(cleaned)
}

#' 保存清理后的数据
save_cleaned_data_v3 <- function(cleaned_data, input_path) {
  dir_path <- dirname(input_path)
  file_name <- basename(input_path)
  clean_name <- sub("_raw\\.csv$", "_Clean.csv", file_name, ignore.case = TRUE)
  
  if (clean_name == file_name) {
    clean_name <- sub("\\.csv$", "_Clean.csv", file_name)
  }
  
  output_path <- file.path(dir_path, clean_name)
  write.csv(cleaned_data, output_path, row.names = FALSE, fileEncoding = "UTF-8")
  
  return(output_path)
}

# ============================================================================
# 第三部分：交互式处理函数
# ============================================================================

process_single_file_v3 <- function() {
  cat("\n")
  cat("#############################################################\n")
  cat("#                                                           #\n")
  cat("#      SPE数据库交互式自动化清理工具 v3.0                   #\n")
  cat("#      (改进版: 支持更多变量、更严格的Matching验证)          #\n")
  cat("#                                                           #\n")
  cat("#############################################################\n")
  cat("\n")
  
  # ===== 步骤1：用户输入路径 =====
  cat("============================================================\n")
  cat("  步骤1：输入数据路径\n")
  cat("============================================================\n")
  cat("请输入原始数据文件路径:\n")
  cat("> ")
  
  user_input <- readline()
  
  # 标准化路径
  user_input <- trimws(user_input)
  user_input <- gsub('^["\']|["\']$', '', user_input)
  user_input <- gsub('\\\\', '/', user_input)
  
  if (!grepl('^[A-Za-z]:', user_input)) {
    file_path <- file.path(getwd(), user_input)
  } else {
    file_path <- user_input
  }
  
  if (!file.exists(file_path)) {
    cat("\n⚠ 错误: 文件不存在!\n")
    return(NULL)
  }
  
  cat(sprintf("\n✓ 文件路径已识别: %s\n", file_path))
  
  # ===== 步骤2：读取并检测变量 =====
  cat("\n============================================================\n")
  cat("  步骤2：读取数据并检测变量\n")
  cat("============================================================\n")
  
  data <- read_spe_file_v3(file_path)
  cat(sprintf("✓ 成功读取数据: %d 行 × %d 列\n", nrow(data), ncol(data)))
  
  mapping <- detect_variable_mapping_v3(data)
  cat(sprintf("✓ 自动检测到 %d 个变量映射\n", length(mapping)))
  
  # ===== 步骤3：用户审核变量 =====
  mapping <- review_variables_v3(mapping, data, basename(file_path))
  
  # ===== 步骤4：清理并保存 =====
  cat("\n============================================================\n")
  cat("  步骤3：数据清理并保存\n")
  cat("============================================================\n")
  
  cleaned_data <- clean_data_v3(data, mapping)
  cat(sprintf("✓ 数据清理完成: %d 行 × %d 列\n", nrow(cleaned_data), ncol(cleaned_data)))
  
  # Matching验证
  cat("\nMatching条件验证:\n")
  match_table <- table(cleaned_data$Matching)
  print(match_table)
  
  if (length(match_table) == 1) {
    cat("\n⚠ 警告: 所有试次的Matching条件相同！\n")
  }
  
  # 显示清理后数据摘要
  cat("\n清理后数据预览 (前5行):\n")
  print(head(cleaned_data, 5))
  
  # 显示变量列表
  cat("\n清理后变量列表:\n")
  cat(paste(names(cleaned_data), collapse = ", "), "\n")
  
  # 保存
  output_path <- save_cleaned_data_v3(cleaned_data, file_path)
  cat(sprintf("\n✓ 已保存到: %s\n", output_path))
  
  return(invisible(list(
    input = file_path,
    output = output_path,
    data = cleaned_data
  )))
}

# ============================================================================
# 第四部分：批量处理
# ============================================================================

batch_process_v3 <- function() {
  cat("\n")
  cat("#############################################################\n")
  cat("#      SPE数据库批量清理工具 v3.0                           #\n")
  cat("#############################################################\n\n")
  
  raw_files <- list.files(
    path = "../1_Data",
    pattern = "_raw\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  cat(sprintf("找到 %d 个原始数据文件\n\n", length(raw_files)))
  
  total <- length(raw_files)
  success <- 0
  failed <- 0
  skipped <- 0
  
  for (i in seq_along(raw_files)) {
    file_path <- raw_files[i]
    file_name <- basename(file_path)
    
    cat(sprintf("[%d/%d] %s\n", i, total, file_name))
    
    file_size <- tryCatch(file.info(file_path)$size, error = function(e) 0)
    if (is.na(file_size) || file_size < 100) {
      cat(sprintf("  ⚠ 跳过: 文件为空\n\n"))
      skipped <- skipped + 1
      next()
    }
    
    tryCatch({
      data <- read_spe_file_v3(file_path)
      mapping <- detect_variable_mapping_v3(data)
      cleaned_data <- clean_data_v3(data, mapping)
      output_path <- save_cleaned_data_v3(cleaned_data, file_path)
      
      success <- success + 1
      cat(sprintf("  ✓ %s (%d 行)\n\n", basename(output_path), nrow(cleaned_data)))
      
    }, error = function(e) {
      failed <- failed + 1
      cat(sprintf("  ✗ 错误: %s\n\n", e$message))
    })
  }
  
  cat("============================================================\n")
  cat(sprintf("处理完成! 总计: %d, 成功: %d, 跳过: %d, 失败: %d\n", 
              total, success, skipped, failed))
  cat("============================================================\n")
}

# ============================================================================
# 主菜单
# ============================================================================

main_menu_v3 <- function() {
  cat("\n")
  cat("#############################################################\n")
  cat("#      SPE数据库交互式自动化清理工具 v3.0                   #\n")
  cat("#############################################################\n")
  cat("\n")
  cat("  [1] 处理单个文件 (交互式)\n")
  cat("  [2] 批量处理所有文件\n")
  cat("  [0] 退出\n")
  cat("\n")
  
  cat("请输入选择 (0-2): ")
  choice <- readline()
  
  if (choice == "1") {
    process_single_file_v3()
  } else if (choice == "2") {
    batch_process_v3()
  } else if (choice == "0") {
    cat("再见!\n")
  }
}

if (sys.nframe() == 0) {
  main_menu_v3()
}

# ============================================================================
# 使用说明
# ============================================================================

# 改进内容说明:
# 1. Shape保留原始刺激（名称/路径/图片名称）
# 2. Matching验证（确保有Matching和NonMatching）
# 3. Label三级标准化（Origin/English/Standardized）
# 4. Block和Trial识别
# 5. Trial_Type识别（Practice/Formal）
# 6. 额外变量支持（Age, Sex, Mood等）
#
# 使用方法:
# 1. source("SPE_Interactive_Clean_V3.R")
# 2. 选择1处理单个文件（交互式）
# 3. 选择2批量处理
#
# 输出变量:
# Subject, Shape, Label, Matching, ACC, RT_ms, RT_sec, Response
# Block, Trial, Trial_Type, Session
# Age, Sex, Handedness
# Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity
# Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity
# [额外变量...]

# 注意: Shape_Standardized_Identity 对于刺激名称(Triangle, Circle等)会标记为Unknown