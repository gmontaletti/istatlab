#' Download Data from ISTAT SDMX API
#'
#' Downloads statistical data from the ISTAT (Istituto Nazionale di Statistica)
#' SDMX API for a specified dataset. Uses centralized configuration for default values.
#'
#' @param dataset_id Character string specifying the ISTAT dataset ID (e.g., "534_50")
#' @param filter Character string specifying data filters. Default uses config value ("ALL")
#' @param start_time Character string specifying the start period (e.g., "2019").
#'   If empty, downloads all available data
#' @param timeout Numeric timeout in seconds for the download operation. Default uses config value
#' @param verbose Logical indicating whether to print status messages. Default is TRUE
#' @param updated_after POSIXct timestamp. If provided, only data updated since this time
#'   will be retrieved. Used for incremental update detection.
#'
#' @return A data.table containing the downloaded data with an additional 'id' column,
#'   or NULL if the download fails
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
#' # Download only data updated since a specific timestamp
#' timestamp <- as.POSIXct("2025-12-10 14:30:00", tz = "UTC")
#' data <- download_istat_data("534_50", updated_after = timestamp)
#' }
download_istat_data <- function(dataset_id, filter = NULL, start_time = "",
                                timeout = NULL, verbose = TRUE,
                                updated_after = NULL) {
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

  if (verbose) {
    message("Downloading dataset ", dataset_id, "...")
  }

  # Set timeout option
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout))
  options(timeout = timeout)

  # Construct API URL using centralized configuration
  api_url <- build_istat_url("data",
                            dataset_id = dataset_id,
                            filter = filter,
                            start_time = start_time,
                            updated_after = updated_after)

  # Download data
  tryCatch({
    result <- readsdmx::read_sdmx(api_url)
    data.table::setDT(result)
    result[, id := dataset_id]

    if (verbose) {
      message("Downloaded ", nrow(result), " rows for dataset ", dataset_id)
    }

    return(result)
  }, error = function(e) {
    # Check if it's a timeout or connectivity issue
    if (grepl("timeout|Timeout|timed out", e$message, ignore.case = TRUE)) {
      warning("ISTAT API request timed out after ", timeout, " seconds. ",
              "The server may be experiencing high load. Please try again later.")
      return(NULL)
    } else if (grepl("resolve|connection|network|internet", e$message, ignore.case = TRUE)) {
      warning("Cannot connect to ISTAT API. Please check your internet connection ",
              "or try again later. Error: ", e$message)
      return(NULL)
    } else {
      # For other errors, provide informative message but don't stop execution
      warning("Failed to download data from ISTAT API: ", e$message,
              ". Dataset: ", dataset_id)
      return(NULL)
    }
  })
}

#' Download Multiple Datasets
#'
#' Downloads multiple datasets from ISTAT SDMX API in parallel.
#' Uses centralized configuration for default values.
#'
#' @param dataset_ids Character vector of ISTAT dataset IDs
#' @param filter Character string specifying data filters. Default uses config value ("ALL")
#' @param start_time Character string specifying the start period
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
download_multiple_datasets <- function(dataset_ids, filter = NULL, start_time = "",
                                       n_cores = parallel::detectCores() - 1,
                                       verbose = TRUE, updated_after = NULL) {
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
    download_istat_data(id,
                       filter = filter,
                       start_time = start_time,
                       verbose = verbose,
                       updated_after = updated_after)
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
    message("Download complete: ", successful, " of ", length(dataset_ids), " datasets successful")
  }

  return(result)
}

#' Check ISTAT API Status
#'
#' Checks if the ISTAT SDMX API is accessible by testing an actual data endpoint
#' using the same method as the download functions. Uses centralized configuration
#' for default values.
#'
#' @param timeout Numeric timeout in seconds for the check. Default uses config value
#' @param test_dataset Character string specifying a lightweight dataset to test.
#'   Default uses config value (job vacancies dataset)
#' @param verbose Logical indicating whether to print detailed messages.
#'   Default is TRUE
#' @param skip Logical indicating whether to skip the check and return TRUE.
#'   Useful for offline development or when API status is already known. Default is FALSE
#'
#' @return Logical indicating if the API is accessible (always TRUE if skip = TRUE)
#' @export
#'
#' @examples
#' \dontrun{
#' # Check API status with default settings
#' if (check_istat_api()) {
#'   # Proceed with data download
#' }
#'
#' # Quick check with shorter timeout
#' if (check_istat_api(timeout = 10, verbose = FALSE)) {
#'   # Proceed with data download
#' }
#' }
check_istat_api <- function(timeout = NULL, test_dataset = NULL, verbose = TRUE, skip = FALSE) {

  # Skip check if requested
  if (isTRUE(skip)) {
    if (verbose) {
      message("API check skipped by user request")
    }
    return(TRUE)
  }

  # Get default values from centralized configuration
  config <- get_istat_config()

  if (is.null(timeout)) {
    # Use adequate timeout for API checks to handle cold starts and network variability
    # Allow at least 60 seconds to account for SSL handshake, DNS resolution, etc.
    timeout <- max(60, min(config$defaults$timeout, 120))
  }

  if (is.null(test_dataset)) {
    test_dataset <- config$defaults$test_dataset
  }

  # Input validation
  if (!is.character(test_dataset) || length(test_dataset) != 1) {
    stop("test_dataset must be a single character string")
  }

  if (verbose) {
    message("Checking ISTAT API connectivity...")
  }

  # Create a lightweight test URL - get only recent data with minimal filter
  # Use a recent year to minimize data transfer
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  test_year <- current_year - 1  # Use previous year to ensure data exists

  # Build test URL using centralized configuration
  test_url <- build_istat_url("data",
                             dataset_id = test_dataset,
                             filter = "ALL",
                             start_time = as.character(test_year))

  api_status <- tryCatch({
    # Set timeout option
    old_timeout <- getOption("timeout")
    on.exit(options(timeout = old_timeout))
    options(timeout = timeout)

    # Test using the same method as actual download functions
    result <- readsdmx::read_sdmx(test_url)

    # Check if we got valid data
    if (is.null(result) || nrow(result) == 0) {
      if (verbose) {
        message("ISTAT API responded but returned no data for test dataset: ", test_dataset)
      }
      FALSE
    } else {
      # API is accessible and returning data
      if (verbose) {
        message("ISTAT API is accessible. Test returned ", nrow(result), " rows from dataset ", test_dataset)
      }
      TRUE
    }

  }, error = function(e) {
    if (verbose) {
      # Provide more specific error information
      error_msg <- e$message
      if (grepl("timeout|Timeout", error_msg, ignore.case = TRUE)) {
        message("ISTAT API connectivity check failed: Connection timeout after ", timeout, " seconds")
      } else if (grepl("resolve|connection", error_msg, ignore.case = TRUE)) {
        message("ISTAT API connectivity check failed: Cannot connect to server (", error_msg, ")")
      } else {
        message("ISTAT API connectivity check failed: ", error_msg)
      }
    }
    FALSE
  })

  return(api_status)
}
