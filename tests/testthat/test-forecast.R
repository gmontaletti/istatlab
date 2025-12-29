# test-forecast.R
# Tests for forecast_series function

# 1. Test helper functions -----
test_that("detect_frequency works correctly", {
  # Monthly data with FREQ column
  monthly_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2020-01-01"), by = "month", length.out = 24),
    valore = rnorm(24, 100, 10),
    FREQ = "M"
  )
  expect_equal(detect_frequency(monthly_data), 12)

  # Quarterly data with FREQ column
  quarterly_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2020-01-01"), by = "quarter", length.out = 16),
    valore = rnorm(16, 100, 10),
    FREQ = "Q"
  )
  expect_equal(detect_frequency(quarterly_data), 4)

  # Annual data with FREQ column
  annual_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2015-01-01"), by = "year", length.out = 10),
    valore = rnorm(10, 100, 10),
    FREQ = "A"
  )
  expect_equal(detect_frequency(annual_data), 1)
})

test_that("detect_frequency auto-detects from intervals", {
  # Monthly data without FREQ column
  monthly_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2020-01-01"), by = "month", length.out = 24),
    valore = rnorm(24, 100, 10)
  )
  expect_equal(detect_frequency(monthly_data, freq_col = "none"), 12)

  # Quarterly data without FREQ column
  quarterly_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2020-01-01"), by = "quarter", length.out = 16),
    valore = rnorm(16, 100, 10)
  )
  expect_equal(detect_frequency(quarterly_data, freq_col = "none"), 4)
})

test_that("dt_to_ts creates valid ts object", {
  monthly_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2020-01-01"), by = "month", length.out = 24),
    valore = 1:24
  )

  ts_obj <- dt_to_ts(monthly_data, frequency = 12)

  expect_s3_class(ts_obj, "ts")
  expect_equal(frequency(ts_obj), 12)
  expect_equal(length(ts_obj), 24)
  expect_equal(start(ts_obj), c(2020, 1))
})

# 2. Test main forecast function -----
test_that("forecast_series works with monthly data", {
  skip_on_cran()

  # Create test data with trend
  set.seed(42)
  n <- 60  # 5 years monthly
  monthly_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2019-01-01"), by = "month", length.out = n),
    valore = 100 + 0.5 * (1:n) + rnorm(n, 0, 5),
    FREQ = "M"
  )

  # Run forecast
  fc <- forecast_series(
    monthly_data,
    horizon = 12,
    models = c("auto.arima", "ets", "naive"),
    verbose = FALSE
  )

  # Check structure
  expect_s3_class(fc, "istat_forecast")
  expect_true("best_model" %in% names(fc))
  expect_true("ensemble" %in% names(fc))
  expect_true("all_models" %in% names(fc))
  expect_true("metadata" %in% names(fc))

  # Check best model
  expect_true(fc$best_model$name %in% c("auto.arima", "ets", "naive"))
  expect_equal(nrow(fc$best_model$forecast), 12)

  # Check ensemble
  expect_equal(nrow(fc$ensemble$forecast), 12)

  # Check metadata
  expect_equal(fc$metadata$horizon, 12)
  expect_equal(fc$metadata$frequency, 12)
})

test_that("forecast_series works with quarterly data", {
  skip_on_cran()

  # Create test data
  set.seed(42)
  n <- 40  # 10 years quarterly
  quarterly_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2014-01-01"), by = "quarter", length.out = n),
    valore = 100 + 0.3 * (1:n) + rnorm(n, 0, 3),
    FREQ = "Q"
  )

  # Run forecast with default horizon (8 quarters = 2 years)
  fc <- forecast_series(
    quarterly_data,
    models = c("auto.arima", "naive"),
    verbose = FALSE
  )

  expect_s3_class(fc, "istat_forecast")
  expect_equal(fc$metadata$frequency, 4)
  expect_equal(fc$metadata$horizon, 8)
})

test_that("forecast_series validates input correctly", {
  # Missing time column
  bad_data <- data.table::data.table(
    date = Sys.Date(),
    value = 100
  )

  expect_error(
    forecast_series(bad_data, verbose = FALSE),
    "Time column 'tempo' not found"
  )

  # Missing value column
  bad_data2 <- data.table::data.table(
    tempo = Sys.Date(),
    value = 100
  )

  expect_error(
    forecast_series(bad_data2, verbose = FALSE),
    "Value column 'valore' not found"
  )
})

test_that("forecast_series handles missing values", {
  set.seed(42)
  n <- 48
  data_with_na <- data.table::data.table(
    tempo = seq.Date(as.Date("2020-01-01"), by = "month", length.out = n),
    valore = 100 + rnorm(n, 0, 5),
    FREQ = "M"
  )
  # Add some NAs
  data_with_na$valore[c(10, 20, 30)] <- NA

  # Should warn but still work
  expect_warning(
    fc <- forecast_series(data_with_na, horizon = 6, models = "naive", verbose = FALSE),
    "missing values"
  )

  expect_s3_class(fc, "istat_forecast")
})

test_that("print.istat_forecast works", {
  skip_on_cran()

  set.seed(42)
  test_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2020-01-01"), by = "month", length.out = 36),
    valore = 100 + rnorm(36, 0, 5),
    FREQ = "M"
  )

  fc <- forecast_series(test_data, horizon = 6, models = "naive", verbose = FALSE)

  # Print should work without error
  expect_output(print(fc), "ISTAT Time Series Forecast")
  expect_output(print(fc), "Best Model:")
})

test_that("forecast_series saves to file when requested", {
  skip_on_cran()

  set.seed(42)
  test_data <- data.table::data.table(
    tempo = seq.Date(as.Date("2020-01-01"), by = "month", length.out = 36),
    valore = 100 + rnorm(36, 0, 5),
    FREQ = "M"
  )

  temp_file <- tempfile(fileext = ".rds")
  on.exit(unlink(temp_file))

  fc <- forecast_series(
    test_data,
    horizon = 6,
    models = "naive",
    save_path = temp_file,
    verbose = FALSE
  )

  expect_true(file.exists(temp_file))

  # Load and verify
  loaded_fc <- readRDS(temp_file)
  expect_s3_class(loaded_fc, "istat_forecast")
  expect_equal(loaded_fc$best_model$name, fc$best_model$name)
})

# 3. Test accuracy calculations -----
test_that("calculate_accuracy computes correct metrics", {
  actual <- c(100, 110, 120, 130, 140)
  predicted <- c(102, 108, 122, 128, 142)

  acc <- calculate_accuracy(actual, predicted)

  expect_true("RMSE" %in% names(acc))
  expect_true("MAE" %in% names(acc))
  expect_true("MAPE" %in% names(acc))

  # RMSE should be sqrt(mean(4, 4, 4, 4, 4)) = 2
  expect_equal(acc$RMSE, 2)
  # MAE should be mean(2, 2, 2, 2, 2) = 2
  expect_equal(acc$MAE, 2)
})
