# Tests for edition-aware download functions
# Covers: parse_edition_date, determine_latest_edition, build_sdmx_filter_key,
#          merge_sdmx_filters, get_available_editions, get_dataset_dimension_positions,
#          download_istat_data_latest_edition

# 1. parse_edition_date -----

test_that("parse_edition_date converts a single edition code to Date", {
  result <- istatlab:::parse_edition_date("G_2024_01")
  expect_s3_class(result, "Date")
  expect_equal(result, as.Date("2024-01-01"))
})

test_that("parse_edition_date converts multiple edition codes", {
  codes <- c("G_2024_01", "G_2023_12", "G_2024_06")
  result <- istatlab:::parse_edition_date(codes)

  expect_length(result, 3)
  expect_equal(result[1], as.Date("2024-01-01"))
  expect_equal(result[2], as.Date("2023-12-01"))
  expect_equal(result[3], as.Date("2024-06-01"))
})

test_that("parse_edition_date produces correct date ordering", {
  codes <- c("G_2023_12", "G_2024_01", "G_2023_06")
  result <- istatlab:::parse_edition_date(codes)
  sorted <- sort(result)

  expect_equal(sorted[1], as.Date("2023-06-01"))
  expect_equal(sorted[2], as.Date("2023-12-01"))
  expect_equal(sorted[3], as.Date("2024-01-01"))
})

# 2. determine_latest_edition -----

test_that("determine_latest_edition selects the most recent edition", {
  editions <- c("G_2023_06", "G_2024_01", "G_2023_12")
  result <- istatlab:::determine_latest_edition(editions)
  expect_equal(result, "G_2024_01")
})

test_that("determine_latest_edition handles alphabetical vs date ordering", {
  # Alphabetically "G_2023_12" > "G_2024_02" is FALSE (correct),

  # but "G_2024_02" > "G_2023_12" must be TRUE chronologically.
  # This case works either way. The important edge case is:
  # "G_2024_09" vs "G_2024_10": alphabetically "09" < "10" works,
  # but verify date-based logic picks the right one.
  editions <- c("G_2024_09", "G_2024_10")
  result <- istatlab:::determine_latest_edition(editions)
  expect_equal(result, "G_2024_10")
})

test_that("determine_latest_edition prefers date over alphabetical order", {
  # "G_2024_02" is chronologically later than "G_2023_12",
  # but alphabetically "G_2023_12" > "G_2024_02" could mislead a naive sort
  editions <- c("G_2023_12", "G_2024_02")
  result <- istatlab:::determine_latest_edition(editions)
  expect_equal(result, "G_2024_02")
})

test_that("determine_latest_edition works with a single edition", {
  result <- istatlab:::determine_latest_edition("G_2024_03")
  expect_equal(result, "G_2024_03")
})

# 3. build_sdmx_filter_key -----

test_that("build_sdmx_filter_key creates basic dot-separated filter", {
  result <- build_sdmx_filter_key(8, list("1" = "M", "7" = "G_2024_01"))
  expect_equal(result, "M......G_2024_01.")
})

test_that("build_sdmx_filter_key produces all wildcards for empty list", {
  result <- build_sdmx_filter_key(4, list())
  expect_equal(result, "...")
})

test_that("build_sdmx_filter_key handles single dimension filter", {
  result <- build_sdmx_filter_key(5, list("3" = "IT"))
  expect_equal(result, "..IT..")
})

test_that("build_sdmx_filter_key errors on non-positive n_dims", {
  expect_error(
    build_sdmx_filter_key(0, list()),
    "n_dims must be a positive integer"
  )
  expect_error(
    build_sdmx_filter_key(-1, list()),
    "n_dims must be a positive integer"
  )
})

test_that("build_sdmx_filter_key errors on non-integer n_dims", {
  expect_error(
    build_sdmx_filter_key(2.5, list()),
    "n_dims must be a positive integer"
  )
  expect_error(
    build_sdmx_filter_key("a", list()),
    "n_dims must be a positive integer"
  )
})

test_that("build_sdmx_filter_key errors on NA n_dims", {
  expect_error(
    build_sdmx_filter_key(NA, list()),
    "n_dims must be a positive integer"
  )
})

test_that("build_sdmx_filter_key errors when dim_values is not a list", {
  expect_error(build_sdmx_filter_key(3, "M"), "dim_values must be a named list")
})

test_that("build_sdmx_filter_key errors on unnamed dim_values", {
  expect_error(
    build_sdmx_filter_key(3, list("M")),
    "All elements of dim_values must be named"
  )
})

test_that("build_sdmx_filter_key errors on non-numeric position names", {
  expect_error(
    build_sdmx_filter_key(3, list("a" = "M")),
    "dim_values names must be integer position numbers"
  )
})

test_that("build_sdmx_filter_key errors on out-of-range positions", {
  expect_error(
    build_sdmx_filter_key(3, list("5" = "M")),
    "Position\\(s\\) out of range"
  )
  expect_error(
    build_sdmx_filter_key(3, list("0" = "M")),
    "Position\\(s\\) out of range"
  )
})

# 4. merge_sdmx_filters -----

test_that("merge_sdmx_filters delegates to build_sdmx_filter_key when base is NULL", {
  result <- istatlab:::merge_sdmx_filters(
    NULL,
    8,
    list("1" = "M", "7" = "G_2024_01")
  )
  expected <- build_sdmx_filter_key(8, list("1" = "M", "7" = "G_2024_01"))
  expect_equal(result, expected)
})

test_that("merge_sdmx_filters delegates to build_sdmx_filter_key when base is ALL", {
  result <- istatlab:::merge_sdmx_filters("ALL", 5, list("3" = "IT"))
  expected <- build_sdmx_filter_key(5, list("3" = "IT"))
  expect_equal(result, expected)
})

test_that("merge_sdmx_filters preserves existing values in base filter", {
  # Position 1 already has "M"; attempting to set position 1 to "Q" should keep "M"
  result <- istatlab:::merge_sdmx_filters(
    "M..IT.....",
    8,
    list("1" = "Q", "7" = "G_2024_01")
  )
  # Position 1 stays "M" (not overwritten), position 7 gets filled
  expect_equal(result, "M..IT....G_2024_01.")
})

test_that("merge_sdmx_filters fills empty positions only", {
  result <- istatlab:::merge_sdmx_filters(
    "M..IT.....",
    8,
    list("7" = "G_2024_01")
  )
  expect_equal(result, "M..IT....G_2024_01.")
})

test_that("merge_sdmx_filters returns base filter unchanged when dim_values is empty", {
  result <- istatlab:::merge_sdmx_filters("M..IT.....", 8, list())
  expect_equal(result, "M..IT.....")
})

# 5. get_available_editions (integration) -----

test_that("get_available_editions returns character vector for edition dataset", {
  skip_on_cran()
  skip_if_offline()

  editions <- get_available_editions("150_915", timeout = 60)

  if (!is.null(editions)) {
    expect_type(editions, "character")
    expect_true(length(editions) > 0)
    # Edition codes should start with "G_"
    expect_true(all(grepl("^G_", editions)))
  }
})

test_that("get_available_editions returns NULL for dataset without editions", {
  skip_on_cran()
  skip_if_offline()

  editions <- get_available_editions("534_50", timeout = 60)
  expect_null(editions)
})

test_that("get_available_editions validates dataset_id input", {
  expect_error(
    get_available_editions(123),
    "dataset_id must be a single character string"
  )
  expect_error(
    get_available_editions(c("150_915", "150_908")),
    "dataset_id must be a single character string"
  )
})

# 6. get_dataset_dimension_positions (integration) -----

test_that("get_dataset_dimension_positions returns named integer vector", {
  skip_on_cran()
  skip_if_offline()

  positions <- get_dataset_dimension_positions("534_50")

  if (!is.null(positions)) {
    expect_type(positions, "integer")
    expect_true(length(positions) > 0)
    expect_true(!is.null(names(positions)))
    expect_true("FREQ" %in% names(positions))
  }
})

test_that("get_dataset_dimension_positions validates dataset_id input", {
  expect_error(
    get_dataset_dimension_positions(123),
    "dataset_id must be a single character string"
  )
})

# 7. download_istat_data_latest_edition (integration) -----

test_that("download_istat_data_latest_edition runs end-to-end", {
  skip("Manual testing only - API call is too expensive for automated testing")

  data <- download_istat_data_latest_edition(
    "150_908",
    start_time = "2024",
    timeout = 120,
    verbose = FALSE
  )

  if (!is.null(data)) {
    expect_true(data.table::is.data.table(data))
    expect_true(nrow(data) > 0)
  }
})

test_that("download_istat_data_latest_edition validates dataset_id input", {
  expect_error(
    download_istat_data_latest_edition(123),
    "dataset_id must be a single character string"
  )
  expect_error(
    download_istat_data_latest_edition(c("a", "b")),
    "dataset_id must be a single character string"
  )
})
