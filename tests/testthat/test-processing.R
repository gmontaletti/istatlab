test_that("validate_istat_data works correctly", {
  # Create test data
  valid_data <- data.table::data.table(
    ObsDimension = c("2020-01", "2020-02", "2020-03"),
    ObsValue = c(100, 105, 110),
    FREQ = c("M", "M", "M")
  )

  empty_data <- data.table::data.table()

  missing_col_data <- data.table::data.table(
    ObsDimension = c("2020-01", "2020-02"),
    NotObsValue = c(100, 105)
  )

  # Test valid data
  expect_true(validate_istat_data(valid_data))

  # Test empty data
  expect_false(suppressWarnings(validate_istat_data(empty_data)))

  # Test missing columns
  expect_false(suppressWarnings(validate_istat_data(missing_col_data)))
})

test_that("clean_variable_names works correctly", {
  input_names <- c("var.1", "var..2", "var...3", "normal_var")
  expected_names <- c("var.1", "var.2", "var.3", "normal_var")

  result <- clean_variable_names(input_names)
  expect_equal(result, expected_names)
})

test_that("filter_by_time works correctly", {
  # Create test data
  test_data <- data.table::data.table(
    tempo = as.Date(c("2020-01-01", "2020-06-01", "2021-01-01", "2021-06-01")),
    valore = c(100, 105, 110, 115)
  )

  # Test filtering from start date
  filtered <- filter_by_time(
    test_data,
    start_date = "2020-06-01",
    time_col = "tempo"
  )
  expect_equal(nrow(filtered), 3)

  # Test filtering to end date
  filtered <- filter_by_time(
    test_data,
    end_date = "2020-12-31",
    time_col = "tempo"
  )
  expect_equal(nrow(filtered), 2)

  # Test filtering with both dates
  filtered <- filter_by_time(
    test_data,
    start_date = "2020-06-01",
    end_date = "2020-12-31",
    time_col = "tempo"
  )
  expect_equal(nrow(filtered), 1)
})
