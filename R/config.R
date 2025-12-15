#' ISTAT SDMX Web Service Configuration
#'
#' Centralized configuration for ISTAT SDMX web service endpoints and settings.
#' This provides a single source of truth for API URLs and service parameters.
#'
#' @name istat_config
NULL

#' Get ISTAT SDMX Service Configuration
#'
#' Returns the configuration for ISTAT SDMX web service including all available
#' endpoints and cache settings based on the official service at https://esploradati.istat.it/SDMXWS.
#'
#' @return A list containing ISTAT SDMX service configuration with the following components:
#'   \itemize{
#'     \item{base_url}: Base URL for ISTAT SDMX web service
#'     \item{endpoints}: List of available API endpoints
#'     \item{provider}: Service provider configuration for rsdmx
#'     \item{defaults}: Default settings for API calls
#'     \item{cache}: Cache configuration with TTL settings for different data types
#'     \item{dataset_categories}: Organized dataset categories
#'     \item{update_tracking}: Configuration for dataset update detection using updatedAfter parameter
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' # Get service configuration
#' config <- get_istat_config()
#' print(config$endpoints$data)
#' print(config$cache$enabled)
#' }
get_istat_config <- function() {
  list(
    # Base service URL
    base_url = "https://esploradati.istat.it/SDMXWS",
    
    # Available SDMX versions and endpoints
    endpoints = list(
      # RESTful API endpoints (primary)
      rest_v1 = "https://esploradati.istat.it/SDMXWS/rest",
      rest_v2 = "https://esploradati.istat.it/SDMXWS/rest/v2",
      
      # Data endpoint pattern
      data = "https://esploradati.istat.it/SDMXWS/rest/data",
      
      # Metadata endpoints
      dataflow = "https://esploradati.istat.it/SDMXWS/rest/dataflow",
      datastructure = "https://esploradati.istat.it/SDMXWS/rest/datastructure",
      codelist = "https://esploradati.istat.it/SDMXWS/rest/codelist",
      
      # Registry endpoint (SDMX v2.1)
      registry = "https://esploradati.istat.it/SDMXWS/rest/registry"
    ),
    
    # Service provider configuration for rsdmx
    provider = list(
      agencyId = "ISTAT2",
      name = "Istituto nazionale di statistica (Italia)",
      scale = "national",
      country = "ITA",
      regUrl = "https://esploradati.istat.it/SDMXWS/rest",
      repoUrl = "https://esploradati.istat.it/SDMXWS/rest",
      compliant = TRUE
    ),
    
    # Default settings
    defaults = list(
      timeout = 240,
      filter = "ALL",
      cache_days = 14,
      cache_dir = "meta",
      test_dataset = "534_50"  # Lightweight dataset for connectivity testing
    ),
    
    # Common dataset categories for organization
    dataset_categories = list(
      employment = c("150_908", "150_915", "150_916"), # Monthly/quarterly employment
      unemployment = c("151_914", "151_915"),          # Unemployment rates
      job_vacancies = c("534_50", "534_51", "534_52"), # Job vacancies
      labour_force = c("152_914", "152_915")           # Labour force statistics
    ),

    # Update tracking configuration
    update_tracking = list(
      enabled = TRUE,
      timestamp_file = "meta/dataset_timestamps.json",
      rate_limit_delay = 12,  # seconds between API requests (5 req/min limit)
      check_timeout = 30      # timeout for update checks (shorter than downloads)
    ),

    # HTTP request configuration for CSV downloads
    http = list(
      accept_csv = "application/vnd.sdmx.data+csv;version=1.0.0",
      accept_xml = "application/vnd.sdmx.structurespecificdata+xml;version=2.1",
      user_agent = "istatlab R package (https://github.com/gmontaletti/istatlab)"
    )
  )
}

#' Build ISTAT API URL
#'
#' Constructs API URLs for different ISTAT SDMX endpoints using centralized configuration.
#'
#' @param endpoint Character string specifying the endpoint type
#'   ("data", "dataflow", "datastructure", "codelist")
#' @param dataset_id Character string specifying dataset ID (required for data endpoint)
#' @param filter Character string specifying data filters (for data endpoint)
#' @param start_time Character string specifying start period (for data endpoint)
#' @param dsd_ref Character string specifying data structure reference (for datastructure)
#' @param updated_after POSIXct timestamp. If provided, the URL will include the updatedAfter
#'   parameter to retrieve only data changed since this time. Used for incremental update detection.
#'
#' @return Character string containing the constructed API URL
#' @export
#'
#' @examples
#' \dontrun{
#' # Build data URL
#' url <- build_istat_url("data", dataset_id = "534_50", start_time = "2020")
#'
#' # Build dataflow URL
#' url <- build_istat_url("dataflow")
#'
#' # Build datastructure URL
#' url <- build_istat_url("datastructure", dsd_ref = "DSD_534_50")
#'
#' # Build data URL with update detection
#' timestamp <- as.POSIXct("2025-12-10 14:30:00", tz = "UTC")
#' url <- build_istat_url("data", dataset_id = "534_50", updated_after = timestamp)
#' }
build_istat_url <- function(endpoint, dataset_id = NULL, filter = "ALL",
                           start_time = NULL, dsd_ref = NULL,
                           updated_after = NULL) {
  
  config <- get_istat_config()
  base_endpoint <- config$endpoints[[endpoint]]
  
  if (is.null(base_endpoint)) {
    stop("Unknown endpoint: ", endpoint, 
         ". Available endpoints: ", paste(names(config$endpoints), collapse = ", "))
  }
  
  switch(endpoint,
    "data" = {
      if (is.null(dataset_id)) {
        stop("dataset_id is required for data endpoint")
      }

      # Build data URL: /data/{dataset_id}/{filter}/all/{?startPeriod&updatedAfter}
      query_params <- character(0)

      # Add startPeriod parameter if provided
      if (!is.null(start_time) && nchar(start_time) > 0) {
        query_params <- c(query_params, paste0("startPeriod=", start_time))
      }

      # Add updatedAfter parameter if provided
      if (!is.null(updated_after)) {
        # Validate that updated_after is a POSIXct object
        if (!inherits(updated_after, "POSIXct")) {
          stop("updated_after must be a POSIXct timestamp")
        }

        # Format as ISO 8601 timestamp
        iso_timestamp <- format(updated_after, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

        # URL-encode the timestamp
        encoded_timestamp <- utils::URLencode(iso_timestamp, reserved = TRUE)

        query_params <- c(query_params, paste0("updatedAfter=", encoded_timestamp))
      }

      # Combine query parameters
      query_string <- if (length(query_params) > 0) {
        paste0("?", paste(query_params, collapse = "&"))
      } else {
        ""
      }

      paste0(base_endpoint, "/", dataset_id, "/", filter, "/all/", query_string)
    },
    
    "datastructure" = {
      if (is.null(dsd_ref)) {
        stop("dsd_ref is required for datastructure endpoint")
      }
      
      # Build datastructure URL: /datastructure/IT1/{dsd_ref}/1.0?references=children
      paste0(base_endpoint, "/IT1/", dsd_ref, "/1.0?references=children")
    },
    
    "dataflow" = {
      # Simple dataflow endpoint
      base_endpoint
    },
    
    "codelist" = {
      # Simple codelist endpoint  
      base_endpoint
    },
    
    # Default: return base endpoint
    base_endpoint
  )
}

#' Get ISTAT Service Provider
#'
#' Creates and returns an ISTAT SDMX service provider for use with rsdmx package.
#'
#' @return An rsdmx SDMXServiceProvider object
#' @export
#'
#' @examples
#' \dontrun{
#' # Get service provider
#' provider <- get_istat_provider()
#' rsdmx::addSDMXServiceProvider(provider)
#' }
get_istat_provider <- function() {
  if (!requireNamespace("rsdmx", quietly = TRUE)) {
    stop("Package 'rsdmx' is required for ISTAT service provider")
  }
  
  config <- get_istat_config()
  
  rsdmx::SDMXServiceProvider(
    agencyId = config$provider$agencyId,
    name = config$provider$name,
    scale = config$provider$scale,
    country = config$provider$country,
    builder = rsdmx::SDMXREST21RequestBuilder(
      regUrl = config$provider$regUrl,
      repoUrl = config$provider$repoUrl,
      compliant = config$provider$compliant
    )
  )
}

#' Get Dataset Category
#'
#' Returns datasets belonging to a specific category for easier organization.
#'
#' @param category Character string specifying the category 
#'   ("employment", "unemployment", "job_vacancies", "labour_force")
#'
#' @return Character vector of dataset IDs in the category
#' @export
#'
#' @examples
#' \dontrun{
#' # Get employment datasets
#' employment_datasets <- get_dataset_category("employment")
#' 
#' # Get all available categories
#' config <- get_istat_config()
#' categories <- names(config$dataset_categories)
#' }
get_dataset_category <- function(category) {
  config <- get_istat_config()
  
  if (!category %in% names(config$dataset_categories)) {
    stop("Unknown category: ", category,
         ". Available categories: ", paste(names(config$dataset_categories), collapse = ", "))
  }
  
  config$dataset_categories[[category]]
}