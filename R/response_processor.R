# response_processor.R - CSV parsing and data transformation
# Handles conversion from raw API response to data.table

# 1. CSV parsing -----

#' Parse CSV Response
#'
#' Parses CSV text response into a data.table using data.table::fread
#' for high performance.
#'
#' @param csv_text Character string containing CSV data
#' @param verbose Logical whether to log status
#'
#' @return data.table or NULL on parse failure
#' @keywords internal
parse_csv_response <- function(csv_text, verbose = TRUE) {
  if (is.null(csv_text) || nchar(csv_text) == 0) {
    if (verbose) istat_log("Empty CSV text provided", "WARNING", verbose)
    return(NULL)
  }

  dt <- tryCatch({
    data.table::fread(
      text = csv_text,
      header = TRUE,
      encoding = "UTF-8",
      showProgress = FALSE,
      na.strings = c("", "NA")
    )
  }, error = function(e) {
    if (verbose) {
      istat_log(paste("CSV parse error:", e$message), "ERROR", verbose)
    }
    return(NULL)
  })

  if (is.null(dt) || nrow(dt) == 0) {
    if (verbose) istat_log("No data rows in CSV response", "WARNING", verbose)
    return(NULL)
  }

  dt
}

# 2. Column normalization -----

#' Normalize CSV Columns
#'
#' Normalizes CSV column names to match expected SDMX naming conventions.
#' Provides backward compatibility with existing code that expects SDMX-style names.
#'
#' Column mappings:
#' - TIME_PERIOD -> ObsDimension (time dimension)
#' - OBS_VALUE -> ObsValue (observation value)
#'
#' Also removes the DATAFLOW column which contains redundant metadata.
#'
#' @param dt data.table from CSV parsing
#'
#' @return data.table with normalized column names (modified in place)
#' @keywords internal
normalize_csv_columns <- function(dt) {
  if (!data.table::is.data.table(dt)) {
    data.table::setDT(dt)
  }

  # Column name mapping from CSV to expected SDMX names
  name_map <- c(
    "TIME_PERIOD" = "ObsDimension",
    "OBS_VALUE" = "ObsValue"
  )

  current_names <- names(dt)
  for (old_name in names(name_map)) {
    if (old_name %in% current_names) {
      data.table::setnames(dt, old_name, name_map[old_name])
    }
  }

  # Remove DATAFLOW column if present (contains redundant info like "IT1:150_908(1.0)")
  if ("DATAFLOW" %in% names(dt)) {
    dt[, DATAFLOW := NULL]
  }

  dt
}

# 3. Checksum computation -----

#' Compute Data Checksum
#'
#' Computes MD5 checksum for data integrity verification.
#' Pattern from reference implementation. Requires the digest package
#' (optional dependency).
#'
#' @param dt data.table to compute checksum for
#'
#' @return Character MD5 hash string, or NA_character_ if digest is not available
#' @keywords internal
compute_data_checksum <- function(dt) {
  if (!requireNamespace("digest", quietly = TRUE)) {
    return(NA_character_)
  }

  tryCatch({
    digest::digest(dt, algo = "md5")
  }, error = function(e) {
    NA_character_
  })
}

# 4. Main processing function -----

#' Process API Response
#'
#' Main function to process raw API response into final data.table.
#' Combines parsing, normalization, and checksum computation.
#'
#' @param http_result Result from http_get() function
#' @param verbose Logical whether to log status
#'
#' @return istat_result object with processed data
#' @keywords internal
process_api_response <- function(http_result, verbose = TRUE) {
  # Check HTTP success
  if (!http_result$success) {
    error_info <- classify_api_error(http_result$error)

    return(create_download_result(
      success = FALSE,
      exit_code = error_info$exit_code,
      message = error_info$message,
      is_timeout = error_info$type == "timeout"
    ))
  }

  # Parse CSV
  dt <- parse_csv_response(http_result$content, verbose)

  if (is.null(dt)) {
    return(create_download_result(
      success = FALSE,
      exit_code = 1L,
      message = "Failed to parse CSV response"
    ))
  }

  # Normalize columns
  dt <- normalize_csv_columns(dt)

  # Compute checksum
  md5 <- compute_data_checksum(dt)

  create_download_result(
    success = TRUE,
    data = dt,
    exit_code = 0L,
    message = paste("Downloaded", nrow(dt), "rows"),
    md5 = md5
  )
}
