test_that("test_endpoint_connectivity works correctly", {
  skip_on_cran()
  skip_if_offline()

  # Test endpoint connectivity function (use default 30s timeout for ISTAT API)
  result <- suppressWarnings(
    test_endpoint_connectivity("dataflow", timeout = 15, verbose = FALSE)
  )
  expect_s3_class(result, "data.frame")
  expect_true("accessible" %in% names(result))
  expect_type(result$accessible, "logical")
})

test_that("download_istat_data validates inputs correctly", {
  # Test input validation
  expect_error(download_istat_data(c("534_50", "534_51")), 
               "dataset_id must be a single character string")
  
  expect_error(download_istat_data(123), 
               "dataset_id must be a single character string")
})

test_that("download_multiple_datasets validates inputs", {
  expect_error(download_multiple_datasets(character(0)), 
               "dataset_ids must be a non-empty character vector")
  
  expect_error(download_multiple_datasets(123), 
               "dataset_ids must be a non-empty character vector")
})

# Mock test for successful data download (to avoid actual API calls in tests)
test_that("download_istat_data returns expected structure", {
  skip("Requires actual API connection - create mock test")

  # This test would be implemented with mocked API responses
  # to avoid dependencies on external services during testing
})

# 1. Tests for return_result parameter -----

test_that("download_istat_data return_result parameter works", {
  skip_on_cran()
  skip_if_offline()

  # Test with return_result = TRUE
  result <- download_istat_data("534_50", start_time = "2024",
                                timeout = 60, verbose = FALSE,
                                return_result = TRUE)

  # Should return istat_result object
  expect_s3_class(result, "istat_result")
  expect_true(is.logical(result$success))
  expect_true(is.integer(result$exit_code))
  expect_true(inherits(result$timestamp, "POSIXct"))

  if (result$success) {
    expect_true(data.table::is.data.table(result$data))
    expect_true("id" %in% names(result$data))
  }
})

# 2. Tests for download_istat_data with return_result -----

test_that("download_istat_data with return_result returns istat_result", {
  skip_on_cran()
  skip_if_offline()

  result <- download_istat_data("534_50", start_time = "2024",
                                timeout = 60, verbose = FALSE, return_result = TRUE)

  # Must return istat_result
  expect_s3_class(result, "istat_result")
  expect_true(is.logical(result$success))
  expect_true(is.integer(result$exit_code))
  expect_true(is.logical(result$is_timeout))

  # Check exit codes are valid
  expect_true(result$exit_code %in% c(0L, 1L, 2L))

  # If success, check data structure
  if (result$success) {
    expect_true(data.table::is.data.table(result$data))
    expect_equal(result$exit_code, 0L)
    expect_false(result$is_timeout)
  }
})

# 3. Tests for MD5 checksum -----

test_that("download_istat_data computes MD5 when digest is available", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("digest")

  result <- download_istat_data("534_50", start_time = "2024",
                                timeout = 60, verbose = FALSE, return_result = TRUE)

  if (result$success) {
    # MD5 should be computed when digest is available
    expect_true(!is.na(result$md5))
    expect_true(is.character(result$md5))
    expect_equal(nchar(result$md5), 32)  # MD5 hash is 32 hex characters
  }
})

# 4. Tests for backward compatibility -----

test_that("download_istat_data maintains backward compatibility", {
  skip_on_cran()
  skip_if_offline()

  # Default behavior: return data.table (not istat_result)
  result <- download_istat_data("534_50", start_time = "2024",
                                timeout = 60, verbose = FALSE)

  if (!is.null(result)) {
    # Should be data.table, not istat_result
    expect_true(data.table::is.data.table(result))
    expect_false(inherits(result, "istat_result"))
    expect_true("id" %in% names(result))
  }
})