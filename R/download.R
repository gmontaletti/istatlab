#' Download Data from ISTAT SDMX API
#'
#' Downloads statistical data from the ISTAT (Istituto Nazionale di Statistica)
#' SDMX API for a specified dataset. Uses centralized configuration for default values.
#'
#' @param dataset_id Character string specifying the ISTAT dataset ID (e.g., "534_50")
#' @param filter Character string specifying data filters. Default uses config value ("ALL")
#' @param start_time Character string specifying the start period (e.g., "2019").
#'   If empty, downloads all available data
#' @param end_time Character string or Date specifying the end period (e.g., "2024",
#'   "2024-06", "2024-06-30"). If empty (default), no upper bound is applied.
#'   Accepts formats "YYYY", "YYYY-MM", or "YYYY-MM-DD".
#' @param incremental Logical or Date/character. If FALSE (default), fetches all data.
#'   If a Date object or character string ("YYYY", "YYYY-MM", or "YYYY-MM-DD"),
#'   fetches only data from that period onwards using the SDMX startPeriod parameter.
#'   Takes precedence over start_time if both are provided.
#' @param timeout Numeric timeout in seconds for the download operation. Default uses config value
#' @param verbose Logical indicating whether to print status messages. Default is TRUE
#' @param updated_after POSIXct timestamp. If provided, only data updated since this time
#'   will be retrieved. Used for incremental update detection.
#' @param return_result Logical indicating whether to return full istat_result object
#'   instead of just the data.table. Default is FALSE for backward compatibility.
#' @param check_update Logical indicating whether to check ISTAT's LAST_UPDATE timestamp
#'   before downloading. If TRUE and data hasn't changed since last download, returns NULL
#'   with a message. Default is FALSE for backward compatibility.
#' @param cache_dir Character string specifying directory for download log cache.
#'   Default is "meta"
#' @param existing_data Optional data.table of previously downloaded data. When provided,
#'   the function determines the already-covered date range and downloads only
#'   non-overlapping periods, merging and deduplicating the result.
#'
#' @return A data.table containing the downloaded data with an additional 'id' column,
#'   or NULL if the download fails or data is unchanged. If return_result = TRUE, returns
#'   an istat_result object with additional metadata (exit_code, md5, message, is_timeout).
#' @export
#'
#' @examples
#' \dontrun{
#' # Download all data for dataset 534_50
#' data <- download_istat_data("534_50")
#'
#' # Download data from 2019 onwards
#' data <- download_istat_data("534_50", start_time = "2019")
#'
#' # Download with specific filter
#' data <- download_istat_data("534_50", filter = "M..", start_time = "2020")
#'
#' # Download data for a specific date interval
#' data <- download_istat_data("534_50", start_time = "2020", end_time = "2023")
#'
#' # Download only data updated since a specific timestamp
#' timestamp <- as.POSIXct("2025-12-10 14:30:00", tz = "UTC")
#' data <- download_istat_data("534_50", updated_after = timestamp)
#'
#' # Get full result with metadata
#' result <- download_istat_data("534_50", return_result = TRUE)
#' if (result$success) {
#'   print(paste("Downloaded", nrow(result$data), "rows, MD5:", result$md5))
#' }
#'
#' # Check if data has been updated before downloading
#' data <- download_istat_data("534_50", check_update = TRUE)
#' # Returns NULL with message if data unchanged since last download
#' }
download_istat_data <- function(
  dataset_id,
  filter = NULL,
  start_time = "",
  end_time = "",
  incremental = FALSE,
  timeout = NULL,
  verbose = TRUE,
  updated_after = NULL,
  return_result = FALSE,
  check_update = FALSE,
  cache_dir = "meta",
  existing_data = NULL
) {
  # Get default values from centralized configuration
  config <- get_istat_config()

  if (is.null(filter)) {
    filter <- config$defaults$filter
  }

  if (is.null(timeout)) {
    timeout <- config$defaults$timeout
  }

  # Input validation
  if (!is.character(dataset_id) || length(dataset_id) != 1) {
    stop("dataset_id must be a single character string")
  }

  # Validate incremental parameter
  if (!isFALSE(incremental)) {
    if (inherits(incremental, "Date")) {
      incremental <- format(incremental, "%Y-%m-%d")
    } else if (is.character(incremental)) {
      if (!grepl("^\\d{4}(-\\d{2})?(-\\d{2})?$", incremental)) {
        stop(
          "incremental must be FALSE, a Date, or character in 'YYYY', 'YYYY-MM', or 'YYYY-MM-DD' format"
        )
      }
    } else {
      stop("incremental must be FALSE, a Date object, or a character string")
    }
  }

  # Validate end_time parameter
  if (nchar(end_time) > 0) {
    if (inherits(end_time, "Date")) {
      end_time <- format(end_time, "%Y-%m-%d")
    } else if (is.character(end_time)) {
      if (!grepl("^\\d{4}(-\\d{2})?(-\\d{2})?$", end_time)) {
        stop(
          "end_time must be a character in 'YYYY', 'YYYY-MM', or 'YYYY-MM-DD' format, or a Date object"
        )
      }
    } else {
      stop("end_time must be a character string or a Date object")
    }
  }

  # Smart update check: compare ISTAT's LAST_UPDATE with our download log
  if (check_update) {
    update_check <- check_data_update_needed(dataset_id, cache_dir, verbose)
    if (!update_check$needs_update) {
      istat_log(
        paste(
          "Data unchanged since",
          update_check$last_download,
          "(ISTAT last update:",
          update_check$istat_last_update,
          ")"
        ),
        "INFO",
        verbose
      )
      if (return_result) {
        return(create_download_result(
          success = TRUE,
          data = NULL,
          exit_code = 0L,
          message = paste("Data unchanged since", update_check$last_download),
          md5 = NA_character_,
          is_timeout = FALSE
        ))
      }
      return(NULL)
    }
  }

  istat_log(paste("Downloading dataset", dataset_id), "INFO", verbose)

  # Construct API URL using centralized configuration
  # Determine effective start_time (incremental takes precedence)
  effective_start_time <- if (!isFALSE(incremental)) incremental else start_time

  api_url <- build_istat_url(
    "data",
    dataset_id = dataset_id,
    filter = filter,
    start_time = effective_start_time,
    end_time = end_time,
    updated_after = updated_after
  )

  # HTTP request using new transport layer
  http_result <- http_get(api_url, timeout = timeout, verbose = verbose)

  # Process response using new processor
  result <- process_api_response(http_result, verbose)

  # Handle failure
  if (!result$success) {
    warning(
      "Failed to download data for dataset: ",
      dataset_id,
      " - ",
      result$message
    )
    if (return_result) {
      return(result)
    }
    return(NULL)
  }

  # Add dataset identifier column
  result$data[, id := dataset_id]

  # Integrate with existing data if provided (overlap deduplication)
  if (!is.null(existing_data)) {
    result$data <- integrate_downloaded_data(existing_data, result$data)
  }

  md5_info <- if (!is.na(result$md5)) {
    paste(" (MD5:", substr(result$md5, 1, 8), "...)")
  } else {
    ""
  }
  istat_log(
    paste(
      "Downloaded",
      nrow(result$data),
      "rows for dataset",
      dataset_id,
      md5_info
    ),
    "INFO",
    verbose
  )

  # Update download log with ISTAT's LAST_UPDATE timestamp
  if (check_update) {
    update_data_download_log(dataset_id, cache_dir)
  }

  # Return based on preference
  if (return_result) {
    return(result)
  }

  result$data
}

#' Download Multiple Datasets
#'
#' Downloads multiple datasets from ISTAT SDMX API in parallel.
#' Uses centralized configuration for default values.
#'
#' @param dataset_ids Character vector of ISTAT dataset IDs
#' @param filter Character string specifying data filters. Default uses config value ("ALL")
#' @param start_time Character string specifying the start period
#' @param incremental Logical or Date/character. If FALSE (default), fetches all data.
#'   If a Date object or character string ("YYYY", "YYYY-MM", or "YYYY-MM-DD"),
#'   fetches only data from that period onwards. Takes precedence over start_time.
#' @param n_cores Integer number of cores to use for parallel processing.
#'   Default is parallel::detectCores() - 1
#' @param verbose Logical indicating whether to print status messages. Default is TRUE
#' @param updated_after POSIXct timestamp. If provided, only data updated since this time
#'   will be retrieved for all datasets. Used for incremental update detection.
#'
#' @return A named list of data.tables, one for each dataset
#' @export
#'
#' @examples
#' \dontrun{
#' # Download multiple datasets
#' datasets <- c("534_50", "534_51", "534_52")
#' data_list <- download_multiple_datasets(datasets, start_time = "2020")
#'
#' # Access individual datasets
#' vacancies_50 <- data_list[["534_50"]]
#'
#' # Download only updated data
#' timestamp <- as.POSIXct("2025-12-10 14:30:00", tz = "UTC")
#' updated_list <- download_multiple_datasets(datasets, updated_after = timestamp)
#' }
download_multiple_datasets <- function(
  dataset_ids,
  filter = NULL,
  start_time = "",
  incremental = FALSE,
  n_cores = parallel::detectCores() - 1,
  verbose = TRUE,
  updated_after = NULL
) {
  # Get default values from centralized configuration
  config <- get_istat_config()

  if (is.null(filter)) {
    filter <- config$defaults$filter
  }

  # Input validation
  if (!is.character(dataset_ids) || length(dataset_ids) == 0) {
    stop("dataset_ids must be a non-empty character vector")
  }

  if (verbose) {
    message("Downloading ", length(dataset_ids), " datasets...")
  }

  # Create download function
  download_function <- function(id) {
    download_istat_data(
      id,
      filter = filter,
      start_time = start_time,
      incremental = incremental,
      verbose = verbose,
      updated_after = updated_after
    )
  }

  # Use parallel processing
  if (n_cores > 1 && length(dataset_ids) > 1) {
    if (verbose) {
      message("Using parallel processing with ", n_cores, " cores...")
    }
    result <- parallel::mclapply(
      dataset_ids,
      download_function,
      mc.cores = n_cores
    )
  } else {
    result <- lapply(
      dataset_ids,
      download_function
    )
  }

  names(result) <- dataset_ids

  if (verbose) {
    successful <- sum(!sapply(result, is.null))
    message(
      "Download complete: ",
      successful,
      " of ",
      length(dataset_ids),
      " datasets successful"
    )
  }

  return(result)
}

# 1. Smart Update Check Helpers -----

#' Check if Data Update is Needed
#'
#' Compares ISTAT's LAST_UPDATE timestamp with our download log to determine
#' if data needs to be re-downloaded.
#'
#' @param dataset_id Character string specifying the dataset ID
#' @param cache_dir Character string specifying cache directory
#' @param verbose Logical for status messages
#'
#' @return List with needs_update (logical), istat_last_update, last_download timestamps
#' @keywords internal
check_data_update_needed <- function(
  dataset_id,
  cache_dir = "meta",
  verbose = TRUE
) {
  # Get current LAST_UPDATE from ISTAT API
  istat_last_update <- get_dataset_last_update(dataset_id)

  if (is.null(istat_last_update)) {
    # Can't determine last update, proceed with download
    return(list(
      needs_update = TRUE,
      istat_last_update = NA,
      last_download = NA
    ))
  }

  # Load download log
  config <- get_istat_config()
  log_file <- file.path(cache_dir, config$cache$data_download_log_file)

  if (!file.exists(log_file)) {
    # No log file, first download
    return(list(
      needs_update = TRUE,
      istat_last_update = istat_last_update,
      last_download = NA
    ))
  }

  download_log <- readRDS(log_file)

  if (!dataset_id %in% names(download_log)) {
    # Dataset not in log, first download
    return(list(
      needs_update = TRUE,
      istat_last_update = istat_last_update,
      last_download = NA
    ))
  }

  # Compare timestamps
  logged_istat_update <- download_log[[dataset_id]]$istat_last_update
  last_download <- download_log[[dataset_id]]$downloaded_at

  if (is.null(logged_istat_update) || is.na(logged_istat_update)) {
    # No stored ISTAT timestamp, need to download
    return(list(
      needs_update = TRUE,
      istat_last_update = istat_last_update,
      last_download = last_download
    ))
  }

  # Check if ISTAT has updated since our last download
  needs_update <- istat_last_update > logged_istat_update

  list(
    needs_update = needs_update,
    istat_last_update = istat_last_update,
    last_download = last_download
  )
}

#' Update Data Download Log
#'
#' Records the download timestamp and ISTAT's LAST_UPDATE for a dataset.
#'
#' @param dataset_id Character string specifying the dataset ID
#' @param cache_dir Character string specifying cache directory
#'
#' @return Invisible NULL
#' @keywords internal
update_data_download_log <- function(dataset_id, cache_dir = "meta") {
  # Get current LAST_UPDATE from ISTAT
  istat_last_update <- get_dataset_last_update(dataset_id)

  config <- get_istat_config()
  log_file <- file.path(cache_dir, config$cache$data_download_log_file)

  # Load existing log or create new
  download_log <- list()
  if (file.exists(log_file) && file.size(log_file) > 0) {
    download_log <- tryCatch(readRDS(log_file), error = function(e) list())
  }

  # Update entry for this dataset
  download_log[[dataset_id]] <- list(
    downloaded_at = Sys.time(),
    istat_last_update = istat_last_update
  )

  # Ensure cache directory exists
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  # Save updated log
  saveRDS(download_log, log_file)

  invisible(NULL)
}

# 2. Overlap integration helper -----

#' Integrate Downloaded Data with Existing Data
#'
#' Merges newly downloaded data with existing data, deduplicating on all
#' dimension columns plus ObsDimension.
#'
#' @param existing_data data.table of previously downloaded data
#' @param new_data data.table of newly downloaded data
#'
#' @return data.table with merged and deduplicated rows
#' @keywords internal
integrate_downloaded_data <- function(existing_data, new_data) {
  if (!data.table::is.data.table(existing_data)) {
    stop("existing_data must be a data.table")
  }
  if (!data.table::is.data.table(new_data)) {
    stop("new_data must be a data.table")
  }

  # Combine both datasets
  combined <- data.table::rbindlist(list(existing_data, new_data), fill = TRUE)

  # Identify key columns for deduplication (all columns except ObsValue)
  key_cols <- setdiff(names(combined), c("ObsValue", "OBS_VALUE"))

  # Deduplicate: keep the latest (new_data) rows by placing them last
  combined <- unique(combined, by = key_cols, fromLast = TRUE)

  return(combined)
}

#' Download ISTAT Data Split by Frequency
#'
#' Downloads data for a dataset, automatically splitting by frequency if
#' multiple frequencies (A, Q, M) exist. Uses the availableconstraint endpoint
#' to detect available frequencies, then makes separate downloads for each.
#'
#' @inheritParams download_istat_data
#' @param freq Character string specifying a single frequency to download (A, Q, or M).
#'   If NULL (default), downloads all available frequencies. When specified, only
#'   the requested frequency is downloaded, avoiding unnecessary API calls.
#'
#' @return Named list of data.tables by frequency (e.g., list(A = dt, Q = dt)).
#'   Each element contains data for a single frequency. If the dataset has only
#'   one frequency, returns a list with a single element.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download with automatic frequency split
#' data_list <- download_istat_data_by_freq("151_914", start_time = "2020")
#'
#' # Access by frequency
#' annual_data <- data_list$A
#' quarterly_data <- data_list$Q
#'
#' # Download only a specific frequency (more efficient)
#' annual_only <- download_istat_data_by_freq("151_914", start_time = "2020", freq = "A")
#'
#' # Single-frequency dataset
#' job_vacancies <- download_istat_data_by_freq("534_50", start_time = "2024")
#' monthly_data <- job_vacancies$M
#' }
download_istat_data_by_freq <- function(
  dataset_id,
  filter = NULL,
  start_time = "",
  end_time = "",
  incremental = FALSE,
  timeout = NULL,
  verbose = TRUE,
  freq = NULL
) {
  # Get default values from centralized configuration
  config <- get_istat_config()

  if (is.null(timeout)) {
    timeout <- config$defaults$timeout
  }

  # Input validation
  if (!is.character(dataset_id) || length(dataset_id) != 1) {
    stop("dataset_id must be a single character string")
  }

  # If specific frequency requested, download only that one (skip frequency detection)
  if (!is.null(freq)) {
    if (
      !is.character(freq) || length(freq) != 1 || !freq %in% c("A", "Q", "M")
    ) {
      stop("freq must be a single character: 'A', 'Q', or 'M'")
    }

    istat_log(
      paste("Downloading single frequency:", freq, "for", dataset_id),
      "INFO",
      verbose
    )

    # Get dimension count to build correct filter
    dims <- get_dataset_dimensions(dataset_id)
    n_dims <- if (!is.null(dims)) length(dims) else 8

    # Build filter with frequency prefix
    freq_filter <- if (is.null(filter) || filter == "ALL") {
      paste0(freq, paste(rep(".", n_dims - 1), collapse = ""))
    } else {
      paste0(freq, ".", sub("^[^.]*\\.?", "", filter))
    }

    data <- download_istat_data(
      dataset_id,
      filter = freq_filter,
      start_time = start_time,
      end_time = end_time,
      incremental = incremental,
      timeout = timeout,
      verbose = verbose
    )
    result <- list()
    result[[freq]] <- data
    return(result)
  }

  # Get available frequencies (when freq not specified)
  istat_log(
    paste("Checking available frequencies for", dataset_id),
    "INFO",
    verbose
  )
  freqs <- get_available_frequencies(dataset_id)

  if (is.null(freqs) || length(freqs) == 0) {
    # Fallback to single download without frequency filter
    istat_log(
      "Could not determine frequencies, downloading all data",
      "WARNING",
      verbose
    )
    data <- download_istat_data(
      dataset_id,
      filter = filter,
      start_time = start_time,
      end_time = end_time,
      incremental = incremental,
      timeout = timeout,
      verbose = verbose
    )
    return(list(ALL = data))
  }

  istat_log(
    paste("Found frequencies:", paste(freqs, collapse = ", ")),
    "INFO",
    verbose
  )

  if (length(freqs) == 1) {
    # Single frequency - regular download, no need to filter by freq
    data <- download_istat_data(
      dataset_id,
      filter = filter,
      start_time = start_time,
      end_time = end_time,
      incremental = incremental,
      timeout = timeout,
      verbose = verbose
    )
    result <- list()
    result[[freqs]] <- data
    return(result)
  }

  # Get dimension count to build correct filter
  # Need to construct filter with correct number of dots
  dims <- get_dataset_dimensions(dataset_id)
  n_dims <- if (!is.null(dims)) length(dims) else 8 # fallback to common count

  # Multiple frequencies - split downloads
  result <- list()
  for (freq in freqs) {
    # Build filter with frequency prefix
    # SDMX filter syntax: {FREQ}.{dim2}.{dim3}... (dot-separated, first is FREQ)
    freq_filter <- if (is.null(filter) || filter == "ALL") {
      # FREQ followed by n-1 dots for remaining dimensions (all wildcards)
      paste0(freq, paste(rep(".", n_dims - 1), collapse = ""))
    } else {
      # Replace first dimension with freq
      paste0(freq, ".", sub("^[^.]*\\.?", "", filter))
    }

    istat_log(
      paste("Downloading", freq, "data for", dataset_id),
      "INFO",
      verbose
    )

    data <- tryCatch(
      {
        download_istat_data(
          dataset_id,
          filter = freq_filter,
          start_time = start_time,
          end_time = end_time,
          incremental = incremental,
          timeout = timeout,
          verbose = verbose
        )
      },
      error = function(e) {
        warning(
          "Failed to download ",
          freq,
          " data for ",
          dataset_id,
          ": ",
          e$message
        )
        NULL
      }
    )

    if (!is.null(data) && nrow(data) > 0) {
      result[[freq]] <- data
    }
  }

  if (length(result) == 0) {
    warning("No data downloaded for any frequency")
    return(NULL)
  }

  istat_log(
    paste(
      "Downloaded",
      length(result),
      "frequency dataset(s):",
      paste(names(result), collapse = ", ")
    ),
    "INFO",
    verbose
  )

  return(result)
}
