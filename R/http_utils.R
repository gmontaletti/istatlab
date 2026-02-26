# http_utils.R - HTTP utility functions for ISTAT API (DEPRECATED)
# These functions are deprecated in favor of http_transport.R and response_processor.R
# They are maintained for backward compatibility and will be removed in version 1.0.0

#' Make HTTP GET request to ISTAT API
#'
#' @description
#' **Deprecated**: This function is deprecated and will be removed in version 1.0.0.
#' Use [http_get()] from http_transport.R instead.
#'
#' @param url Character string with the full API URL
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param verbose Logical whether to print status messages
#'
#' @return httr response object or NULL on failure
#' @keywords internal
istat_http_get <- function(url, timeout = 120, accept = NULL, verbose = TRUE) {
  .Deprecated(
    "http_get",
    package = "istatlab",
    msg = "istat_http_get is deprecated. Use http_get() instead."
  )

  # Redirect to new function
  result <- http_get(url, timeout, accept, verbose)

  # Convert to old format for backward compatibility
  if (result$success) {
    # Create mock response-like structure
    list(
      status_code = result$status_code,
      content = result$content
    )
  } else {
    NULL
  }
}

#' Fetch data from ISTAT API in CSV format
#'
#' @description
#' **Deprecated**: This function is deprecated and will be removed in version 1.0.0.
#' Use [http_get()] followed by [process_api_response()] instead.
#'
#' @param url Character string with the full API URL
#' @param timeout Numeric timeout in seconds
#' @param verbose Logical whether to print status messages
#'
#' @return data.table with normalized column names or NULL on failure
#' @keywords internal
istat_fetch_data_csv <- function(url, timeout = 120, verbose = TRUE) {
  .Deprecated(
    "process_api_response",
    package = "istatlab",
    msg = "istat_fetch_data_csv is deprecated. Use http_get() + process_api_response() instead."
  )

  # Redirect to new functions
  http_result <- http_get(url, timeout = timeout, verbose = verbose)
  result <- process_api_response(http_result, verbose)

  if (result$success) {
    result$data
  } else {
    NULL
  }
}

# Note: normalize_csv_columns is now defined in response_processor.R
# This file re-exports it for backward compatibility
# The function in response_processor.R is the canonical implementation
