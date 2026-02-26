# test-hvd-download.R - Tests for HVD download functions (hvd_download.R)

# 1. download_hvd_data input validation -----

test_that("download_hvd_data errors when dataset_id is missing", {
  expect_error(
    download_hvd_data(),
    "dataset_id"
  )
})

test_that("download_hvd_data errors when dataset_id is empty", {
  expect_error(
    download_hvd_data(""),
    "dataset_id must be a non-empty"
  )
})

test_that("download_hvd_data errors when dataset_id is not character", {
  expect_error(
    download_hvd_data(123),
    "dataset_id must be a non-empty single character string"
  )
})

test_that("download_hvd_data errors on invalid version", {
  expect_error(
    download_hvd_data("534_50", version = "v3"),
    "version must be 'v1' or 'v2'"
  )
  expect_error(
    download_hvd_data("534_50", version = "legacy"),
    "version must be 'v1' or 'v2'"
  )
})

test_that("download_hvd_data accepts valid version strings", {
  # These should pass validation but will fail at the HTTP layer.
  # We mock the internal dispatcher to verify routing.
  mock_called <- FALSE

  local_mocked_bindings(
    hvd_download_data = function(...) {
      mock_called <<- TRUE
      list(
        success = TRUE,
        data = data.table::data.table(
          ObsDimension = "2024-01",
          ObsValue = 100
        ),
        message = "OK"
      )
    }
  )

  result_v1 <- download_hvd_data("534_50", version = "v1", verbose = FALSE)
  expect_true(mock_called)
  expect_true(data.table::is.data.table(result_v1))

  mock_called <- FALSE
  result_v2 <- download_hvd_data("534_50", version = "v2", verbose = FALSE)
  expect_true(mock_called)
  expect_true(data.table::is.data.table(result_v2))
})

test_that("download_hvd_data default method is GET", {
  # Capture the method argument passed to the dispatcher
  captured_method <- NULL

  local_mocked_bindings(
    hvd_download_data = function(..., method = "GET") {
      captured_method <<- method
      list(
        success = TRUE,
        data = data.table::data.table(
          ObsDimension = "2024-01",
          ObsValue = 100
        ),
        message = "OK"
      )
    }
  )

  download_hvd_data("534_50", verbose = FALSE)
  expect_equal(captured_method, "GET")
})

test_that("download_hvd_data errors on invalid method", {
  expect_error(
    download_hvd_data("534_50", method = "DELETE"),
    "method must be 'GET' or 'POST'"
  )
})

# 2. hvd_download_data routing -----

test_that("hvd_download_data routes to v1 handler for hvd_v1", {
  handler_called <- NULL

  local_mocked_bindings(
    hvd_v1_download = function(dataset_id, ...) {
      handler_called <<- "v1"
      list(
        success = TRUE,
        data = data.table::data.table(
          ObsDimension = "2024-01",
          ObsValue = 100
        ),
        message = "OK"
      )
    },
    hvd_v2_download = function(dataset_id, ...) {
      handler_called <<- "v2"
      list(
        success = TRUE,
        data = data.table::data.table(
          ObsDimension = "2024-01",
          ObsValue = 100
        ),
        message = "OK"
      )
    }
  )

  hvd_download_data(
    dataset_id = "534_50",
    api_version = "hvd_v1",
    verbose = FALSE
  )
  expect_equal(handler_called, "v1")
})

test_that("hvd_download_data routes to v2 handler for hvd_v2", {
  handler_called <- NULL

  local_mocked_bindings(
    hvd_v1_download = function(dataset_id, ...) {
      handler_called <<- "v1"
      list(
        success = TRUE,
        data = data.table::data.table(
          ObsDimension = "2024-01",
          ObsValue = 100
        ),
        message = "OK"
      )
    },
    hvd_v2_download = function(dataset_id, ...) {
      handler_called <<- "v2"
      list(
        success = TRUE,
        data = data.table::data.table(
          ObsDimension = "2024-01",
          ObsValue = 100
        ),
        message = "OK"
      )
    }
  )

  hvd_download_data(
    dataset_id = "534_50",
    api_version = "hvd_v2",
    verbose = FALSE
  )
  expect_equal(handler_called, "v2")
})

test_that("hvd_download_data validates dataset_id", {
  expect_error(
    hvd_download_data(dataset_id = "", api_version = "hvd_v1"),
    "dataset_id must be a non-empty"
  )
  expect_error(
    hvd_download_data(dataset_id = 123, api_version = "hvd_v1"),
    "dataset_id must be a non-empty single character string"
  )
})

test_that("hvd_download_data validates api_version", {
  expect_error(
    hvd_download_data(dataset_id = "534_50", api_version = "legacy"),
    "api_version must be 'hvd_v1' or 'hvd_v2'"
  )
})

test_that("hvd_download_data validates method", {
  expect_error(
    hvd_download_data(
      dataset_id = "534_50",
      api_version = "hvd_v1",
      method = "PUT"
    ),
    "method must be 'GET' or 'POST'"
  )
})

# 3. normalize_csv_columns_v2 tests -----

test_that("normalize_csv_columns_v2 does nothing when columns follow legacy naming", {
  dt <- data.table::data.table(
    FREQ = "M",
    ObsDimension = "2024-01",
    ObsValue = 100
  )
  original_names <- names(dt)
  result <- normalize_csv_columns_v2(dt)
  expect_equal(names(result), original_names)
})

test_that("normalize_csv_columns_v2 renames TIME_PERIOD to ObsDimension", {
  dt <- data.table::data.table(
    FREQ = "M",
    TIME_PERIOD = "2024-01",
    OBS_VALUE = 100
  )
  result <- normalize_csv_columns_v2(dt)
  expect_true("ObsDimension" %in% names(result))
  expect_false("TIME_PERIOD" %in% names(result))
})

test_that("normalize_csv_columns_v2 renames OBS_VALUE to ObsValue", {
  dt <- data.table::data.table(
    FREQ = "M",
    TIME_PERIOD = "2024-01",
    OBS_VALUE = 100
  )
  result <- normalize_csv_columns_v2(dt)
  expect_true("ObsValue" %in% names(result))
  expect_false("OBS_VALUE" %in% names(result))
})

test_that("normalize_csv_columns_v2 removes STRUCTURE columns when present", {
  dt <- data.table::data.table(
    STRUCTURE = "DF_150_908",
    STRUCTURE_ID = "DSD_150_908",
    STRUCTURE_NAME = "Employment",
    ACTION = "I",
    FREQ = "M",
    TIME_PERIOD = "2024-01",
    OBS_VALUE = 100
  )
  result <- normalize_csv_columns_v2(dt)
  expect_false("STRUCTURE" %in% names(result))
  expect_false("STRUCTURE_ID" %in% names(result))
  expect_false("STRUCTURE_NAME" %in% names(result))
  expect_false("ACTION" %in% names(result))
})

test_that("normalize_csv_columns_v2 does not error when v2 cols are absent", {
  dt <- data.table::data.table(
    FREQ = "M",
    TIME_PERIOD = "2024-01",
    OBS_VALUE = 100
  )
  expect_no_error(normalize_csv_columns_v2(dt))
  result <- normalize_csv_columns_v2(dt)
  # FREQ should be preserved
  expect_true("FREQ" %in% names(result))
})

test_that("normalize_csv_columns_v2 preserves data values after renaming", {
  dt <- data.table::data.table(
    TIME_PERIOD = c("2024-01", "2024-02"),
    OBS_VALUE = c(100.5, 200.3),
    FREQ = c("M", "M")
  )
  result <- normalize_csv_columns_v2(dt)
  expect_equal(result$ObsDimension, c("2024-01", "2024-02"))
  expect_equal(result$ObsValue, c(100.5, 200.3))
})

test_that("normalize_csv_columns_v2 removes v2 meta cols even when already normalized", {
  dt <- data.table::data.table(
    STRUCTURE = "DF_150_908",
    ACTION = "I",
    ObsDimension = "2024-01",
    ObsValue = 100
  )
  result <- normalize_csv_columns_v2(dt)
  expect_false("STRUCTURE" %in% names(result))
  expect_false("ACTION" %in% names(result))
  expect_true("ObsDimension" %in% names(result))
  expect_true("ObsValue" %in% names(result))
})

test_that("normalize_csv_columns_v2 converts data.frame to data.table", {
  df <- data.frame(
    TIME_PERIOD = "2024-01",
    OBS_VALUE = 100,
    stringsAsFactors = FALSE
  )
  result <- normalize_csv_columns_v2(df)
  expect_true(data.table::is.data.table(result))
  expect_true("ObsDimension" %in% names(result))
})

test_that("normalize_csv_columns_v2 also removes DATAFLOW column", {
  dt <- data.table::data.table(
    DATAFLOW = "IT1:DF_150_908(1.0)",
    FREQ = "M",
    TIME_PERIOD = "2024-01",
    OBS_VALUE = 100
  )
  result <- normalize_csv_columns_v2(dt)
  expect_false("DATAFLOW" %in% names(result))
})

# 4. get_hvd_info tests -----

test_that("get_hvd_info returns a list with v1 and v2 elements", {
  info <- get_hvd_info()
  expect_type(info, "list")
  expect_true("v1" %in% names(info))
  expect_true("v2" %in% names(info))
})

test_that("get_hvd_info v1 element has expected fields", {
  info <- get_hvd_info()
  v1 <- info$v1
  expected_fields <- c(
    "base_url",
    "status",
    "sdmx_version",
    "methods",
    "description"
  )
  for (field in expected_fields) {
    expect_true(
      field %in% names(v1),
      info = paste("Missing field:", field)
    )
  }
})

test_that("get_hvd_info v2 element has expected fields", {
  info <- get_hvd_info()
  v2 <- info$v2
  expected_fields <- c(
    "base_url",
    "status",
    "sdmx_version",
    "methods",
    "description"
  )
  for (field in expected_fields) {
    expect_true(
      field %in% names(v2),
      info = paste("Missing field:", field)
    )
  }
})

test_that("get_hvd_info v1 status is stable and v2 is experimental", {
  info <- get_hvd_info()
  expect_equal(info$v1$status, "stable")
  expect_equal(info$v2$status, "experimental")
})

test_that("get_hvd_info sdmx versions are correct", {
  info <- get_hvd_info()
  expect_equal(info$v1$sdmx_version, "2.1")
  expect_equal(info$v2$sdmx_version, "3.0")
})

test_that("get_hvd_info methods include GET and POST", {
  info <- get_hvd_info()
  expect_true("GET" %in% info$v1$methods)
  expect_true("POST" %in% info$v1$methods)
  expect_true("GET" %in% info$v2$methods)
  expect_true("POST" %in% info$v2$methods)
})

test_that("get_hvd_info base_url values are non-empty strings", {
  info <- get_hvd_info()
  expect_true(is.character(info$v1$base_url))
  expect_true(nchar(info$v1$base_url) > 0)
  expect_true(is.character(info$v2$base_url))
  expect_true(nchar(info$v2$base_url) > 0)
})

# 5. Live connectivity (skip_on_cran) -----

test_that("HVD endpoints are reachable", {
  skip_on_cran()
  skip_if_offline()

  result <- suppressMessages(
    test_hvd_connectivity(timeout = 15, verbose = FALSE)
  )
  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
  expect_true("accessible" %in% names(result))
  expect_true("version" %in% names(result))
  expect_true("endpoint" %in% names(result))
  expect_type(result$accessible, "logical")
})
