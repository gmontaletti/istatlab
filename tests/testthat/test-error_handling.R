# Tests for error_handling.R module

# 1. Timeout detection tests -----

test_that("is_timeout_error correctly identifies timeout patterns", {
  # Positive cases
  expect_true(is_timeout_error("connection timed out"))
  expect_true(is_timeout_error("Request Timeout"))
  expect_true(is_timeout_error("HTTP 504 Gateway Timeout"))
  expect_true(is_timeout_error("error 408"))
  expect_true(is_timeout_error("operation timed out"))
  expect_true(is_timeout_error("TIMEOUT occurred"))

  # Negative cases
  expect_false(is_timeout_error("connection refused"))
  expect_false(is_timeout_error("unknown error"))
  expect_false(is_timeout_error("file not found"))
  expect_false(is_timeout_error("permission denied"))

  # Edge cases
  expect_false(is_timeout_error(NULL))
  expect_false(is_timeout_error(""))
  expect_false(is_timeout_error(123))
})

# 2. Connectivity error detection tests -----

test_that("is_connectivity_error correctly identifies connectivity patterns", {
  # Positive cases
  expect_true(is_connectivity_error("cannot resolve host"))
  expect_true(is_connectivity_error("connection refused"))
  expect_true(is_connectivity_error("network unreachable"))
  expect_true(is_connectivity_error("DNS lookup failed"))
  expect_true(is_connectivity_error("internet not available"))

  # Negative cases
  expect_false(is_connectivity_error("file not found"))
  expect_false(is_connectivity_error("timeout"))
  expect_false(is_connectivity_error("invalid syntax"))

  # Edge cases
  expect_false(is_connectivity_error(NULL))
  expect_false(is_connectivity_error(""))
})

# 3. HTTP error detection tests -----

test_that("is_http_error correctly identifies HTTP status errors", {
  # Positive cases
  expect_true(is_http_error("HTTP error 404"))
  expect_true(is_http_error("status code 500"))
  expect_true(is_http_error("received 403 forbidden"))
  expect_true(is_http_error("502 bad gateway"))

  # Negative cases
  expect_false(is_http_error("timeout"))
  expect_false(is_http_error("connection refused"))
  expect_false(is_http_error("success"))

  # Edge cases
  expect_false(is_http_error(NULL))
  expect_false(is_http_error(""))
})

# 4. Error classification tests -----

test_that("classify_api_error returns correct exit codes", {
  # Timeout errors -> exit code 2
  timeout_result <- classify_api_error("connection timed out")
  expect_equal(timeout_result$exit_code, 2L)
  expect_equal(timeout_result$type, "timeout")

  # Connectivity errors -> exit code 1
  connectivity_result <- classify_api_error("cannot resolve host")
  expect_equal(connectivity_result$exit_code, 1L)
  expect_equal(connectivity_result$type, "connectivity")

  # HTTP errors -> exit code 1
  http_result <- classify_api_error("HTTP error 500")
  expect_equal(http_result$exit_code, 1L)
  expect_equal(http_result$type, "http")

  # Unknown errors -> exit code 1
  unknown_result <- classify_api_error("something went wrong")
  expect_equal(unknown_result$exit_code, 1L)
  expect_equal(unknown_result$type, "unknown")

  # NULL handling
  null_result <- classify_api_error(NULL)
  expect_equal(null_result$exit_code, 1L)
})

# 5. Result structure tests -----

test_that("create_download_result creates valid structure", {
  # Success case
  success_result <- create_download_result(
    success = TRUE,
    data = data.table::data.table(x = 1:3),
    exit_code = 0L,
    md5 = "abc123"
  )

  expect_s3_class(success_result, "istat_result")
  expect_true(success_result$success)
  expect_equal(success_result$exit_code, 0L)
  expect_equal(success_result$md5, "abc123")
  expect_false(success_result$is_timeout)
  expect_s3_class(success_result$timestamp, "POSIXct")

  # Failure case
  failure_result <- create_download_result(
    success = FALSE,
    exit_code = 2L,
    message = "Server timeout",
    is_timeout = TRUE
  )

  expect_false(failure_result$success)
  expect_equal(failure_result$exit_code, 2L)
  expect_true(failure_result$is_timeout)
  expect_null(failure_result$data)
})

test_that("print.istat_result produces output", {
  result <- create_download_result(
    success = TRUE,
    data = data.table::data.table(x = 1:5),
    exit_code = 0L,
    message = "Test message",
    md5 = "abc123"
  )

  expect_output(print(result), "SUCCESS")
  expect_output(print(result), "Exit code: 0")
})

# 6. Logging tests -----

test_that("istat_log produces formatted output when verbose", {
  # Test INFO level
  expect_message(istat_log("Test message", "INFO", TRUE), "\\[INFO\\]")
  expect_message(istat_log("Test message", "INFO", TRUE), "Test message")

  # Test WARNING level
  expect_message(istat_log("Warning message", "WARNING", TRUE), "\\[WARNING\\]")

  # Test ERROR level
  expect_message(istat_log("Error message", "ERROR", TRUE), "\\[ERROR\\]")

  # Test silent when verbose = FALSE
  expect_no_message(istat_log("Silent", "INFO", FALSE))
})
