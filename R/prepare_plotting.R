# prepare_plotting.R - Functions for preparing ISTAT data for visualization
#
# This file contains functions to download, process, and prepare ISTAT data
# for plotting with ggplot2, including metadata reports and statistics.

# 1. Main function -----

#' Prepare ISTAT Data for Plotting
#'
#' Downloads or processes ISTAT data, applies labels, extracts non-invariant
#' columns, computes extended statistics per time series, and saves outputs
#' for visualization.
#'
#' @param data Either a character string (dataset_id to download) or a data.table
#'   containing raw ISTAT data with ObsDimension and ObsValue columns.
#' @param output_dir Character string specifying the output directory for saved files.
#'   Default is "output".
#' @param prefix Character string to prepend to output filenames. Default is NULL
#'   (uses dataset_id or "data").
#' @param start_time Character string specifying start period for download.
#'   Only used when data is a dataset_id. Default is "".
#' @param freq Character string specifying frequency filter (A, Q, M).
#'   Only used when data is a dataset_id. Default is NULL (all frequencies).
#' @param save_data Logical indicating whether to save data.rds. Default is TRUE.
#' @param save_report Logical indicating whether to save report files. Default is TRUE.
#' @param verbose Logical indicating whether to print status messages. Default is TRUE.
#'
#' @return A list with class "istat_plot_ready" containing:
#'   \itemize{
#'     \item data: data.table with labeled data ready for ggplot2
#'     \item report: list with structured metadata and series_stats (data.table with labels)
#'     \item files: list with paths to saved files (data_rds, report_rds)
#'     \item summary: Quick summary of the data (n_rows, n_series, date_range)
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' # From dataset_id (downloads and processes)
#' result <- prepare_for_plotting("534_50", output_dir = "output")
#'
#' # From pre-downloaded data
#' raw_data <- download_istat_data("534_50")
#' result <- prepare_for_plotting(raw_data, prefix = "job_vacancies")
#'
#' # Access components
#' plot_data <- result$data
#' stats <- result$report$series_stats
#' }
prepare_for_plotting <- function(data,
                                  output_dir = "output",
                                  prefix = NULL,
                                  start_time = "",
                                  freq = NULL,
                                  save_data = TRUE,
                                  save_report = TRUE,
                                  verbose = TRUE) {

  # 1. Input validation and data acquisition -----
  if (is.character(data) && length(data) == 1) {
    # data is a dataset_id - download it
    dataset_id <- data
    istat_log(paste("Downloading dataset:", dataset_id), "INFO", verbose)

    # Ensure codelists are available first
    ensure_codelists(dataset_id, verbose = verbose)

    # Download data (with frequency filter if specified)
    if (!is.null(freq)) {
      data_list <- download_istat_data_by_freq(dataset_id, start_time = start_time,
                                                freq = freq, verbose = verbose)
      data <- data_list[[freq]]
    } else {
      data <- download_istat_data(dataset_id, start_time = start_time, verbose = verbose)
    }

    if (is.null(data) || nrow(data) == 0) {
      stop("Failed to download data for dataset: ", dataset_id)
    }

  } else if (data.table::is.data.table(data) || is.data.frame(data)) {
    # data is pre-downloaded
    if (!data.table::is.data.table(data)) {
      data.table::setDT(data)
    }
    dataset_id <- if ("id" %in% names(data)) data$id[1] else "unknown"

  } else {
    stop("data must be a dataset_id (character) or a data.table/data.frame")
  }

  # Validate required columns
  if (!validate_istat_data(data)) {
    stop("Data validation failed. Required columns: ObsDimension, ObsValue")
  }

  # 2. Apply labels -----
  istat_log("Applying labels...", "INFO", verbose)

  # Ensure codelists for this dataset
  if (dataset_id != "unknown") {
    ensure_codelists(dataset_id, verbose = verbose)
  }

  labeled_data <- apply_labels(data, verbose = verbose)

  # 3. Identify unique time series using label columns -----
  all_cols <- names(labeled_data)

  # Use label columns for grouping (human-readable)
  label_cols <- grep("_label$", all_cols, value = TRUE)
  # Exclude tempo and valore related labels

  label_cols <- setdiff(label_cols, c("tempo_label", "valore_label"))

  # Also identify code columns for reference
  exclude_cols <- c("tempo", "valore", "id", "tempo_temp", "ObsValue", "ObsDimension")
  code_cols <- setdiff(all_cols, c(exclude_cols, label_cols))
  dimension_cols <- code_cols[vapply(labeled_data[, ..code_cols], is.factor, logical(1))]

  istat_log(paste("Identified", length(label_cols), "label columns:",
                  paste(label_cols, collapse = ", ")), "INFO", verbose)

  # Get unique series combinations using labels
  if (length(label_cols) > 0) {
    series_keys <- unique(labeled_data[, ..label_cols])
    n_series <- nrow(series_keys)
  } else {
    n_series <- 1L
  }
  istat_log(paste("Found", n_series, "unique time series"), "INFO", verbose)

  # 4. Compute statistics per time series (using labels) -----
  istat_log("Computing statistics...", "INFO", verbose)
  series_stats <- compute_series_stats(labeled_data, label_cols)

  # 5. Build report structure -----


  # Look up dataset name from cached metadata
  dataset_name_it <- NA_character_
  dataset_name_en <- NA_character_
  config <- get_istat_config()
  metadata_file <- file.path("meta", config$cache$metadata_file)
  if (file.exists(metadata_file)) {
    flussi <- tryCatch(readRDS(metadata_file), error = function(e) NULL)
    if (!is.null(flussi) && dataset_id %in% flussi$id) {
      idx <- which(flussi$id == dataset_id)[1]
      dataset_name_it <- flussi$Name.it[idx]
      dataset_name_en <- flussi$Name.en[idx]
    }
  }

  report <- list(
    # Metadata
    metadata = list(
      dataset_id = dataset_id,
      dataset_name_it = dataset_name_it,
      dataset_name_en = dataset_name_en,
      created_at = Sys.time(),
      istatlab_version = tryCatch(
        as.character(utils::packageVersion("istatlab")),
        error = function(e) "unknown"
      ),
      r_version = R.version.string
    ),

    # Data summary
    data_summary = list(
      n_rows = nrow(labeled_data),
      n_columns = ncol(labeled_data),
      n_series = n_series,
      dimension_columns = dimension_cols,
      label_columns = label_cols,
      frequency = if ("FREQ" %in% names(labeled_data))
                    as.character(unique(labeled_data$FREQ)) else NA_character_
    ),

    # Date range (overall)
    date_range = list(
      start = min(labeled_data$tempo, na.rm = TRUE),
      end = max(labeled_data$tempo, na.rm = TRUE),
      span_days = as.numeric(max(labeled_data$tempo, na.rm = TRUE) -
                             min(labeled_data$tempo, na.rm = TRUE))
    ),

    # Per-series statistics
    series_stats = series_stats,

    # Aggregate statistics (across all series)
    aggregate_stats = list(
      total_observations = nrow(labeled_data),
      total_missing = sum(is.na(labeled_data$valore)),
      pct_missing = round(100 * sum(is.na(labeled_data$valore)) / nrow(labeled_data), 2),
      value_range = range(labeled_data$valore, na.rm = TRUE),
      overall_mean = mean(labeled_data$valore, na.rm = TRUE),
      overall_sd = sd(labeled_data$valore, na.rm = TRUE)
    )
  )

  # 6. Save files -----
  files <- list(data_rds = NULL, report_rds = NULL)

  # Create output directory
  if ((save_data || save_report) && !dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Determine file prefix
  if (is.null(prefix)) {
    prefix <- if (dataset_id != "unknown") dataset_id else "data"
  }

  # Save data RDS
  if (save_data) {
    data_file <- file.path(output_dir, paste0(prefix, "_data.rds"))
    saveRDS(labeled_data, data_file)
    files$data_rds <- normalizePath(data_file)
    istat_log(paste("Saved data to:", files$data_rds), "INFO", verbose)
  }

  # Save report RDS (contains series_stats as data.table with labels)
  if (save_report) {
    report_file <- file.path(output_dir, paste0(prefix, "_report.rds"))
    saveRDS(report, report_file)
    files$report_rds <- normalizePath(report_file)
    istat_log(paste("Saved report to:", files$report_rds), "INFO", verbose)
  }

  # 7. Return result -----
  result <- structure(
    list(
      data = labeled_data,
      report = report,
      files = files,
      summary = list(
        dataset_id = dataset_id,
        n_rows = nrow(labeled_data),
        n_series = n_series,
        date_range = paste(report$date_range$start, "to", report$date_range$end),
        dimensions = paste(label_cols, collapse = ", ")
      )
    ),
    class = c("istat_plot_ready", "list")
  )

  istat_log("Preparation complete", "INFO", verbose)
  return(result)
}

# 2. Helper: Compute series statistics -----

#' Compute Statistics for Each Time Series
#'
#' Computes extended statistics for each unique time series in the data.
#'
#' @param dt data.table with labeled ISTAT data
#' @param dimension_cols Character vector of dimension column names
#'
#' @return data.table with statistics per series
#' @keywords internal
compute_series_stats <- function(dt, dimension_cols) {

  # Helper function for single series statistics
  compute_single_stats <- function(values, dates) {
    # Remove NA values for calculations
    valid_idx <- !is.na(values) & !is.na(dates)
    values_clean <- values[valid_idx]
    dates_clean <- dates[valid_idx]

    n <- length(values)
    n_valid <- length(values_clean)
    n_missing <- n - n_valid

    # Initialize stats list
    stats <- list(
      n = n,
      n_valid = n_valid,
      n_missing = n_missing,
      pct_missing = round(100 * n_missing / max(n, 1), 2)
    )

    if (n_valid > 0) {
      # Descriptive statistics
      stats$min <- min(values_clean)
      stats$max <- max(values_clean)
      stats$mean <- mean(values_clean)
      stats$sd <- if (n_valid > 1) sd(values_clean) else NA_real_
      stats$median <- median(values_clean)
      stats$q1 <- as.numeric(quantile(values_clean, 0.25))
      stats$q3 <- as.numeric(quantile(values_clean, 0.75))

      # Date range
      stats$date_start <- min(dates_clean)
      stats$date_end <- max(dates_clean)
      stats$date_span_days <- as.numeric(stats$date_end - stats$date_start)

      # Trend direction (simple linear fit)
      if (n_valid >= 3) {
        time_numeric <- as.numeric(dates_clean - min(dates_clean))
        fit <- tryCatch({
          lm(values_clean ~ time_numeric)
        }, error = function(e) NULL)

        if (!is.null(fit)) {
          slope <- coef(fit)[2]
          stats$trend_slope <- as.numeric(slope)
          stats$trend_direction <- if (slope > 0.01) "positive"
                                    else if (slope < -0.01) "negative"
                                    else "flat"
        } else {
          stats$trend_slope <- NA_real_
          stats$trend_direction <- "unknown"
        }
      } else {
        stats$trend_slope <- NA_real_
        stats$trend_direction <- "insufficient_data"
      }

      # Growth rates
      if (n_valid >= 2) {
        # Order by date for proper growth calculation
        ord <- order(dates_clean)
        values_ordered <- values_clean[ord]

        # Period-over-period growth
        growth_rates <- diff(values_ordered) / head(values_ordered, -1) * 100
        stats$avg_growth_rate <- mean(growth_rates[is.finite(growth_rates)], na.rm = TRUE)

        # CAGR (Compound Annual Growth Rate)
        years <- stats$date_span_days / 365.25
        first_val <- values_ordered[1]
        last_val <- tail(values_ordered, 1)
        if (years > 0 && first_val > 0 && last_val > 0) {
          stats$cagr <- ((last_val / first_val)^(1/years) - 1) * 100
        } else {
          stats$cagr <- NA_real_
        }
      } else {
        stats$avg_growth_rate <- NA_real_
        stats$cagr <- NA_real_
      }

    } else {
      # All values missing
      stats$min <- NA_real_
      stats$max <- NA_real_
      stats$mean <- NA_real_
      stats$sd <- NA_real_
      stats$median <- NA_real_
      stats$q1 <- NA_real_
      stats$q3 <- NA_real_
      stats$date_start <- as.Date(NA)
      stats$date_end <- as.Date(NA)
      stats$date_span_days <- NA_real_
      stats$trend_slope <- NA_real_
      stats$trend_direction <- "no_data"
      stats$avg_growth_rate <- NA_real_
      stats$cagr <- NA_real_
    }

    return(stats)
  }

  # Compute stats for each series using data.table grouping
  if (length(dimension_cols) > 0) {
    stats_dt <- dt[, {
      s <- compute_single_stats(valore, tempo)
      as.list(s)
    }, by = dimension_cols]
  } else {
    # Single series (no dimension columns)
    s <- compute_single_stats(dt$valore, dt$tempo)
    stats_dt <- data.table::as.data.table(c(list(series_id = 1L), s))
  }

  return(stats_dt)
}

# 3. S3 print method -----

#' Print Method for istat_plot_ready
#'
#' @param x An istat_plot_ready object
#' @param ... Additional arguments (ignored)
#'
#' @return Invisible x
#' @export
print.istat_plot_ready <- function(x, ...) {
  cat("ISTAT Plot-Ready Data\n")
  cat(paste(rep("-", 40), collapse = ""), "\n")
  cat("Dataset:", x$summary$dataset_id)
  if (!is.na(x$report$metadata$dataset_name_it)) {
    cat(" -", x$report$metadata$dataset_name_it)
  }
  cat("\n")
  cat("Rows:", x$summary$n_rows, "\n")
  cat("Time series:", x$summary$n_series, "\n")
  cat("Date range:", x$summary$date_range, "\n")
  cat("Dimensions:", x$summary$dimensions, "\n")
  cat("\nFiles saved:\n")
  if (!is.null(x$files$data_rds)) cat("  Data:", x$files$data_rds, "\n")
  if (!is.null(x$files$report_rds)) cat("  Report:", x$files$report_rds, "\n")
  invisible(x)
}
