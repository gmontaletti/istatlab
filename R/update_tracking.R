#' ISTAT Dataset Update Tracking
#'
#' Functions for tracking and detecting updates to ISTAT datasets using
#' timestamp registry and SDMX updatedAfter parameter.
#'
#' @name update_tracking
NULL

# ==============================================================================
# TIMESTAMP REGISTRY FUNCTIONS
# ==============================================================================

#' Get Dataset Timestamps
#'
#' Reads the timestamp registry from a JSON file containing download history
#' for ISTAT datasets.
#'
#' @param timestamp_file Character string specifying path to timestamp registry file.
#'   If NULL, uses default from configuration
#'
#' @return A list with components:
#'   \itemize{
#'     \item{version}: Registry format version
#'     \item{datasets}: Named list of dataset entries with timestamp and row_count
#'   }
#'   Returns empty structure if file does not exist
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get all timestamps
#' timestamps <- get_dataset_timestamps()
#'
#' # Get timestamps from custom file
#' timestamps <- get_dataset_timestamps("path/to/timestamps.json")
#' }
get_dataset_timestamps <- function(timestamp_file = NULL) {

  # Get default path from config if not specified
  if (is.null(timestamp_file)) {
    config <- get_istat_config()
    timestamp_file <- config$update_tracking$timestamp_file
  }

  # Return empty structure if file does not exist
  if (!file.exists(timestamp_file)) {
    return(list(
      version = "1.0",
      datasets = list()
    ))
  }

  # Read and parse JSON file
  tryCatch({
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("Package 'jsonlite' is required for timestamp tracking")
    }

    timestamps <- jsonlite::read_json(timestamp_file, simplifyVector = FALSE)

    # Ensure structure has required components
    if (is.null(timestamps$version)) {
      timestamps$version <- "1.0"
    }
    if (is.null(timestamps$datasets)) {
      timestamps$datasets <- list()
    }

    return(timestamps)

  }, error = function(e) {
    warning("Failed to read timestamp file: ", e$message,
            ". Returning empty structure.")
    return(list(
      version = "1.0",
      datasets = list()
    ))
  })
}

#' Save Dataset Timestamps
#'
#' Saves the timestamp registry to a JSON file using atomic write operation
#' (write to temporary file then rename).
#'
#' @param timestamps List containing timestamp registry data
#' @param timestamp_file Character string specifying path to timestamp registry file.
#'   If NULL, uses default from configuration
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Save timestamps
#' timestamps <- get_dataset_timestamps()
#' timestamps$datasets[["534_50"]] <- list(
#'   last_download = Sys.time(),
#'   row_count = 1000
#' )
#' save_dataset_timestamps(timestamps)
#' }
save_dataset_timestamps <- function(timestamps, timestamp_file = NULL) {

  # Get default path from config if not specified
  if (is.null(timestamp_file)) {
    config <- get_istat_config()
    timestamp_file <- config$update_tracking$timestamp_file
  }

  # Create directory if needed
  timestamp_dir <- dirname(timestamp_file)
  if (!dir.exists(timestamp_dir)) {
    dir.create(timestamp_dir, recursive = TRUE)
  }

  # Write to temporary file first (atomic operation)
  temp_file <- paste0(timestamp_file, ".tmp")

  tryCatch({
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("Package 'jsonlite' is required for timestamp tracking")
    }

    # Write JSON with pretty formatting
    jsonlite::write_json(
      timestamps,
      temp_file,
      pretty = TRUE,
      auto_unbox = TRUE
    )

    # Rename temp file to actual file (atomic on most filesystems)
    file.rename(temp_file, timestamp_file)

  }, error = function(e) {
    # Clean up temp file if it exists
    if (file.exists(temp_file)) {
      file.remove(temp_file)
    }
    stop("Failed to save timestamp file: ", e$message)
  })

  invisible(NULL)
}

#' Get Last Download Time
#'
#' Retrieves the last download timestamp for a specific dataset.
#'
#' @param dataset_id Character string specifying the dataset ID
#' @param timestamp_file Character string specifying path to timestamp registry file.
#'   If NULL, uses default from configuration
#'
#' @return POSIXct timestamp of last download, or NULL if dataset not found
#' @export
#'
#' @examples
#' \dontrun{
#' # Get last download time for a dataset
#' last_time <- get_last_download_time("534_50")
#'
#' if (!is.null(last_time)) {
#'   message("Last downloaded: ", last_time)
#' }
#' }
get_last_download_time <- function(dataset_id, timestamp_file = NULL) {

  timestamps <- get_dataset_timestamps(timestamp_file)

  # Check if dataset exists in registry
  if (dataset_id %in% names(timestamps$datasets)) {
    last_download <- timestamps$datasets[[dataset_id]]$last_download

    # Convert to POSIXct if needed
    if (!is.null(last_download)) {
      return(as.POSIXct(last_download, tz = "UTC"))
    }
  }

  return(NULL)
}

#' Record Download Timestamp
#'
#' Records a successful download with current timestamp and optional row count.
#'
#' @param dataset_id Character string specifying the dataset ID
#' @param row_count Optional integer specifying number of rows downloaded
#' @param timestamp_file Character string specifying path to timestamp registry file.
#'   If NULL, uses default from configuration
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Record successful download
#' record_download_timestamp("534_50", row_count = 1500)
#' }
record_download_timestamp <- function(dataset_id, row_count = NULL,
                                     timestamp_file = NULL) {

  # Get current timestamps
  timestamps <- get_dataset_timestamps(timestamp_file)

  # Create or update dataset entry
  timestamps$datasets[[dataset_id]] <- list(
    last_download = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    row_count = row_count
  )

  # Save updated timestamps
  save_dataset_timestamps(timestamps, timestamp_file)

  invisible(NULL)
}

# ==============================================================================
# UPDATE DETECTION FUNCTIONS
# ==============================================================================

#' Check if Dataset Has Updates
#'
#' Checks if a dataset has updates since last download using SDMX updatedAfter
#' parameter. This is the core update detection function.
#'
#' @param dataset_id Character string specifying the dataset ID
#' @param timestamp_file Character string specifying path to timestamp registry file.
#'   If NULL, uses default from configuration
#' @param timeout Numeric timeout in seconds for the API call. Default is 30
#' @param verbose Logical indicating whether to print status messages. Default is TRUE
#'
#' @return A list with components:
#'   \itemize{
#'     \item{dataset_id}: The dataset ID checked
#'     \item{has_updates}: Logical indicating if updates are available
#'     \item{last_download}: POSIXct of last download or NULL
#'     \item{reason}: Character string explaining the result
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Check if dataset has updates
#' status <- check_dataset_updated("534_50")
#'
#' if (status$has_updates) {
#'   message("Dataset ", status$dataset_id, " has updates!")
#' }
#' }
check_dataset_updated <- function(dataset_id, timestamp_file = NULL,
                                 timeout = 30, verbose = TRUE) {

  # Get last download time
  last_download <- get_last_download_time(dataset_id, timestamp_file)

  # If no previous download, return has_updates = TRUE
  if (is.null(last_download)) {
    return(list(
      dataset_id = dataset_id,
      has_updates = TRUE,
      last_download = NULL,
      reason = "first_download"
    ))
  }

  if (verbose) {
    message("Checking updates for dataset ", dataset_id,
            " (last download: ", last_download, ")...")
  }

  # Build URL with updatedAfter parameter using centralized config
  config <- get_istat_config()
  updated_url <- build_istat_url("data",
                                 dataset_id = dataset_id,
                                 filter = config$defaults$filter,
                                 start_time = "",
                                 updated_after = last_download)

  # Set timeout
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout))
  options(timeout = timeout)

  # Query API for updates
  tryCatch({
    result <- readsdmx::read_sdmx(updated_url)

    # Empty response means no updates; non-empty means has updates
    has_updates <- !is.null(result) && nrow(result) > 0

    reason <- if (has_updates) {
      "data_modified_since_last_download"
    } else {
      "no_updates_available"
    }

    if (verbose) {
      if (has_updates) {
        message("Updates available for dataset ", dataset_id)
      } else {
        message("No updates for dataset ", dataset_id)
      }
    }

    return(list(
      dataset_id = dataset_id,
      has_updates = has_updates,
      last_download = last_download,
      reason = reason
    ))

  }, error = function(e) {
    # Handle API errors
    warning("Failed to check updates for dataset ", dataset_id, ": ", e$message)

    return(list(
      dataset_id = dataset_id,
      has_updates = FALSE,
      last_download = last_download,
      reason = paste0("api_error: ", e$message)
    ))
  })
}

#' Check Multiple Datasets for Updates
#'
#' Batch check multiple datasets with rate limiting to avoid overwhelming the API.
#'
#' @param dataset_ids Character vector of dataset IDs to check
#' @param timestamp_file Character string specifying path to timestamp registry file.
#'   If NULL, uses default from configuration
#' @param rate_limit_delay Numeric delay in seconds between requests.
#'   If NULL, uses default from configuration (12 seconds)
#' @param verbose Logical indicating whether to print status messages. Default is TRUE
#'
#' @return A data.table with columns:
#'   \itemize{
#'     \item{dataset_id}: Dataset ID
#'     \item{has_updates}: Logical indicating if updates are available
#'     \item{last_download}: POSIXct of last download or NULL
#'     \item{reason}: Character explanation of result
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Check multiple datasets
#' datasets <- c("534_50", "534_51", "534_52")
#' results <- check_multiple_datasets_updated(datasets)
#'
#' # Filter to datasets with updates
#' needs_update <- results[has_updates == TRUE]
#' }
check_multiple_datasets_updated <- function(dataset_ids, timestamp_file = NULL,
                                           rate_limit_delay = NULL, verbose = TRUE) {

  # Get rate limit delay from config if not specified
  if (is.null(rate_limit_delay)) {
    config <- get_istat_config()
    rate_limit_delay <- config$update_tracking$rate_limit_delay
  }

  if (verbose) {
    message("Checking ", length(dataset_ids), " datasets for updates...")
    message("Using rate limit delay of ", rate_limit_delay, " seconds")
  }

  # Check each dataset
  results <- list()

  for (i in seq_along(dataset_ids)) {
    dataset_id <- dataset_ids[i]

    if (verbose && i > 1) {
      message("Waiting ", rate_limit_delay, " seconds before next request...")
      Sys.sleep(rate_limit_delay)
    }

    # Check this dataset
    result <- check_dataset_updated(
      dataset_id = dataset_id,
      timestamp_file = timestamp_file,
      verbose = verbose
    )

    results[[i]] <- result
  }

  # Convert to data.table
  results_dt <- data.table::rbindlist(results)

  if (verbose) {
    n_updates <- sum(results_dt$has_updates)
    message("Update check complete: ", n_updates, " of ", length(dataset_ids),
            " datasets have updates")
  }

  return(results_dt)
}

# ==============================================================================
# CONDITIONAL DOWNLOAD FUNCTIONS
# ==============================================================================

#' Download Dataset if Updated
#'
#' Wrapper function that checks for updates and downloads only if updates are available.
#' This is the main user-facing function for update-aware downloads.
#'
#' @param dataset_id Character string specifying the dataset ID
#' @param filter Character string specifying data filters. Default uses config value
#' @param start_time Character string specifying start period. Default is empty (all data)
#' @param force Logical indicating whether to skip update check and force download.
#'   Default is FALSE
#' @param timestamp_file Character string specifying path to timestamp registry file.
#'   If NULL, uses default from configuration
#' @param timeout Numeric timeout in seconds for the download. If NULL, uses config value
#' @param verbose Logical indicating whether to print status messages. Default is TRUE
#'
#' @return A data.table containing the downloaded data if updates available,
#'   or NULL if no updates and force = FALSE
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Download only if updated
#' data <- download_if_updated("534_50", start_time = "2020")
#'
#' # Force download regardless of update status
#' data <- download_if_updated("534_50", force = TRUE)
#'
#' # Download with custom filter
#' data <- download_if_updated("534_50", filter = "M..", start_time = "2020")
#' }
download_if_updated <- function(dataset_id, filter = NULL, start_time = "",
                               force = FALSE, timestamp_file = NULL,
                               timeout = NULL, verbose = TRUE) {

  # Get config defaults
  config <- get_istat_config()
  if (is.null(filter)) {
    filter <- config$defaults$filter
  }
  if (is.null(timeout)) {
    timeout <- config$defaults$timeout
  }

  # Skip update check if force = TRUE
  if (force) {
    if (verbose) {
      message("Force download requested for dataset ", dataset_id)
    }

    # Download data
    data <- download_istat_data(
      dataset_id = dataset_id,
      filter = filter,
      start_time = start_time,
      timeout = timeout,
      verbose = verbose
    )

    # Record timestamp if download successful
    if (!is.null(data)) {
      record_download_timestamp(
        dataset_id = dataset_id,
        row_count = nrow(data),
        timestamp_file = timestamp_file
      )
    }

    return(data)
  }

  # Check for updates
  update_status <- check_dataset_updated(
    dataset_id = dataset_id,
    timestamp_file = timestamp_file,
    verbose = verbose
  )

  # If no updates, return NULL with message
  if (!update_status$has_updates) {
    if (verbose) {
      message("No updates available for dataset ", dataset_id,
              ". Skipping download.")
      if (!is.null(update_status$last_download)) {
        message("Last download: ", update_status$last_download)
      }
    }
    return(NULL)
  }

  # Updates available, download data
  if (verbose) {
    message("Updates available for dataset ", dataset_id, ". Downloading...")
  }

  data <- download_istat_data(
    dataset_id = dataset_id,
    filter = filter,
    start_time = start_time,
    timeout = timeout,
    verbose = verbose
  )

  # Record timestamp if download successful
  if (!is.null(data)) {
    record_download_timestamp(
      dataset_id = dataset_id,
      row_count = nrow(data),
      timestamp_file = timestamp_file
    )

    if (verbose) {
      message("Download complete and timestamp recorded for dataset ", dataset_id)
    }
  }

  return(data)
}
