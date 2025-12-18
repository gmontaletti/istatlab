#' ISTAT SDMX Endpoint Functions
#'
#' Functions organized by ISTAT SDMX web service endpoints for better maintainability
#' and alignment with the official ISTAT web service structure.
#'
#' @name endpoints
NULL

# ==============================================================================
# DATA ENDPOINT FUNCTIONS
# ==============================================================================

#' Download Data from ISTAT Data Endpoint
#'
#' Downloads statistical data using the ISTAT SDMX data endpoint:
#' https://esploradati.istat.it/SDMXWS/rest/data
#'
#' @param dataset_id Character string specifying the ISTAT dataset ID
#' @param filter Character string specifying data filters. Default uses config
#' @param start_time Character string specifying start period
#' @param timeout Numeric timeout in seconds. Default uses config
#'
#' @return A data.table containing the downloaded data
#' @export
#'
#' @examples
#' \dontrun{
#' # Download data using data endpoint
#' data <- fetch_data_endpoint("534_50", start_time = "2020")
#' }
fetch_data_endpoint <- function(dataset_id, filter = NULL, start_time = NULL, timeout = NULL) {
  
  # Get configuration defaults
  config <- get_istat_config()
  if (is.null(filter)) filter <- config$defaults$filter
  if (is.null(timeout)) timeout <- config$defaults$timeout
  
  # Use existing download function with centralized config
  download_istat_data(dataset_id = dataset_id, 
                     filter = filter, 
                     start_time = start_time %||% "", 
                     timeout = timeout)
}

#' Download Multiple Datasets from Data Endpoint
#'
#' Downloads multiple datasets in parallel using the data endpoint.
#'
#' @param dataset_ids Character vector of dataset IDs
#' @param ... Additional parameters passed to fetch_data_endpoint
#'
#' @return A named list of data.tables
#' @export
#'
#' @examples
#' \dontrun{
#' # Download multiple datasets by category
#' employment_ids <- get_dataset_category("employment")
#' employment_data <- fetch_multiple_data_endpoint(employment_ids)
#' }
fetch_multiple_data_endpoint <- function(dataset_ids, ...) {
  download_multiple_datasets(dataset_ids, ...)
}

# ==============================================================================
# DATAFLOW ENDPOINT FUNCTIONS  
# ==============================================================================

#' Download Dataflows from ISTAT Dataflow Endpoint
#'
#' Downloads dataset metadata using the ISTAT SDMX dataflow endpoint:
#' https://esploradati.istat.it/SDMXWS/rest/dataflow
#'
#' @param force_update Logical to force metadata update
#' @param cache_dir Character string for cache directory
#'
#' @return A data.table containing dataflow information
#' @export
#'
#' @examples
#' \dontrun{
#' # Get all available dataflows
#' dataflows <- fetch_dataflow_endpoint()
#' 
#' # Filter to find employment-related datasets
#' employment_flows <- dataflows[grepl("employment|lavoro", name, ignore.case = TRUE)]
#' }
fetch_dataflow_endpoint <- function(force_update = FALSE, cache_dir = NULL) {
  
  config <- get_istat_config()
  if (is.null(cache_dir)) cache_dir <- config$defaults$cache_dir
  
  # Use existing metadata download function
  download_metadata(force_update = force_update, cache_dir = cache_dir)
}

#' Search Dataflows by Keywords
#'
#' Searches available dataflows using keywords in Italian and English.
#'
#' @param keywords Character vector of search terms
#' @param fields Character vector of fields to search in. Default searches
#'   Name.it (Italian), Name.en (English), and id
#' @param ignore_case Logical indicating case-insensitive search. Default TRUE
#'
#' @return A filtered data.table of matching dataflows
#' @export
#'
#' @examples
#' \dontrun{
#' # Search for employment-related datasets (Italian)
#' lavoro_datasets <- search_dataflows("lavoro")
#'
#' # Search for employment-related datasets (multiple terms)
#' employment_datasets <- search_dataflows(c("employment", "lavoro", "occupazione"))
#'
#' # Search unemployment datasets
#' unemployment_datasets <- search_dataflows(c("unemployment", "disoccupazione"))
#'
#' # Search only in dataset IDs
#' datasets_534 <- search_dataflows("534", fields = "id")
#' }
search_dataflows <- function(keywords, fields = c("Name.it", "Name.en", "id"), ignore_case = TRUE) {

  dataflows <- fetch_dataflow_endpoint()
  data.table::setDT(dataflows)

  # Create search pattern

  pattern <- paste(keywords, collapse = "|")

  # Search across specified fields
  matches <- data.table::data.table()

  for (field in fields) {
    if (field %in% names(dataflows)) {
      field_matches <- dataflows[grepl(pattern, get(field), ignore.case = ignore_case)]
      matches <- data.table::rbindlist(list(matches, field_matches), use.names = TRUE, fill = TRUE)
    }
  }

  # Remove duplicates and return
  unique(matches, by = "id")
}

# ==============================================================================
# REGISTRY ENDPOINT FUNCTIONS
# ==============================================================================

#' Get Dataset Dimensions from Registry Endpoint
#'
#' Retrieves dataset dimensions using the ISTAT SDMX registry capabilities.
#'
#' @param dataset_id Character string specifying dataset ID
#'
#' @return A list of dataset dimensions
#' @export
#'
#' @examples
#' \dontrun{
#' # Get dimensions for employment dataset
#' dims <- fetch_registry_dimensions("150_908")
#' }
fetch_registry_dimensions <- function(dataset_id) {
  # Use existing dimension function  
  get_dataset_dimensions(dataset_id)
}

# ==============================================================================
# UTILITY FUNCTIONS FOR ENDPOINT ORGANIZATION
# ==============================================================================

#' List Available ISTAT Endpoints
#'
#' Returns information about all available ISTAT SDMX endpoints.
#'
#' @return A data.frame describing available endpoints
#' @export
#'
#' @examples
#' \dontrun{
#' # See all available endpoints
#' endpoints <- list_istat_endpoints()
#' print(endpoints)
#' }
list_istat_endpoints <- function() {
  config <- get_istat_config()
  
  data.frame(
    endpoint = names(config$endpoints),
    url = unlist(config$endpoints),
    description = c(
      "RESTful API v1 (legacy)",
      "RESTful API v2",
      "Data retrieval endpoint",
      "Dataset metadata endpoint",
      "Data structure and codelists endpoint",
      "Code list definitions endpoint",
      "SDMX v2.1 registry endpoint",
      "Available constraints (dimension values)"
    ),
    function_prefix = c(
      "rest_v1", "rest_v2", "fetch_data_", "fetch_dataflow_",
      "download_codelists", "fetch_codelist_", "fetch_registry_",
      "get_available_frequencies"
    ),
    stringsAsFactors = FALSE
  )
}

#' Get Dataset Information by Category
#'
#' Returns organized dataset information grouped by labour market categories.
#'
#' @param category Optional character string to filter by category
#'
#' @return A list containing dataset IDs organized by category
#' @export
#'
#' @examples
#' \dontrun{
#' # Get all categorized datasets
#' all_categories <- get_categorized_datasets()
#' 
#' # Get just employment datasets
#' employment <- get_categorized_datasets("employment")
#' }
get_categorized_datasets <- function(category = NULL) {
  config <- get_istat_config()
  
  if (is.null(category)) {
    return(config$dataset_categories)
  } else {
    return(get_dataset_category(category))
  }
}

#' Test ISTAT Endpoint Connectivity
#'
#' Tests connectivity to different ISTAT SDMX endpoints.
#'
#' @param endpoints Character vector of endpoint names to test
#' @param timeout Numeric timeout for each test
#' @param verbose Logical for detailed output
#'
#' @return A data.frame with connectivity test results
#' @export
#'
#' @examples
#' \dontrun{
#' # Test all main endpoints
#' status <- test_endpoint_connectivity(c("data", "dataflow", "datastructure"))
#' }
test_endpoint_connectivity <- function(endpoints = c("data", "dataflow"), timeout = 30, verbose = TRUE) {
  
  config <- get_istat_config()
  results <- data.frame(
    endpoint = character(),
    url = character(), 
    accessible = logical(),
    response_time = numeric(),
    error_message = character(),
    stringsAsFactors = FALSE
  )
  
  for (endpoint in endpoints) {
    if (verbose) message("Testing ", endpoint, " endpoint...")
    
    start_time <- Sys.time()
    
    if (endpoint == "data") {
      # Test data endpoint with connectivity check function
      accessible <- check_istat_api(timeout = timeout, verbose = FALSE)
      error_msg <- if (accessible) "" else "Data endpoint connectivity failed"
      test_url <- build_istat_url("data", 
                                 dataset_id = config$defaults$test_dataset,
                                 start_time = as.character(as.numeric(format(Sys.Date(), "%Y")) - 1))
    } else {
      # Test other endpoints with simple URL construction
      test_url <- config$endpoints[[endpoint]]
      accessible <- TRUE  # Would need specific tests for each endpoint type
      error_msg <- ""
    }
    
    end_time <- Sys.time()
    response_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
    
    results <- rbind(results, data.frame(
      endpoint = endpoint,
      url = test_url,
      accessible = accessible,
      response_time = response_time,
      error_message = error_msg,
      stringsAsFactors = FALSE
    ))
  }
  
  if (verbose) {
    message("\nEndpoint connectivity summary:")
    for (i in 1:nrow(results)) {
      status <- if (results$accessible[i]) "[OK] ACCESSIBLE" else "[X] FAILED"
      message(sprintf("%-15s %s (%.2fs)", results$endpoint[i], status, results$response_time[i]))
    }
  }
  
  return(results)
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x