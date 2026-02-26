# test-http-post.R - Tests for HTTP POST functions (http_transport.R sections 7-10)

# 1. http_post_httr structure -----

test_that("http_post_httr exists and is a function", {
  expect_true(is.function(http_post_httr))
})

test_that("http_post_httr returns expected list structure on success", {
  local_mocked_bindings(
    get_istat_config = function() {
      list(http = list(user_agent = "istatlab-test/0.0.1"))
    }
  )

  local_mocked_bindings(
    POST = function(...) {
      structure(
        list(
          status_code = 200L,
          headers = list(),
          content = charToRaw("test response content")
        ),
        class = "response"
      )
    },
    status_code = function(x) 200L,
    content = function(x, ...) "test response content",
    .package = "httr"
  )

  result <- http_post_httr(
    url = "https://example.com/test",
    body = "test_body",
    timeout = 30,
    accept = "text/csv",
    content_type = "application/x-www-form-urlencoded",
    verbose = FALSE
  )

  expect_type(result, "list")
  expect_true("success" %in% names(result))
  expect_true("content" %in% names(result))
  expect_true("status_code" %in% names(result))
  expect_true("error" %in% names(result))
  expect_true("headers" %in% names(result))
  expect_true(result$success)
  expect_equal(result$content, "test response content")
})

test_that("http_post_httr returns error structure on HTTP failure", {
  local_mocked_bindings(
    get_istat_config = function() {
      list(http = list(user_agent = "istatlab-test/0.0.1"))
    }
  )

  local_mocked_bindings(
    POST = function(...) {
      structure(
        list(
          status_code = 500L,
          headers = list()
        ),
        class = "response"
      )
    },
    status_code = function(x) 500L,
    headers = function(x) {
      structure(list(), class = "insensitive")
    },
    .package = "httr"
  )

  result <- http_post_httr(
    url = "https://example.com/test",
    body = "test_body",
    timeout = 30,
    accept = "text/csv",
    content_type = "application/x-www-form-urlencoded",
    verbose = FALSE
  )

  expect_false(result$success)
  expect_equal(result$status_code, 500L)
  expect_true(grepl("500", result$error))
})

test_that("http_post_httr returns error structure on connection failure", {
  local_mocked_bindings(
    get_istat_config = function() {
      list(http = list(user_agent = "istatlab-test/0.0.1"))
    }
  )

  local_mocked_bindings(
    POST = function(...) stop("Connection refused"),
    .package = "httr"
  )

  result <- http_post_httr(
    url = "https://example.com/test",
    body = "test_body",
    timeout = 30,
    accept = "text/csv",
    content_type = "application/x-www-form-urlencoded",
    verbose = FALSE
  )

  expect_false(result$success)
  expect_true(is.na(result$status_code))
  expect_true(grepl("Connection refused", result$error))
})

# 2. http_post basic -----

test_that("http_post returns result with method='httr' on success", {
  local_mocked_bindings(
    http_post_httr = function(
      url,
      body,
      timeout,
      accept,
      content_type,
      verbose
    ) {
      list(
        success = TRUE,
        content = "mock csv data",
        status_code = 200L,
        error = NULL,
        headers = NULL
      )
    }
  )

  result <- http_post(
    url = "https://example.com/data",
    body = "ALL",
    timeout = 30,
    verbose = FALSE
  )

  expect_true(result$success)
  expect_equal(result$method, "httr")
  expect_equal(result$content, "mock csv data")
})

test_that("http_post returns error structure on httr failure", {
  local_mocked_bindings(
    http_post_httr = function(
      url,
      body,
      timeout,
      accept,
      content_type,
      verbose
    ) {
      list(
        success = FALSE,
        content = NULL,
        status_code = 503L,
        error = "HTTP error: 503",
        headers = NULL
      )
    }
  )

  result <- http_post(
    url = "https://example.com/data",
    body = "ALL",
    timeout = 30,
    verbose = FALSE
  )

  expect_false(result$success)
  expect_equal(result$method, "httr")
  expect_equal(result$status_code, 503L)
  expect_true(grepl("503", result$error))
})

test_that("http_post uses config accept_csv when accept is NULL", {
  captured_accept <- NULL

  local_mocked_bindings(
    http_post_httr = function(
      url,
      body,
      timeout,
      accept,
      content_type,
      verbose
    ) {
      captured_accept <<- accept
      list(
        success = TRUE,
        content = "mock",
        status_code = 200L,
        error = NULL,
        headers = NULL
      )
    }
  )

  http_post(
    url = "https://example.com/data",
    body = "ALL",
    timeout = 30,
    accept = NULL,
    verbose = FALSE
  )

  config <- get_istat_config()
  expect_equal(captured_accept, config$http$accept_csv)
})

# 3. http_post_with_retry retry logic -----

test_that("http_post_with_retry retries on 429 then succeeds", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  attempt_count <- 0L

  # Use minimal backoff config to avoid real delays
  fast_config <- get_istat_config()
  fast_config$rate_limit$initial_backoff <- 0.01
  fast_config$rate_limit$max_backoff <- 0.01
  fast_config$rate_limit$jitter_fraction <- 0

  local_mocked_bindings(
    http_post = function(url, body, timeout, accept, content_type, verbose) {
      attempt_count <<- attempt_count + 1L
      if (attempt_count <= 2L) {
        list(
          success = FALSE,
          content = NULL,
          status_code = 429L,
          error = "HTTP error: 429",
          method = "httr",
          headers = list("retry-after" = "0.01")
        )
      } else {
        list(
          success = TRUE,
          content = "success data",
          status_code = 200L,
          error = NULL,
          method = "httr",
          headers = NULL
        )
      }
    },
    throttle = function(...) invisible(NULL),
    get_istat_config = function() fast_config
  )

  result <- http_post_with_retry(
    url = "https://example.com/data",
    body = "ALL",
    timeout = 30,
    verbose = FALSE
  )

  expect_true(result$success)
  expect_equal(result$content, "success data")
  expect_equal(attempt_count, 3L)
})

test_that("http_post_with_retry retries on 503 status", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  attempt_count <- 0L

  # Use minimal backoff config to avoid real delays
  fast_config <- get_istat_config()
  fast_config$rate_limit$initial_backoff <- 0.01
  fast_config$rate_limit$max_backoff <- 0.01
  fast_config$rate_limit$jitter_fraction <- 0

  local_mocked_bindings(
    http_post = function(url, body, timeout, accept, content_type, verbose) {
      attempt_count <<- attempt_count + 1L
      if (attempt_count == 1L) {
        list(
          success = FALSE,
          content = NULL,
          status_code = 503L,
          error = "HTTP error: 503",
          method = "httr",
          headers = NULL
        )
      } else {
        list(
          success = TRUE,
          content = "recovered",
          status_code = 200L,
          error = NULL,
          method = "httr",
          headers = NULL
        )
      }
    },
    throttle = function(...) invisible(NULL),
    get_istat_config = function() fast_config
  )

  result <- http_post_with_retry(
    url = "https://example.com/data",
    body = "ALL",
    timeout = 30,
    verbose = FALSE
  )

  expect_true(result$success)
  expect_gte(attempt_count, 2L)
})

test_that("http_post_with_retry returns failure when max retries reached", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  # Use minimal backoff config to avoid real delays
  fast_config <- get_istat_config()
  fast_config$rate_limit$initial_backoff <- 0.01
  fast_config$rate_limit$max_backoff <- 0.01
  fast_config$rate_limit$jitter_fraction <- 0

  local_mocked_bindings(
    http_post = function(url, body, timeout, accept, content_type, verbose) {
      list(
        success = FALSE,
        content = NULL,
        status_code = 429L,
        error = "HTTP error: 429",
        method = "httr",
        headers = list("retry-after" = "0.01")
      )
    },
    throttle = function(...) invisible(NULL),
    detect_ban = function(...) FALSE,
    get_istat_config = function() fast_config
  )

  result <- suppressWarnings(
    http_post_with_retry(
      url = "https://example.com/data",
      body = "ALL",
      timeout = 30,
      verbose = FALSE
    )
  )

  expect_false(result$success)
  expect_equal(result$status_code, 429L)
})

test_that("http_post_with_retry does not retry non-retryable errors", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  attempt_count <- 0L

  local_mocked_bindings(
    http_post = function(url, body, timeout, accept, content_type, verbose) {
      attempt_count <<- attempt_count + 1L
      list(
        success = FALSE,
        content = NULL,
        status_code = 404L,
        error = "HTTP error: 404",
        method = "httr",
        headers = NULL
      )
    },
    throttle = function(...) invisible(NULL)
  )

  result <- http_post_with_retry(
    url = "https://example.com/data",
    body = "ALL",
    timeout = 30,
    verbose = FALSE
  )

  expect_false(result$success)
  expect_equal(attempt_count, 1L)
  expect_equal(result$status_code, 404L)
})

test_that("http_post_with_retry resets 429 counter on success", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  .istat_rate_limiter$consecutive_429s <- 2L
  attempt_count <- 0L

  local_mocked_bindings(
    http_post = function(url, body, timeout, accept, content_type, verbose) {
      attempt_count <<- attempt_count + 1L
      list(
        success = TRUE,
        content = "ok",
        status_code = 200L,
        error = NULL,
        method = "httr",
        headers = NULL
      )
    },
    throttle = function(...) invisible(NULL)
  )

  result <- http_post_with_retry(
    url = "https://example.com/data",
    body = "ALL",
    timeout = 30,
    verbose = FALSE
  )

  expect_true(result$success)
  expect_equal(.istat_rate_limiter$consecutive_429s, 0L)
})

# 4. http_post_json -----

test_that("http_post_json parses valid JSON response", {
  local_mocked_bindings(
    http_post_with_retry = function(
      url,
      body,
      timeout,
      accept,
      content_type,
      verbose
    ) {
      list(
        success = TRUE,
        content = '{"data": [1, 2, 3], "status": "ok"}',
        status_code = 200L,
        error = NULL,
        method = "httr",
        headers = NULL
      )
    }
  )

  result <- http_post_json(
    url = "https://example.com/api",
    body = "query_body",
    timeout = 30,
    verbose = FALSE,
    simplifyVector = TRUE
  )

  expect_type(result, "list")
  expect_equal(result$status, "ok")
  expect_equal(result$data, c(1, 2, 3))
})

test_that("http_post_json errors on HTTP failure", {
  local_mocked_bindings(
    http_post_with_retry = function(
      url,
      body,
      timeout,
      accept,
      content_type,
      verbose
    ) {
      list(
        success = FALSE,
        content = NULL,
        status_code = 500L,
        error = "HTTP error: 500",
        method = "httr",
        headers = NULL
      )
    }
  )

  expect_error(
    http_post_json(
      url = "https://example.com/api",
      body = "query_body",
      timeout = 30,
      verbose = FALSE
    ),
    "HTTP error: 500"
  )
})

test_that("http_post_json passes content_type through", {
  captured_content_type <- NULL

  local_mocked_bindings(
    http_post_with_retry = function(
      url,
      body,
      timeout,
      accept,
      content_type,
      verbose
    ) {
      captured_content_type <<- content_type
      list(
        success = TRUE,
        content = '{"ok": true}',
        status_code = 200L,
        error = NULL,
        method = "httr",
        headers = NULL
      )
    }
  )

  http_post_json(
    url = "https://example.com/api",
    body = "body",
    timeout = 30,
    verbose = FALSE,
    content_type = "application/json"
  )

  expect_equal(captured_content_type, "application/json")
})

test_that("http_post_json sends accept as application/json", {
  captured_accept <- NULL

  local_mocked_bindings(
    http_post_with_retry = function(
      url,
      body,
      timeout,
      accept,
      content_type,
      verbose
    ) {
      captured_accept <<- accept
      list(
        success = TRUE,
        content = '{"ok": true}',
        status_code = 200L,
        error = NULL,
        method = "httr",
        headers = NULL
      )
    }
  )

  http_post_json(
    url = "https://example.com/api",
    body = "body",
    timeout = 30,
    verbose = FALSE
  )

  expect_equal(captured_accept, "application/json")
})
