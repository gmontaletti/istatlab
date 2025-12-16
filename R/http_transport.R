# http_transport.R - HTTP transport layer for ISTAT API
# Handles raw HTTP operations with retry and fallback strategies

# 1. Main HTTP function -----

#' HTTP GET Request with Fallback
#'
#' Performs HTTP GET request using httr with system curl fallback.
#' This is the single point for all HTTP operations.
#'
#' @param url Character string with the full URL
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param verbose Logical whether to log status messages
#'
#' @return A list with components:
#'   \itemize{
#'     \item{success}: Logical indicating if request succeeded
#'     \item{content}: Character string with response body (or NULL)
#'     \item{status_code}: HTTP status code (or NA)
#'     \item{error}: Error message if failed (or NULL)
#'     \item{method}: Character indicating which method succeeded ("httr" or "curl")
#'   }
#' @keywords internal
http_get <- function(url, timeout = 120, accept = NULL, verbose = TRUE) {
  config <- get_istat_config()

  if (is.null(accept)) {
    accept <- config$http$accept_csv
  }

  # Try httr first
  httr_result <- http_get_httr(url, timeout, accept, verbose)

  if (httr_result$success) {
    httr_result$method <- "httr"
    return(httr_result)
  }

  # Fallback to system curl
  if (verbose) {
    istat_log("Primary HTTP method failed, using curl fallback", "WARNING", verbose)
  }

  curl_result <- http_get_curl(url, timeout, accept, verbose)
  curl_result$method <- "curl"

  return(curl_result)
}

# 2. httr implementation -----

#' HTTP GET using httr Package
#'
#' Internal function that performs HTTP GET using the httr package.
#'
#' @param url Character string with the full URL
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param verbose Logical whether to log status messages
#'
#' @return A list with success, content, status_code, and error components
#' @keywords internal
http_get_httr <- function(url, timeout, accept, verbose) {
  config <- get_istat_config()

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
    return(list(
      success = FALSE,
      content = NULL,
      status_code = NA_integer_,
      error = e$message
    ))
  })

  # Check if tryCatch returned an error structure
  if (is.list(response) && !inherits(response, "response")) {
    return(response)
  }

  status <- httr::status_code(response)

  if (status != 200) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = status,
      error = paste("HTTP error:", status)
    ))
  }

  # Extract content
  content <- tryCatch({
    httr::content(response, as = "text", encoding = "UTF-8")
  }, error = function(e) NULL)

  # Validate content
  if (is.null(content) || nchar(content) == 0) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = status,
      error = "Empty response body"
    ))
  }

  list(
    success = TRUE,
    content = content,
    status_code = status,
    error = NULL
  )
}

# 3. curl fallback implementation -----

#' HTTP GET using System Curl
#'
#' Fallback function using system curl for downloads when httr has issues.
#' Uses temp file to capture response and returns content as string.
#'
#' @param url Character string with the full URL
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param verbose Logical whether to log status messages
#'
#' @return A list with success, content, status_code, and error components
#' @keywords internal
http_get_curl <- function(url, timeout, accept, verbose) {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  # Build curl command with HTTP status code capture
  cmd <- sprintf(
    'curl -s -m %d -H "Accept: %s" -o "%s" -w "%%{http_code}" "%s"',
    timeout, accept, tmp, url
  )

  result <- tryCatch({
    output <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    status_code <- as.integer(output[length(output)])
    list(exit_status = 0, status_code = status_code)
  }, error = function(e) {
    list(exit_status = 1, error = e$message)
  })

  # Check for system error
 if (result$exit_status != 0) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = NA_integer_,
      error = if (!is.null(result$error)) result$error else "curl command failed"
    ))
  }

  # Check HTTP status
  if (!is.na(result$status_code) && result$status_code != 200) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = result$status_code,
      error = paste("HTTP error:", result$status_code)
    ))
  }

  # Check if file was created and has content
  if (!file.exists(tmp) || file.size(tmp) == 0) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = result$status_code,
      error = "Empty response from curl"
    ))
  }

  # Read content from temp file
  content <- paste(readLines(tmp, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  list(
    success = TRUE,
    content = content,
    status_code = result$status_code,
    error = NULL
  )
}
