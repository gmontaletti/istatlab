# test-prepare-plotting.R - Unit tests for prepare_for_plotting function
#
# Tests cover: input validation, statistics computation, file output,
# report structure, label column grouping, and edge cases.

# 1. Helper functions for creating mock data -----

#' Create mock labeled ISTAT data for testing
#' This bypasses the need for API calls and metadata
create_mock_labeled_data <- function(n_rows = 100, n_series = 2,
                                      include_na = FALSE,
                                      frequency = "M") {

  # Generate dates based on frequency
  if (frequency == "M") {
    dates <- seq(as.Date("2020-01-01"),
                 by = "month", length.out = n_rows / n_series)
  } else if (frequency == "Q") {
    dates <- seq(as.Date("2020-01-01"),
                 by = "quarter", length.out = n_rows / n_series)
  } else {
    dates <- seq(as.Date("2020-01-01"),
                 by = "year", length.out = n_rows / n_series)
  }

  # Create data for each series
  series_list <- lapply(seq_len(n_series), function(i) {
    set.seed(42 + i)
    values <- 100 + cumsum(rnorm(length(dates), mean = 0.5, sd = 2))
    if (include_na) {
      values[sample(length(values), 2)] <- NA
    }

    data.table::data.table(
      id = "test_dataset",
      FREQ = frequency,
      REF_AREA = paste0("IT", i),
      REF_AREA_label = paste0("Italy Region ", i),
      SEX = c("M", "F")[i],
      SEX_label = c("Males", "Females")[i],
      tempo = dates,
      valore = values,
      ObsDimension = format(dates, "%Y-%m"),
      ObsValue = as.character(values)
    )
  })

  data.table::rbindlist(series_list)
}

#' Create minimal mock data with known values for statistics testing
create_known_values_data <- function() {
  # Series with exactly known statistics
  data.table::data.table(
    id = "known_test",
    FREQ = "M",
    REF_AREA = "IT1",
    REF_AREA_label = "Test Region",
    tempo = as.Date(c("2020-01-01", "2020-02-01", "2020-03-01",
                      "2020-04-01", "2020-05-01")),
    valore = c(100, 110, 120, 130, 140),  # Linear trend for known calculations
    ObsDimension = c("2020-01", "2020-02", "2020-03", "2020-04", "2020-05"),
    ObsValue = as.character(c(100, 110, 120, 130, 140))
  )
}

# 2. Tests for compute_series_stats helper function -----

test_that("compute_series_stats computes correct statistics for known values", {
  known_data <- create_known_values_data()
  label_cols <- "REF_AREA_label"

  stats <- compute_series_stats(known_data, label_cols)

  # Check basic structure

  expect_s3_class(stats, "data.table")
  expect_true(nrow(stats) >= 1)


  # Check descriptive statistics with known values
  expect_equal(stats$n[1], 5L)
  expect_equal(stats$n_valid[1], 5L)
  expect_equal(stats$n_missing[1], 0L)
  expect_equal(stats$min[1], 100)
  expect_equal(stats$max[1], 140)
  expect_equal(stats$mean[1], 120)  # (100+110+120+130+140)/5 = 120
  expect_equal(stats$median[1], 120)

  # Check date range
  expect_equal(stats$date_start[1], as.Date("2020-01-01"))
  expect_equal(stats$date_end[1], as.Date("2020-05-01"))

  # Check trend direction (positive slope for increasing values)
  expect_equal(stats$trend_direction[1], "positive")
})

test_that("compute_series_stats handles multiple series", {
  mock_data <- create_mock_labeled_data(n_rows = 100, n_series = 2)
  label_cols <- c("REF_AREA_label", "SEX_label")

  stats <- compute_series_stats(mock_data, label_cols)

  # Should have 2 series (2 regions)
  expect_equal(nrow(stats), 2)
  expect_true("REF_AREA_label" %in% names(stats))
  expect_true("SEX_label" %in% names(stats))
})

test_that("compute_series_stats handles NA values correctly", {
  data_with_na <- create_mock_labeled_data(n_rows = 20, n_series = 1,
                                            include_na = TRUE)
  label_cols <- c("REF_AREA_label", "SEX_label")

  stats <- compute_series_stats(data_with_na, label_cols)

  expect_true(stats$n_missing[1] >= 0)
  expect_true(stats$pct_missing[1] >= 0)
  expect_true(stats$n_valid[1] <= stats$n[1])
})

test_that("compute_series_stats handles single row data", {
  single_row <- data.table::data.table(
    REF_AREA_label = "Test",
    tempo = as.Date("2020-01-01"),
    valore = 100
  )
  label_cols <- "REF_AREA_label"

  stats <- compute_series_stats(single_row, label_cols)

  expect_equal(stats$n[1], 1L)
  expect_equal(stats$min[1], 100)
  expect_equal(stats$max[1], 100)
  expect_equal(stats$mean[1], 100)
  expect_true(is.na(stats$sd[1]))  # SD undefined for n=1
  expect_equal(stats$trend_direction[1], "insufficient_data")
})

test_that("compute_series_stats handles all NA values", {
  all_na_data <- data.table::data.table(
    REF_AREA_label = "Test",
    tempo = as.Date(c("2020-01-01", "2020-02-01", "2020-03-01")),
    valore = c(NA_real_, NA_real_, NA_real_)
  )
  label_cols <- "REF_AREA_label"

  stats <- compute_series_stats(all_na_data, label_cols)

  expect_equal(stats$n_valid[1], 0L)
  expect_equal(stats$n_missing[1], 3L)
  expect_true(is.na(stats$min[1]))
  expect_true(is.na(stats$max[1]))
  expect_true(is.na(stats$mean[1]))
  expect_equal(stats$trend_direction[1], "no_data")
})

test_that("compute_series_stats with no dimension columns returns single series", {
  simple_data <- data.table::data.table(
    tempo = as.Date(c("2020-01-01", "2020-02-01", "2020-03-01")),
    valore = c(100, 110, 120)
  )

  stats <- compute_series_stats(simple_data, character(0))

  expect_equal(nrow(stats), 1)
  expect_true("series_id" %in% names(stats))
})

# 3. Tests for statistics output fields -----

test_that("compute_series_stats returns all expected statistic fields", {
  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1)
  label_cols <- c("REF_AREA_label", "SEX_label")

  stats <- compute_series_stats(mock_data, label_cols)

  expected_fields <- c(
    "n", "n_valid", "n_missing", "pct_missing",
    "min", "max", "mean", "sd", "median", "q1", "q3",
    "date_start", "date_end", "date_span_days",
    "trend_slope", "trend_direction",
    "avg_growth_rate", "cagr"
  )

  for (field in expected_fields) {
    expect_true(field %in% names(stats),
                info = paste("Missing field:", field))
  }
})

test_that("compute_series_stats calculates growth rates correctly", {
  # Create data with known growth pattern: 100 -> 110 (10% growth each period)
  growth_data <- data.table::data.table(
    REF_AREA_label = "Test",
    tempo = as.Date(c("2020-01-01", "2021-01-01", "2022-01-01")),
    valore = c(100, 110, 121)  # ~10% annual growth
  )
  label_cols <- "REF_AREA_label"

  stats <- compute_series_stats(growth_data, label_cols)

  # Average growth rate should be around 10%
  expect_true(stats$avg_growth_rate[1] > 9 && stats$avg_growth_rate[1] < 11)
  # CAGR should also be around 10%
  expect_true(!is.na(stats$cagr[1]))
})

# 4. Tests for prepare_for_plotting input validation -----

test_that("prepare_for_plotting rejects invalid input types", {
  expect_error(
    prepare_for_plotting(123, verbose = FALSE),
    "data must be a dataset_id"
  )

  expect_error(
    prepare_for_plotting(list(a = 1, b = 2), verbose = FALSE),
    "data must be a dataset_id"
  )

  expect_error(
    prepare_for_plotting(NULL, verbose = FALSE),
    "data must be a dataset_id"
  )
})

test_that("prepare_for_plotting rejects vector of dataset IDs", {
  expect_error(
    prepare_for_plotting(c("534_50", "534_51"), verbose = FALSE),
    "data must be a dataset_id"
  )
})

test_that("prepare_for_plotting validates required columns in data.table input", {
  invalid_dt <- data.table::data.table(
    x = 1:5,
    y = letters[1:5]
  )

  expect_error(
    prepare_for_plotting(invalid_dt, verbose = FALSE),
    "Data validation failed"
  )
})

# 5. Tests for file output -----

test_that("prepare_for_plotting creates output files when save options are TRUE", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1)
  temp_dir <- tempfile("istatlab_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Mock apply_labels to return our data unchanged
  # (since we already have labeled data)
  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    output_dir = temp_dir,
    prefix = "test",
    save_data = TRUE,
    save_report = TRUE,
    verbose = FALSE
  )

  # Check files were created
  expect_true(file.exists(file.path(temp_dir, "test_data.rds")))
  expect_true(file.exists(file.path(temp_dir, "test_report.rds")))

  # Check file paths are returned
  expect_true(!is.null(result$files$data_rds))
  expect_true(!is.null(result$files$report_rds))
})

test_that("prepare_for_plotting does not create files when save options are FALSE", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1)
  temp_dir <- tempfile("istatlab_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    output_dir = temp_dir,
    prefix = "test",
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  # Check files were NOT created
  expect_false(file.exists(file.path(temp_dir, "test_data.rds")))
  expect_false(file.exists(file.path(temp_dir, "test_report.rds")))

  # File paths should be NULL
  expect_null(result$files$data_rds)
  expect_null(result$files$report_rds)
})

test_that("prepare_for_plotting uses dataset_id as prefix when prefix is NULL", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1)
  mock_data$id <- "534_50"  # Set specific dataset_id
  temp_dir <- tempfile("istatlab_test_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    output_dir = temp_dir,
    prefix = NULL,  # Should use dataset_id
    save_data = TRUE,
    save_report = FALSE,
    verbose = FALSE
  )

  expect_true(file.exists(file.path(temp_dir, "534_50_data.rds")))
})

# 6. Tests for report structure -----

test_that("prepare_for_plotting returns correct object class", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  expect_s3_class(result, "istat_plot_ready")
  expect_s3_class(result, "list")
})

test_that("prepare_for_plotting report contains all expected sections", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 40, n_series = 2)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  report <- result$report

  # Check top-level report sections
  expect_true("metadata" %in% names(report))
  expect_true("data_summary" %in% names(report))
  expect_true("date_range" %in% names(report))
  expect_true("series_stats" %in% names(report))
  expect_true("aggregate_stats" %in% names(report))
})

test_that("prepare_for_plotting report metadata has expected fields", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  metadata <- result$report$metadata

  expect_true("dataset_id" %in% names(metadata))
  expect_true("dataset_name_it" %in% names(metadata))
  expect_true("dataset_name_en" %in% names(metadata))
  expect_true("created_at" %in% names(metadata))
  expect_true("istatlab_version" %in% names(metadata))
  expect_true("r_version" %in% names(metadata))

  expect_s3_class(metadata$created_at, "POSIXt")
})

test_that("prepare_for_plotting data_summary has expected fields", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 40, n_series = 2)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  data_summary <- result$report$data_summary

  expect_true("n_rows" %in% names(data_summary))
  expect_true("n_columns" %in% names(data_summary))
  expect_true("n_series" %in% names(data_summary))
  expect_true("label_columns" %in% names(data_summary))

  expect_equal(data_summary$n_rows, 40)
  expect_equal(data_summary$n_series, 2)
})

# 7. Tests for label column identification -----

test_that("prepare_for_plotting uses label columns for grouping, not code columns", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 40, n_series = 2)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  label_cols <- result$report$data_summary$label_columns

  # Label columns should end with _label
  expect_true(all(grepl("_label$", label_cols)))

  # Should not include code columns directly
  expect_false("REF_AREA" %in% label_cols)
  expect_false("SEX" %in% label_cols)

  # Should include label versions
  expect_true("REF_AREA_label" %in% label_cols)
  expect_true("SEX_label" %in% label_cols)
})

test_that("prepare_for_plotting series_stats uses label columns as keys", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 40, n_series = 2)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  series_stats <- result$report$series_stats

  # Series stats should be grouped by label columns
  expect_true("REF_AREA_label" %in% names(series_stats))
  expect_true("SEX_label" %in% names(series_stats))
})

# 8. Tests for summary field -----

test_that("prepare_for_plotting summary has correct structure", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 40, n_series = 2)
  mock_data$id <- "534_50"

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  summary <- result$summary

  expect_true("dataset_id" %in% names(summary))
  expect_true("n_rows" %in% names(summary))
  expect_true("n_series" %in% names(summary))
  expect_true("date_range" %in% names(summary))
  expect_true("dimensions" %in% names(summary))

  expect_equal(summary$dataset_id, "534_50")
  expect_equal(summary$n_rows, 40)
  expect_equal(summary$n_series, 2)
})

# 9. Tests for data.frame input conversion -----

test_that("prepare_for_plotting accepts data.frame and converts to data.table", {
  skip_on_cran()

  mock_data <- as.data.frame(create_mock_labeled_data(n_rows = 20, n_series = 1))

  local_mocked_bindings(
    apply_labels = function(data, ...) {
      if (!data.table::is.data.table(data)) {
        data.table::setDT(data)
      }
      return(data)
    },
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  expect_s3_class(result, "istat_plot_ready")
  expect_true(data.table::is.data.table(result$data))
})

# 10. Tests for date range calculation -----

test_that("prepare_for_plotting computes correct date range", {
  skip_on_cran()

  mock_data <- data.table::data.table(
    id = "test",
    FREQ = "M",
    REF_AREA_label = "Test",
    tempo = as.Date(c("2020-01-01", "2020-06-01", "2021-01-01")),
    valore = c(100, 110, 120),
    ObsDimension = c("2020-01", "2020-06", "2021-01"),
    ObsValue = c("100", "110", "120")
  )

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  date_range <- result$report$date_range

  expect_equal(date_range$start, as.Date("2020-01-01"))
  expect_equal(date_range$end, as.Date("2021-01-01"))
  expect_equal(date_range$span_days, as.numeric(as.Date("2021-01-01") -
                                                   as.Date("2020-01-01")))
})

# 11. Tests for aggregate statistics -----

test_that("prepare_for_plotting computes aggregate statistics correctly", {
  skip_on_cran()

  mock_data <- data.table::data.table(
    id = "test",
    FREQ = "M",
    REF_AREA_label = "Test",
    tempo = as.Date(c("2020-01-01", "2020-02-01", "2020-03-01", "2020-04-01")),
    valore = c(100, NA, 120, 140),  # One NA value
    ObsDimension = c("2020-01", "2020-02", "2020-03", "2020-04"),
    ObsValue = c("100", NA, "120", "140")
  )

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  agg_stats <- result$report$aggregate_stats

  expect_equal(agg_stats$total_observations, 4)
  expect_equal(agg_stats$total_missing, 1)
  expect_equal(agg_stats$pct_missing, 25)  # 1/4 = 25%
  expect_equal(agg_stats$value_range, c(100, 140))
  expect_equal(agg_stats$overall_mean, 120)  # mean of 100, 120, 140
})

# 12. Tests for print method -----

test_that("print.istat_plot_ready outputs expected format", {
  skip_on_cran()

  mock_result <- structure(
    list(
      data = data.table::data.table(x = 1:10),
      report = list(
        metadata = list(
          dataset_name_it = "Test Dataset IT",
          dataset_name_en = "Test Dataset EN"
        )
      ),
      files = list(data_rds = "/tmp/data.rds", report_rds = "/tmp/report.rds"),
      summary = list(
        dataset_id = "test_123",
        n_rows = 100,
        n_series = 5,
        date_range = "2020-01-01 to 2021-12-01",
        dimensions = "REF_AREA_label, SEX_label"
      )
    ),
    class = c("istat_plot_ready", "list")
  )

  output <- capture.output(print(mock_result))

  expect_true(any(grepl("ISTAT Plot-Ready Data", output)))
  expect_true(any(grepl("test_123", output)))
  expect_true(any(grepl("100", output)))
  expect_true(any(grepl("5", output)))
})

# 13. Edge case tests -----

test_that("prepare_for_plotting handles empty data gracefully", {
  skip_on_cran()

  empty_data <- data.table::data.table(
    id = character(0),
    ObsDimension = character(0),
    ObsValue = character(0)
  )

  # Should fail validation
  expect_error(
    prepare_for_plotting(empty_data, verbose = FALSE),
    "Data validation failed"
  )
})

test_that("prepare_for_plotting handles data with unknown dataset_id", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1)
  # Use "unknown" instead of NA to avoid comparison issues
  mock_data$id <- "unknown"

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  # Should handle unknown dataset_id
  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  expect_s3_class(result, "istat_plot_ready")
  expect_equal(result$summary$dataset_id, "unknown")
})

# 14. Tests for frequency handling -----

test_that("prepare_for_plotting identifies frequency from FREQ column", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1, frequency = "Q")

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  result <- prepare_for_plotting(
    mock_data,
    save_data = FALSE,
    save_report = FALSE,
    verbose = FALSE
  )

  expect_equal(result$report$data_summary$frequency, "Q")
})

# 15. Tests for output directory creation -----

test_that("prepare_for_plotting creates output directory if it does not exist", {
  skip_on_cran()

  mock_data <- create_mock_labeled_data(n_rows = 20, n_series = 1)
  nested_dir <- file.path(tempdir(), "istatlab_test", "nested", "output")
  on.exit(unlink(dirname(dirname(nested_dir)), recursive = TRUE), add = TRUE)

  local_mocked_bindings(
    apply_labels = function(data, ...) data,
    ensure_codelists = function(...) invisible(NULL),
    istat_log = function(...) invisible(NULL),
    validate_istat_data = function(...) TRUE,
    .package = "istatlab"
  )

  expect_false(dir.exists(nested_dir))

  result <- prepare_for_plotting(
    mock_data,
    output_dir = nested_dir,
    prefix = "test",
    save_data = TRUE,
    save_report = FALSE,
    verbose = FALSE
  )

  expect_true(dir.exists(nested_dir))
  expect_true(file.exists(file.path(nested_dir, "test_data.rds")))
})
