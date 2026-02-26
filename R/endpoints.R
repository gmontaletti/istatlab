#' ISTAT SDMX Endpoint Functions
#'
#' Functions organized by ISTAT SDMX web service endpoints for better maintainability
#' and alignment with the official ISTAT web service structure.
#'
#' @name endpoints
NULL

# ==============================================================================
# DATAFLOW ENDPOINT FUNCTIONS
# ==============================================================================

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
search_dataflows <- function(
  keywords,
  fields = c("Name.it", "Name.en", "id"),
  ignore_case = TRUE
) {
  dataflows <- download_metadata()
  data.table::setDT(dataflows)

  # Create search pattern

  pattern <- paste(keywords, collapse = "|")

  # Search across specified fields
  matches <- data.table::data.table()

  for (field in fields) {
    if (field %in% names(dataflows)) {
      field_matches <- dataflows[grepl(
        pattern,
        get(field),
        ignore.case = ignore_case
      )]
      matches <- data.table::rbindlist(
        list(matches, field_matches),
        use.names = TRUE,
        fill = TRUE
      )
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

  # Legacy SDMX endpoints
  legacy_df <- data.frame(
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
      "rest_v1",
      "rest_v2",
      "fetch_data_",
      "fetch_dataflow_",
      "download_codelists",
      "fetch_codelist_",
      "fetch_registry_",
      "get_available_frequencies"
    ),
    stringsAsFactors = FALSE
  )

  # HVD (High Value Datasets) endpoints
  hvd_df <- data.frame(
    endpoint = c(
      "hvd_v1_data",
      "hvd_v1_dataflow",
      "hvd_v1_structure",
      "hvd_v2_data",
      "hvd_v2_structure",
      "hvd_v2_availability"
    ),
    url = c(
      config$hvd$v1$data,
      config$hvd$v1$dataflow,
      config$hvd$v1$datastructure,
      config$hvd$v2$data,
      config$hvd$v2$structure,
      config$hvd$v2$availability
    ),
    description = c(
      "HVD v1 data retrieval (SDMX 2.1)",
      "HVD v1 dataflow listing",
      "HVD v1 data structure",
      "HVD v2 data retrieval (SDMX 3.0)",
      "HVD v2 structure queries",
      "HVD v2 data availability"
    ),
    function_prefix = c(
      "download_hvd_",
      "list_hvd_",
      "hvd_get_",
      "download_hvd_",
      "hvd_get_",
      "hvd_get_"
    ),
    stringsAsFactors = FALSE
  )

  # Combine legacy and HVD endpoints
  rbind(legacy_df, hvd_df)
}

#' Get Dataset Information by Category
#'
#' Returns organized dataset information grouped by statistical categories.
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

# 1. check_endpoint_status -----

#' Check Endpoint HTTP Status
#'
#' Lightweight connectivity check using httr.
#' Fetches only response headers (status code) without downloading body.
#'
#' @param url Character URL to check
#' @param timeout Numeric timeout in seconds (default 10)
#'
#' @return A list with accessible (logical), status_code, response_time, error
#' @keywords internal
check_endpoint_status <- function(url, timeout = 10) {
  throttle()
  start_time <- Sys.time()

  tryCatch(
    {
      response <- httr::HEAD(url, httr::timeout(timeout))

      end_time <- Sys.time()
      response_time <- as.numeric(difftime(
        end_time,
        start_time,
        units = "secs"
      ))

      status <- as.integer(httr::status_code(response))

      list(
        accessible = status %in% c(200L, 302L, 400L),
        status_code = status,
        response_time = response_time,
        error = ""
      )
    },
    error = function(e) {
      end_time <- Sys.time()
      response_time <- as.numeric(difftime(
        end_time,
        start_time,
        units = "secs"
      ))

      list(
        accessible = FALSE,
        status_code = NA_integer_,
        response_time = response_time,
        error = e$message
      )
    }
  )
}

#' Test ISTAT Endpoint Connectivity
#'
#' Tests connectivity to ISTAT SDMX endpoints using lightweight HTTP status checks.
#'
#' @param endpoints Character vector of endpoint names to test (default "data").
#'   Available: "data", "dataflow", "datastructure", "codelist", "registry", "availableconstraint"
#' @param timeout Numeric timeout in seconds for each test (default 30)
#' @param verbose Logical for detailed output
#'
#' @return A data.frame with connectivity test results including:
#'   endpoint, url, accessible, status_code, response_time, error_message
#' @export
#'
#' @examples
#' \dontrun{
#' # Quick connectivity check (default: data endpoint only)
#' status <- test_endpoint_connectivity()
#'
#' # Test multiple endpoints
#' status <- test_endpoint_connectivity(c("data", "dataflow"))
#' }
test_endpoint_connectivity <- function(
  endpoints = "data",
  timeout = 30,
  verbose = TRUE
) {
  config <- get_istat_config()

  # Build complete endpoint URL map (legacy + HVD)
  all_endpoints <- c(
    config$endpoints,
    list(
      hvd_v1_data = config$hvd$v1$data,
      hvd_v1_dataflow = config$hvd$v1$dataflow,
      hvd_v1_structure = config$hvd$v1$datastructure,
      hvd_v2_data = config$hvd$v2$data,
      hvd_v2_structure = config$hvd$v2$structure,
      hvd_v2_availability = config$hvd$v2$availability
    )
  )
  available_endpoints <- names(all_endpoints)

  # Validate endpoints

  invalid <- setdiff(endpoints, available_endpoints)
  if (length(invalid) > 0) {
    stop(
      "Unknown endpoint(s): ",
      paste(invalid, collapse = ", "),
      ". Available: ",
      paste(available_endpoints, collapse = ", ")
    )
  }

  results <- data.frame(
    endpoint = character(),
    url = character(),
    accessible = logical(),
    status_code = integer(),
    response_time = numeric(),
    error_message = character(),
    stringsAsFactors = FALSE
  )

  for (endpoint in endpoints) {
    if (verbose) {
      message("Testing ", endpoint, " endpoint...")
    }

    test_url <- all_endpoints[[endpoint]]
    status <- check_endpoint_status(test_url, timeout = timeout)

    results <- rbind(
      results,
      data.frame(
        endpoint = endpoint,
        url = test_url,
        accessible = status$accessible,
        status_code = status$status_code,
        response_time = status$response_time,
        error_message = status$error,
        stringsAsFactors = FALSE
      )
    )
  }

  if (verbose) {
    message("\nEndpoint connectivity summary:")
    for (i in seq_len(nrow(results))) {
      status_text <- if (results$accessible[i]) "[OK]" else "[X]"
      code_text <- if (is.na(results$status_code[i])) {
        "ERR"
      } else {
        results$status_code[i]
      }
      time_text <- if (is.na(results$response_time[i])) {
        "-"
      } else {
        sprintf("%.2fs", results$response_time[i])
      }
      message(sprintf(
        "%-20s %s %s (%s)",
        results$endpoint[i],
        status_text,
        code_text,
        time_text
      ))
    }
  }

  return(results)
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x
