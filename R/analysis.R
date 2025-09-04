#' Analyze Time Series Trends
#'
#' Performs trend analysis on ISTAT time series data using various methods.
#'
#' @param data A data.table with time series data
#' @param value_col Character string specifying the value column name.
#'   Default is "valore"
#' @param time_col Character string specifying the time column name.
#'   Default is "tempo"
#' @param method Character string specifying the trend analysis method.
#'   Options: "linear", "loess", "stl". Default is "linear"
#' @param group_vars Character vector of variables to group by for analysis
#'
#' @return A list containing trend analysis results
#' @export
#'
#' @examples
#' \dontrun{
#' # Analyze linear trend
#' trend_results <- analyze_trends(data, method = "linear")
#' 
#' # Analyze with grouping
#' trend_results <- analyze_trends(data, group_vars = c("region", "sector"))
#' }
analyze_trends <- function(data, value_col = "valore", time_col = "tempo", 
                          method = "linear", group_vars = NULL) {
  
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
  
  # Prepare data for analysis
  analysis_data <- data[!is.na(get(value_col)) & !is.na(get(time_col))]
  
  if (nrow(analysis_data) == 0) {
    stop("No valid data points for analysis")
  }
  
  # Perform analysis by group if specified
  if (!is.null(group_vars)) {
    missing_groups <- setdiff(group_vars, names(analysis_data))
    if (length(missing_groups) > 0) {
      stop("Group variables not found: ", paste(missing_groups, collapse = ", "))
    }
    
    results <- analysis_data[, .(trend_result = list(
      perform_trend_analysis(.SD, value_col, time_col, method)
    )), by = group_vars]
    
  } else {
    results <- perform_trend_analysis(analysis_data, value_col, time_col, method)
  }
  
  return(results)
}

#' Perform Trend Analysis
#'
#' Internal function to perform the actual trend analysis using the specified method.
#' Supports linear regression, LOESS smoothing, and STL decomposition for trend estimation.
#'
#' @param data A data.table subset for analysis containing time series data
#' @param value_col Character string specifying the value column name
#' @param time_col Character string specifying the time column name  
#' @param method Character string specifying the analysis method ("linear", "loess", or "stl")
#'
#' @return A list with trend analysis results including method used, number of observations,
#'   date range, and method-specific results (slopes, fitted values, decomposition components)
#' @keywords internal
perform_trend_analysis <- function(data, value_col, time_col, method) {
  
  # Convert time to numeric for analysis
  if (inherits(data[[time_col]], "Date")) {
    time_numeric <- as.numeric(data[[time_col]])
  } else {
    time_numeric <- as.numeric(data[[time_col]])
  }
  
  values <- data[[value_col]]
  
  result <- list(
    method = method,
    n_observations = length(values),
    start_date = min(data[[time_col]], na.rm = TRUE),
    end_date = max(data[[time_col]], na.rm = TRUE)
  )
  
  switch(method,
    "linear" = {
      # Linear regression
      model <- lm(values ~ time_numeric)
      result$slope <- coef(model)[2]
      result$intercept <- coef(model)[1]
      result$r_squared <- summary(model)$r.squared
      result$p_value <- summary(model)$coefficients[2, 4]
      result$fitted_values <- fitted(model)
    },
    
    "loess" = {
      # LOESS smoothing
      if (length(values) >= 4) {
        loess_model <- loess(values ~ time_numeric)
        result$fitted_values <- fitted(loess_model)
        result$residuals <- residuals(loess_model)
      } else {
        warning("Insufficient data points for LOESS analysis")
        result$fitted_values <- rep(mean(values), length(values))
      }
    },
    
    "stl" = {
      # STL decomposition (for time series)
      if (length(values) >= 12) {
        ts_data <- ts(values, frequency = determine_frequency(data[[time_col]]))
        stl_result <- stl(ts_data, s.window = "periodic")
        result$trend <- as.numeric(stl_result$time.series[, "trend"])
        result$seasonal <- as.numeric(stl_result$time.series[, "seasonal"])
        result$remainder <- as.numeric(stl_result$time.series[, "remainder"])
      } else {
        warning("Insufficient data points for STL decomposition")
        result$trend <- rep(mean(values), length(values))
      }
    }
  )
  
  return(result)
}

#' Calculate Growth Rates
#'
#' Calculates various growth rates for time series data.
#'
#' @param data A data.table with time series data
#' @param value_col Character string specifying the value column name
#' @param time_col Character string specifying the time column name
#' @param type Character string specifying growth rate type.
#'   Options: "period", "annual", "cumulative". Default is "period"
#' @param group_vars Character vector of variables to group by
#'
#' @return A data.table with calculated growth rates
#' @export
#'
#' @examples
#' \dontrun{
#' # Calculate period-over-period growth rates
#' growth_data <- calculate_growth_rates(data, type = "period")
#' 
#' # Calculate annual growth rates
#' growth_data <- calculate_growth_rates(data, type = "annual")
#' }
calculate_growth_rates <- function(data, value_col = "valore", time_col = "tempo",
                                 type = "period", group_vars = NULL) {
  
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
  
  # Sort data
  if (is.null(group_vars)) {
    data.table::setorderv(data, time_col)
  } else {
    data.table::setorderv(data, c(group_vars, time_col))
  }
  
  # Calculate growth rates
  if (is.null(group_vars)) {
    result <- calculate_growth_by_type(data, value_col, type)
  } else {
    result <- data[, calculate_growth_by_type(.SD, value_col, type), by = group_vars]
  }
  
  return(result)
}

#' Calculate Growth by Type
#'
#' Internal function to calculate growth rates by type. Supports period-over-period,
#' year-over-year (annual), and cumulative growth rate calculations.
#'
#' @param data A data.table containing the time series data for calculation
#' @param value_col Character string specifying the value column name
#' @param type Character string specifying growth rate type: 
#'   "period" for period-over-period, "annual" for year-over-year, 
#'   "cumulative" for growth from first observation
#'
#' @return A data.table with original data plus a new growth rate column
#' @keywords internal
calculate_growth_by_type <- function(data, value_col, type) {
  
  values <- data[[value_col]]
  
  switch(type,
    "period" = {
      # Period-over-period growth
      growth_rate <- c(NA, diff(values) / values[-length(values)] * 100)
    },
    
    "annual" = {
      # Year-over-year growth (assuming regular periods)
      freq <- determine_frequency(data[[names(data)[grepl("tempo", names(data))]]])
      if (freq > 1) {
        lag_periods <- freq
        growth_rate <- c(rep(NA, lag_periods), 
                        (values[(lag_periods + 1):length(values)] - 
                         values[1:(length(values) - lag_periods)]) / 
                         values[1:(length(values) - lag_periods)] * 100)
      } else {
        growth_rate <- c(NA, diff(values) / values[-length(values)] * 100)
      }
    },
    
    "cumulative" = {
      # Cumulative growth from first period
      base_value <- values[1]
      growth_rate <- (values - base_value) / base_value * 100
      growth_rate[1] <- 0  # First period is 0% growth
    }
  )
  
  result <- data.table::copy(data)
  result[, paste0("growth_", type) := growth_rate]
  
  return(result)
}

#' Determine Data Frequency
#'
#' Determines the frequency of time series data based on typical intervals
#' between observations. This is used internally for time series analysis
#' and forecasting functions.
#'
#' @param dates A vector of dates (Date, POSIXct, or coercible to Date)
#'
#' @return Numeric frequency value: 12 for monthly, 4 for quarterly, 1 for annual/other
#' @keywords internal
determine_frequency <- function(dates) {
  
  if (length(dates) < 2) {
    return(1)
  }
  
  # Calculate typical interval
  intervals <- diff(sort(as.Date(dates)))
  typical_interval <- as.numeric(median(intervals, na.rm = TRUE))
  
  # Determine frequency based on interval
  if (typical_interval <= 32) {
    return(12)  # Monthly
  } else if (typical_interval <= 100) {
    return(4)   # Quarterly
  } else {
    return(1)   # Annual
  }
}

#' Detect Structural Breaks
#'
#' Detects structural breaks in time series data.
#'
#' @param data A data.table with time series data
#' @param value_col Character string specifying the value column name
#' @param time_col Character string specifying the time column name
#' @param method Character string specifying detection method.
#'   Options: "bcp", "chow". Default is "chow"
#' @param confidence_level Numeric confidence level for break detection.
#'   Default is 0.95
#'
#' @return A list with structural break results
#' @export
#'
#' @examples
#' \dontrun{
#' # Detect structural breaks using Chow test
#' breaks <- detect_structural_breaks(data, method = "chow")
#' }
detect_structural_breaks <- function(data, value_col = "valore", time_col = "tempo",
                                   method = "chow", confidence_level = 0.95) {
  
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
  
  # Sort and clean data
  data <- data[!is.na(get(value_col)) & !is.na(get(time_col))]
  data.table::setorderv(data, time_col)
  
  if (nrow(data) < 10) {
    warning("Insufficient data for structural break detection")
    return(list(breaks = NULL, method = method))
  }
  
  # Prepare data
  time_numeric <- as.numeric(data[[time_col]])
  values <- data[[value_col]]
  
  result <- list(method = method, n_observations = length(values))
  
  switch(method,
    "chow" = {
      # Simple Chow test approach
      result$breaks <- detect_chow_breaks(values, time_numeric, confidence_level)
    },
    
    "bcp" = {
      # Bayesian change point detection would require additional packages
      warning("BCP method not implemented. Use 'chow' method.")
      result$breaks <- NULL
    }
  )
  
  return(result)
}

#' Detect Chow Breaks
#'
#' Internal function to detect structural breaks using Chow test logic.
#'
#' @param values Numeric vector of values
#' @param time_numeric Numeric vector of time points
#' @param confidence_level Numeric confidence level
#'
#' @return A vector of break point indices
#' @keywords internal
detect_chow_breaks <- function(values, time_numeric, confidence_level) {
  
  n <- length(values)
  if (n < 10) return(NULL)
  
  # Simple approach: test for breaks at various points
  potential_breaks <- seq(0.2 * n, 0.8 * n, by = 1)
  significant_breaks <- c()
  
  for (break_point in potential_breaks) {
    
    # Split data
    before <- 1:break_point
    after <- (break_point + 1):n
    
    if (length(before) < 3 || length(after) < 3) next
    
    # Fit separate models
    model_before <- lm(values[before] ~ time_numeric[before])
    model_after <- lm(values[after] ~ time_numeric[after])
    
    # Simple test based on coefficient differences
    coef_diff <- abs(coef(model_after)[2] - coef(model_before)[2])
    
    # Use a simple threshold (this is a simplified approach)
    threshold <- quantile(abs(diff(values)), 0.9, na.rm = TRUE) / 
                 median(abs(diff(time_numeric)), na.rm = TRUE)
    
    if (coef_diff > threshold) {
      significant_breaks <- c(significant_breaks, break_point)
    }
  }
  
  return(unique(significant_breaks))
}

#' Calculate Summary Statistics
#'
#' Calculates comprehensive summary statistics for ISTAT data.
#'
#' @param data A data.table with data to summarize
#' @param value_col Character string specifying the value column name
#' @param group_vars Character vector of variables to group by
#'
#' @return A data.table with summary statistics
#' @export
#'
#' @examples
#' \dontrun{
#' # Calculate overall summary statistics
#' summary_stats <- calculate_summary_stats(data)
#' 
#' # Calculate summary by groups
#' summary_stats <- calculate_summary_stats(data, group_vars = c("region"))
#' }
calculate_summary_stats <- function(data, value_col = "valore", group_vars = NULL) {
  
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }
  
  # Validate inputs
  if (!value_col %in% names(data)) {
    stop("Value column '", value_col, "' not found in data")
  }
  
  # Calculate statistics
  if (is.null(group_vars)) {
    result <- data[!is.na(get(value_col)), .(
      n = .N,
      mean = mean(get(value_col)),
      median = median(get(value_col)),
      sd = sd(get(value_col)),
      min = min(get(value_col)),
      max = max(get(value_col)),
      q25 = quantile(get(value_col), 0.25),
      q75 = quantile(get(value_col), 0.75),
      cv = sd(get(value_col)) / mean(get(value_col)) * 100
    )]
  } else {
    result <- data[!is.na(get(value_col)), .(
      n = .N,
      mean = mean(get(value_col)),
      median = median(get(value_col)),
      sd = sd(get(value_col)),
      min = min(get(value_col)),
      max = max(get(value_col)),
      q25 = quantile(get(value_col), 0.25),
      q75 = quantile(get(value_col), 0.75),
      cv = sd(get(value_col)) / mean(get(value_col)) * 100
    ), by = group_vars]
  }
  
  return(result)
}