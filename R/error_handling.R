# error_handling.R - Structured error handling for ISTAT API operations
# Provides consistent error types, exit codes, and logging

# 1. Result structure -----

#' ISTAT Download Result Structure
#'
#' Standard return structure for download operations providing consistent
#' success/failure information with exit codes.
#'
#' @name istat_result
#' @description
#' An `istat_result` object is a list with the following components:
#' \itemize{
#'   \item{success}: Logical indicating if operation succeeded
#'   \item{data}: data.table with downloaded data (or NULL on failure)
#'   \item{exit_code}: Integer exit code (0=success, 1=error, 2=timeout)
#'   \item{message}: Character message describing result
#'   \item{md5}: Character MD5 checksum of data (or NA if not computed)
#'   \item{is_timeout}: Logical indicating if failure was due to timeout
#'   \item{timestamp}: POSIXct timestamp when result was created
#' }
NULL

#' Create Download Result
#'
#' Creates a standardized result object for download operations.
#'
#' @param success Logical indicating if operation succeeded
#' @param data data.table with downloaded data (or NULL on failure)
#' @param exit_code Integer exit code (0=success, 1=error, 2=timeout)
#' @param message Character message describing result
#' @param md5 Character MD5 checksum of data (optional)
#' @param is_timeout Logical indicating if failure was due to timeout
#'
#' @return A list with class "istat_result"
#' @keywords internal
create_download_result <- function(success, data = NULL, exit_code = 0L,
                                   message = "", md5 = NA_character_,
                                   is_timeout = FALSE) {
  structure(
    list(
      success = success,
      data = data,
      exit_code = as.integer(exit_code),
      message = message,
      md5 = md5,
      is_timeout = is_timeout,
      timestamp = Sys.time()
    ),
    class = c("istat_result", "list")
  )
}

#' Print Method for istat_result
#'
#' @param x An istat_result object
#' @param ... Additional arguments (ignored)
#' @return Invisible x
#' @export
#' @keywords internal
print.istat_result <- function(x, ...) {
  status <- if (x$success) "SUCCESS" else "FAILED"
  cat("ISTAT Download Result:", status, "\n")
  cat("  Exit code:", x$exit_code, "\n")

  cat("  Message:", x$message, "\n")
  if (x$success && !is.null(x$data)) {
    cat("  Rows:", nrow(x$data), "\n")
  }
  if (!is.na(x$md5)) {
    cat("  MD5:", x$md5, "\n")
  }
  cat("  Timestamp:", format(x$timestamp, "%Y-%m-%d %H:%M:%S %Z"), "\n")
  invisible(x)
}

# 2. Error detection functions -----

#' Check if Error is Timeout
#'
#' Detects timeout errors from error messages using multiple patterns.
#' Incorporates patterns from reference implementation.
#'
#' @param error_message Character string containing error message
#'
#' @return Logical indicating if error is timeout-related
#' @keywords internal
is_timeout_error <- function(error_message) {
  if (is.null(error_message) || !is.character(error_message)) {
    return(FALSE)
  }

  timeout_patterns <- c(
    "timeout",
    "timed out",
    "time out",
    "connection timed out",
    "request timeout",
    "gateway timeout",
    "504",
    "408"
  )

  error_lower <- tolower(error_message)
  any(vapply(timeout_patterns, function(p) grepl(p, error_lower), logical(1)))
}

#' Check if Error is Connectivity Issue
#'
#' Detects network/connectivity errors from error messages.
#'
#' @param error_message Character string containing error message
#'
#' @return Logical indicating if error is connectivity-related
#' @keywords internal
is_connectivity_error <- function(error_message) {
  if (is.null(error_message) || !is.character(error_message)) {
    return(FALSE)
  }

  connectivity_patterns <- c(
    "resolve",
    "connection",
    "network",
    "internet",
    "dns",
    "refused",
    "unreachable",
    "host"
  )

  error_lower <- tolower(error_message)
  any(vapply(connectivity_patterns, function(p) grepl(p, error_lower), logical(1)))
}

#' Check if Error is HTTP Status Error
#'
#' Detects HTTP status code errors from messages.
#'
#' @param error_message Character string containing error message
#'
#' @return Logical indicating if error is HTTP status-related
#' @keywords internal
is_http_error <- function(error_message) {
  if (is.null(error_message) || !is.character(error_message)) {
    return(FALSE)
  }

  http_patterns <- c(
    "http error",
    "status code",
    "400",
    "401",
    "403",
    "404",
    "500",
    "502",
    "503"
  )

  error_lower <- tolower(error_message)
  any(vapply(http_patterns, function(p) grepl(p, error_lower), logical(1)))
}

# 3. Error classification -----

#' Classify API Error
#'
#' Classifies an API error into standard categories with exit codes.
#' Exit codes follow the reference implementation:
#' - 0: Success
#' - 1: Generic error (connectivity, HTTP, parsing)
#' - 2: Timeout error
#'
#' @param error_message Character string containing error message
#'
#' @return A list with type, exit_code, and formatted message
#' @keywords internal
classify_api_error <- function(error_message) {
  if (is.null(error_message)) {
    error_message <- "Unknown error"
  }

  if (is_timeout_error(error_message)) {
    list(
      type = "timeout",
      exit_code = 2L,
      message = paste("Server timeout:", error_message)
    )
  } else if (is_connectivity_error(error_message)) {
    list(
      type = "connectivity",
      exit_code = 1L,
      message = paste("Network connectivity issue:", error_message)
    )
  } else if (is_http_error(error_message)) {
    list(
      type = "http",
      exit_code = 1L,
      message = paste("HTTP error:", error_message)
    )
  } else {
    list(
      type = "unknown",
      exit_code = 1L,
      message = paste("API error:", error_message)
    )
  }
}

# 4. Logging -----

#' Structured Logging Function
#'
#' Provides timestamped logging consistent with reference implementation.
#' Output format: `YYYY-MM-DD HH:MM:SS TZ [LEVEL] - message`
#'
#' @param msg Character message to log
#' @param level Character log level: one of "INFO", "WARNING", or "ERROR"
#' @param verbose Logical whether to output message
#'
#' @return Invisible NULL
#' @keywords internal
istat_log <- function(msg, level = "INFO", verbose = TRUE) {
  if (!verbose) return(invisible(NULL))

  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  full_msg <- paste0(timestamp, " [", level, "] - ", msg)

  message(full_msg)

  invisible(NULL)
}
