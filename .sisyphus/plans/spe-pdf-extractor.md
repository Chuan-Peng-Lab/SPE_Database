# SPE PDF Metadata Extractor — Work Plan

## TL;DR

> **Quick Summary**: Build a Streamlit-based Python tool that reads academic PDFs and extracts 34 structured metadata variables related to the Self-matching Paradigm Experiment (SPE), outputting results as a bilingual CSV table.
>
> **Deliverables**:
> - `extract_spe.py` — Core extraction pipeline (PDF → LLM → structured data)
> - `models.py` — Pydantic data models for 34 variables + bilingual column mapping
> - `pdf_reader.py` — PDF text extraction module (PyMuPDF)
> - `llm_client.py` — DeepSeek API client + prompt templates
> - `app.py` — Streamlit web UI (API key input, PDF selection, results table, CSV download)
> - `requirements.txt` — Python dependencies
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: models.py → llm_client.py → extract_spe.py → app.py

---

## Context

### Original Request
User wants a Python tool to read academic PDFs (single file or folder) and extract 34 structured variables about SPE experiments, outputting to CSV. They have a DeepSeek API key and want a Streamlit UI for ease of use. Output should be bilingual (Chinese/English).

### Interview Summary
**Key Discussions**:
- **LLM Provider**: DeepSeek API (OpenAI-compatible format, base_url: https://api.deepseek.com)
- **UI Framework**: Streamlit web application
- **Extraction Depth**: Section-based (abstract + methods focus for SPE-specific variables)
- **Language**: Bilingual UI (Chinese/English switch) + bilingual CSV output
- **Variable Scope**: All 34 variables retained; missing data filled with N/A
- **Independence**: Standalone tool, no dependency on existing Dataset_inf.xlsx
- **File_Name Convention**: Author_Year_Journal abbreviation (user's existing format)
- **Output Location**: `D:\GitHub_programe\GitHub\SPE_Database\Datasets\6_AI-Tool\`

**Research Findings**:
- PyMuPDF (pymupdf) is the fastest and most reliable Python PDF text extraction library
- DeepSeek API uses OpenAI-compatible format — can use `openai` Python library with custom `base_url`
- Pydantic models + `response_format` parameter ensures structured JSON output from LLM
- Streamlit provides rapid prototyping for data apps with minimal boilerplate

### Self-Closing Review
**Identified Gaps** (addressed):
- PDFs with scanned images may fail text extraction → add warning + skip with N/A
- Very long PDFs may exceed LLM context → section-based extraction (abstract + methods)
- Multiple experiments per paper → extract as separate rows (one per experiment)
- API rate limits → add retry logic with exponential backoff
- Non-English papers → DeepSeek handles Chinese well, no special treatment needed

---

## Work Objectives

### Core Objective
Create a standalone Python/Streamlit tool that automates the extraction of 34 SPE-related metadata variables from academic PDFs using DeepSeek LLM, replacing manual data entry.

### Concrete Deliverables
1. `requirements.txt` — Python dependencies
2. `models.py` — Pydantic schemas for extraction output + bilingual column name mapping
3. `pdf_reader.py` — PDF text extraction (single file + folder batch)
4. `llm_client.py` — DeepSeek API wrapper + prompt templates
5. `extract_spe.py` — End-to-end extraction pipeline
6. `app.py` — Streamlit UI with bilingual support
7. `README.md` — Usage instructions

### Definition of Done
- [ ] User can upload a PDF or select a folder via Streamlit UI
- [ ] All 34 variables are extracted (with N/A for missing)
- [ ] CSV output matches the specified column schema
- [ ] Bilingual UI switch works (Chinese ↔ English)
- [ ] CSV download button produces valid CSV file
- [ ] Tool handles errors gracefully (corrupt PDF, API failure, rate limit)

### Must Have
- Two input modes: single PDF path + folder path
- 34 output columns as specified
- DeepSeek API integration
- Streamlit web UI
- Bilingual output (Chinese/English)
- CSV export
- Error handling for unreadable PDFs and API failures

### Must NOT Have (Guardrails)
- Do NOT depend on existing Dataset_inf.xlsx or manual tables
- Do NOT store API keys in files (session-only)
- Do NOT over-engineer: no database, no user accounts, no complex auth
- Do NOT add PDF download/scraping functionality (user provides PDFs)
- Do NOT modify the 34-variable schema without user approval

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: NO
- **Automated tests**: None (manual verification via Streamlit UI)
- **Framework**: N/A
- **Agent-Executed QA**: Playwright for Streamlit UI testing

### QA Policy
Every task includes agent-executed QA scenarios using:
- **UI**: Playwright — open Streamlit, interact, verify DOM
- **API**: Bash (curl) — test DeepSeek API connectivity
- **Module**: Bash (python) — import and call functions directly

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — foundation):
├── Task 1: Project setup + requirements.txt [quick]
├── Task 2: Pydantic models + bilingual column mapping [quick]
└── Task 3: PDF text extraction module [unspecified-low]

Wave 2 (After Wave 1 — core logic):
├── Task 4: DeepSeek LLM client + prompt templates [deep]
└── Task 5: End-to-end extraction pipeline [deep]

Wave 3 (After Wave 2 — UI):
├── Task 6: Streamlit UI — input controls + API key [visual-engineering]
└── Task 7: Streamlit UI — results table + download + bilingual [visual-engineering]

Wave FINAL (After ALL tasks):
├── Task F1: Integration QA — full pipeline test [unspecified-high]
└── Task F2: README + usage docs [writing]
```

### Dependency Matrix
- **T1**: None → T4, T5, T6
- **T2**: None → T4, T5
- **T3**: None → T5
- **T4**: T2 → T5
- **T5**: T2, T3, T4 → T6, T7
- **T6**: T5 → T7
- **T7**: T5, T6 → F1, F2

### Critical Path
T2 (models) → T4 (LLM client) → T5 (pipeline) → T6 (UI) → T7 (display) → F1 (QA)

---

## TODOs

- [ ] 1. Project setup + requirements.txt

  **What to do**:
  - Create `requirements.txt` in `Datasets/6_AI-Tool/` with dependencies:
    - `pymupdf` (PDF text extraction)
    - `openai` (DeepSeek API client, OpenAI-compatible)
    - `pydantic>=2.0` (data validation)
    - `pandas` (CSV output)
    - `streamlit` (web UI)
  - Create empty `__init__.py` if needed for module structure
  - Verify all packages install correctly

  **Must NOT do**:
  - Do NOT create virtual environment (user manages their own)
  - Do NOT add unrelated dependencies

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple file creation with standard Python dependencies
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None needed

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: Task 4, 5, 6
  - **Blocked By**: None

  **References**:
  - DeepSeek API docs: `https://platform.deepseek.com/api-docs/` — confirms OpenAI-compatible SDK usage
  - PyMuPDF PyPI: `https://pypi.org/project/PyMuPDF/` — latest version and install command
  - Streamlit docs: `https://docs.streamlit.io/` — installation requirements

  **Acceptance Criteria**:
  - [ ] `requirements.txt` exists with all 5 dependencies listed
  - [ ] `pip install -r requirements.txt` completes without errors

  **QA Scenarios**:
  ```
  Scenario: Install dependencies from requirements.txt
    Tool: Bash (pip)
    Preconditions: Python 3.9+ environment available
    Steps:
      1. Run: pip install -r requirements.txt
      2. Verify: python -c "import pymupdf, openai, pydantic, pandas, streamlit"
    Expected Result: All imports succeed without ImportError
    Failure Indicators: Any ImportError or pip install failure
    Evidence: .sisyphus/evidence/task-1-install.log

  Scenario: Verify DeepSeek API compatibility
    Tool: Bash (python)
    Preconditions: Dependencies installed
    Steps:
      1. Run: python -c "from openai import OpenAI; c = OpenAI(api_key='test', base_url='https://api.deepseek.com'); print('OK')"
    Expected Result: Prints "OK" — no error
    Failure Indicators: Import error or client initialization failure
    Evidence: .sisyphus/evidence/task-1-deepseek-check.log
  ```

  **Commit**: NO (wait for wave completion)
  - Message: N/A
  - Files: `Datasets/6_AI-Tool/requirements.txt`

- [ ] 2. Pydantic models + bilingual column mapping

  **What to do**:
  - Create `models.py` in `Datasets/6_AI-Tool/`
  - Define `SPEMetadata` Pydantic model with all 34 fields:
    ```python
    class SPEMetadata(BaseModel):
        behavior_data: Optional[str] = Field(default="N/A", description="Whether behavioral data (RT, ACC) is collected: Yes/No")
        questionnaire_data: Optional[str] = Field(default="N/A", description="Whether questionnaire data is collected: Yes/No")
        eeg_fmri_data: Optional[str] = Field(default="N/A", description="Whether EEG/fMRI data is collected: Yes/No")
        corresponding_author: Optional[str] = Field(default="N/A")
        email: Optional[str] = Field(default="N/A")
        author: Optional[str] = Field(default="N/A", description="First author name")
        year: Optional[str] = Field(default="N/A")
        journal: Optional[str] = Field(default="N/A")
        exp: Optional[str] = Field(default="N/A", description="Experiment number(s), e.g. Exp1, Exp2")
        study: Optional[str] = Field(default="N/A", description="Study number if applicable")
        # ... all 34 fields
    ```
  - Define `ExtractionResult` model wrapping list of `SPEMetadata` (for multiple experiments)
  - Define bilingual column mapping:
    ```python
    COLUMNS_EN = ["Behavior_Data", "Questionnaire_Data", ..., "License"]
    COLUMNS_ZH = ["行为数据", "问卷数据", ..., "许可证"]
    COLUMN_MAP = dict(zip(COLUMNS_EN, COLUMNS_ZH))
    ```
  - Define field-to-column mapping for Pydantic → DataFrame conversion

  **Must NOT do**:
  - Do NOT change the 34-variable schema without user approval
  - Do NOT add extra fields beyond the specified 34

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Data modeling task — straightforward Pydantic schema definition
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None needed

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: Task 4, 5
  - **Blocked By**: None

  **References**:
  - Pydantic v2 docs: `https://docs.pydantic.dev/latest/concepts/models/` — Model definition patterns
  - User's 34-variable specification (from interview)
  - Existing `Dataset_inf.xlsx` column names for consistency

  **Acceptance Criteria**:
  - [ ] `SPEMetadata` model validates correctly with sample data
  - [ ] All 34 fields present with Chinese descriptions
  - [ ] Bilingual column mapping contains both EN and ZH versions
  - [ ] Field-to-column name mapping correctly converts snake_case → Title_Case

  **QA Scenarios**:
  ```
  Scenario: Validate SPEMetadata model with complete data
    Tool: Bash (python)
    Preconditions: models.py created
    Steps:
      1. Run: python -c "from models import SPEMetadata; m = SPEMetadata(behavior_data='Yes', author='Test', year='2024'); print(m.model_dump_json())"
    Expected Result: Valid JSON output with all fields present
    Failure Indicators: ValidationError or missing fields
    Evidence: .sisyphus/evidence/task-2-model-validate.log

  Scenario: Validate bilingual column mapping completeness
    Tool: Bash (python)
    Preconditions: models.py created
    Steps:
      1. Run: python -c "from models import COLUMNS_EN, COLUMNS_ZH; assert len(COLUMNS_EN) == 34; assert len(COLUMNS_ZH) == 34; print(f'EN: {len(COLUMNS_EN)}, ZH: {len(COLUMNS_ZH)}')"
    Expected Result: Both lists have exactly 34 entries
    Failure Indicators: AssertionError or count mismatch
    Evidence: .sisyphus/evidence/task-2-columns-check.log
  ```

  **Commit**: NO (wait for wave completion)

- [ ] 3. PDF text extraction module

  **What to do**:
  - Create `pdf_reader.py` in `Datasets/6_AI-Tool/`
  - Implement `extract_text_from_pdf(pdf_path: str) -> str`:
    - Use `pymupdf.open()` to read PDF
    - Extract text from all pages using `page.get_text()`
    - Return concatenated text
    - Handle errors: corrupted PDF, empty PDF, password-protected PDF
  - Implement `extract_texts_from_folder(folder_path: str) -> dict[str, str]`:
    - Scan folder for all `.pdf` files (case-insensitive)
    - Return dict mapping filename → extracted text
    - Skip files that fail extraction, log warnings
  - Implement `get_pdf_files(folder_path: str) -> list[str]`:
    - Return sorted list of PDF file paths in folder
  - Handle edge cases:
    - Scanned PDFs (image-only): detect and warn
    - Very large PDFs: no truncation (let LLM handle context)
    - Non-PDF files in folder: skip silently

  **Must NOT do**:
  - Do NOT add OCR functionality (out of scope)
  - Do NOT truncate or summarize text

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: File I/O task using well-documented PyMuPDF library
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None needed

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: Task 5
  - **Blocked By**: None

  **References**:
  - PyMuPDF text extraction: `https://pymupdf.readthedocs.io/en/latest/recipes-text.html` — page.get_text() patterns
  - Existing project structure: `1_Data/` folders contain PDFs for testing

  **Acceptance Criteria**:
  - [ ] `extract_text_from_pdf()` returns non-empty string for valid PDF
  - [ ] `extract_texts_from_folder()` returns dict with all PDF filenames
  - [ ] Corrupted PDF raises clear exception (not crash)
  - [ ] Non-PDF files in folder are silently skipped

  **QA Scenarios**:
  ```
  Scenario: Extract text from a valid PDF
    Tool: Bash (python)
    Preconditions: A sample PDF exists in 1_Data/
    Steps:
      1. Run: python -c "from pdf_reader import extract_text_from_pdf; text = extract_text_from_pdf('1_Data/Constable_2019_EPHPP/Constable_2019_EPHPP.pdf'); print(f'Length: {len(text)}'); print(text[:200])"
    Expected Result: Text length > 1000 characters, first 200 chars contain readable text
    Failure Indicators: Empty string, exception, or garbled text
    Evidence: .sisyphus/evidence/task-3-extract-single.log

  Scenario: Extract texts from folder
    Tool: Bash (python)
    Preconditions: A folder with multiple PDFs exists
    Steps:
      1. Run: python -c "from pdf_reader import extract_texts_from_folder; result = extract_texts_from_folder('1_Data/Constable_2019_EPHPP/'); print(f'Files: {len(result)}'); [print(f'  {k}: {len(v)} chars') for k,v in result.items()]"
    Expected Result: Dict with all PDF files, each having non-empty text
    Failure Indicators: Empty dict, missing files, or exceptions
    Evidence: .sisyphus/evidence/task-3-extract-folder.log

  Scenario: Handle corrupted PDF gracefully
    Tool: Bash (python)
    Preconditions: Create a fake .pdf file with random content
    Steps:
      1. Run: python -c "open('/tmp/bad.pdf','w').write('not a pdf'); from pdf_reader import extract_text_from_pdf; extract_text_from_pdf('/tmp/bad.pdf')"
    Expected Result: Raises a clear exception message, not a cryptic crash
    Failure Indicators: Unhandled exception or Python crash
    Evidence: .sisyphus/evidence/task-3-corrupt-pdf.log
  ```

  **Commit**: NO (wait for wave completion)

- [ ] 4. DeepSeek LLM client + prompt templates

  **What to do**:
  - Create `llm_client.py` in `Datasets/6_AI-Tool/`
  - Implement `create_client(api_key: str) -> OpenAI`:
    - Use `openai.OpenAI(api_key=api_key, base_url="https://api.deepseek.com")`
    - Return configured client
  - Implement extraction prompt template:
    - System prompt: instruct LLM to extract SPE metadata from paper text
    - Include all 34 field definitions with Chinese descriptions
    - Instruct to return valid JSON matching SPEMetadata schema
    - Handle multiple experiments (return array of objects)
  - Implement `extract_metadata(client, paper_text: str) -> list[SPEMetadata]`:
    - Send paper text to DeepSeek API (model: "deepseek-reasoner")
    - Use structured output (response_format with Pydantic)
    - Parse response into list of SPEMetadata objects
    - Handle API errors: rate limit (429), timeout, invalid JSON
    - Retry logic: 3 retries with exponential backoff (1s, 2s, 4s)
  - Implement section-based extraction strategy:
    - Extract abstract section (for basic metadata)
    - Extract methods section (for experimental design)
    - Extract data availability section (for repo_link, license)
    - Combine into single prompt with labeled sections

  **Must NOT do**:
  - Do NOT hardcode API key
  - Do NOT store API key in files
  - Do NOT use GPT-4 or Claude models (DeepSeek only)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Requires careful prompt engineering, error handling, and API integration
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None needed

  **Parallelization**:
  - **Can Run In Parallel**: NO (depends on Task 2 models)
  - **Parallel Group**: Wave 2 (with Task 5)
  - **Blocks**: Task 5
  - **Blocked By**: Task 2

  **References**:
  - DeepSeek API docs: `https://platform.deepseek.com/api-docs/` — model names, rate limits
  - OpenAI structured output: `https://platform.openai.com/docs/guides/structured-outputs` — response_format usage
  - Pydantic model_validate_json: `https://docs.pydantic.dev/latest/concepts/serialization/` — parsing patterns

  **Acceptance Criteria**:
  - [ ] `create_client()` returns valid OpenAI client with DeepSeek base_url
  - [ ] Prompt template includes all 34 field definitions
  - [ ] `extract_metadata()` returns list of SPEMetadata on success
  - [ ] Rate limit errors trigger retry with backoff
  - [ ] Invalid JSON response triggers retry

  **QA Scenarios**:
  ```
  Scenario: Create DeepSeek client
    Tool: Bash (python)
    Preconditions: Dependencies installed
    Steps:
      1. Run: python -c "from llm_client import create_client; c = create_client('test-key'); print(type(c))"
    Expected Result: Prints "<class 'openai.OpenAI'>" — no error
    Failure Indicators: Exception during client creation
    Evidence: .sisyphus/evidence/task-4-client-create.log

  Scenario: Extract metadata from sample text (with valid API key)
    Tool: Bash (python)
    Preconditions: Valid DeepSeek API key available, network access
    Steps:
      1. Run: python -c "
         from llm_client import create_client, extract_metadata
         import os
         client = create_client(os.environ['DEEPSEEK_API_KEY'])
         sample = 'Title: Self-prioritization effect. Authors: Sui et al. 2012. Journal: Psychological Science. N=40 participants.'
         result = extract_metadata(client, sample)
         print(f'Extracted {len(result)} experiment(s)')
         print(result[0].model_dump_json(indent=2))
         "
    Expected Result: Returns 1+ SPEMetadata objects with author='Sui', year='2012', journal='Psychological Science'
    Failure Indicators: API error, empty result, or fields not matching
    Evidence: .sisyphus/evidence/task-4-extract-sample.log

  Scenario: Handle API rate limit with retry
    Tool: Bash (python)
    Preconditions: Mock or rapid-fire API calls to trigger rate limit
    Steps:
      1. Call extract_metadata() rapidly 10 times
      2. Verify retry logic activates on 429 errors
    Expected Result: Retries happen, eventual success or clear error after 3 retries
    Failure Indicators: Immediate failure without retry
    Evidence: .sisyphus/evidence/task-4-retry-logic.log
  ```

  **Commit**: NO (wait for wave completion)

- [ ] 5. End-to-end extraction pipeline

  **What to do**:
  - Create `extract_spe.py` in `Datasets/6_AI-Tool/`
  - Implement `extract_single_pdf(pdf_path: str, api_key: str) -> dict`:
    - Call `extract_text_from_pdf()` to get paper text
    - Call `create_client()` + `extract_metadata()` to get SPEMetadata list
    - Convert to dict with column names as keys
    - Add `File_Name` from PDF filename (Author_Year_Journal format)
    - Return dict (one row per experiment)
  - Implement `extract_batch_pdfs(pdf_paths: list[str], api_key: str, progress_callback=None) -> list[dict]`:
    - Iterate over PDFs, call `extract_single_pdf()` for each
    - Call `progress_callback(current, total, filename)` if provided
    - Collect all results into list of dicts
    - Handle individual PDF failures: log error, append row with N/A
  - Implement `results_to_dataframe(results: list[dict], lang: str = "en") -> pd.DataFrame`:
    - Convert list of dicts to DataFrame
    - Apply bilingual column names based on `lang` parameter
    - Ensure column order matches the 34-variable specification
    - Fill missing values with "N/A"
  - Implement `dataframe_to_csv(df: pd.DataFrame, output_path: str)`:
    - Export to CSV with UTF-8 BOM encoding (for Chinese character support)
    - Use `df.to_csv(output_path, index=False, encoding='utf-8-sig')`

  **Must NOT do**:
  - Do NOT modify the 34-variable column order
  - Do NOT silently drop extraction failures (must log)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Integration logic requiring careful orchestration of PDF reader, LLM client, and data models
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None needed

  **Parallelization**:
  - **Can Run In Parallel**: NO (depends on Tasks 2, 3, 4)
  - **Parallel Group**: Wave 2 (with Task 4)
  - **Blocks**: Task 6, 7
  - **Blocked By**: Task 2, 3, 4

  **References**:
  - models.py: SPEMetadata model — field names and types
  - pdf_reader.py: extract_text_from_pdf() — text extraction interface
  - llm_client.py: extract_metadata() — LLM extraction interface
  - pandas DataFrame: `https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_csv.html` — CSV export

  **Acceptance Criteria**:
  - [ ] `extract_single_pdf()` returns dict with all 34 keys
  - [ ] `extract_batch_pdfs()` processes multiple PDFs with progress tracking
  - [ ] `results_to_dataframe()` produces DataFrame with correct column order
  - [ ] `dataframe_to_csv()` produces valid UTF-8 CSV readable in Excel
  - [ ] Failed PDFs produce N/A rows (not crash)
  - [ ] Bilingual column names work for both "en" and "zh"

  **QA Scenarios**:
  ```
  Scenario: Extract single PDF end-to-end
    Tool: Bash (python)
    Preconditions: Valid API key, sample PDF in 1_Data/
    Steps:
      1. Run: python -c "
         from extract_spe import extract_single_pdf
         import os
         result = extract_single_pdf('1_Data/Constable_2019_EPHPP/Constable_2019_EPHPP.pdf', os.environ['DEEPSEEK_API_KEY'])
         print(f'Keys: {len(result)}')
         print(f'Author: {result.get(\"Author\", \"MISSING\")}')
         print(f'Year: {result.get(\"Year\", \"MISSING\")}')
         "
    Expected Result: Dict with 34 keys, Author and Year populated
    Failure Indicators: Missing keys, exception, all N/A
    Evidence: .sisyphus/evidence/task-5-single-pdf.log

  Scenario: Convert results to bilingual DataFrame
    Tool: Bash (python)
    Preconditions: extract_spe.py created
    Steps:
      1. Run: python -c "
         from extract_spe import results_to_dataframe
         sample = [{'Behavior_Data': 'Yes', 'Author': 'Sui', 'Year': '2012', 'File_Name': 'Sui_2012'}]
         df_en = results_to_dataframe(sample, 'en')
         df_zh = results_to_dataframe(sample, 'zh')
         print(f'EN columns: {list(df_en.columns)[:5]}')
         print(f'ZH columns: {list(df_zh.columns)[:5]}')
         print(f'Total columns: EN={len(df_en.columns)}, ZH={len(df_zh.columns)}')
         "
    Expected Result: Both DataFrames have 34 columns with correct language names
    Failure Indicators: Wrong column count, wrong language
    Evidence: .sisyphus/evidence/task-5-bilingual-df.log
  ```

  **Commit**: NO (wait for wave completion)

- [ ] 6. Streamlit UI — input controls + API key

  **What to do**:
  - Create `app.py` in `Datasets/6_AI-Tool/`
  - Implement sidebar:
    - Language selector (中文 / English) using `st.selectbox`
    - API key input using `st.text_input(type="password")`
    - Input mode selector: "单个PDF文件" / "Single PDF" vs "文件夹批量处理" / "Batch Folder"
  - Implement single file mode:
    - File uploader using `st.file_uploader(type=["pdf"])`
    - Or text input for file path
  - Implement folder mode:
    - Text input for folder path
    - Display list of detected PDF files using `st.expander`
  - Implement "开始提取" / "Start Extraction" button
  - Session state management:
    - Store API key in `st.session_state` (not persisted)
    - Store extraction results in `st.session_state`
    - Store language preference in `st.session_state`
  - Responsive layout with `st.columns`

  **Must NOT do**:
  - Do NOT store API key in files or environment variables
  - Do NOT auto-start extraction on page load

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Streamlit UI development requiring layout design and user interaction flow
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None needed

  **Parallelization**:
  - **Can Run In Parallel**: NO (depends on Task 5 pipeline)
  - **Parallel Group**: Wave 3 (with Task 7)
  - **Blocks**: Task 7
  - **Blocked By**: Task 5

  **References**:
  - Streamlit file_uploader: `https://docs.streamlit.io/develop/api-reference/widgets/st.file_uploader`
  - Streamlit text_input: `https://docs.streamlit.io/develop/api-reference/widgets/st.text_input`
  - Streamlit session_state: `https://docs.streamlit.io/develop/api-reference/caching-and-state/st.session_state`
  - extract_spe.py: extraction pipeline interface

  **Acceptance Criteria**:
  - [ ] Streamlit app starts without errors: `streamlit run app.py`
  - [ ] Sidebar shows language selector, API key input, mode selector
  - [ ] Single file mode shows file uploader
  - [ ] Folder mode shows path input + detected PDF list
  - [ ] API key is masked in UI

  **QA Scenarios**:
  ```
  Scenario: Launch Streamlit app
    Tool: Playwright
    Preconditions: Dependencies installed
    Steps:
      1. Run: streamlit run app.py (background)
      2. Open browser at http://localhost:8501
      3. Verify: page loads with sidebar visible
      4. Verify: language selector present
      5. Verify: API key input field present (masked)
      6. Screenshot: .sisyphus/evidence/task-6-app-launch.png
    Expected Result: App loads, all input controls visible
    Failure Indicators: Page error, missing controls, crash
    Evidence: .sisyphus/evidence/task-6-app-launch.png

  Scenario: Switch language changes UI labels
    Tool: Playwright
    Preconditions: App running
    Steps:
      1. Select "中文" in language selector
      2. Verify: button text changes to "开始提取"
      3. Select "English"
      4. Verify: button text changes to "Start Extraction"
    Expected Result: UI labels update correctly
    Failure Indicators: Labels don't change or show wrong language
    Evidence: .sisyphus/evidence/task-6-language-switch.png
  ```

  **Commit**: NO (wait for wave completion)

- [ ] 7. Streamlit UI — results table + download + bilingual

  **What to do**:
  - In `app.py`, implement results display section:
    - Show extraction progress bar during processing using `st.progress`
    - Display results as interactive table using `st.dataframe`
    - Color-code N/A values for visibility
    - Show extraction summary: "成功提取 X 篇文章 / Successfully extracted X papers"
  - Implement CSV download:
    - Generate CSV in memory using `df.to_csv(index=False, encoding='utf-8-sig')`
    - Download button using `st.download_button`
    - Filename: `SPE_metadata_{lang}.csv` (e.g., `SPE_metadata_zh.csv`)
  - Implement bilingual output:
    - Column headers switch based on language selector
    - Download CSV uses selected language column names
  - Implement error display:
    - Show failed PDFs in `st.warning` or `st.error` boxes
    - Show API error messages in expandable details
  - Implement batch progress tracking:
    - Progress bar showing current/total PDFs
    - Current file name display
    - Estimated time remaining

  **Must NOT do**:
  - Do NOT auto-download CSV (require user click)
  - Do NOT modify extraction results in display

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: UI development for data display, download functionality, and progress tracking
  - **Skills**: []
  - **Skills Evaluated but Omitted**: None needed

  **Parallelization**:
  - **Can Run In Parallel**: NO (depends on Task 6)
  - **Parallel Group**: Wave 3 (with Task 6)
  - **Blocks**: F1
  - **Blocked By**: Task 5, 6

  **References**:
  - Streamlit dataframe: `https://docs.streamlit.io/develop/api-reference/data/st.dataframe`
  - Streamlit download_button: `https://docs.streamlit.io/develop/api-reference/widgets/st.download_button`
  - Streamlit progress: `https://docs.streamlit.io/develop/api-reference/status/st.progress`

  **Acceptance Criteria**:
  - [ ] Results table displays all 34 columns
  - [ ] CSV download produces valid file readable in Excel
  - [ ] Progress bar updates during batch extraction
  - [ ] Language switch changes both UI labels and column headers
  - [ ] Failed PDFs shown in warning boxes, not crash

  **QA Scenarios**:
  ```
  Scenario: Extract and display results
    Tool: Playwright
    Preconditions: App running, valid API key entered
    Steps:
      1. Upload a sample PDF via file uploader
      2. Click "Start Extraction"
      3. Wait for progress bar to complete
      4. Verify: results table appears with 34 columns
      5. Screenshot: .sisyphus/evidence/task-7-results-table.png
    Expected Result: Table shows extracted data, all columns present
    Failure Indicators: Empty table, missing columns, or error
    Evidence: .sisyphus/evidence/task-7-results-table.png

  Scenario: Download CSV in Chinese
    Tool: Playwright
    Preconditions: Results displayed, language set to 中文
    Steps:
      1. Click "下载CSV" / "Download CSV" button
      2. Verify: file downloads as SPE_metadata_zh.csv
      3. Open CSV and verify Chinese column headers
    Expected Result: CSV has Chinese column headers, valid UTF-8 encoding
    Failure Indicators: Wrong filename, garbled Chinese, missing columns
    Evidence: .sisyphus/evidence/task-7-download-zh.csv

  Scenario: Batch extraction with progress
    Tool: Playwright
    Preconditions: App running, folder mode selected, valid path entered
    Steps:
      1. Enter folder path with 3+ PDFs
      2. Click "Start Extraction"
      3. Verify: progress bar shows 1/3, 2/3, 3/3
      4. Verify: current filename displayed during each extraction
      5. Verify: final results table has 3+ rows
    Expected Result: Progress tracking works, all PDFs processed
    Failure Indicators: No progress updates, missing PDFs, or crash
    Evidence: .sisyphus/evidence/task-7-batch-progress.png
  ```

  **Commit**: YES (group with wave)
  - Message: `feat(ai-tool): SPE PDF metadata extractor with Streamlit UI`
  - Files: `Datasets/6_AI-Tool/app.py`

---

## Final Verification Wave

- [ ] F1. **Integration QA** — full pipeline test
  Run `streamlit run app.py`, upload a real PDF from `1_Data/`, enter DeepSeek API key, extract metadata, verify all 34 columns populated, download CSV, open in Excel, verify Chinese headers work. Test both single file and folder modes. Test error cases: invalid API key, corrupted PDF, empty folder.
  Output: `Pipeline [PASS/FAIL] | Single PDF [PASS/FAIL] | Batch [PASS/FAIL] | CSV Download [PASS/FAIL] | Bilingual [PASS/FAIL] | VERDICT`

- [ ] F2. **README + usage docs** — `writing`
  Write `README.md` in `Datasets/6_AI-Tool/` covering: installation (`pip install -r requirements.txt`), usage (`streamlit run app.py`), API key setup, input modes, output format, troubleshooting common errors (API key invalid, PDF unreadable, rate limit).
  Output: `README [COMPLETE] | Usage Guide [COMPLETE] | VERDICT`

---

## Commit Strategy

- **Wave 1+2**: No individual commits — wait for all code complete
- **Final**: `feat(ai-tool): SPE PDF metadata extractor with Streamlit UI`
  - Files: `Datasets/6_AI-Tool/*.py`, `Datasets/6_AI-Tool/requirements.txt`, `Datasets/6_AI-Tool/README.md`

---

## Success Criteria

### Verification Commands
```bash
cd Datasets/6_AI-Tool
pip install -r requirements.txt
streamlit run app.py
# Expected: Browser opens at http://localhost:8501 with working UI
```

### Final Checklist
- [ ] All 34 variables extractable from PDFs
- [ ] Single PDF mode works
- [ ] Folder batch mode works
- [ ] Bilingual UI (Chinese/English switch)
- [ ] CSV download with correct encoding
- [ ] Error handling for corrupt PDFs and API failures
- [ ] README with usage instructions
