#' Create Time Series Plot
#'
#' Creates publication-ready time series plots for ISTAT data using ggplot2.
#'
#' @param data A data.table with time series data
#' @param value_col Character string specifying the value column name.
#'   Default is "valore"
#' @param time_col Character string specifying the time column name.
#'   Default is "tempo"
#' @param group_col Character string specifying the grouping variable for multiple series.
#'   Default is NULL
#' @param title Character string for plot title
#' @param subtitle Character string for plot subtitle
#' @param y_label Character string for y-axis label
#' @param x_label Character string for x-axis label
#' @param theme Character string specifying ggplot2 theme.
#'   Options: "minimal", "classic", "bw". Default is "minimal"
#' @param colors Character vector of colors for the series.
#'   Default is NULL (uses ggplot2 defaults)
#'
#' @return A ggplot object
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic time series plot
#' plot <- create_time_series_plot(data, title = "Labour Market Trends")
#' 
#' # Multiple series plot
#' plot <- create_time_series_plot(data, group_col = "region", 
#'                                title = "Regional Labour Market Comparison")
#' }
create_time_series_plot <- function(data, value_col = "valore", time_col = "tempo",
                                  group_col = NULL, title = NULL, subtitle = NULL,
                                  y_label = "Value", x_label = "Time",
                                  theme = "minimal", colors = NULL) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for visualization")
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
  
  if (!is.null(group_col) && !group_col %in% names(data)) {
    stop("Group column '", group_col, "' not found in data")
  }
  
  # Clean data
  plot_data <- data[!is.na(get(value_col)) & !is.na(get(time_col))]
  
  # Create base plot
  if (is.null(group_col)) {
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = get(time_col), y = get(value_col))) +
         ggplot2::geom_line(linewidth = 1.2, color = colors[1] %||% "#2E86AB")
  } else {
    p <- ggplot2::ggplot(plot_data, 
                        ggplot2::aes(x = get(time_col), y = get(value_col), 
                                   color = get(group_col))) +
         ggplot2::geom_line(linewidth = 1.2)
    
    if (!is.null(colors)) {
      p <- p + ggplot2::scale_color_manual(values = colors, name = group_col)
    }
  }
  
  # Add labels and formatting
  p <- p +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = x_label,
      y = y_label
    ) +
    ggplot2::scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
    ggplot2::scale_y_continuous(labels = scales::comma_format())
  
  # Apply theme
  p <- switch(theme,
    "minimal" = p + ggplot2::theme_minimal(),
    "classic" = p + ggplot2::theme_classic(),
    "bw" = p + ggplot2::theme_bw(),
    p + ggplot2::theme_minimal()  # default
  )
  
  # Additional theme customization
  p <- p + ggplot2::theme(
    plot.title = ggplot2::element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = ggplot2::element_text(size = 12, hjust = 0.5),
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
    legend.position = if(is.null(group_col)) "none" else "bottom"
  )
  
  return(p)
}

#' Create Forecast Plot
#'
#' Creates a plot showing historical data and forecasts with confidence intervals.
#'
#' @param historical_data A data.table with historical data
#' @param forecast_results List of forecast results from forecast_series()
#' @param value_col Character string specifying the value column name
#' @param time_col Character string specifying the time column name
#' @param title Character string for plot title
#' @param subtitle Character string for plot subtitle
#' @param confidence_level Numeric confidence level to display. Default is 0.95
#' @param theme Character string specifying ggplot2 theme
#'
#' @return A ggplot object
#' @export
#'
#' @examples
#' \dontrun{
#' # Create forecast plot
#' forecast_plot <- create_forecast_plot(historical_data, forecast_results,
#'                                      title = "Labour Market Forecast")
#' }
create_forecast_plot <- function(historical_data, forecast_results, 
                               value_col = "valore", time_col = "tempo",
                               title = "Time Series Forecast", subtitle = NULL,
                               confidence_level = 0.95, theme = "minimal") {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for visualization")
  }
  
  if (!data.table::is.data.table(historical_data)) {
    data.table::setDT(historical_data)
  }
  
  # Validate forecast results
  if (is.null(forecast_results$point_forecast) || is.null(forecast_results$forecast_dates)) {
    stop("Invalid forecast results. Missing point_forecast or forecast_dates.")
  }
  
  # Prepare historical data
  hist_data <- historical_data[!is.na(get(value_col)) & !is.na(get(time_col))]
  data.table::setorderv(hist_data, time_col)
  
  # Create forecast data table
  forecast_data <- data.table::data.table(
    time = forecast_results$forecast_dates,
    forecast = forecast_results$point_forecast
  )
  
  # Add confidence intervals if available
  confidence_col <- paste0("upper_", confidence_level * 100)
  lower_confidence_col <- paste0("lower_", confidence_level * 100)
  
  if (!is.null(forecast_results$upper_bounds) && !is.null(forecast_results$lower_bounds)) {
    if (confidence_col %in% colnames(forecast_results$upper_bounds)) {
      forecast_data[, upper := forecast_results$upper_bounds[, confidence_col]]
      forecast_data[, lower := forecast_results$lower_bounds[, lower_confidence_col]]
    }
  }
  
  # Create the plot
  p <- ggplot2::ggplot() +
    # Historical data
    ggplot2::geom_line(data = hist_data, 
                      ggplot2::aes(x = get(time_col), y = get(value_col)), 
                      linewidth = 1.2, color = "#2E86AB") +
    # Forecast line
    ggplot2::geom_line(data = forecast_data, 
                      ggplot2::aes(x = time, y = forecast),
                      linewidth = 1.2, color = "#A23B72", linetype = "dashed")
  
  # Add confidence intervals if available
  if ("upper" %in% names(forecast_data) && "lower" %in% names(forecast_data)) {
    p <- p + ggplot2::geom_ribbon(data = forecast_data,
                                 ggplot2::aes(x = time, ymin = lower, ymax = upper),
                                 alpha = 0.3, fill = "#A23B72")
  }
  
  # Add vertical line to separate historical and forecast
  last_historical_date <- max(hist_data[[time_col]])
  p <- p + ggplot2::geom_vline(xintercept = as.numeric(last_historical_date),
                              linetype = "dotted", color = "gray50")
  
  # Labels and formatting
  p <- p +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Time",
      y = "Value"
    ) +
    ggplot2::scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
    ggplot2::scale_y_continuous(labels = scales::comma_format())
  
  # Apply theme
  p <- switch(theme,
    "minimal" = p + ggplot2::theme_minimal(),
    "classic" = p + ggplot2::theme_classic(),
    "bw" = p + ggplot2::theme_bw(),
    p + ggplot2::theme_minimal()  # default
  )
  
  # Theme customization
  p <- p + ggplot2::theme(
    plot.title = ggplot2::element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = ggplot2::element_text(size = 12, hjust = 0.5),
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  )
  
  return(p)
}

#' Create Comparison Plot
#'
#' Creates a plot comparing multiple series or regions.
#'
#' @param data A data.table with data to compare
#' @param value_col Character string specifying the value column name
#' @param time_col Character string specifying the time column name
#' @param group_col Character string specifying the grouping variable
#' @param facet_col Character string specifying variable for faceting.
#'   Default is NULL
#' @param plot_type Character string specifying plot type.
#'   Options: "line", "area". Default is "line"
#' @param title Character string for plot title
#' @param subtitle Character string for plot subtitle
#' @param colors Character vector of colors
#'
#' @return A ggplot object
#' @export
#'
#' @examples
#' \dontrun{
#' # Compare regions
#' comparison_plot <- create_comparison_plot(data, group_col = "region",
#'                                          title = "Regional Comparison")
#' 
#' # Faceted comparison
#' comparison_plot <- create_comparison_plot(data, group_col = "region",
#'                                          facet_col = "sector")
#' }
create_comparison_plot <- function(data, value_col = "valore", time_col = "tempo",
                                 group_col, facet_col = NULL, plot_type = "line",
                                 title = "Data Comparison", subtitle = NULL,
                                 colors = NULL) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for visualization")
  }
  
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }
  
  # Validate inputs
  required_cols <- c(value_col, time_col, group_col)
  if (!is.null(facet_col)) {
    required_cols <- c(required_cols, facet_col)
  }
  
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop("Missing columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Clean data
  plot_data <- data[!is.na(get(value_col)) & !is.na(get(time_col))]
  
  # Create base plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = get(time_col), y = get(value_col)))
  
  if (plot_type == "line") {
    p <- p + ggplot2::geom_line(ggplot2::aes(color = get(group_col)), linewidth = 1.2)
  } else if (plot_type == "area") {
    p <- p + ggplot2::geom_area(ggplot2::aes(fill = get(group_col)), alpha = 0.7, position = "identity")
  }
  
  # Add colors
  if (!is.null(colors)) {
    if (plot_type == "line") {
      p <- p + ggplot2::scale_color_manual(values = colors, name = group_col)
    } else {
      p <- p + ggplot2::scale_fill_manual(values = colors, name = group_col)
    }
  }
  
  # Add faceting if specified
  if (!is.null(facet_col)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(get(facet_col)), scales = "free_y")
  }
  
  # Labels and formatting
  p <- p +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Time",
      y = "Value"
    ) +
    ggplot2::scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
    ggplot2::scale_y_continuous(labels = scales::comma_format()) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = ggplot2::element_text(size = 12, hjust = 0.5),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      legend.position = "bottom",
      strip.text = ggplot2::element_text(face = "bold")
    )
  
  return(p)
}

#' Create Growth Rate Plot
#'
#' Creates a plot showing growth rates over time.
#'
#' @param data A data.table with growth rate data
#' @param growth_col Character string specifying the growth rate column name
#' @param time_col Character string specifying the time column name
#' @param group_col Character string specifying the grouping variable.
#'   Default is NULL
#' @param title Character string for plot title
#' @param subtitle Character string for plot subtitle
#' @param include_zero_line Logical indicating whether to include a horizontal line at zero
#' @param colors Character vector of colors
#'
#' @return A ggplot object
#' @export
#'
#' @examples
#' \dontrun{
#' # Create growth rate plot
#' growth_plot <- create_growth_plot(data_with_growth, 
#'                                  growth_col = "growth_period",
#'                                  title = "Growth Rates Over Time")
#' }
create_growth_plot <- function(data, growth_col, time_col = "tempo", group_col = NULL,
                             title = "Growth Rates", subtitle = NULL,
                             include_zero_line = TRUE, colors = NULL) {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for visualization")
  }
  
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }
  
  # Validate inputs
  required_cols <- c(growth_col, time_col)
  if (!is.null(group_col)) {
    required_cols <- c(required_cols, group_col)
  }
  
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop("Missing columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Clean data
  plot_data <- data[!is.na(get(growth_col)) & !is.na(get(time_col))]
  
  # Create plot
  if (is.null(group_col)) {
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = get(time_col), y = get(growth_col))) +
         ggplot2::geom_line(linewidth = 1.2, color = colors[1] %||% "#2E86AB")
  } else {
    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = get(time_col), y = get(growth_col),
                                                color = get(group_col))) +
         ggplot2::geom_line(linewidth = 1.2)
    
    if (!is.null(colors)) {
      p <- p + ggplot2::scale_color_manual(values = colors, name = group_col)
    }
  }
  
  # Add zero line if requested
  if (include_zero_line) {
    p <- p + ggplot2::geom_hline(yintercept = 0, linetype = "dashed", 
                                color = "gray50", alpha = 0.7)
  }
  
  # Labels and formatting
  p <- p +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Time",
      y = "Growth Rate (%)"
    ) +
    ggplot2::scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
    ggplot2::scale_y_continuous(labels = function(x) paste0(x, "%")) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = ggplot2::element_text(size = 12, hjust = 0.5),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      legend.position = if(is.null(group_col)) "none" else "bottom"
    )
  
  return(p)
}

#' Create Dashboard Plot
#'
#' Creates a multi-panel dashboard plot combining different visualizations.
#'
#' @param data A data.table with data for plotting
#' @param panels Character vector specifying which panels to include.
#'   Options: "timeseries", "growth", "distribution", "summary"
#' @param value_col Character string specifying the value column name
#' @param time_col Character string specifying the time column name
#' @param group_col Character string specifying the grouping variable
#' @param title Character string for overall title
#'
#' @return A combined ggplot object
#' @export
#'
#' @examples
#' \dontrun{
#' # Create dashboard with multiple panels
#' dashboard <- create_dashboard_plot(data, 
#'                                   panels = c("timeseries", "growth"),
#'                                   title = "Labour Market Dashboard")
#' }
create_dashboard_plot <- function(data, panels = c("timeseries", "growth"),
                                value_col = "valore", time_col = "tempo", 
                                group_col = NULL, title = "Dashboard") {
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for visualization")
  }
  
  if (!requireNamespace("patchwork", quietly = TRUE)) {
    message("Package 'patchwork' recommended for better dashboard layout")
  }
  
  plot_list <- list()
  
  # Time series panel
  if ("timeseries" %in% panels) {
    ts_plot <- create_time_series_plot(data, value_col = value_col, 
                                      time_col = time_col, group_col = group_col,
                                      title = "Time Series")
    plot_list$timeseries <- ts_plot
  }
  
  # Growth rates panel
  if ("growth" %in% panels) {
    # Calculate growth rates first
    growth_data <- calculate_growth_rates(data, value_col = value_col, 
                                         time_col = time_col, group_vars = group_col)
    
    growth_plot <- create_growth_plot(growth_data, growth_col = "growth_period",
                                    time_col = time_col, group_col = group_col,
                                    title = "Growth Rates")
    plot_list$growth <- growth_plot
  }
  
  # Distribution panel
  if ("distribution" %in% panels) {
    dist_plot <- ggplot2::ggplot(data[!is.na(get(value_col))], 
                                ggplot2::aes(x = get(value_col))) +
      ggplot2::geom_histogram(bins = 30, fill = "#2E86AB", alpha = 0.7) +
      ggplot2::labs(title = "Value Distribution", x = "Value", y = "Frequency") +
      ggplot2::theme_minimal()
    
    plot_list$distribution <- dist_plot
  }
  
  # Summary statistics panel
  if ("summary" %in% panels) {
    summary_stats <- calculate_summary_stats(data, value_col = value_col, 
                                           group_vars = group_col)
    
    # Create a simple summary plot (could be enhanced)
    summary_plot <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 0.5, y = 0.5, 
                       label = paste("Summary Statistics",
                                   paste0("Mean: ", round(summary_stats$mean, 2)),
                                   paste0("Median: ", round(summary_stats$median, 2)),
                                   paste0("SD: ", round(summary_stats$sd, 2)),
                                   sep = "\n"),
                       hjust = 0.5, vjust = 0.5, size = 4) +
      ggplot2::xlim(0, 1) + ggplot2::ylim(0, 1) +
      ggplot2::theme_void() +
      ggplot2::labs(title = "Summary Statistics")
    
    plot_list$summary <- summary_plot
  }
  
  # Combine plots
  if (length(plot_list) == 1) {
    combined_plot <- plot_list[[1]]
  } else if (requireNamespace("patchwork", quietly = TRUE)) {
    combined_plot <- patchwork::wrap_plots(plot_list, ncol = 2)
    combined_plot <- combined_plot + patchwork::plot_annotation(
      title = title,
      theme = ggplot2::theme(plot.title = ggplot2::element_text(size = 18, face = "bold"))
    )
  } else {
    # Fallback: return list of plots
    warning("Install 'patchwork' package for combined dashboard layout")
    combined_plot <- plot_list
  }
  
  return(combined_plot)
}