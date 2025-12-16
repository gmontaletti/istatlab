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
#' @param return_result Logical indicating whether to return full istat_result object
#'   instead of just the data.table. Default is FALSE for backward compatibility.
#'
#' @return A data.table containing the downloaded data with an additional 'id' column,
#'   or NULL if the download fails. If return_result = TRUE, returns an istat_result
#'   object with additional metadata (exit_code, md5, message, is_timeout).
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
#'
#' # Get full result with metadata
#' result <- download_istat_data("534_50", return_result = TRUE)
#' if (result$success) {
#'   print(paste("Downloaded", nrow(result$data), "rows, MD5:", result$md5))
#' }
#' }
download_istat_data <- function(dataset_id, filter = NULL, start_time = "",
                                timeout = NULL, verbose = TRUE,
                                updated_after = NULL, return_result = FALSE) {
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

  istat_log(paste("Downloading dataset", dataset_id), "INFO", verbose)

  # Construct API URL using centralized configuration
  api_url <- build_istat_url("data",
                            dataset_id = dataset_id,
                            filter = filter,
                            start_time = start_time,
                            updated_after = updated_after)

  # HTTP request using new transport layer
  http_result <- http_get(api_url, timeout = timeout, verbose = verbose)

  # Process response using new processor
  result <- process_api_response(http_result, verbose)

  # Handle failure
  if (!result$success) {
    warning("Failed to download data for dataset: ", dataset_id, " - ", result$message)
    if (return_result) return(result)
    return(NULL)
  }

  # Add dataset identifier column
  result$data[, id := dataset_id]

  md5_info <- if (!is.na(result$md5)) paste(" (MD5:", substr(result$md5, 1, 8), "...)") else ""
  istat_log(paste("Downloaded", nrow(result$data), "rows for dataset", dataset_id, md5_info),
            "INFO", verbose)

  # Return based on preference
  if (return_result) {
    return(result)
  }

  result$data
}

#' Download Data with Full Result Information
#'
#' Downloads data and returns structured result with exit code and checksum.
#' Useful for automated pipelines and batch processing.
#'
#' @inheritParams download_istat_data
#'
#' @return An istat_result object with components:
#'   \itemize{
#'     \item{success}: Logical indicating if download succeeded
#'     \item{data}: data.table with downloaded data (or NULL)
#'     \item{exit_code}: Integer (0=success, 1=error, 2=timeout)
#'     \item{message}: Character message describing result
#'     \item{md5}: MD5 checksum of data (or NA if digest not available)
#'     \item{is_timeout}: Logical indicating timeout failure
#'     \item{timestamp}: POSIXct timestamp when result was created
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' # Download with full result information
#' result <- download_istat_data_full("534_50", start_time = "2024")
#'
#' if (result$success) {
#'   cat("Downloaded", nrow(result$data), "rows\n")
#'   cat("MD5:", result$md5, "\n")
#' } else {
#'   cat("Download failed:", result$message, "\n")
#'   cat("Exit code:", result$exit_code, "\n")
#'   if (result$is_timeout) {
#'     cat("Failure was due to timeout\n")
#'   }
#' }
#' }
download_istat_data_full <- function(dataset_id, filter = NULL, start_time = "",
                                     timeout = NULL, verbose = TRUE,
                                     updated_after = NULL) {
  download_istat_data(
    dataset_id = dataset_id,
    filter = filter,
    start_time = start_time,
    timeout = timeout,
    verbose = verbose,
    updated_after = updated_after,
    return_result = TRUE
  )
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

  istat_log("Checking ISTAT API connectivity...", "INFO", verbose)

  # Create a lightweight test URL - get only recent data with minimal filter
  # Use a recent year to minimize data transfer
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  test_year <- current_year - 1  # Use previous year to ensure data exists

  # Build test URL using centralized configuration
  test_url <- build_istat_url("data",
                             dataset_id = test_dataset,
                             filter = "ALL",
                             start_time = as.character(test_year))

  # Test using new HTTP transport layer
  http_result <- http_get(test_url, timeout = timeout, verbose = FALSE)
  result <- process_api_response(http_result, verbose = FALSE)

  # Check if we got valid data
  if (!result$success || is.null(result$data) || nrow(result$data) == 0) {
    istat_log(
      paste("ISTAT API connectivity check failed:", result$message),
      "WARNING", verbose
    )
    return(FALSE)
  }

  # API is accessible and returning data
  istat_log(
    paste("ISTAT API is accessible. Test returned", nrow(result$data), "rows from dataset", test_dataset),
    "INFO", verbose
  )
  return(TRUE)
}
