test_that("evaluate_forecast_accuracy works correctly", {
  actual <- c(100, 105, 110, 115, 120)
  predicted <- c(98, 107, 109, 117, 118)
  
  # Test accuracy metrics
  accuracy <- evaluate_forecast_accuracy(actual, predicted)
  
  expect_true("MAE" %in% names(accuracy))
  expect_true("RMSE" %in% names(accuracy))
  expect_true("MAPE" %in% names(accuracy))
  expect_true("sMAPE" %in% names(accuracy))
  
  # Check MAE calculation
  expected_mae <- mean(abs(actual - predicted))
  expect_equal(accuracy$MAE, expected_mae)
  
  # Check RMSE calculation
  expected_rmse <- sqrt(mean((actual - predicted)^2))
  expect_equal(accuracy$RMSE, expected_rmse)
})

test_that("evaluate_forecast_accuracy handles edge cases", {
  # Test with different vector lengths
  expect_error(evaluate_forecast_accuracy(c(1, 2, 3), c(1, 2)), 
               "Actual and predicted vectors must have the same length")
  
  # Test with zero actual values (MAPE undefined)
  actual_with_zero <- c(0, 105, 110)
  predicted_with_zero <- c(2, 107, 109)
  
  accuracy <- suppressWarnings(evaluate_forecast_accuracy(actual_with_zero, predicted_with_zero))
  expect_true(is.na(accuracy$MAPE))
})

test_that("generate_forecast_dates works correctly", {
  # Test monthly data
  historical <- seq.Date(from = as.Date("2020-01-01"), 
                        to = as.Date("2020-12-01"), 
                        by = "month")
  forecast_dates <- generate_forecast_dates(historical, 3, 12)
  
  expect_length(forecast_dates, 3)
  expect_equal(forecast_dates[1], as.Date("2021-01-01"))
  
  # Test quarterly data
  historical_q <- seq.Date(from = as.Date("2020-01-01"), 
                          to = as.Date("2020-10-01"), 
                          by = "quarter")
  forecast_dates_q <- generate_forecast_dates(historical_q, 2, 4)
  
  expect_length(forecast_dates_q, 2)
})

test_that("forecast_naive works correctly", {
  # Create simple time series
  ts_data <- ts(c(100, 105, 110, 115), frequency = 4)
  
  # Test naive forecast
  naive_result <- forecast_naive(ts_data, 2, c(0.8, 0.95))
  
  expect_equal(length(naive_result$mean), 2)
  expect_equal(naive_result$mean, c(115, 115))  # Last value repeated
  expect_equal(ncol(naive_result$upper), 2)  # Two confidence levels
  expect_equal(ncol(naive_result$lower), 2)
})

test_that("forecast_linear works correctly", {
  # Create time series with linear trend
  ts_data <- ts(c(100, 110, 120, 130), frequency = 4)
  
  # Test linear forecast
  linear_result <- forecast_linear(ts_data, 2, c(0.8, 0.95))
  
  expect_equal(length(linear_result$mean), 2)
  expect_true(linear_result$mean[1] > 130)  # Should extrapolate trend
  expect_equal(ncol(linear_result$upper), 2)
  expect_equal(ncol(linear_result$lower), 2)
})