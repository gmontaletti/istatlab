#' Forecast Time Series
#'
#' Generates forecasts for ISTAT time series data using various methods.
#'
#' @param data A data.table with time series data
#' @param value_col Character string specifying the value column name.
#'   Default is "valore"
#' @param time_col Character string specifying the time column name.
#'   Default is "tempo"
#' @param periods Integer number of periods to forecast. Default is 12
#' @param method Character string specifying forecasting method.
#'   Options: "auto.arima", "ets", "naive", "linear". Default is "auto.arima"
#' @param confidence_levels Numeric vector of confidence levels for intervals.
#'   Default is c(0.8, 0.95)
#' @param group_vars Character vector of variables to group by for forecasting
#'
#' @return A list containing forecast results and model information
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate 12-period forecast using auto.arima
#' forecast_results <- forecast_series(data, periods = 12)
#' 
#' # Forecast with different method
#' forecast_results <- forecast_series(data, method = "ets", periods = 6)
#' 
#' # Forecast by groups
#' forecast_results <- forecast_series(data, group_vars = c("region"))
#' }
forecast_series <- function(data, value_col = "valore", time_col = "tempo", 
                          periods = 12, method = "auto.arima", 
                          confidence_levels = c(0.8, 0.95), group_vars = NULL) {
  
  if (!requireNamespace("forecast", quietly = TRUE)) {
    stop("Package 'forecast' is required for forecasting functionality")
  }
  
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }
  
  # Validate inputs
  if (!value_col %in% names(data)) {
    stop("Value column '", value_col, "' not found in data")
  }
  
  if (!time_col %in% names(data)) {
    stop("Time column '", time_col, "' not found in data")
  }
  
  # Clean and sort data
  forecast_data <- data[!is.na(get(value_col)) & !is.na(get(time_col))]
  
  if (is.null(group_vars)) {
    data.table::setorderv(forecast_data, time_col)
  } else {
    data.table::setorderv(forecast_data, c(group_vars, time_col))
  }
  
  # Perform forecasting
  if (is.null(group_vars)) {
    result <- perform_forecast(forecast_data, value_col, time_col, 
                             periods, method, confidence_levels)
  } else {
    result <- forecast_data[, .(forecast_result = list(
      perform_forecast(.SD, value_col, time_col, periods, method, confidence_levels)
    )), by = group_vars]
  }
  
  return(result)
}

#' Perform Forecast
#'
#' Internal function to perform the actual forecasting using the specified method.
#' Supports auto.arima, ETS, naive (random walk), and linear trend forecasting.
#'
#' @param data A data.table subset containing time series data for forecasting
#' @param value_col Character string specifying the value column name
#' @param time_col Character string specifying the time column name
#' @param periods Integer number of periods to forecast ahead
#' @param method Character string specifying forecasting method 
#'   ("auto.arima", "ets", "naive", "linear")
#' @param confidence_levels Numeric vector of confidence levels for prediction intervals
#'
#' @return A list with comprehensive forecast results including point forecasts,
#'   confidence intervals, fitted values, residuals, forecast dates, and model information
#' @keywords internal
perform_forecast <- function(data, value_col, time_col, periods, method, confidence_levels) {
  
  values <- data[[value_col]]
  time_points <- data[[time_col]]
  
  if (length(values) < 4) {
    warning("Insufficient data points for forecasting")
    return(list(error = "Insufficient data"))
  }
  
  # Determine frequency
  freq <- determine_frequency(time_points)
  
  # Create time series object
  ts_data <- ts(values, frequency = freq)
  
  # Generate forecast
  result <- list(
    method = method,
    periods = periods,
    frequency = freq,
    n_observations = length(values),
    last_observation_date = max(time_points),
    confidence_levels = confidence_levels
  )
  
  tryCatch({
    forecast_obj <- switch(method,
      "auto.arima" = {
        if (requireNamespace("forecast", quietly = TRUE)) {
          model <- forecast::auto.arima(ts_data)
          forecast::forecast(model, h = periods, level = confidence_levels * 100)
        } else {
          stop("forecast package required for auto.arima method")
        }
      },
      
      "ets" = {
        if (requireNamespace("forecast", quietly = TRUE)) {
          model <- forecast::ets(ts_data)
          forecast::forecast(model, h = periods, level = confidence_levels * 100)
        } else {
          stop("forecast package required for ETS method")
        }
      },
      
      "naive" = {
        forecast_naive(ts_data, periods, confidence_levels)
      },
      
      "linear" = {
        forecast_linear(ts_data, periods, confidence_levels)
      }
    )
    
    # Extract forecast components
    result$point_forecast <- as.numeric(forecast_obj$mean)
    result$fitted_values <- as.numeric(forecast_obj$fitted)
    result$residuals <- as.numeric(forecast_obj$residuals)
    
    # Extract confidence intervals
    if (!is.null(forecast_obj$upper) && !is.null(forecast_obj$lower)) {
      result$upper_bounds <- as.matrix(forecast_obj$upper)
      result$lower_bounds <- as.matrix(forecast_obj$lower)
      colnames(result$upper_bounds) <- paste0("upper_", confidence_levels * 100)
      colnames(result$lower_bounds) <- paste0("lower_", confidence_levels * 100)
    }
    
    # Generate forecast dates
    result$forecast_dates <- generate_forecast_dates(time_points, periods, freq)
    
    # Model information
    if (method %in% c("auto.arima", "ets")) {
      result$model_info <- forecast_obj$model
      result$aic <- AIC(forecast_obj$model)
      result$bic <- BIC(forecast_obj$model)
    }
    
  }, error = function(e) {
    result$error <- paste("Forecasting failed:", e$message)
    warning("Forecasting failed: ", e$message)
  })
  
  return(result)
}

#' Naive Forecast
#'
#' Performs naive forecasting (last value carried forward).
#'
#' @param ts_data A time series object
#' @param periods Integer number of periods to forecast
#' @param confidence_levels Numeric vector of confidence levels
#'
#' @return A forecast-like object
#' @keywords internal
forecast_naive <- function(ts_data, periods, confidence_levels) {
  
  last_value <- as.numeric(tail(ts_data, 1))
  residuals <- diff(ts_data)
  residual_sd <- sd(residuals, na.rm = TRUE)
  
  # Point forecast (naive - last value repeated)
  point_forecast <- rep(last_value, periods)
  
  # Confidence intervals
  z_scores <- qnorm(1 - (1 - confidence_levels) / 2)
  
  upper_bounds <- matrix(nrow = periods, ncol = length(confidence_levels))
  lower_bounds <- matrix(nrow = periods, ncol = length(confidence_levels))
  
  for (i in seq_along(confidence_levels)) {
    margin <- z_scores[i] * residual_sd * sqrt(1:periods)
    upper_bounds[, i] <- point_forecast + margin
    lower_bounds[, i] <- point_forecast - margin
  }
  
  return(list(
    mean = point_forecast,
    upper = upper_bounds,
    lower = lower_bounds,
    fitted = as.numeric(ts_data),
    residuals = c(NA, residuals)
  ))
}

#' Linear Trend Forecast
#'
#' Performs linear trend forecasting.
#'
#' @param ts_data A time series object
#' @param periods Integer number of periods to forecast
#' @param confidence_levels Numeric vector of confidence levels
#'
#' @return A forecast-like object
#' @keywords internal
forecast_linear <- function(ts_data, periods, confidence_levels) {
  
  n <- length(ts_data)
  time_index <- 1:n
  
  # Fit linear model
  model <- lm(as.numeric(ts_data) ~ time_index)
  
  # Generate forecasts
  future_time <- (n + 1):(n + periods)
  point_forecast <- predict(model, newdata = data.frame(time_index = future_time))
  
  # Confidence intervals
  forecast_se <- predict(model, newdata = data.frame(time_index = future_time), 
                        se.fit = TRUE)$se.fit
  residual_sd <- summary(model)$sigma
  
  total_se <- sqrt(forecast_se^2 + residual_sd^2)
  
  upper_bounds <- matrix(nrow = periods, ncol = length(confidence_levels))
  lower_bounds <- matrix(nrow = periods, ncol = length(confidence_levels))
  
  for (i in seq_along(confidence_levels)) {
    t_value <- qt(1 - (1 - confidence_levels[i]) / 2, df = n - 2)
    margin <- t_value * total_se
    upper_bounds[, i] <- point_forecast + margin
    lower_bounds[, i] <- point_forecast - margin
  }
  
  return(list(
    mean = point_forecast,
    upper = upper_bounds,
    lower = lower_bounds,
    fitted = fitted(model),
    residuals = residuals(model)
  ))
}

#' Generate Forecast Dates
#'
#' Generates future dates for forecasting periods.
#'
#' @param historical_dates Vector of historical dates
#' @param periods Integer number of forecast periods
#' @param frequency Numeric frequency of the data
#'
#' @return Vector of forecast dates
#' @keywords internal
generate_forecast_dates <- function(historical_dates, periods, frequency) {
  
  if (!inherits(historical_dates, "Date")) {
    historical_dates <- as.Date(historical_dates)
  }
  
  last_date <- max(historical_dates)
  
  # Determine period increment
  if (frequency == 12) {
    # Monthly data
    increment <- "month"
  } else if (frequency == 4) {
    # Quarterly data
    increment <- "3 months"
  } else {
    # Annual or other
    increment <- "year"
  }
  
  # Generate future dates
  forecast_dates <- seq.Date(
    from = last_date,
    by = increment,
    length.out = periods + 1
  )[-1]  # Remove the first date (which is the last historical date)
  
  return(forecast_dates)
}

#' Evaluate Forecast Accuracy
#'
#' Evaluates the accuracy of forecasts against actual values.
#'
#' @param actual Numeric vector of actual values
#' @param predicted Numeric vector of predicted values
#' @param metrics Character vector of metrics to calculate.
#'   Options: "MAE", "RMSE", "MAPE", "sMAPE", "MASE". Default is all
#'
#' @return A named list of accuracy metrics
#' @export
#'
#' @examples
#' \dontrun{
#' # Evaluate forecast accuracy
#' accuracy <- evaluate_forecast_accuracy(actual_values, predicted_values)
#' }
evaluate_forecast_accuracy <- function(actual, predicted, 
                                     metrics = c("MAE", "RMSE", "MAPE", "sMAPE", "MASE")) {
  
  if (length(actual) != length(predicted)) {
    stop("Actual and predicted vectors must have the same length")
  }
  
  # Remove NA values
  valid_indices <- !is.na(actual) & !is.na(predicted)
  actual <- actual[valid_indices]
  predicted <- predicted[valid_indices]
  
  if (length(actual) == 0) {
    stop("No valid observations for accuracy evaluation")
  }
  
  errors <- actual - predicted
  abs_errors <- abs(errors)
  
  result <- list()
  
  if ("MAE" %in% metrics) {
    result$MAE <- mean(abs_errors)
  }
  
  if ("RMSE" %in% metrics) {
    result$RMSE <- sqrt(mean(errors^2))
  }
  
  if ("MAPE" %in% metrics) {
    if (any(actual == 0)) {
      warning("MAPE undefined for zero actual values")
      result$MAPE <- NA
    } else {
      result$MAPE <- mean(abs_errors / abs(actual)) * 100
    }
  }
  
  if ("sMAPE" %in% metrics) {
    result$sMAPE <- mean(2 * abs_errors / (abs(actual) + abs(predicted))) * 100
  }
  
  if ("MASE" %in% metrics) {
    # Simplified MASE calculation
    if (length(actual) > 1) {
      naive_mae <- mean(abs(diff(actual)))
      if (naive_mae != 0) {
        result$MASE <- mean(abs_errors) / naive_mae
      } else {
        result$MASE <- NA
      }
    } else {
      result$MASE <- NA
    }
  }
  
  return(result)
}

#' Create Forecast Summary
#'
#' Creates a summary table of forecast results.
#'
#' @param forecast_results List of forecast results from forecast_series()
#' @param group_vars Character vector of grouping variables (if used)
#'
#' @return A data.table with forecast summary
#' @export
#'
#' @examples
#' \dontrun{
#' # Create forecast summary
#' summary <- create_forecast_summary(forecast_results)
#' }
create_forecast_summary <- function(forecast_results, group_vars = NULL) {
  
  if (is.null(group_vars)) {
    # Single forecast result
    if (is.list(forecast_results) && !is.null(forecast_results$point_forecast)) {
      result <- data.table::data.table(
        period = 1:length(forecast_results$point_forecast),
        forecast_date = forecast_results$forecast_dates,
        point_forecast = forecast_results$point_forecast
      )
      
      # Add confidence intervals if available
      if (!is.null(forecast_results$upper_bounds)) {
        for (i in seq_len(ncol(forecast_results$upper_bounds))) {
          col_name <- colnames(forecast_results$upper_bounds)[i]
          result[, (col_name) := forecast_results$upper_bounds[, i]]
        }
      }
      
      if (!is.null(forecast_results$lower_bounds)) {
        for (i in seq_len(ncol(forecast_results$lower_bounds))) {
          col_name <- colnames(forecast_results$lower_bounds)[i]
          result[, (col_name) := forecast_results$lower_bounds[, i]]
        }
      }
    } else {
      result <- data.table::data.table(error = "Invalid forecast results")
    }
  } else {
    # Multiple forecast results by groups
    if (data.table::is.data.table(forecast_results) && "forecast_result" %in% names(forecast_results)) {
      result_list <- list()
      
      for (i in 1:nrow(forecast_results)) {
        group_info <- forecast_results[i, ..group_vars]
        forecast_data <- forecast_results[i]$forecast_result[[1]]
        
        if (!is.null(forecast_data$point_forecast)) {
          temp_result <- data.table::data.table(
            period = 1:length(forecast_data$point_forecast),
            forecast_date = forecast_data$forecast_dates,
            point_forecast = forecast_data$point_forecast
          )
          
          # Add group information
          for (var in group_vars) {
            temp_result[, (var) := group_info[[var]]]
          }
          
          result_list[[i]] <- temp_result
        }
      }
      
      if (length(result_list) > 0) {
        result <- data.table::rbindlist(result_list, fill = TRUE)
      } else {
        result <- data.table::data.table(error = "No valid forecast results")
      }
    } else {
      result <- data.table::data.table(error = "Invalid grouped forecast results")
    }
  }
  
  return(result)
}