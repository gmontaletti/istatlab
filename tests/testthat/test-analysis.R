test_that("calculate_growth_rates works correctly", {
  # Create test data
  test_data <- data.table::data.table(
    tempo = as.Date(c("2020-01-01", "2020-02-01", "2020-03-01", "2020-04-01")),
    valore = c(100, 105, 110, 115)
  )
  
  # Test period growth
  result <- calculate_growth_rates(test_data, type = "period")
  expect_true("growth_period" %in% names(result))
  expect_equal(result$growth_period[2], 5)  # (105-100)/100 * 100
  
  # Test cumulative growth
  result <- calculate_growth_rates(test_data, type = "cumulative")
  expect_true("growth_cumulative" %in% names(result))
  expect_equal(result$growth_cumulative[1], 0)  # First period is 0
  expect_equal(result$growth_cumulative[4], 15)  # (115-100)/100 * 100
})

test_that("determine_frequency works correctly", {
  # Monthly data
  monthly_dates <- seq.Date(from = as.Date("2020-01-01"), 
                           to = as.Date("2020-12-01"), 
                           by = "month")
  expect_equal(determine_frequency(monthly_dates), 12)
  
  # Quarterly data  
  quarterly_dates <- seq.Date(from = as.Date("2020-01-01"), 
                             to = as.Date("2023-01-01"), 
                             by = "quarter")
  expect_equal(determine_frequency(quarterly_dates), 4)
  
  # Annual data
  annual_dates <- seq.Date(from = as.Date("2020-01-01"), 
                          to = as.Date("2025-01-01"), 
                          by = "year")
  expect_equal(determine_frequency(annual_dates), 1)
})

test_that("calculate_summary_stats works correctly", {
  # Create test data
  test_data <- data.table::data.table(
    valore = c(100, 105, 110, 115, 120),
    group = c("A", "A", "B", "B", "B")
  )
  
  # Test overall summary
  summary_all <- calculate_summary_stats(test_data)
  expect_equal(summary_all$mean, 110)
  expect_equal(summary_all$n, 5)
  
  # Test grouped summary
  summary_grouped <- calculate_summary_stats(test_data, group_vars = "group")
  expect_equal(nrow(summary_grouped), 2)
  expect_true(all(c("A", "B") %in% summary_grouped$group))
})