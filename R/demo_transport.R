# demo_transport.R - Binary download transport for demo.istat.it demographic data
# Handles ZIP file downloads with rate limiting, retry logic, and HEAD requests

# 1. Demo rate limiter state -----

# Package-level environment for demo.istat.it rate limiting state
# Separate from .istat_rate_limiter to avoid interference with SDMX transport
.demo_rate_limiter <- new.env(parent = emptyenv())
.demo_rate_limiter$last_request_time <- NULL

# 2. Demo rate limiting functions -----

#' Throttle Demo API Requests
#'
#' Enforces minimum delay between HTTP requests to demo.istat.it.
#' Reads rate limit settings from \code{get_istat_config()$demo_rate_limit}
#' and uses a separate state environment from the SDMX throttle.
#'
#' @param config_override Optional list to override demo_rate_limit config values.
#'   Must contain \code{delay} and \code{jitter_fraction} fields.
#'
#' @return Invisible NULL
#' @keywords internal
demo_throttle <- function(config_override = NULL) {
  config <- if (!is.null(config_override)) {
    config_override
  } else {
    get_istat_config()$demo_rate_limit
  }

  delay <- config$delay
  jitter_fraction <- config$jitter_fraction

  last_time <- .demo_rate_limiter$last_request_time

  if (!is.null(last_time)) {
    elapsed <- as.numeric(difftime(Sys.time(), last_time, units = "secs"))
    remaining <- delay - elapsed

    if (remaining > 0) {
      # Add jitter: +/- jitter_fraction of delay
      jitter_range <- delay * jitter_fraction
      jitter <- stats::runif(1, -jitter_range, jitter_range)
      wait_time <- max(0, remaining + jitter)

      if (wait_time > 0) {
        Sys.sleep(wait_time)
      }
    }
  }

  .demo_rate_limiter$last_request_time <- Sys.time()
  invisible(NULL)
}

#' Reset Demo Rate Limiter State
#'
#' Resets the internal rate limiter state for demo.istat.it requests.
#' Useful for testing or after switching between data sources.
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Reset demo rate limiter between sessions
#' reset_demo_rate_limiter()
#' }
reset_demo_rate_limiter <- function() {
  .demo_rate_limiter$last_request_time <- NULL
  invisible(NULL)
}

# 3. Binary download transport -----

#' Download Binary File to Disk
#'
#' Core transport function for downloading binary files (ZIP archives) from
#' demo.istat.it. Uses httr as the primary method with curl as fallback.
#'
#' Unlike \code{http_get()} which returns text content for SDMX responses,
#' this function writes binary data directly to disk using
#' \code{httr::write_disk()}.
#'
#' @param url Character string with the full URL to download.
#' @param dest_path Character string with the local file path to write to.
#' @param timeout Numeric timeout in seconds. Default 120.
#' @param verbose Logical whether to log status messages. Default TRUE.
#'
#' @return A list with components:
#'   \describe{
#'     \item{success}{Logical indicating if download succeeded}
#'     \item{dest_path}{Character path where file was written}
#'     \item{status_code}{HTTP status code (integer), or NA on connection error}
#'     \item{error}{Error message string, or NULL on success}
#'     \item{method}{Character indicating which method succeeded ("httr" or "curl")}
#'     \item{file_size}{Numeric file size in bytes (only present on success)}
#'   }
#' @keywords internal
http_download_binary <- function(
  url,
  dest_path,
  timeout = 120,
  verbose = TRUE
) {
  config <- get_istat_config()

  # Try httr first
  httr_result <- .download_binary_httr(url, dest_path, timeout, config, verbose)

  if (httr_result$success) {
    httr_result$method <- "httr"
    return(httr_result)
  }

  # Fallback to curl if httr failed with a connection/timeout error
  # Do not retry on HTTP-level errors (4xx, 5xx) as curl would get the same
  is_transport_error <- is.na(httr_result$status_code) ||
    is_timeout_error(httr_result$error %||% "") ||
    is_connectivity_error(httr_result$error %||% "")

  if (!is_transport_error) {
    httr_result$method <- "httr"
    return(httr_result)
  }

  if (verbose) {
    istat_log(
      "Primary download method failed, using curl fallback",
      "WARNING",
      verbose
    )
  }

  curl_result <- .download_binary_curl(url, dest_path, timeout, config)
  curl_result$method <- "curl"

  return(curl_result)
}

# 4. httr binary download implementation -----

#' Download Binary File Using httr
#'
#' Internal function performing binary download with httr::write_disk().
#'
#' @param url Character URL to download.
#' @param dest_path Character local file path.
#' @param timeout Numeric timeout in seconds.
#' @param config Configuration list from get_istat_config().
#' @param verbose Logical whether to show progress.
#'
#' @return A list with success, dest_path, status_code, error, and file_size.
#' @keywords internal
.download_binary_httr <- function(url, dest_path, timeout, config, verbose) {
  response <- tryCatch(
    {
      httr::GET(
        url,
        httr::add_headers(`User-Agent` = config$http$user_agent),
        httr::write_disk(dest_path, overwrite = TRUE),
        httr::timeout(timeout),
        if (verbose) httr::progress() else NULL
      )
    },
    error = function(e) {
      return(list(
        success = FALSE,
        dest_path = dest_path,
        status_code = NA_integer_,
        error = e$message,
        file_size = NULL
      ))
    }
  )

  # Check if tryCatch returned an error structure
  if (is.list(response) && !inherits(response, "response")) {
    return(response)
  }

  status <- httr::status_code(response)

  if (status != 200L) {
    # Remove partial file on HTTP error
    if (file.exists(dest_path)) {
      unlink(dest_path)
    }
    return(list(
      success = FALSE,
      dest_path = dest_path,
      status_code = as.integer(status),
      error = paste("HTTP error:", status),
      file_size = NULL
    ))
  }

  # Verify the file was written
  if (!file.exists(dest_path) || file.size(dest_path) == 0) {
    return(list(
      success = FALSE,
      dest_path = dest_path,
      status_code = as.integer(status),
      error = "Download produced empty file",
      file_size = NULL
    ))
  }

  list(
    success = TRUE,
    dest_path = dest_path,
    status_code = as.integer(status),
    error = NULL,
    file_size = file.size(dest_path)
  )
}

# 5. curl binary download fallback -----

#' Download Binary File Using curl
#'
#' Fallback function using \code{curl::curl_download()} for binary downloads
#' when httr encounters transport-level errors.
#'
#' @param url Character URL to download.
#' @param dest_path Character local file path.
#' @param timeout Numeric timeout in seconds.
#' @param config Configuration list from get_istat_config().
#'
#' @return A list with success, dest_path, status_code, error, and file_size.
#' @keywords internal
.download_binary_curl <- function(url, dest_path, timeout, config) {
  tryCatch(
    {
      h <- curl::new_handle()
      curl::handle_setopt(
        h,
        timeout = timeout,
        connecttimeout = min(timeout, 30),
        followlocation = TRUE,
        useragent = config$http$user_agent
      )

      curl::curl_download(url, dest_path, handle = h)

      # Verify the file was written
      if (!file.exists(dest_path) || file.size(dest_path) == 0) {
        return(list(
          success = FALSE,
          dest_path = dest_path,
          status_code = NA_integer_,
          error = "curl download produced empty file",
          file_size = NULL
        ))
      }

      list(
        success = TRUE,
        dest_path = dest_path,
        status_code = 200L,
        error = NULL,
        file_size = file.size(dest_path)
      )
    },
    error = function(e) {
      # Remove partial file on error
      if (file.exists(dest_path)) {
        unlink(dest_path)
      }
      list(
        success = FALSE,
        dest_path = dest_path,
        status_code = NA_integer_,
        error = e$message,
        file_size = NULL
      )
    }
  )
}

# 6. HEAD request for update detection -----

#' HTTP HEAD Request for Demo Endpoint
#'
#' Performs a lightweight HEAD request to retrieve response headers from
#' demo.istat.it URLs. Used primarily for update detection via the
#' \code{Last-Modified} header and file size estimation via
#' \code{Content-Length}.
#'
#' Uses \code{curl::curl_fetch_memory()} with \code{nobody = TRUE}
#' (same pattern as \code{check_endpoint_status()} in endpoints.R).
#'
#' @param url Character string with the URL to check.
#' @param timeout Numeric timeout in seconds. Default 10.
#'
#' @return A list with components:
#'   \describe{
#'     \item{success}{Logical indicating if HEAD request succeeded}
#'     \item{status_code}{HTTP status code (integer), or NA on error}
#'     \item{last_modified}{POSIXct parsed from Last-Modified header, or NA}
#'     \item{content_length}{Integer parsed from Content-Length header, or NA}
#'     \item{error}{Error message string, or NULL on success}
#'   }
#' @keywords internal
http_head_demo <- function(url, timeout = 10) {
  tryCatch(
    {
      config <- get_istat_config()

      h <- curl::new_handle()
      curl::handle_setopt(
        h,
        timeout = timeout,
        connecttimeout = timeout,
        nobody = TRUE,
        followlocation = TRUE,
        useragent = config$http$user_agent
      )

      response <- curl::curl_fetch_memory(url, handle = h)

      status <- as.integer(response$status_code)

      if (status < 200L || status >= 400L) {
        return(list(
          success = FALSE,
          status_code = status,
          last_modified = NA,
          content_length = NA_integer_,
          error = paste("HTTP error:", status)
        ))
      }

      # Parse response headers
      headers <- .parse_response_headers(rawToChar(response$headers))

      # Extract Last-Modified header as POSIXct
      last_modified <- NA
      if (!is.null(headers[["last-modified"]])) {
        last_modified <- tryCatch(
          as.POSIXct(
            headers[["last-modified"]],
            format = "%a, %d %b %Y %H:%M:%S",
            tz = "GMT"
          ),
          error = function(e) NA
        )
      }

      # Extract Content-Length header as integer
      content_length <- NA_integer_
      if (!is.null(headers[["content-length"]])) {
        content_length <- suppressWarnings(
          as.integer(headers[["content-length"]])
        )
        if (is.na(content_length)) content_length <- NA_integer_
      }

      list(
        success = TRUE,
        status_code = status,
        last_modified = last_modified,
        content_length = content_length,
        error = NULL
      )
    },
    error = function(e) {
      list(
        success = FALSE,
        status_code = NA_integer_,
        last_modified = NA,
        content_length = NA_integer_,
        error = e$message
      )
    }
  )
}

#' Parse Raw HTTP Response Headers
#'
#' Splits raw header text into a named list with lowercase keys.
#' Handles multi-line values and CRLF line endings.
#'
#' @param raw_headers Character string of raw HTTP headers.
#'
#' @return Named list of header values (keys are lowercase).
#' @keywords internal
.parse_response_headers <- function(raw_headers) {
  if (is.null(raw_headers) || nchar(raw_headers) == 0) {
    return(list())
  }

  lines <- strsplit(raw_headers, "\r?\n")[[1]]

  # Skip the status line (e.g., "HTTP/1.1 200 OK")
  lines <- lines[!grepl("^HTTP/", lines)]

  # Remove empty lines
  lines <- lines[nchar(trimws(lines)) > 0]

  headers <- list()
  for (line in lines) {
    # Split on first colon
    colon_pos <- regexpr(":", line)
    if (colon_pos > 0) {
      key <- tolower(trimws(substr(line, 1, colon_pos - 1)))
      value <- trimws(substr(line, colon_pos + 1, nchar(line)))
      headers[[key]] <- value
    }
  }

  headers
}

# 7. Binary download with retry -----

#' Download Binary File with Retry and Rate Limiting
#'
#' Wraps \code{http_download_binary()} with demo-specific throttling and
#' exponential backoff retry logic. Uses configuration from
#' \code{get_istat_config()$demo_rate_limit}.
#'
#' Retries are attempted on HTTP 429 (rate limited) and 503 (service
#' unavailable) responses. Non-retryable errors (e.g., 404) are returned
#' immediately.
#'
#' @param url Character string with the full URL to download.
#' @param dest_path Character string with the local file path to write to.
#' @param timeout Numeric timeout in seconds. Default 120.
#' @param verbose Logical whether to log status messages. Default TRUE.
#'
#' @return A list with same structure as \code{http_download_binary()}.
#' @keywords internal
http_download_binary_with_retry <- function(
  url,
  dest_path,
  timeout = 120,
  verbose = TRUE
) {
  config <- get_istat_config()
  rl <- config$demo_rate_limit

  for (attempt in seq_len(rl$max_retries + 1)) {
    # Throttle before each request
    demo_throttle()

    # Make the download request
    result <- http_download_binary(
      url,
      dest_path = dest_path,
      timeout = timeout,
      verbose = verbose
    )

    # Success: return immediately
    if (result$success) {
      return(result)
    }

    # Check if retryable (429 or 503)
    is_429 <- !is.na(result$status_code) && result$status_code == 429L
    is_503 <- !is.na(result$status_code) && result$status_code == 503L

    # Connection/timeout errors are also retryable
    is_transport <- is.na(result$status_code) &&
      !is.null(result$error) &&
      (is_timeout_error(result$error) || is_connectivity_error(result$error))

    if (!is_429 && !is_503 && !is_transport) {
      # Non-retryable error (e.g., 404, 403)
      return(result)
    }

    # Check if we have retries left
    if (attempt > rl$max_retries) {
      if (verbose) {
        istat_log(
          paste("Max retries reached after", rl$max_retries, "attempts"),
          "WARNING",
          verbose
        )
      }
      return(result)
    }

    # Compute backoff with jitter
    backoff <- min(
      rl$initial_backoff * (rl$backoff_multiplier^(attempt - 1)),
      rl$max_backoff
    )

    jitter_range <- backoff * rl$jitter_fraction
    backoff <- backoff + stats::runif(1, -jitter_range, jitter_range)
    backoff <- max(1, backoff)

    status_type <- if (is_429) {
      "429 (rate limited)"
    } else if (is_503) {
      "503 (service unavailable)"
    } else {
      "transport error"
    }

    if (verbose) {
      istat_log(
        paste0(
          "HTTP ",
          status_type,
          " on attempt ",
          attempt,
          ". Retrying in ",
          round(backoff),
          "s..."
        ),
        "WARNING",
        verbose
      )
    }

    Sys.sleep(backoff)
  }

  result
}
