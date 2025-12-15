# http_utils.R - HTTP utility functions for ISTAT API
# Internal functions for making HTTP requests and parsing CSV responses

#' Make HTTP GET request to ISTAT API
#'
#' Internal function that performs HTTP GET requests with proper Accept headers.
#'
#' @param url Character string with the full API URL
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param verbose Logical whether to print status messages
#'
#' @return httr response object or NULL on failure
#' @keywords internal
istat_http_get <- function(url, timeout = 120, accept = NULL, verbose = TRUE) {
  config <- get_istat_config()

  if (is.null(accept)) {
    accept <- config$http$accept_csv
  }

  response <- tryCatch({
    httr::GET(
      url,
      httr::add_headers(
        Accept = accept,
        `User-Agent` = config$http$user_agent
      ),
      httr::timeout(timeout)
    )
  }, error = function(e) {
    if (verbose) {
      error_msg <- e$message
      if (grepl("timeout|Timeout", error_msg, ignore.case = TRUE)) {
        message("HTTP request timed out after ", timeout, " seconds")
      } else if (grepl("resolve|connection", error_msg, ignore.case = TRUE)) {
        message("Cannot connect to ISTAT API: ", error_msg)
      } else {
        message("HTTP request failed: ", error_msg)
      }
    }
    return(NULL)
  })

  if (is.null(response)) return(NULL)

  status <- httr::status_code(response)
  if (status != 200) {
    if (verbose) {
      message("HTTP error: ", status)
    }
    return(NULL)
  }

  return(response)
}

#' Fetch data from ISTAT API in CSV format
#'
#' Internal function that fetches data from ISTAT API using CSV format
#' and returns a data.table with normalized column names. Uses httr as primary
#' method with system curl as fallback for better reliability.
#'
#' @param url Character string with the full API URL
#' @param timeout Numeric timeout in seconds
#' @param verbose Logical whether to print status messages
#'
#' @return data.table with normalized column names or NULL on failure
#' @keywords internal
istat_fetch_data_csv <- function(url, timeout = 120, verbose = TRUE) {
  config <- get_istat_config()
  csv_text <- NULL

  # Try httr first
  response <- istat_http_get(url, timeout = timeout, verbose = FALSE)

  if (!is.null(response)) {
    csv_text <- tryCatch({
      httr::content(response, as = "text", encoding = "UTF-8")
    }, error = function(e) NULL)
  }

  # If httr failed or returned empty, try system curl as fallback
  if (is.null(csv_text) || nchar(csv_text) == 0) {
    if (verbose) message("Using system curl for download...")
    csv_text <- istat_fetch_with_curl(url, timeout, config$http$accept_csv, verbose)
  }

  if (is.null(csv_text) || nchar(csv_text) == 0) {
    if (verbose) message("Empty response received from API")
    return(NULL)
  }

  # Parse CSV with data.table::fread for performance
  dt <- tryCatch({
    data.table::fread(
      text = csv_text,
      header = TRUE,
      encoding = "UTF-8",
      showProgress = FALSE,
      na.strings = c("", "NA")
    )
  }, error = function(e) {
    if (verbose) message("Failed to parse CSV response: ", e$message)
    return(NULL)
  })

  if (is.null(dt) || nrow(dt) == 0) {
    if (verbose) message("No data returned from API")
    return(NULL)
  }

  # Normalize column names for backward compatibility with SDMX format
  dt <- normalize_csv_columns(dt)

  return(dt)
}

#' Fetch data using system curl command
#'
#' Fallback function using system curl for downloads when httr has issues.
#'
#' @param url Character string with the full API URL
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param verbose Logical whether to print status messages
#'
#' @return Character string with CSV content or NULL on failure
#' @keywords internal
istat_fetch_with_curl <- function(url, timeout = 120, accept, verbose = TRUE) {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  # Build curl command
  cmd <- sprintf(
    'curl -s -m %d -H "Accept: %s" -o "%s" "%s"',
    timeout, accept, tmp, url
  )

  # Execute curl
  result <- tryCatch({
    system(cmd, intern = FALSE, ignore.stdout = TRUE, ignore.stderr = TRUE)
  }, error = function(e) {
    if (verbose) message("System curl failed: ", e$message)
    return(1)
  })

  # Check if file was created and has content
 if (file.exists(tmp) && file.size(tmp) > 0) {
    return(readLines(tmp, warn = FALSE, encoding = "UTF-8") |> paste(collapse = "\n"))
  }

  return(NULL)
}

#' Normalize CSV column names for backward compatibility
#'
#' Internal function that renames CSV columns to match the expected
#' SDMX-style column names used throughout the package.
#'
#' @param dt data.table from CSV parsing
#'
#' @return data.table with normalized column names
#' @keywords internal
normalize_csv_columns <- function(dt) {
  if (!data.table::is.data.table(dt)) {
    data.table::setDT(dt)
  }


  # Column name mapping from CSV to expected SDMX names
  # TIME_PERIOD -> ObsDimension (time dimension)
  # OBS_VALUE -> ObsValue (observation value)
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
  # The dataset_id is added separately by the calling function
  if ("DATAFLOW" %in% names(dt)) {
    dt[, DATAFLOW := NULL]
  }

  return(dt)
}
