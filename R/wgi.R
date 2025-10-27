#' Download, unzip, and read Excel workbook(s) from a ZIP URL
#'
#' @description
#' **Edict:** Fetch a ZIP from the web, extract *.xlsx* files, and read either
#' the first sheet of the first workbook (default) or all sheets from all workbooks.
#'
#' @param url Character. Direct link to the ZIP file.
#' @param file_pattern Regex to select files inside the ZIP (default: `"\\.xlsx$"`).
#' @param sheet Sheet to read when `read_all = FALSE`. Can be `NULL` (first sheet),
#'   a sheet name, or an index. Ignored when `read_all = TRUE`.
#' @param read_all Logical. If `TRUE`, read **all** sheets from **all** .xlsx files
#'   and return a nested named list. If `FALSE` (default), read a single sheet.
#' @param verbose Logical. Print progress messages (default `TRUE`).
#' @param keep_dir Logical. If `TRUE`, keep the extracted directory and return
#'   its path (as an attribute). Otherwise it’s created in tempdir (default `FALSE`).
#'
#' @return
#' If `read_all = FALSE`: a data.frame/tibble of the requested sheet.
#' If `read_all = TRUE`: a nested named list `list(<file> = list(<sheet> = tibble, ...), ...)`.
#' In both cases, the return value has attributes `zip_path`, `unzip_dir`, and `files`.
#'
#' @importFrom  readxl read_excel excel_sheets
#' @importFrom curl curl_download
#' @importFrom utils unzip
#' @importFrom stats setNames
#' @examples
#' \dontrun{
#' url <- "https://www.worldbank.org/content/dam/sites/govindicators/doc/wgidataset_excel.zip"
#' # Read the first sheet of the first workbook
#' df <- read_zip_xlsx(url)
#'
#' # Read a specific sheet by name
#' df2 <- read_zip_xlsx(url, sheet = "Data")
#'
#' # Read all sheets from all workbooks
#' all_tbls <- read_zip_xlsx(url, read_all = TRUE)
#' names(all_tbls)                # files
#' names(all_tbls[[1]])           # sheets in first file
#' }
read_zip_xlsx <- function(url,
                          file_pattern = "\\.xlsx$",
                          sheet = NULL,
                          read_all = FALSE,
                          verbose = TRUE,
                          keep_dir = FALSE) {
  # deps
  if (!requireNamespace("readxl", quietly = TRUE))
    stop("Package 'readxl' is required.")
  if (!requireNamespace("curl", quietly = TRUE))
    stop("Package 'curl' is required.")

  # 1) Download ZIP
  zip_path <- tempfile(fileext = ".zip")
  curl::curl_download(url, destfile = zip_path, mode = "wb")
  if (verbose) message("Downloaded ZIP to: ", zip_path)

  # 2) Unzip
  unzip_dir <- if (keep_dir) {
    file.path(getwd(), paste0("unzipped_", as.integer(Sys.time())))
  } else {
    tempfile("unzipped_")
  }
  dir.create(unzip_dir, recursive = TRUE, showWarnings = FALSE)
  utils::unzip(zip_path, exdir = unzip_dir, overwrite = TRUE)
  if (verbose) message("Extracted to: ", unzip_dir)

  # 3) Find XLSX files
  xlsx_files <- list.files(unzip_dir, pattern = file_pattern, recursive = TRUE, full.names = TRUE)
  if (length(xlsx_files) == 0) stop("No files matching '", file_pattern, "' found in the ZIP.")

  # Helper to attach context attributes
  # attach_ctx <- function(obj) {
  #   attr(obj, "zip_path")  <- zip_path
  #   attr(obj, "unzip_dir") <- unzip_dir
  #   attr(obj, "files")     <- xlsx_files
  #   obj
  # }

  # 4) Read
  if (read_all) {
    out <- lapply(xlsx_files, function(f) {
      sh <- readxl::excel_sheets(f)
      setNames(lapply(sh, function(s) readxl::read_excel(f, sheet = s)), sh)
    })
    names(out) <- basename(xlsx_files)
    if (verbose) message("Read all sheets from ", length(xlsx_files), " workbook(s).")
    return(out)
  } else {
    # First file
    first_xlsx <- xlsx_files[1]
    sh <- readxl::excel_sheets(first_xlsx)
    target_sheet <- if (is.null(sheet)) sh[1] else sheet
    if (verbose) {
      message("Reading: ", basename(first_xlsx),
              " | Sheet: ", if (is.null(names(target_sheet))) target_sheet else target_sheet)
    }
    df <- readxl::read_excel(first_xlsx, sheet = target_sheet)
    return(df)
  }
}


#' Read and tidy World Governance Indicators (WGI) from the official ZIP
#'
#' @description
#' **Edict:** Download the WGI Excel bundle, extract the main table,
#' and return a tidy tibble filtered by years, countries, indicator codes,
#' and variable type (e.g., `estimate`, `stddev`, `pctrank`, …).
#'
#' Indicator codes:
#' - `va` = Voice and Accountability
#' - `pv` = Political Stability/Absence of Violence
#' - `ge` = Government Effectiveness
#' - `rq` = Regulatory Quality
#' - `rl` = Rule of Law
#' - `cc` = Control of Corruption
#'
#' @param startyear Integer or `NULL`. First year to keep. If `NULL`, uses min available.
#' @param endyear   Integer or `NULL`. Last year to keep. If `NULL`, uses max available.
#' @param country   Character vector of country names to keep (matches the `countryname` column).
#'                  If `NULL`, keeps all.
#' @param indicator Character vector of indicator **codes** to keep
#'                  (subset of `c("va","pv","ge","rq","rl","cc")`). If `NULL`, keeps all six.
#' @param variable  Character vector of WGI variable names to keep among
#'                  `c("estimate","stddev","pctrank","nsource","pctranklower","pctrankupper")`.
#'                  If `NULL`, keeps all.
#' @param na.rm     Logical. If `TRUE` (default), drop rows with `NA` in `value`.
#'
#' @return A tibble with at least:
#'   `countryname`, `indicator`, `year`, `variable`, `value`, plus any other columns
#'   present in the source file (with lower-cased names).
#'
#' @details
#' - Relies on a helper `read_zip_xlsx(url)` that downloads/unzips the ZIP and returns
#'   the first workbook's first sheet as a tibble (as you defined earlier).
#' - Column names are lower-cased on read to avoid case-mismatch issues.
#' - The function validates that expected WGI columns exist and errors clearly otherwise.
#'
#' @examples
#' \dontrun{
#' wgi <- read_wgi(startyear = 2010, endyear = 2023, indicator = c("ge","rl"),
#'                 variable = c("estimate","pctrank"))
#' dplyr::count(wgi, indicator, year)
#' }
#'
#' @importFrom tidyr pivot_longer
#' @importFrom dplyr filter mutate arrange all_of
#' @import rlang
#' @export
read_wgi <- function(startyear = NULL,
                     endyear   = NULL,
                     country   = NULL,
                     indicator = NULL,
                     variable  = NULL,
                     na.rm     = TRUE) {

  # Official WGI ZIP (Excel)
  url_link <- "https://www.worldbank.org/content/dam/sites/govindicators/doc/wgidataset_excel.zip"

  # Map of indicator codes to labels (labels are informational only here)
  set_indicator <- c(
    va = "Voice",
    pv = "Political",
    ge = "Government",
    rq = "Regulatory",
    rl = "Rule",
    cc = "Control"
  )

  # Keep all indicators if none specified, otherwise keep the requested codes
  if (is.null(indicator)) {
    list_indicator <- set_indicator
  } else {
    list_indicator <- set_indicator[names(set_indicator) %in% indicator]
  }

  # ---- Read the first workbook/sheet from the ZIP ----------------------------
  # (Assumes your helper read_zip_xlsx(url) is defined)
  wgi_df <- suppressWarnings(read_zip_xlsx(url = url_link))

  # Standardize column names to lower-case to be robust to casing
  names(wgi_df) <- tolower(names(wgi_df))

  # Sanity check for required columns (WGI public layout)
  needed <- c("countryname", "indicator", "year",
              "estimate", "stddev", "pctrank", "nsource", "pctranklower", "pctrankupper")
  miss <- setdiff(needed, names(wgi_df))
  if (length(miss)) {
    stop("Missing expected columns in WGI data: ", paste(miss, collapse = ", "),
         "\nAvailable: ", paste(names(wgi_df), collapse = ", "))
  }

  # Long pivot of selected value columns
  wgi_df <- wgi_df |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(c("estimate", "stddev", "pctrank", "nsource", "pctranklower", "pctrankupper")),
      names_to  = "variable",
      values_to = "value"
    ) |>
    dplyr::mutate(value = suppressWarnings(as.numeric(.data$value))) |>
    dplyr::filter(.data$indicator %in% names(list_indicator))

  # Determine year range if not provided
  years_avail <- sort(unique(wgi_df$year))
  if (is.null(startyear)) startyear <- min(years_avail, na.rm = TRUE)
  if (is.null(endyear))   endyear   <- max(years_avail, na.rm = TRUE)

  # Year filter
  wgi_df <- wgi_df |>
    dplyr::filter(.data$year >= startyear, .data$year <= endyear)

  # Country filter (optional)
  if (!is.null(country)) {
    wgi_df <- wgi_df |>
      dplyr::filter(.data$countryname %in% country)
  }

  # Variable filter (optional)
  if (!is.null(variable)) {
    wgi_df <- wgi_df |>
      dplyr::filter(.data$variable %in% variable)
  }

  # Remove NA values if requested
  if (isTRUE(na.rm)) {
    wgi_df <- wgi_df |>
      dplyr::filter(!is.na(.data$value))
  }

  # Nice ordering
  wgi_df <- dplyr::arrange(wgi_df, .data$countryname, .data$indicator, .data$year, .data$variable)

  return(wgi_df)
}


