# Tests for rate limiting functionality (http_transport.R and error_handling.R)

# 1. Rate limiter environment tests -----

test_that(".istat_rate_limiter environment exists with correct initial state", {
  expect_true(is.environment(.istat_rate_limiter))
  expect_true(
    "last_request_time" %in% ls(.istat_rate_limiter, all.names = TRUE)
  )
  expect_true("consecutive_429s" %in% ls(.istat_rate_limiter, all.names = TRUE))
})

# 2. throttle() function tests -----

test_that("throttle first call does not sleep when no previous timestamp", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  test_config <- list(delay = 1, jitter_fraction = 0)

  start <- Sys.time()
  throttle(config_override = test_config)
  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))

  expect_lt(elapsed, 0.5)
})

test_that("throttle enforces delay between consecutive calls", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  test_config <- list(delay = 1, jitter_fraction = 0)

  throttle(config_override = test_config) # first call sets timestamp
  start <- Sys.time()
  throttle(config_override = test_config) # second call should wait
  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))

  expect_gte(elapsed, 0.8)
})

test_that("throttle updates last_request_time after each call", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  test_config <- list(delay = 0, jitter_fraction = 0)

  expect_null(.istat_rate_limiter$last_request_time)
  throttle(config_override = test_config)
  expect_s3_class(.istat_rate_limiter$last_request_time, "POSIXct")
})

test_that("throttle returns invisible NULL", {
  reset_rate_limiter()
  on.exit(reset_rate_limiter())

  test_config <- list(delay = 0, jitter_fraction = 0)
  result <- throttle(config_override = test_config)

  expect_null(result)
})

# 3. detect_ban() function tests -----

test_that("detect_ban returns TRUE when threshold is met or exceeded", {
  expect_true(suppressWarnings(detect_ban(3, 3)))
  expect_true(suppressWarnings(detect_ban(5, 3)))
})

test_that("detect_ban returns FALSE below threshold", {
  expect_false(detect_ban(2, 3))
  expect_false(detect_ban(0, 3))
})

test_that("detect_ban issues warning when ban is detected", {
  expect_warning(detect_ban(3, 3), "429")
  expect_warning(detect_ban(3, 3), "temporarily banned")
})

test_that("detect_ban does not warn below threshold", {
  expect_no_warning(detect_ban(2, 3))
  expect_no_warning(detect_ban(0, 3))
})

# 4. reset_rate_limiter() function tests -----

test_that("reset_rate_limiter clears all state", {
  .istat_rate_limiter$last_request_time <- Sys.time()
  .istat_rate_limiter$consecutive_429s <- 5L
  reset_rate_limiter()

  expect_null(.istat_rate_limiter$last_request_time)
  expect_equal(.istat_rate_limiter$consecutive_429s, 0L)
})

test_that("reset_rate_limiter returns invisible NULL", {
  result <- reset_rate_limiter()
  expect_null(result)
})

test_that("reset_rate_limiter is safe to call on already clean state", {
  reset_rate_limiter()
  expect_no_error(reset_rate_limiter())
  expect_null(.istat_rate_limiter$last_request_time)
  expect_equal(.istat_rate_limiter$consecutive_429s, 0L)
})

# 5. is_rate_limited_error() function tests -----

test_that("is_rate_limited_error identifies rate limit patterns", {
  # Positive cases
  expect_true(is_rate_limited_error("429"))
  expect_true(is_rate_limited_error("HTTP error: 429"))
  expect_true(is_rate_limited_error("Too Many Requests"))
  expect_true(is_rate_limited_error("rate limit exceeded"))

  # Case insensitivity
  expect_true(is_rate_limited_error("RATE LIMIT EXCEEDED"))
  expect_true(is_rate_limited_error("too many requests"))
})

test_that("is_rate_limited_error rejects non-rate-limit errors", {
  # Negative cases
  expect_false(is_rate_limited_error("timeout"))
  expect_false(is_rate_limited_error("500"))
  expect_false(is_rate_limited_error("connection refused"))
})

test_that("is_rate_limited_error handles edge cases", {
  expect_false(is_rate_limited_error(NULL))
  expect_false(is_rate_limited_error(""))
  expect_false(is_rate_limited_error(123))
})

# 6. classify_api_error() exit code 3 for rate limiting -----

test_that("classify_api_error returns exit code 3 for rate limited errors", {
  result_429 <- classify_api_error("HTTP error: 429")
  expect_equal(result_429$type, "rate_limited")
  expect_equal(result_429$exit_code, 3L)

  result_tmr <- classify_api_error("Too Many Requests")
  expect_equal(result_tmr$type, "rate_limited")
  expect_equal(result_tmr$exit_code, 3L)
})

test_that("classify_api_error prioritizes rate_limited over http for 429", {
  # "429" matches both is_rate_limited_error and is_http_error patterns
  # rate_limited should win because it is checked first
  result <- classify_api_error("HTTP error: 429")
  expect_equal(result$type, "rate_limited")
  expect_equal(result$exit_code, 3L)
})

test_that("classify_api_error includes formatted message for rate limited", {
  result <- classify_api_error("HTTP error: 429")
  expect_true(grepl("Rate limited", result$message))
})

# 7. Config validation tests -----

test_that("get_istat_config contains rate_limit section", {
  config <- get_istat_config()
  expect_true("rate_limit" %in% names(config))
})

test_that("rate_limit config has correct default values", {
  rl <- get_istat_config()$rate_limit

  expect_equal(rl$delay, 13)
  expect_equal(rl$min_delay, 5)
  expect_equal(rl$max_retries, 3)
})

test_that("rate_limit config values are internally consistent", {
  rl <- get_istat_config()$rate_limit

  # delay must be at least min_delay
  expect_gte(rl$delay, rl$min_delay)

  # backoff values must be sensible
  expect_gt(rl$initial_backoff, 0)
  expect_gt(rl$backoff_multiplier, 1)
  expect_gt(rl$max_backoff, rl$initial_backoff)

  # jitter must be a fraction between 0 and 1
  expect_gt(rl$jitter_fraction, 0)
  expect_lt(rl$jitter_fraction, 1)

  # ban detection threshold must be positive
  expect_gt(rl$ban_detection_threshold, 0)
})

# 8. Cleanup -----

# Ensure rate limiter is reset after all tests in this file
reset_rate_limiter()
