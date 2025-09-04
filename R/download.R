#' Download Data from ISTAT SDMX API
#'
#' Downloads statistical data from the ISTAT (Istituto Nazionale di Statistica)
#' SDMX API for a specified dataset.
#'
#' @param dataset_id Character string specifying the ISTAT dataset ID (e.g., "534_50")
#' @param filter Character string specifying data filters. Default is "ALL"
#' @param start_time Character string specifying the start period (e.g., "2019"). 
#'   If empty, downloads all available data
#' @param timeout Numeric timeout in seconds for the download operation. Default is 240
#'
#' @return A data.table containing the downloaded data with an additional 'id' column
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
#' }
download_istat_data <- function(dataset_id, filter = "ALL", start_time = "", timeout = 240) {
  
  # Input validation
  if (!is.character(dataset_id) || length(dataset_id) != 1) {
    stop("dataset_id must be a single character string")
  }
  
  # Set timeout option
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout))
  options(timeout = timeout)
  
  # Construct time parameter
  if (is.null(start_time) || nchar(start_time) == 0) {
    time_param <- ""
  } else {
    time_param <- paste0("?startPeriod=", start_time)
  }
  
  # Construct API URL
  api_url <- paste0(
    "https://esploradati.istat.it/SDMXWS/rest/data/",
    dataset_id,
    "/",
    filter,
    "/all/",
    time_param
  )
  
  # Download data
  tryCatch({
    result <- readsdmx::read_sdmx(api_url)
    data.table::setDT(result)
    result[, id := dataset_id]
    return(result)
  }, error = function(e) {
    stop("Failed to download data from ISTAT API: ", e$message)
  })
}

#' Download Multiple Datasets
#'
#' Downloads multiple datasets from ISTAT SDMX API in parallel.
#'
#' @param dataset_ids Character vector of ISTAT dataset IDs
#' @param filter Character string specifying data filters. Default is "ALL"
#' @param start_time Character string specifying the start period
#' @param n_cores Integer number of cores to use for parallel processing.
#'   Default is parallel::detectCores() - 1
#'
#' @return A named list of data.tables, one for each dataset
#' @export
#'
#' @examples
#' \dontrun{
#' # Download multiple datasets
#' datasets <- c("534_50", "534_51", "534_52")
#' data_list <- download_multiple_datasets(datasets, start_time = "2020")
#' }
download_multiple_datasets <- function(dataset_ids, filter = "ALL", start_time = "", 
                                     n_cores = parallel::detectCores() - 1) {
  
  if (!is.character(dataset_ids) || length(dataset_ids) == 0) {
    stop("dataset_ids must be a non-empty character vector")
  }
  
  # Use parallel processing
  if (n_cores > 1 && length(dataset_ids) > 1) {
    result <- parallel::mclapply(
      dataset_ids,
      function(id) download_istat_data(id, filter = filter, start_time = start_time),
      mc.cores = n_cores
    )
  } else {
    result <- lapply(
      dataset_ids,
      function(id) download_istat_data(id, filter = filter, start_time = start_time)
    )
  }
  
  names(result) <- dataset_ids
  return(result)
}

#' Check ISTAT API Status
#'
#' Checks if the ISTAT SDMX API is accessible.
#'
#' @param timeout Numeric timeout in seconds for the check. Default is 10
#'
#' @return Logical indicating if the API is accessible
#' @export
#'
#' @examples
#' \dontrun{
#' if (check_istat_api()) {
#'   # Proceed with data download
#' }
#' }
check_istat_api <- function(timeout = 10) {
  test_url <- "https://esploradati.istat.it/SDMXWS/rest/dataflow"
  
  tryCatch({
    # Set timeout
    old_timeout <- getOption("timeout")
    on.exit(options(timeout = old_timeout))
    options(timeout = timeout)
    
    # Try to access the API
    response <- readLines(test_url, n = 1, warn = FALSE)
    return(TRUE)
  }, error = function(e) {
    message("ISTAT API is not accessible: ", e$message)
    return(FALSE)
  })
}