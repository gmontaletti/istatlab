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
  expect_error(
    download_istat_data(c("534_50", "534_51")),
    "dataset_id must be a single character string"
  )

  expect_error(
    download_istat_data(123),
    "dataset_id must be a single character string"
  )
})

test_that("download_multiple_datasets validates inputs", {
  expect_error(
    download_multiple_datasets(character(0)),
    "dataset_ids must be a non-empty character vector"
  )

  expect_error(
    download_multiple_datasets(123),
    "dataset_ids must be a non-empty character vector"
  )
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
  result <- download_istat_data(
    "534_50",
    start_time = "2024",
    timeout = 60,
    verbose = FALSE,
    return_result = TRUE
  )

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

  result <- download_istat_data(
    "534_50",
    start_time = "2024",
    timeout = 60,
    verbose = FALSE,
    return_result = TRUE
  )

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

  result <- download_istat_data(
    "534_50",
    start_time = "2024",
    timeout = 60,
    verbose = FALSE,
    return_result = TRUE
  )

  if (result$success) {
    # MD5 should be computed when digest is available
    expect_true(!is.na(result$md5))
    expect_true(is.character(result$md5))
    expect_equal(nchar(result$md5), 32) # MD5 hash is 32 hex characters
  }
})

# 4. Tests for backward compatibility -----

test_that("download_istat_data maintains backward compatibility", {
  skip_on_cran()
  skip_if_offline()

  # Default behavior: return data.table (not istat_result)
  result <- download_istat_data(
    "534_50",
    start_time = "2024",
    timeout = 60,
    verbose = FALSE
  )

  if (!is.null(result)) {
    # Should be data.table, not istat_result
    expect_true(data.table::is.data.table(result))
    expect_false(inherits(result, "istat_result"))
    expect_true("id" %in% names(result))
  }
})

# 5. Tests for end_time parameter -----

test_that("end_time rejects invalid formats", {
  expect_error(
    download_istat_data("534_50", end_time = "not-a-date"),
    "end_time must be a character"
  )
  expect_error(
    download_istat_data("534_50", end_time = "20201"),
    "end_time must be a character"
  )
  expect_error(
    download_istat_data("534_50", end_time = 12345),
    "end_time must be a character string or a Date object"
  )
})

test_that("end_time accepts valid formats", {
  # These should not error on validation (will fail at API call, but that's fine)
  # We test by checking the URL construction instead
  url <- build_istat_url("data", dataset_id = "534_50", end_time = "2024")
  expect_true(grepl("endPeriod=2024", url))

  url <- build_istat_url("data", dataset_id = "534_50", end_time = "2024-06")
  expect_true(grepl("endPeriod=2024-06", url))

  url <- build_istat_url("data", dataset_id = "534_50", end_time = "2024-06-30")
  expect_true(grepl("endPeriod=2024-06-30", url))
})

test_that("build_istat_url includes both startPeriod and endPeriod", {
  url <- build_istat_url(
    "data",
    dataset_id = "534_50",
    start_time = "2020",
    end_time = "2024"
  )
  expect_true(grepl("startPeriod=2020", url))
  expect_true(grepl("endPeriod=2024", url))
})

test_that("end_time is not included when empty", {
  url <- build_istat_url("data", dataset_id = "534_50")
  expect_false(grepl("endPeriod", url))

  url <- build_istat_url("data", dataset_id = "534_50", end_time = "")
  expect_false(grepl("endPeriod", url))
})

# 6. Tests for integrate_downloaded_data -----

test_that("integrate_downloaded_data merges and deduplicates", {
  existing <- data.table::data.table(
    FREQ = "M",
    ObsDimension = c("2020-01", "2020-02", "2020-03"),
    ObsValue = c(100, 200, 300),
    id = "test"
  )
  new_data <- data.table::data.table(
    FREQ = "M",
    ObsDimension = c("2020-03", "2020-04"),
    ObsValue = c(350, 400),
    id = "test"
  )

  result <- integrate_downloaded_data(existing, new_data)
  expect_equal(nrow(result), 4) # 3 + 2 - 1 overlap
  # The overlapping row should have the new value (350)
  expect_equal(result[ObsDimension == "2020-03", ObsValue], 350)
})

test_that("integrate_downloaded_data validates inputs", {
  expect_error(
    integrate_downloaded_data("not_dt", data.table::data.table()),
    "existing_data must be a data.table"
  )
  expect_error(
    integrate_downloaded_data(data.table::data.table(), "not_dt"),
    "new_data must be a data.table"
  )
})

# 7. Tests for download with end_time (API) -----

test_that("download_istat_data works with end_time", {
  skip_on_cran()
  skip_if_offline()

  data <- download_istat_data(
    "534_50",
    start_time = "2023",
    end_time = "2023",
    timeout = 60,
    verbose = FALSE
  )
  if (!is.null(data)) {
    expect_true(data.table::is.data.table(data))
    expect_true(nrow(data) > 0)
    # Data should be bounded; fewer rows than an unbounded download
    all_data <- download_istat_data(
      "534_50",
      start_time = "2020",
      timeout = 60,
      verbose = FALSE
    )
    if (!is.null(all_data)) {
      expect_true(nrow(data) < nrow(all_data))
    }
  }
})
