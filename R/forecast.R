# forecast.R
# Time series forecasting functions for istatlab
# Author: Giampaolo Montaletti

# 1. Helper Functions -----
#' Detect time series frequency from data
#'
#' @param data data.table with time series data
#' @param time_col Column name for dates
#' @param freq_col Column name for frequency indicator (optional)
#' @return Numeric frequency (12 for monthly, 4 for quarterly, 1 for annual)
#' @noRd
detect_frequency <- function(data, time_col = "tempo", freq_col = "FREQ") {
  # Try to detect from FREQ column first

if (freq_col %in% names(data)) {
    freq_value <- unique(data[[freq_col]])[1]
    if (!is.na(freq_value)) {
      freq_map <- c("M" = 12, "Q" = 4, "A" = 1, "S" = 2)
      if (freq_value %in% names(freq_map)) {
        return(unname(freq_map[freq_value]))
      }
    }
  }

  # Fallback: detect from time intervals
  dates <- sort(data[[time_col]])
  if (length(dates) < 2) {
    warning("Insufficient data points to detect frequency, assuming monthly (12)")
    return(12)
  }

  # Calculate median interval in days
  intervals <- as.numeric(diff(dates))
  median_interval <- median(intervals, na.rm = TRUE)

  # Classify based on interval
  if (median_interval < 45) {
    return(12)  # Monthly
  } else if (median_interval < 120) {
    return(4)   # Quarterly
  } else {
    return(1)   # Annual
  }
}

#' Convert data.table to ts object
#'
#' @param data data.table with time series data
#' @param time_col Column name for dates
#' @param value_col Column name for values
#' @param frequency Time series frequency
#' @return ts object
#' @noRd
dt_to_ts <- function(data, time_col = "tempo", value_col = "valore", frequency = 12) {
  # Sort by time
  dt <- data.table::copy(data)
  data.table::setorderv(dt, time_col)

  # Extract values
  values <- dt[[value_col]]

  # Get start date
  start_date <- min(dt[[time_col]])
  start_year <- as.numeric(format(start_date, "%Y"))

  if (frequency == 12) {
    start_period <- as.numeric(format(start_date, "%m"))
  } else if (frequency == 4) {
    start_period <- ceiling(as.numeric(format(start_date, "%m")) / 3)
  } else {
    start_period <- 1
  }

  # Create ts object
  ts(values, start = c(start_year, start_period), frequency = frequency)
}

#' Convert forecast object to data.table
#'
#' @param fc_object forecast object from forecast package
#' @param last_date Last date in historical data
#' @param frequency Time series frequency
#' @return data.table with forecast values and intervals
#' @noRd
forecast_to_dt <- function(fc_object, last_date, frequency = 12) {
  h <- length(fc_object$mean)

  # Generate future dates
  if (frequency == 12) {
    future_dates <- seq.Date(last_date, by = "month", length.out = h + 1)[-1]
  } else if (frequency == 4) {
    future_dates <- seq.Date(last_date, by = "quarter", length.out = h + 1)[-1]
  } else {
    future_dates <- seq.Date(last_date, by = "year", length.out = h + 1)[-1]
  }

  data.table::data.table(
    tempo = future_dates,
    valore_forecast = as.numeric(fc_object$mean),
    lower_80 = as.numeric(fc_object$lower[, 1]),
    upper_80 = as.numeric(fc_object$upper[, 1]),
    lower_95 = as.numeric(fc_object$lower[, 2]),
    upper_95 = as.numeric(fc_object$upper[, 2])
  )
}

#' Calculate ensemble forecast from multiple models
#'
#' @param all_forecasts List of forecast data.tables
#' @param weights Weighting method: "equal" or "accuracy"
#' @param accuracies Named vector of accuracy values (for accuracy weighting)
#' @return data.table with ensemble forecast
#' @noRd
calculate_ensemble <- function(all_forecasts, weights = "equal", accuracies = NULL) {
  # Get forecast values from each model
  fc_matrix <- sapply(all_forecasts, function(x) x$valore_forecast)

  if (weights == "equal") {
    ensemble_mean <- rowMeans(fc_matrix, na.rm = TRUE)
    ensemble_sd <- apply(fc_matrix, 1, sd, na.rm = TRUE)
  } else if (weights == "accuracy" && !is.null(accuracies)) {
    # Inverse accuracy weighting (lower RMSE = higher weight)
    w <- 1 / accuracies
    w <- w / sum(w)
    ensemble_mean <- as.numeric(fc_matrix %*% w)
    ensemble_sd <- apply(fc_matrix, 1, sd, na.rm = TRUE)
  } else {
    ensemble_mean <- rowMeans(fc_matrix, na.rm = TRUE)
    ensemble_sd <- apply(fc_matrix, 1, sd, na.rm = TRUE)
  }

  data.table::data.table(
    tempo = all_forecasts[[1]]$tempo,
    valore_forecast = ensemble_mean,
    sd = ensemble_sd,
    lower_95 = ensemble_mean - 1.96 * ensemble_sd,
    upper_95 = ensemble_mean + 1.96 * ensemble_sd
  )
}

#' Fit a single forecast model
#'
#' @param ts_data ts object
#' @param model_name Name of the model to fit
#' @param h Forecast horizon
#' @return List with model object and forecast
#' @noRd
fit_model <- function(ts_data, model_name, h) {
  result <- tryCatch({
    if (model_name == "auto.arima") {
      model <- forecast::auto.arima(ts_data)
      fc <- forecast::forecast(model, h = h)
    } else if (model_name == "ets") {
      model <- forecast::ets(ts_data)
      fc <- forecast::forecast(model, h = h)
    } else if (model_name == "theta") {
      fc <- forecast::thetaf(ts_data, h = h)
      model <- NULL
    } else if (model_name == "naive") {
      fc <- forecast::naive(ts_data, h = h)
      model <- NULL
    } else if (model_name == "snaive") {
      fc <- forecast::snaive(ts_data, h = h)
      model <- NULL
    } else {
      stop("Unknown model: ", model_name)
    }
    list(model = model, forecast = fc, success = TRUE)
  }, error = function(e) {
    list(model = NULL, forecast = NULL, success = FALSE, error = e$message)
  })
  result
}

#' Calculate accuracy metrics
#'
#' @param actual Actual values
#' @param predicted Predicted values
#' @return Named list with RMSE, MAE, MAPE
#' @noRd
calculate_accuracy <- function(actual, predicted) {
  errors <- actual - predicted
  abs_errors <- abs(errors)
  pct_errors <- abs_errors / abs(actual) * 100

  list(
    RMSE = sqrt(mean(errors^2, na.rm = TRUE)),
    MAE = mean(abs_errors, na.rm = TRUE),
    MAPE = mean(pct_errors[is.finite(pct_errors)], na.rm = TRUE)
  )
}

# 2. Main Forecast Function -----
#' Forecast a time series using multiple models
#'
#' Tests multiple forecasting models, selects the best one based on accuracy
#' metrics, and also provides an ensemble (average) forecast.
#'
#' @param data data.table with a single time series
#' @param time_col Column name for dates (default "tempo")
#' @param value_col Column name for values (default "valore")
#' @param freq_col Column name for frequency indicator (default "FREQ")
#' @param horizon Forecast periods. NULL for auto-detect (24 monthly, 8 quarterly, 2 annual)
#' @param models Character vector of model names to test
#' @param metric Accuracy metric for model selection: "RMSE", "MAE", or "MAPE"
#' @param test_size Proportion of data to use for testing (default 0.2)
#' @param save_path Optional file path to save the forecast as RDS
#' @param verbose Print progress messages (default TRUE)
#'
#' @return An S3 object of class "istat_forecast" containing:
#' \itemize{
#'   \item best_model: Best performing model with forecast and accuracy
#'   \item ensemble: Average forecast from all models
#'   \item all_models: Results from each individual model
#'   \item metadata: Forecast parameters and metadata
#'   \item original_data: Input data
#' }
#'
#' @examples
#' \dontrun{
#' # Load some ISTAT data
#' data <- download_istat_data("534_50", start_time = "2015")
#' data <- apply_labels(data)
#'
#' # Filter to a single series
#' series <- data[ECON_ACTIVITY_NACE_2007_label == "TOTALE INDUSTRIA E SERVIZI  (b-n)"]
#'
#' # Generate forecast
#' fc <- forecast_series(series, horizon = 24)
#'
#' # View results
#' print(fc)
#' plot(fc)
#' }
#'
#' @export
forecast_series <- function(
    data,
    time_col = "tempo",
    value_col = "valore",
    freq_col = "FREQ",
    horizon = NULL,
    models = c("auto.arima", "ets", "theta", "naive", "snaive"),
    metric = c("RMSE", "MAE", "MAPE"),
    test_size = 0.2,
    save_path = NULL,
    verbose = TRUE
) {
  # Match metric argument
  metric <- match.arg(metric)

  # 1. Input validation -----
  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  if (!time_col %in% names(data)) {
    stop("Time column '", time_col, "' not found in data")
  }
  if (!value_col %in% names(data)) {
    stop("Value column '", value_col, "' not found in data")
  }

  # Check for NA values
  n_na <- sum(is.na(data[[value_col]]))
  if (n_na > 0) {
    warning("Data contains ", n_na, " missing values. These will be interpolated.")
  }

  # 2. Detect frequency and set horizon -----
  frequency <- detect_frequency(data, time_col, freq_col)

  if (is.null(horizon)) {
    # Default: 2 years
    horizon <- switch(as.character(frequency),
                      "12" = 24,  # 24 months
                      "4" = 8,    # 8 quarters
                      "1" = 2,    # 2 years
                      24)         # default
  }

  if (verbose) {
    message("Detected frequency: ", frequency, " (",
            c("12" = "monthly", "4" = "quarterly", "1" = "annual")[as.character(frequency)], ")")
    message("Forecast horizon: ", horizon, " periods")
  }

  # 3. Prepare data -----
  dt <- data.table::copy(data)
  data.table::setorderv(dt, time_col)

  # Handle missing values with linear interpolation
  if (n_na > 0) {
    dt[[value_col]] <- zoo::na.approx(dt[[value_col]], na.rm = FALSE)
  }

  # Convert to ts
  ts_full <- dt_to_ts(dt, time_col, value_col, frequency)

  # 4. Split train/test -----
  n <- length(ts_full)
  n_test <- max(1, floor(n * test_size))
  n_train <- n - n_test

  if (n_train < frequency * 2) {
    warning("Training data may be too short for reliable forecasting")
  }

  ts_train <- window(ts_full, end = time(ts_full)[n_train])
  ts_test <- window(ts_full, start = time(ts_full)[n_train + 1])

  if (verbose) {
    message("Training observations: ", n_train)
    message("Test observations: ", n_test)
  }

  # 5. Fit models and evaluate -----
  all_results <- list()
  accuracies <- numeric()

  for (model_name in models) {
    if (verbose) message("Fitting model: ", model_name)

    # Fit on training data
    fit_result <- fit_model(ts_train, model_name, h = n_test)

    if (!fit_result$success) {
      if (verbose) message("  Model failed: ", fit_result$error)
      next
    }

    # Calculate accuracy on test set
    predicted <- as.numeric(fit_result$forecast$mean)
    actual <- as.numeric(ts_test)
    acc <- calculate_accuracy(actual, predicted)

    all_results[[model_name]] <- list(
      model = fit_result$model,
      train_forecast = fit_result$forecast,
      accuracy = acc
    )
    accuracies[model_name] <- acc[[metric]]
  }

  if (length(all_results) == 0) {
    stop("All models failed to fit")
  }

  # 6. Select best model -----
  best_model_name <- names(which.min(accuracies))

  if (verbose) {
    message("\nModel accuracy (", metric, "):")
    for (m in names(accuracies)) {
      marker <- if (m == best_model_name) " <-- BEST" else ""
      message("  ", m, ": ", round(accuracies[m], 4), marker)
    }
  }

  # 7. Generate final forecasts -----
  last_date <- max(dt[[time_col]])
  all_forecasts <- list()

  for (model_name in names(all_results)) {
    if (verbose) message("Generating final forecast: ", model_name)

    # Refit on full data
    final_fit <- fit_model(ts_full, model_name, h = horizon)

    if (final_fit$success) {
      fc_dt <- forecast_to_dt(final_fit$forecast, last_date, frequency)

      all_results[[model_name]]$final_model <- final_fit$model
      all_results[[model_name]]$forecast <- fc_dt
      all_forecasts[[model_name]] <- fc_dt
    }
  }

  # 8. Create ensemble forecast -----
  if (length(all_forecasts) > 1) {
    ensemble <- calculate_ensemble(all_forecasts, weights = "equal")
    ensemble_accuracy <- calculate_ensemble(all_forecasts, weights = "accuracy",
                                            accuracies = accuracies[names(all_forecasts)])
  } else {
    ensemble <- all_forecasts[[1]]
    ensemble_accuracy <- ensemble
  }

  # 9. Build return object -----
  result <- list(
    best_model = list(
      name = best_model_name,
      forecast = all_results[[best_model_name]]$forecast,
      accuracy = all_results[[best_model_name]]$accuracy,
      model_object = all_results[[best_model_name]]$final_model
    ),
    ensemble = list(
      forecast = ensemble,
      forecast_weighted = ensemble_accuracy,
      models_used = names(all_forecasts),
      weights = "equal"
    ),
    all_models = all_results,
    metadata = list(
      horizon = horizon,
      frequency = frequency,
      metric_used = metric,
      train_end = as.character(dt[[time_col]][n_train]),
      forecast_start = as.character(last_date + 1),
      n_observations = n,
      n_train = n_train,
      n_test = n_test,
      created = Sys.time()
    ),
    original_data = data
  )

  class(result) <- c("istat_forecast", "list")

  # 10. Save if requested -----
  if (!is.null(save_path)) {
    saveRDS(result, save_path)
    if (verbose) message("Forecast saved to: ", save_path)
  }

  result
}

# 3. S3 Methods -----
#' Print method for istat_forecast objects
#'
#' @param x An istat_forecast object
#' @param ... Additional arguments (ignored)
#' @export
print.istat_forecast <- function(x, ...) {
  cat("ISTAT Time Series Forecast\n")
  cat("==========================\n\n")

  cat("Best Model:", x$best_model$name, "\n")
  cat("Accuracy (", x$metadata$metric_used, "): ",
      round(x$best_model$accuracy[[x$metadata$metric_used]], 4), "\n\n", sep = "")

  cat("Forecast Horizon:", x$metadata$horizon, "periods\n")
  cat("Frequency:", x$metadata$frequency,
      "(", c("12" = "monthly", "4" = "quarterly", "1" = "annual")[as.character(x$metadata$frequency)], ")\n\n")

  cat("Models tested:", paste(names(x$all_models), collapse = ", "), "\n")
  cat("Ensemble uses:", length(x$ensemble$models_used), "models\n\n")

  cat("Data summary:\n")
  cat("  Observations:", x$metadata$n_observations, "\n")
  cat("  Training:", x$metadata$n_train, "\n")
  cat("  Test:", x$metadata$n_test, "\n")
  cat("  Created:", as.character(x$metadata$created), "\n")

  invisible(x)
}

#' Plot method for istat_forecast objects
#'
#' @param x An istat_forecast object
#' @param include_ensemble Include ensemble forecast in plot (default TRUE)
#' @param include_intervals Include prediction intervals (default TRUE)
#' @param ... Additional arguments passed to plot
#' @export
plot.istat_forecast <- function(x, include_ensemble = TRUE, include_intervals = TRUE, ...) {
  # Get original data
  orig <- x$original_data
  time_col <- "tempo"
  value_col <- "valore"

  # Prepare historical data
  hist_data <- data.table::data.table(
    tempo = orig[[time_col]],
    valore = orig[[value_col]],
    type = "Historical"
  )

  # Prepare best model forecast
  best_fc <- x$best_model$forecast
  fc_data <- data.table::data.table(
    tempo = best_fc$tempo,
    valore = best_fc$valore_forecast,
    type = paste0("Forecast (", x$best_model$name, ")")
  )

  # Combine for plotting
  plot_data <- data.table::rbindlist(list(hist_data, fc_data), fill = TRUE)

  # Basic plot
  plot(plot_data$tempo, plot_data$valore,
       type = "n",
       xlab = "Time", ylab = "Value",
       main = paste("Forecast using", x$best_model$name),
       ...)

  # Historical line
  hist_idx <- plot_data$type == "Historical"
  lines(plot_data$tempo[hist_idx], plot_data$valore[hist_idx], col = "black", lwd = 2)

  # Prediction intervals
  if (include_intervals) {
    polygon(
      c(best_fc$tempo, rev(best_fc$tempo)),
      c(best_fc$lower_95, rev(best_fc$upper_95)),
      col = rgb(0.2, 0.4, 0.8, 0.2), border = NA
    )
    polygon(
      c(best_fc$tempo, rev(best_fc$tempo)),
      c(best_fc$lower_80, rev(best_fc$upper_80)),
      col = rgb(0.2, 0.4, 0.8, 0.3), border = NA
    )
  }

  # Best model forecast line
  lines(best_fc$tempo, best_fc$valore_forecast, col = "blue", lwd = 2)

  # Ensemble forecast
  if (include_ensemble && length(x$ensemble$models_used) > 1) {
    ens_fc <- x$ensemble$forecast
    lines(ens_fc$tempo, ens_fc$valore_forecast, col = "red", lwd = 2, lty = 2)
  }

  # Legend
  legend_items <- c("Historical", paste0("Best (", x$best_model$name, ")"))
  legend_cols <- c("black", "blue")
  legend_lty <- c(1, 1)

  if (include_ensemble && length(x$ensemble$models_used) > 1) {
    legend_items <- c(legend_items, "Ensemble")
    legend_cols <- c(legend_cols, "red")
    legend_lty <- c(legend_lty, 2)
  }

  legend("topleft", legend = legend_items, col = legend_cols, lty = legend_lty, lwd = 2)

  invisible(x)
}
