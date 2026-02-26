# http_transport.R - HTTP transport layer for ISTAT API
# Handles raw HTTP operations with retry, fallback, and rate limiting

# 1. Rate limiter state -----

# Package-level environment for rate limiting state
.istat_rate_limiter <- new.env(parent = emptyenv())
.istat_rate_limiter$last_request_time <- NULL
.istat_rate_limiter$consecutive_429s <- 0L

# 2. Rate limiting functions -----

#' Throttle API Requests
#'
#' Enforces minimum delay between HTTP requests to respect ISTAT rate limits.
#' Adds jitter to prevent synchronized request patterns.
#'
#' @param config_override Optional list to override rate_limit config values
#'
#' @return Invisible NULL
#' @keywords internal
throttle <- function(config_override = NULL) {
  config <- if (!is.null(config_override)) {
    config_override
  } else {
    get_istat_config()$rate_limit
  }

  delay <- config$delay
  jitter_fraction <- config$jitter_fraction

  last_time <- .istat_rate_limiter$last_request_time

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

  .istat_rate_limiter$last_request_time <- Sys.time()
  invisible(NULL)
}

#' Detect Potential IP Ban
#'
#' Checks if consecutive 429 responses indicate a likely IP ban.
#'
#' @param consecutive_429s Integer count of consecutive 429 responses
#' @param threshold Integer ban detection threshold
#'
#' @return Logical TRUE if ban is likely
#' @keywords internal
detect_ban <- function(consecutive_429s, threshold) {
  if (consecutive_429s >= threshold) {
    warning(
      "Received ",
      consecutive_429s,
      " consecutive HTTP 429 responses. ",
      "Your IP may be temporarily banned by ISTAT. ",
      "Wait 24-48 hours before retrying.",
      call. = FALSE
    )
    return(TRUE)
  }
  FALSE
}

#' Reset Rate Limiter State
#'
#' Resets the internal rate limiter state. Useful for testing
#' or after an IP ban has expired.
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Reset after ban period
#' reset_rate_limiter()
#' }
reset_rate_limiter <- function() {
  .istat_rate_limiter$last_request_time <- NULL
  .istat_rate_limiter$consecutive_429s <- 0L
  invisible(NULL)
}

# 3. Main HTTP function -----

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
#'     \item{headers}: Response headers list (when available)
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
    istat_log(
      "Primary HTTP method failed, using curl fallback",
      "WARNING",
      verbose
    )
  }

  curl_result <- http_get_curl(url, timeout, accept, verbose)
  curl_result$method <- "curl"

  return(curl_result)
}

#' HTTP GET with Retry and Rate Limiting
#'
#' Wraps http_get() with throttling, retry logic, and ban detection.
#' Handles 429 (Too Many Requests) and 503 (Service Unavailable) with
#' exponential backoff.
#'
#' @param url Character string with the full URL
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param verbose Logical whether to log status messages
#'
#' @return A list with same structure as http_get()
#' @keywords internal
http_get_with_retry <- function(
  url,
  timeout = 120,
  accept = NULL,
  verbose = TRUE
) {
  config <- get_istat_config()
  rl <- config$rate_limit

  for (attempt in seq_len(rl$max_retries + 1)) {
    # Throttle before each request
    throttle()

    # Make the request
    result <- http_get(
      url,
      timeout = timeout,
      accept = accept,
      verbose = verbose
    )

    # Success: reset counter and return
    if (result$success) {
      .istat_rate_limiter$consecutive_429s <- 0L
      return(result)
    }

    # Check if retryable (429 or 503)
    is_429 <- !is.na(result$status_code) && result$status_code == 429L
    is_503 <- !is.na(result$status_code) && result$status_code == 503L

    if (!is_429 && !is_503) {
      # Non-retryable error
      .istat_rate_limiter$consecutive_429s <- 0L
      return(result)
    }

    # Track consecutive 429s
    if (is_429) {
      .istat_rate_limiter$consecutive_429s <- .istat_rate_limiter$consecutive_429s +
        1L

      if (
        detect_ban(
          .istat_rate_limiter$consecutive_429s,
          rl$ban_detection_threshold
        )
      ) {
        return(result)
      }
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
    retry_after <- NULL
    if (!is.null(result$headers) && !is.null(result$headers[["retry-after"]])) {
      retry_after <- suppressWarnings(as.numeric(result$headers[[
        "retry-after"
      ]]))
    }

    backoff <- if (!is.null(retry_after) && !is.na(retry_after)) {
      retry_after
    } else {
      min(
        rl$initial_backoff * (rl$backoff_multiplier^(attempt - 1)),
        rl$max_backoff
      )
    }

    # Add jitter to backoff
    jitter_range <- backoff * rl$jitter_fraction
    backoff <- backoff + stats::runif(1, -jitter_range, jitter_range)
    backoff <- max(1, backoff)

    status_type <- if (is_429) {
      "429 (rate limited)"
    } else {
      "503 (service unavailable)"
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

# 4. JSON and XML transport helpers -----

#' HTTP GET with JSON Parsing
#'
#' Fetches a URL through the throttled transport layer and parses the
#' response as JSON. Replaces direct httr::GET + jsonlite::fromJSON calls.
#'
#' @param url Character string with the full URL
#' @param timeout Numeric timeout in seconds
#' @param verbose Logical whether to log status messages
#' @param simplifyVector Logical passed to jsonlite::fromJSON. Default FALSE.
#' @param flatten Logical passed to jsonlite::fromJSON. Default FALSE.
#'
#' @return Parsed JSON object (list), or signals an error on failure
#' @keywords internal
http_get_json <- function(
  url,
  timeout = 120,
  verbose = TRUE,
  simplifyVector = FALSE,
  flatten = FALSE
) {
  result <- http_get_with_retry(
    url,
    timeout = timeout,
    accept = "application/json",
    verbose = verbose
  )

  if (!result$success) {
    stop(result$error %||% paste("HTTP error:", result$status_code))
  }

  jsonlite::fromJSON(
    result$content,
    simplifyVector = simplifyVector,
    flatten = flatten
  )
}

#' HTTP GET with XML Content
#'
#' Fetches a URL through the throttled transport layer and returns
#' the raw text content for XML parsing. Replaces direct httr::GET calls
#' for XML endpoints.
#'
#' @param url Character string with the full URL
#' @param timeout Numeric timeout in seconds
#' @param verbose Logical whether to log status messages
#'
#' @return Character string with XML content, or signals an error on failure
#' @keywords internal
http_get_xml <- function(url, timeout = 120, verbose = TRUE) {
  result <- http_get_with_retry(
    url,
    timeout = timeout,
    accept = "application/xml",
    verbose = verbose
  )

  if (!result$success) {
    stop(result$error %||% paste("HTTP error:", result$status_code))
  }

  result$content
}

# 5. httr implementation -----

#' HTTP GET using httr Package
#'
#' Internal function that performs HTTP GET using the httr package.
#' Captures response headers on non-200 responses for retry logic.
#'
#' @param url Character string with the full URL
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param verbose Logical whether to log status messages
#'
#' @return A list with success, content, status_code, error, and headers components
#' @keywords internal
http_get_httr <- function(url, timeout, accept, verbose) {
  config <- get_istat_config()

  response <- tryCatch(
    {
      httr::GET(
        url,
        httr::add_headers(
          Accept = accept,
          `User-Agent` = config$http$user_agent
        ),
        httr::timeout(timeout)
      )
    },
    error = function(e) {
      return(list(
        success = FALSE,
        content = NULL,
        status_code = NA_integer_,
        error = e$message,
        headers = NULL
      ))
    }
  )

  # Check if tryCatch returned an error structure
  if (is.list(response) && !inherits(response, "response")) {
    return(response)
  }

  status <- httr::status_code(response)

  if (status != 200) {
    # Capture response headers for retry logic (e.g., Retry-After)
    resp_headers <- tryCatch(
      {
        as.list(httr::headers(response))
      },
      error = function(e) NULL
    )

    return(list(
      success = FALSE,
      content = NULL,
      status_code = status,
      error = paste("HTTP error:", status),
      headers = resp_headers
    ))
  }

  # Extract content
  content <- tryCatch(
    {
      httr::content(response, as = "text", encoding = "UTF-8")
    },
    error = function(e) NULL
  )

  # Validate content
  if (is.null(content) || nchar(content) == 0) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = status,
      error = "Empty response body",
      headers = NULL
    ))
  }

  list(
    success = TRUE,
    content = content,
    status_code = status,
    error = NULL,
    headers = NULL
  )
}

# 6. curl fallback implementation -----

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
    timeout,
    accept,
    tmp,
    url
  )

  result <- tryCatch(
    {
      output <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
      # system() with intern=TRUE stores exit code in status attribute
      curl_exit <- attr(output, "status")
      if (is.null(curl_exit)) {
        curl_exit <- 0L
      }
      status_code <- as.integer(output[length(output)])
      list(exit_status = curl_exit, status_code = status_code)
    },
    error = function(e) {
      list(exit_status = 1L, error = e$message)
    }
  )

  # Check for curl error (exit status != 0)
  # Common curl exit codes: 6=DNS error, 7=connection refused, 28=timeout
  if (!is.null(result$exit_status) && result$exit_status != 0) {
    error_msg <- switch(
      as.character(result$exit_status),
      "6" = "Could not resolve host",
      "7" = "Connection refused",
      "28" = "Connection timed out",
      "35" = "SSL connection error",
      "52" = "Empty server response",
      "56" = "Network error during receive",
      paste("curl error:", result$exit_status)
    )
    return(list(
      success = FALSE,
      content = NULL,
      status_code = NA_integer_,
      error = error_msg,
      headers = NULL
    ))
  }

  # Check HTTP status
  if (!is.na(result$status_code) && result$status_code != 200) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = result$status_code,
      error = paste("HTTP error:", result$status_code),
      headers = NULL
    ))
  }

  # Check if file was created and has content
  if (!file.exists(tmp) || file.size(tmp) == 0) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = result$status_code,
      error = "Empty response from curl",
      headers = NULL
    ))
  }

  # Read content from temp file
  content <- paste(
    readLines(tmp, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )

  list(
    success = TRUE,
    content = content,
    status_code = result$status_code,
    error = NULL,
    headers = NULL
  )
}

# 7. HTTP POST via httr -----

#' HTTP POST using httr Package
#'
#' Internal function that performs HTTP POST using the httr package.
#' Mirrors [http_get_httr()] but sends a POST request with a body payload.
#' Designed for SDMX filter key queries that exceed GET URL length limits.
#'
#' @param url Character string with the full URL
#' @param body Character string with the POST request body
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param content_type Character string with Content-Type header value
#' @param verbose Logical whether to log status messages
#'
#' @return A list with success, content, status_code, error, and headers components
#' @keywords internal
http_post_httr <- function(
  url,
  body,
  timeout,
  accept,
  content_type,
  verbose
) {
  config <- get_istat_config()

  response <- tryCatch(
    {
      httr::POST(
        url,
        body = body,
        httr::content_type(content_type),
        httr::add_headers(
          Accept = accept,
          `User-Agent` = config$http$user_agent
        ),
        httr::timeout(timeout)
      )
    },
    error = function(e) {
      return(list(
        success = FALSE,
        content = NULL,
        status_code = NA_integer_,
        error = e$message,
        headers = NULL
      ))
    }
  )

  # Check if tryCatch returned an error structure
  if (is.list(response) && !inherits(response, "response")) {
    return(response)
  }

  status <- httr::status_code(response)

  if (status != 200) {
    # Capture response headers for retry logic (e.g., Retry-After)
    resp_headers <- tryCatch(
      {
        as.list(httr::headers(response))
      },
      error = function(e) NULL
    )

    return(list(
      success = FALSE,
      content = NULL,
      status_code = status,
      error = paste("HTTP error:", status),
      headers = resp_headers
    ))
  }

  # Extract content
  content <- tryCatch(
    {
      httr::content(response, as = "text", encoding = "UTF-8")
    },
    error = function(e) NULL
  )

  # Validate content
  if (is.null(content) || nchar(content) == 0) {
    return(list(
      success = FALSE,
      content = NULL,
      status_code = status,
      error = "Empty response body",
      headers = NULL
    ))
  }

  list(
    success = TRUE,
    content = content,
    status_code = status,
    error = NULL,
    headers = NULL
  )
}

# 8. Main HTTP POST function -----

#' HTTP POST Request
#'
#' Performs HTTP POST request using httr. Mirrors [http_get()] but for POST
#' requests with a body payload. No curl fallback is provided for POST.
#'
#' @param url Character string with the full URL
#' @param body Character string with the POST request body (typically an SDMX
#'   filter key for large queries)
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param content_type Character string with Content-Type header value.
#'   Defaults to `"application/x-www-form-urlencoded"`.
#' @param verbose Logical whether to log status messages
#'
#' @return A list with components:
#'   \itemize{
#'     \item{success}: Logical indicating if request succeeded
#'     \item{content}: Character string with response body (or NULL)
#'     \item{status_code}: HTTP status code (or NA)
#'     \item{error}: Error message if failed (or NULL)
#'     \item{method}: Character `"httr"` (POST uses httr only)
#'     \item{headers}: Response headers list (when available)
#'   }
#' @keywords internal
http_post <- function(
  url,
  body,
  timeout = 120,
  accept = NULL,
  content_type = "application/x-www-form-urlencoded",
  verbose = TRUE
) {
  config <- get_istat_config()

  if (is.null(accept)) {
    accept <- config$http$accept_csv
  }

  result <- http_post_httr(url, body, timeout, accept, content_type, verbose)
  result$method <- "httr"

  return(result)
}

# 9. HTTP POST with retry -----

#' HTTP POST with Retry and Rate Limiting
#'
#' Wraps [http_post()] with throttling, retry logic, and ban detection.
#' Handles 429 (Too Many Requests) and 503 (Service Unavailable) with
#' exponential backoff. Mirrors [http_get_with_retry()] for POST requests.
#'
#' @param url Character string with the full URL
#' @param body Character string with the POST request body
#' @param timeout Numeric timeout in seconds
#' @param accept Character string with Accept header value
#' @param content_type Character string with Content-Type header value.
#'   Defaults to `"application/x-www-form-urlencoded"`.
#' @param verbose Logical whether to log status messages
#'
#' @return A list with same structure as [http_post()]
#' @keywords internal
http_post_with_retry <- function(
  url,
  body,
  timeout = 120,
  accept = NULL,
  content_type = "application/x-www-form-urlencoded",
  verbose = TRUE
) {
  config <- get_istat_config()
  rl <- config$rate_limit

  for (attempt in seq_len(rl$max_retries + 1)) {
    # Throttle before each request
    throttle()

    # Make the request
    result <- http_post(
      url,
      body = body,
      timeout = timeout,
      accept = accept,
      content_type = content_type,
      verbose = verbose
    )

    # Success: reset counter and return
    if (result$success) {
      .istat_rate_limiter$consecutive_429s <- 0L
      return(result)
    }

    # Check if retryable (429 or 503)
    is_429 <- !is.na(result$status_code) && result$status_code == 429L
    is_503 <- !is.na(result$status_code) && result$status_code == 503L

    if (!is_429 && !is_503) {
      # Non-retryable error
      .istat_rate_limiter$consecutive_429s <- 0L
      return(result)
    }

    # Track consecutive 429s
    if (is_429) {
      .istat_rate_limiter$consecutive_429s <- .istat_rate_limiter$consecutive_429s +
        1L

      if (
        detect_ban(
          .istat_rate_limiter$consecutive_429s,
          rl$ban_detection_threshold
        )
      ) {
        return(result)
      }
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
    retry_after <- NULL
    if (!is.null(result$headers) && !is.null(result$headers[["retry-after"]])) {
      retry_after <- suppressWarnings(as.numeric(result$headers[[
        "retry-after"
      ]]))
    }

    backoff <- if (!is.null(retry_after) && !is.na(retry_after)) {
      retry_after
    } else {
      min(
        rl$initial_backoff * (rl$backoff_multiplier^(attempt - 1)),
        rl$max_backoff
      )
    }

    # Add jitter to backoff
    jitter_range <- backoff * rl$jitter_fraction
    backoff <- backoff + stats::runif(1, -jitter_range, jitter_range)
    backoff <- max(1, backoff)

    status_type <- if (is_429) {
      "429 (rate limited)"
    } else {
      "503 (service unavailable)"
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

# 10. POST JSON helper -----

#' HTTP POST with JSON Parsing
#'
#' Sends a POST request through the throttled transport layer and parses the
#' response as JSON. Mirrors [http_get_json()] for POST requests.
#'
#' @param url Character string with the full URL
#' @param body Character string with the POST request body
#' @param timeout Numeric timeout in seconds
#' @param verbose Logical whether to log status messages
#' @param simplifyVector Logical passed to [jsonlite::fromJSON()]. Default FALSE.
#' @param flatten Logical passed to [jsonlite::fromJSON()]. Default FALSE.
#' @param content_type Character string with Content-Type header value.
#'   Defaults to `"application/x-www-form-urlencoded"`.
#'
#' @return Parsed JSON object (list), or signals an error on failure
#' @keywords internal
http_post_json <- function(
  url,
  body,
  timeout = 120,
  verbose = TRUE,
  simplifyVector = FALSE,
  flatten = FALSE,
  content_type = "application/x-www-form-urlencoded"
) {
  result <- http_post_with_retry(
    url,
    body = body,
    timeout = timeout,
    accept = "application/json",
    content_type = content_type,
    verbose = verbose
  )

  if (!result$success) {
    stop(result$error %||% paste("HTTP error:", result$status_code))
  }

  jsonlite::fromJSON(
    result$content,
    simplifyVector = simplifyVector,
    flatten = flatten
  )
}
