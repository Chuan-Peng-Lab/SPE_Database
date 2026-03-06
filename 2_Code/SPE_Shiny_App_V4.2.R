# SPE数据库可视化清理工具 - Shiny网页版 v4.2
# ========================================
# 修复：Label预览问题
# ========================================

if (!require("shiny")) install.packages("shiny")
if (!require("dplyr")) install.packages("dplyr")

library(shiny)
library(dplyr)

# 数据读取
read_spe_data <- function(file_path) {
  encodings <- c("UTF-8-BOM", "UTF-8", "latin1", "")
  for (enc in encodings) {
    tryCatch({
      if (enc == "") {
        data <- read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)
      } else {
        data <- read.csv(file_path, stringsAsFactors = FALSE, fileEncoding = enc, check.names = FALSE)
      }
      if (nrow(data) > 0) return(data)
    }, error = function(e) NULL)
  }
  return(NULL)
}

# 变量检测
detect_vars <- function(data) {
  cols <- names(data)
  mapping <- list()
  
  required_patterns <- list(
    subject = c("Subject", "subject", "Participant", "participant", "V1"),
    shape = c("Shape", "shape", "Stimulus", "stimulus"),
    label = c("Label", "label", "Label1", "Label2"),
    matching = c("Matching", "matching", "Match", "match", "Condition", "condition", "V14"),
    acc = c("ACC", "acc", "corr", "correct", "Target.ACC", "respond3.ACC", "V15"),
    rt = c("RT_ms", "RT", "rt", "latency", "Target.RT", "respond3.RT", "V16", "RTTime"),
    response = c("Response", "response", "Resp", "resp", "V5", "Target.RESP")
  )
  
  optional_patterns <- list(
    block = c("Block", "block", "Procedure.Block.", "Running.Block.", "BlockList"),
    trial = c("Trial", "trial", "TrialNumber", "Trial.N", "SubTrial", "trialinblock", "TrialList"),
    trial_type = c("Practice", "practice", "Prac", "prac", "Phase", "phase", "Training", "Procedure.", "Running."),
    session = c("Session", "session", "Phase"),
    age = c("Age", "age"),
    sex = c("Sex", "sex", "Gender", "gender"),
    handedness = c("Hand", "hand", "Handedness", "handedness")
  )
  
  for (var_name in names(required_patterns)) {
    for (pattern in required_patterns[[var_name]]) {
      matches <- grep(pattern, cols, ignore.case = TRUE, value = TRUE)
      if (length(matches) > 0) {
        mapping[[var_name]] <- matches[1]
        break
      }
    }
  }
  
  for (var_name in names(optional_patterns)) {
    for (pattern in optional_patterns[[var_name]]) {
      matches <- grep(pattern, cols, ignore.case = TRUE, value = TRUE)
      if (length(matches) > 0) {
        mapping[[var_name]] <- matches[1]
        break
      }
    }
  }
  
  return(mapping)
}

# 自动检测Identity
auto_detect_identity <- function(val) {
  val_lower <- tolower(val)
  if (grepl("self|you|自我|自己|Sie|你", val_lower)) return("Self")
  if (grepl("friend|close|familiar|朋友|Freund", val_lower)) return("Close")
  if (grepl("stranger|other|陌生人|Fremder", val_lower)) return("Stranger")
  if (grepl("acquaintance|熟人", val_lower)) return("Acquaintance")
  if (grepl("celebrity|名人", val_lower)) return("Celebrity")
  if (grepl("nonperson|object|none|物体", val_lower)) return("NonPerson")
  if (grepl("moral", val_lower)) return("Self")
  if (grepl("immoral", val_lower)) return("Self")
  return("Unknown")
}

# UI
ui <- fluidPage(
  titlePanel("SPE数据库可视化清理工具 v4.2"),
  
  wellPanel(
    h3("📂 原始数据预览"),
    helpText("加载数据后显示原始文件内容"),
    dataTableOutput("raw_data_top"),
    verbatimTextOutput("raw_data_info")
  ),
  
  hr(),
  
  sidebarLayout(
    sidebarPanel(
      h3("步骤1: 输入文件"),
      textInput("file_path", "文件路径:", placeholder = "D:/path/to/file.csv"),
      actionButton("load_btn", "加载数据", icon = icon("upload")),
      hr(),
      h4("操作按钮"),
      actionButton("auto_detect_btn", "自动检测变量", icon = icon("search"), class = "btn-success"),
      actionButton("preview_identity_btn", "预览Shape/Label值", icon = icon("eye"), class = "btn-info"),
      actionButton("clean_btn", "开始清理", icon = icon("play"), class = "btn-primary"),
      hr(),
      downloadButton("download_btn", "下载清理后的数据", icon = icon("download")),
      hr(),
      verbatimTextOutput("status")
    ),
    
    mainPanel(
      h3("步骤2: 变量映射"),
      helpText("红色*为必选变量。点击'自动检测'后确认修改。"),
      
      wellPanel(h5("必需变量 *"), uiOutput("required_mapping_ui")),
      wellPanel(h5("可选变量 (可选择'无')"), uiOutput("optional_mapping_ui")),
      wellPanel(
        h5("添加额外变量"),
        fluidRow(
          column(6, textInput("extra_name", "新变量名", placeholder = "如: Mood")),
          column(6, textInput("extra_col", "原始列名", placeholder = "如: Mood_Type"))
        ),
        actionButton("add_extra_btn", "添加", icon = icon("plus")),
        uiOutput("extra_vars_ui")
      ),
      
      hr(),
      
      h3("步骤3: Identity映射"),
      helpText("为Shape和Label的每个值指定Identity类别"),
      
      wellPanel(
        h4("Shape Identity 映射"),
        uiOutput("shape_identity_mapping_ui"),
        actionButton("apply_shape_mapping", "应用Shape映射", class = "btn-success btn-sm")
      ),
      
      wellPanel(
        h4("Label Identity 映射"),
        uiOutput("label_identity_mapping_ui"),
        actionButton("apply_label_mapping", "应用Label映射", class = "btn-success btn-sm")
      ),
      
      wellPanel(h4("已应用的映射"), verbatimTextOutput("applied_mappings")),
      
      hr(),
      
      h3("步骤4: 清理后数据预览"),
      wellPanel(
        h4("📊 数据统计"),
        fluidRow(
          column(4, verbatimTextOutput("stats_rows")),
          column(4, verbatimTextOutput("stats_cols")),
          column(4, verbatimTextOutput("stats_subjects"))
        )
      ),
      wellPanel(h4("✅ Matching验证"), tableOutput("matching_table")),
      wellPanel(
        h4("📋 Identity分布"),
        h5("Shape_Standardized_Identity:"), tableOutput("shape_identity_table"),
        h5("Label_Standardized_Identity:"), tableOutput("label_identity_table")
      ),
      wellPanel(h4("📄 清理后数据预览 (前20行)"), dataTableOutput("cleaned_preview"))
    )
  )
)

# Server
server <- function(input, output, session) {
  rv <- reactiveValues(
    data = NULL, cleaned = NULL, mapping = NULL, extra_vars = list(),
    shape_values = character(0), label_values = character(0),
    shape_identity_map = list(), label_identity_map = list(),
    applied_shape_map = list(), applied_label_map = list(),
    loaded = FALSE
  )
  
  # 加载数据
  observeEvent(input$load_btn, {
    fp <- input$file_path
    fp <- gsub('["\']', '', fp)
    fp <- gsub('\\\\', '/', fp)
    if (!grepl('^[A-Za-z]:', fp)) fp <- file.path(getwd(), fp)
    
    if (!file.exists(fp)) {
      output$status <- renderText("错误: 文件不存在!")
      return()
    }
    
    data <- read_spe_data(fp)
    if (is.null(data)) {
      output$status <- renderText("错误: 无法读取文件!")
      return()
    }
    
    rv$data <- data
    rv$mapping <- detect_vars(data)
    rv$extra_vars <- list()
    rv$shape_values <- character(0)
    rv$label_values <- character(0)
    rv$shape_identity_map <- list()
    rv$label_identity_map <- list()
    rv$applied_shape_map <- list()
    rv$applied_label_map <- list()
    rv$loaded <- TRUE
    rv$cleaned <- NULL
    
    output$status <- renderText(sprintf("已加载: %d行 × %d列\n请在步骤2选择变量后，点击'预览Shape/Label值'", nrow(data), ncol(data)))
  })
  
  # 自动检测
  observeEvent(input$auto_detect_btn, {
    req(rv$loaded, rv$data)
    rv$mapping <- detect_vars(rv$data)
    output$status <- renderText("✅ 已自动检测变量映射!")
  })
  
  # 预览Shape/Label值 - 修复版
  observeEvent(input$preview_identity_btn, {
    req(rv$loaded, rv$data)
    
    # 先检查用户是否在步骤2中选择了Shape和Label列
    # 如果用户已经选择了，使用用户选择的
    user_shape <- input$map_shape
    user_label <- input$map_label
    
    # 获取Shape列
    shape_col <- NA
    if (!is.null(user_shape) && user_shape != "" && user_shape != "__NONE__") {
      shape_col <- user_shape
    } else if (!is.null(rv$mapping$shape)) {
      shape_col <- rv$mapping$shape
    }
    
    # 获取Label列 - 关键修复
    label_col <- NA
    if (!is.null(user_label) && user_label != "" && user_label != "__NONE__") {
      label_col <- user_label
    } else if (!is.null(rv$mapping$label)) {
      label_col <- rv$mapping$label
    }
    
    # 如果还是没有，尝试从数据中查找可能的Label列
    if (is.na(label_col)) {
      cols <- names(rv$data)
      label_candidates <- grep("label|Label", cols, value = TRUE, ignore.case = TRUE)
      if (length(label_candidates) > 0) {
        label_col <- label_candidates[1]
      }
    }
    
    # 获取Shape值
    if (!is.na(shape_col) && shape_col %in% names(rv$data)) {
      rv$shape_values <- unique(na.omit(as.character(rv$data[[shape_col]])))
    }
    
    # 获取Label值 - 关键修复
    if (!is.na(label_col) && label_col %in% names(rv$data)) {
      rv$label_values <- unique(na.omit(as.character(rv$data[[label_col]])))
    }
    
    # 初始化映射
    if (length(rv$shape_values) > 0) {
      for (val in rv$shape_values) {
        if (is.null(rv$shape_identity_map[[val]])) {
          rv$shape_identity_map[[val]] <- auto_detect_identity(val)
        }
      }
    }
    
    if (length(rv$label_values) > 0) {
      for (val in rv$label_values) {
        if (is.null(rv$label_identity_map[[val]])) {
          rv$label_identity_map[[val]] <- auto_detect_identity(val)
        }
      }
    }
    
    # 输出状态
    msg <- sprintf("已检测: Shape=%d个值, Label=%d个值", 
                  length(rv$shape_values), length(rv$label_values))
    if (length(rv$label_values) == 0) {
      msg <- paste0(msg, "\n⚠️ 警告: 未检测到Label列，请在步骤2中选择Label对应的列名")
    }
    output$status <- renderText(msg)
  })
  
  # 渲染Shape Identity映射UI
  output$shape_identity_mapping_ui <- renderUI({
    req(length(rv$shape_values) > 0)
    identity_options <- c("Self", "Close", "Acquaintance", "Celebrity", "Stranger", "NonPerson", "Unknown")
    
    lapply(rv$shape_values, function(val) {
      current_val <- rv$shape_identity_map[[val]]
      if (is.null(current_val)) current_val <- "Unknown"
      fluidRow(
        column(4, strong(val)),
        column(4, selectInput(paste0("shape_map_", val), label = NULL, choices = identity_options, selected = current_val)),
        column(4, textInput(paste0("shape_custom_", val), label = "手动输入", value = ifelse(current_val == "Unknown", "", current_val)))
      )
    })
  })
  
  # 渲染Label Identity映射UI
  output$label_identity_mapping_ui <- renderUI({
    req(length(rv$label_values) > 0)
    identity_options <- c("Self", "Close", "Acquaintance", "Celebrity", "Stranger", "NonPerson", "Unknown")
    
    lapply(rv$label_values, function(val) {
      current_val <- rv$label_identity_map[[val]]
      if (is.null(current_val)) current_val <- "Unknown"
      fluidRow(
        column(4, strong(val)),
        column(4, selectInput(paste0("label_map_", val), label = NULL, choices = identity_options, selected = current_val)),
        column(4, textInput(paste0("label_custom_", val), label = "手动输入", value = ifelse(current_val == "Unknown", "", current_val)))
      )
    })
  })
  
  # 应用映射
  observeEvent(input$apply_shape_mapping, {
    req(length(rv$shape_values) > 0)
    for (val in rv$shape_values) {
      custom_val <- input[[paste0("shape_custom_", val)]]
      if (!is.null(custom_val) && trimws(custom_val) != "") {
        rv$shape_identity_map[[val]] <- trimws(custom_val)
      } else {
        select_val <- input[[paste0("shape_map_", val)]]
        if (!is.null(select_val)) rv$shape_identity_map[[val]] <- select_val
      }
    }
    rv$applied_shape_map <- rv$shape_identity_map
    output$status <- renderText(sprintf("✅ Shape映射已应用 (%d个值)", length(rv$applied_shape_map)))
  })
  
  observeEvent(input$apply_label_mapping, {
    req(length(rv$label_values) > 0)
    for (val in rv$label_values) {
      custom_val <- input[[paste0("label_custom_", val)]]
      if (!is.null(custom_val) && trimws(custom_val) != "") {
        rv$label_identity_map[[val]] <- trimws(custom_val)
      } else {
        select_val <- input[[paste0("label_map_", val)]]
        if (!is.null(select_val)) rv$label_identity_map[[val]] <- select_val
      }
    }
    rv$applied_label_map <- rv$label_identity_map
    output$status <- renderText(sprintf("✅ Label映射已应用 (%d个值)", length(rv$applied_label_map)))
  })
  
  output$applied_mappings <- renderText({
    txt <- ""
    if (length(rv$applied_shape_map) > 0) {
      txt <- paste0(txt, "Shape映射:\n")
      for (nm in names(rv$applied_shape_map)) txt <- paste0(txt, sprintf("  %s -> %s\n", nm, rv$applied_shape_map[[nm]]))
    }
    if (length(rv$applied_label_map) > 0) {
      txt <- paste0(txt, "\nLabel映射:\n")
      for (nm in names(rv$applied_label_map)) txt <- paste0(txt, sprintf("  %s -> %s\n", nm, rv$applied_label_map[[nm]]))
    }
    if (txt == "") txt <- "暂无映射"
    txt
  })
  
  # 渲染变量映射UI
  output$required_mapping_ui <- renderUI({
    req(rv$loaded)
    cols <- names(rv$data)
    choices_with_none <- c("无" = "__NONE__", cols)
    required_vars <- c("subject", "shape", "label", "matching", "acc", "rt", "response")
    labels <- c("Subject *", "Shape *", "Label *", "Matching *", "ACC *", "RT(ms) *", "Response")
    
    lapply(1:length(required_vars), function(i) {
      var <- required_vars[i]
      lbl <- labels[i]
      sel <- rv$mapping[[var]]
      fluidRow(
        column(3, strong(lbl)),
        column(9, selectInput(paste0("map_", var), label = NULL, choices = choices_with_none, selected = ifelse(is.null(sel), "", sel)))
      )
    })
  })
  
  output$optional_mapping_ui <- renderUI({
    req(rv$loaded)
    cols <- names(rv$data)
    choices_with_none <- c("无" = "__NONE__", cols)
    optional_vars <- c("block", "trial", "trial_type", "session", "age", "sex", "handedness")
    labels <- c("Block", "Trial", "Trial_Type", "Session", "Age", "Sex", "Handedness")
    
    lapply(1:length(optional_vars), function(i) {
      var <- optional_vars[i]
      lbl <- labels[i]
      sel <- rv$mapping[[var]]
      fluidRow(
        column(3, lbl),
        column(9, selectInput(paste0("map_", var), label = NULL, choices = choices_with_none, selected = ifelse(is.null(sel), "__NONE__", sel)))
      )
    })
  })
  
  observeEvent(input$add_extra_btn, {
    name <- trimws(input$extra_name)
    col <- trimws(input$extra_col)
    if (name != "" && col != "" && !is.null(rv$data) && col %in% names(rv$data)) {
      rv$extra_vars[[name]] <- col
      updateTextInput(session, "extra_name", value = "")
      updateTextInput(session, "extra_col", value = "")
    }
  })
  
  output$extra_vars_ui <- renderUI({
    req(length(rv$extra_vars) > 0)
    lapply(names(rv$extra_vars), function(nm) fluidRow(column(12, strong(sprintf("%s -> %s", nm, rv$extra_vars[[nm]])))))
  })
  
  # 清理数据
  observeEvent(input$clean_btn, {
    req(rv$loaded, rv$data)
    
    # 更新映射 - 先获取用户选择的值
    required_vars <- c("subject", "shape", "label", "matching", "acc", "rt", "response")
    for (var in required_vars) {
      val <- input[[paste0("map_", var)]]
      if (!is.null(val) && val != "" && val != "__NONE__") {
        rv$mapping[[var]] <- val
      }
    }
    
    optional_vars <- c("block", "trial", "trial_type", "session", "age", "sex", "handedness")
    for (var in optional_vars) {
      val <- input[[paste0("map_", var)]]
      if (!is.null(val)) {
        if (val == "__NONE__") {
          rv$mapping[[var]] <- NULL
        } else if (val != "") {
          rv$mapping[[var]] <- val
        }
      }
    }
    
    rv$cleaned <- clean_data_advanced(rv$data, rv$mapping, rv$extra_vars, rv$applied_shape_map, rv$applied_label_map)
    output$status <- renderText(sprintf("✅ 清理完成! %d行 × %d列", nrow(rv$cleaned), ncol(rv$cleaned)))
  })
  
  # 清理函数
  clean_data_advanced <- function(data, mapping, extra_vars, shape_map, label_map) {
    n <- nrow(data)
    out <- data.frame(Subject = 1:n, stringsAsFactors = FALSE)
    
    if (!is.null(mapping$subject)) out$Subject <- as.numeric(as.character(data[[mapping$subject]]))
    if (!is.null(mapping$shape)) out$Shape <- as.character(data[[mapping$shape]]) else out$Shape <- NA
    if (!is.null(mapping$label)) out$Label <- as.character(data[[mapping$label]]) else out$Label <- NA
    
    if (!is.null(mapping$matching)) {
      m <- as.character(data[[mapping$matching]])
      out$Matching <- ifelse(grepl("match|Match|1|true|yes", m, ignore.case = TRUE), "Matching", "Nonmatching")
    } else if (!is.null(mapping$shape) && !is.null(mapping$label)) {
      out$Matching <- ifelse(out$Shape == out$Label, "Matching", "Nonmatching")
    } else {
      out$Matching <- "Unknown"
    }
    
    if (!is.null(mapping$acc)) { a <- as.numeric(data[[mapping$acc]]); out$ACC <- ifelse(a > 0, 1, 0) } else out$ACC <- NA
    if (!is.null(mapping$rt)) {
      r <- as.numeric(data[[mapping$rt]])
      if (median(r, na.rm = TRUE) < 10) { out$RT_ms <- r * 1000; out$RT_sec <- r } else { out$RT_ms <- r; out$RT_sec <- r / 1000 }
    } else { out$RT_ms <- NA; out$RT_sec <- NA }
    
    if (!is.null(mapping$response)) out$Response <- as.character(data[[mapping$response]])
    if (!is.null(mapping$block)) out$Block <- as.numeric(data[[mapping$block]])
    if (!is.null(mapping$trial)) out$Trial <- as.numeric(data[[mapping$trial]])
    if (!is.null(mapping$trial_type)) { tt <- as.character(data[[mapping$trial_type]]); out$Trial_Type <- ifelse(grepl("prac|practice|training", tt, ignore.case = TRUE), "Practice", "Formal") }
    if (!is.null(mapping$session)) out$Session <- as.character(data[[mapping$session]])
    if (!is.null(mapping$age)) out$Age <- as.numeric(data[[mapping$age]])
    if (!is.null(mapping$sex)) out$Sex <- as.character(data[[mapping$sex]])
    if (!is.null(mapping$handedness)) out$Handedness <- as.character(data[[mapping$handedness]])
    
    # Identity
    out$Shape_Origin_Identity <- out$Shape
    out$Label_Origin_Identity <- out$Label
    
    get_identity <- function(val, custom_map) {
      if (!is.null(custom_map) && length(custom_map) > 0 && !is.null(custom_map[[as.character(val)]])) return(custom_map[[as.character(val)]])
      val_lower <- tolower(val)
      if (grepl("self|you|自我|自己|Sie|你", val_lower)) return("Self")
      if (grepl("friend|close|familiar|朋友|Freund", val_lower)) return("Close")
      if (grepl("stranger|other|陌生人|Fremder", val_lower)) return("Stranger")
      if (grepl("acquaintance|熟人", val_lower)) return("Acquaintance")
      if (grepl("celebrity|名人", val_lower)) return("Celebrity")
      if (grepl("nonperson|object|none|物体", val_lower)) return("NonPerson")
      if (grepl("moral", val_lower)) return("Self")
      if (grepl("immoral", val_lower)) return("Self")
      return("Unknown")
    }
    
    out$Shape_English_Identity <- sapply(out$Shape, function(x) get_identity(x, shape_map))
    out$Shape_Standardized_Identity <- out$Shape_English_Identity
    out$Label_English_Identity <- sapply(out$Label, function(x) get_identity(x, label_map))
    out$Label_Standardized_Identity <- out$Label_English_Identity
    
    # 额外变量
    for (i in seq_along(extra_vars)) {
      col_name <- extra_vars[[i]]
      var_name <- names(extra_vars)[i]
      if (col_name %in% names(data)) out[[var_name]] <- as.character(data[[col_name]])
    }
    
    out$Matching <- factor(out$Matching, levels = c("Matching", "Nonmatching", "Unknown"))
    out <- out %>% filter(!is.na(Subject))
    return(out)
  }
  
  # 输出
  output$raw_data_top <- renderDataTable({ req(rv$loaded, rv$data); head(rv$data, 50) }, options = list(pageLength = 50, scrollX = TRUE))
  output$raw_data_info <- renderText({ req(rv$loaded, rv$data); sprintf("原始数据: %d 行 × %d 列", nrow(rv$data), ncol(rv$data)) })
  output$stats_rows <- renderText({ req(rv$cleaned); paste0("行数: ", nrow(rv$cleaned)) })
  output$stats_cols <- renderText({ req(rv$cleaned); paste0("列数: ", ncol(rv$cleaned)) })
  output$stats_subjects <- renderText({ req(rv$cleaned); paste0("被试数: ", length(unique(rv$cleaned$Subject))) })
  output$matching_table <- renderTable({ req(!is.null(rv$cleaned)); as.data.frame(table(rv$cleaned$Matching, useNA = "ifany")) })
  output$shape_identity_table <- renderTable({ req(!is.null(rv$cleaned)); as.data.frame(table(rv$cleaned$Shape_Standardized_Identity, useNA = "ifany")) })
  output$label_identity_table <- renderTable({ req(!is.null(rv$cleaned)); as.data.frame(table(rv$cleaned$Label_Standardized_Identity, useNA = "ifany")) })
  output$cleaned_preview <- renderDataTable({ req(!is.null(rv$cleaned)); head(rv$cleaned, 20) }, options = list(pageLength = 20, scrollX = TRUE))
  
  output$download_btn <- downloadHandler(
    filename = function() {
      fp <- input$file_path
      fp <- gsub('["\']', '', fp)
      nm <- basename(fp)
      sub("_raw\\.csv$", "_Clean.csv", nm, ignore.case = TRUE)
    },
    content = function(file) write.csv(rv$cleaned, file, row.names = FALSE, fileEncoding = "UTF-8")
  )
}

shinyApp(ui = ui, server = server)