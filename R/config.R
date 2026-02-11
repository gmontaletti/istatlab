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
#'     \item{defaults}: Default settings for API calls
#'     \item{dataset_categories}: Organized dataset categories
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
      registry = "https://esploradati.istat.it/SDMXWS/rest/registry",

      # Available constraint endpoint (for dimension values)
      availableconstraint = "https://esploradati.istat.it/SDMXWS/rest/availableconstraint"
    ),

    # Default settings
    defaults = list(
      timeout = 240,
      filter = "ALL",
      cache_days = 14,
      cache_dir = "meta",
      test_dataset = "534_50" # Lightweight dataset for connectivity testing
    ),

    # Common dataset categories for organization
    dataset_categories = list(
      employment = c("150_908", "150_915", "150_916"), # Monthly/quarterly employment
      unemployment = c("151_914", "151_915"), # Unemployment rates
      job_vacancies = c("534_50", "534_51", "534_52"), # Job vacancies
      labour_force = c("152_914", "152_915") # Labour force statistics
    ),

    # HTTP request configuration for CSV downloads
    http = list(
      accept_csv = "application/vnd.sdmx.data+csv;version=1.0.0",
      accept_xml = "application/vnd.sdmx.structurespecificdata+xml;version=2.1",
      user_agent = "istatlab R package (https://github.com/gmontaletti/istatlab)"
    ),

    # Rate limiting configuration (ISTAT enforces ~5 req/min)
    rate_limit = list(
      delay = 13, # seconds between requests (~4.6 req/min)
      min_delay = 5, # minimum allowed delay (user override floor)
      max_retries = 3, # retry attempts on 429/503
      initial_backoff = 60, # first retry wait (seconds)
      backoff_multiplier = 2, # exponential backoff factor
      max_backoff = 300, # cap at 5 minutes
      jitter_fraction = 0.1, # +/- 10% randomization on delays
      ban_detection_threshold = 3 # consecutive 429s = likely ban
    ),

    # demo.istat.it configuration (demographic data, static CSV-in-ZIP files)
    demo = list(
      base_url = "https://demo.istat.it/data",
      cache_dir = "demo_data",
      cache_max_age_days = 30
    ),

    # Rate limiting for demo.istat.it (lighter than SDMX)
    demo_rate_limit = list(
      delay = 2,
      jitter_fraction = 0.1,
      max_retries = 2,
      initial_backoff = 10,
      backoff_multiplier = 2,
      max_backoff = 60
    ),

    # Cache file configuration
    cache = list(
      codelists_file = "codelists.rds",
      dataset_map_file = "dataset_codelist_map.rds",
      metadata_file = "flussi_istat.rds",
      data_download_log_file = "data_download_log.rds",
      codelist_metadata_file = "codelist_metadata.rds",

      # Staggered TTL configuration for codelists
      # Each codelist gets TTL = base + (hash(codelist_id) % jitter)
      # This prevents all codelists from expiring simultaneously
      codelist_base_ttl_days = 14,
      codelist_jitter_days = 14
    )
  )
}

#' Build ISTAT API URL
#'
#' Constructs API URLs for different ISTAT SDMX endpoints using centralized configuration.
#'
#' @param endpoint Character string specifying the endpoint type
#'   ("data", "dataflow", "datastructure", "codelist", "availableconstraint")
#' @param dataset_id Character string specifying dataset ID (required for data endpoint)
#' @param filter Character string specifying data filters (for data endpoint)
#' @param start_time Character string specifying start period (for data endpoint)
#' @param end_time Character string specifying end period (for data endpoint)
#' @param dsd_ref Character string specifying data structure reference (for datastructure)
#' @param updated_after POSIXct timestamp. If provided, the URL will include the updatedAfter
#'   parameter to retrieve only data changed since this time. Used for incremental update detection.
#' @param lastNObservations Integer. If provided, limits the response to the last N observations
#'   per time series. Useful for reducing data transfer in connectivity checks.
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
#'
#' # Build lightweight URL for connectivity check
#' url <- build_istat_url("data", dataset_id = "534_50", lastNObservations = 1)
#' }
build_istat_url <- function(
  endpoint,
  dataset_id = NULL,
  filter = "ALL",
  start_time = NULL,
  end_time = NULL,
  dsd_ref = NULL,
  updated_after = NULL,
  lastNObservations = NULL
) {
  config <- get_istat_config()
  base_endpoint <- config$endpoints[[endpoint]]

  if (is.null(base_endpoint)) {
    stop(
      "Unknown endpoint: ",
      endpoint,
      ". Available endpoints: ",
      paste(names(config$endpoints), collapse = ", ")
    )
  }

  switch(
    endpoint,
    "data" = {
      if (is.null(dataset_id)) {
        stop("dataset_id is required for data endpoint")
      }

      # Build data URL: /data/{dataset_id}/{filter}/all/{?params}
      # includeHistory=false by default to get only current data (not historical revisions)
      query_params <- c("includeHistory=false")

      # Add startPeriod parameter if provided
      if (!is.null(start_time) && nchar(start_time) > 0) {
        query_params <- c(query_params, paste0("startPeriod=", start_time))
      }

      # Add endPeriod parameter if provided
      if (!is.null(end_time) && nchar(end_time) > 0) {
        query_params <- c(query_params, paste0("endPeriod=", end_time))
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

        query_params <- c(
          query_params,
          paste0("updatedAfter=", encoded_timestamp)
        )
      }

      # Add lastNObservations parameter if provided (limits returned observations)
      if (!is.null(lastNObservations)) {
        query_params <- c(
          query_params,
          paste0("lastNObservations=", as.integer(lastNObservations))
        )
      }

      # Combine query parameters
      query_string <- paste0("?", paste(query_params, collapse = "&"))

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

    "availableconstraint" = {
      if (is.null(dataset_id)) {
        stop("dataset_id is required for availableconstraint endpoint")
      }
      # Build availableconstraint URL: /availableconstraint/{dataset_id}/all/all?mode=available
      paste0(base_endpoint, "/", dataset_id, "/all/all?mode=available")
    },

    # Default: return base endpoint
    base_endpoint
  )
}

#' Build SDMX Positional Filter Key
#'
#' Constructs a dot-separated positional filter key for SDMX API queries.
#' The ISTAT SDMX API uses positional filters where each dimension is separated
#' by a dot. Empty positions act as wildcards (match all values). For example,
#' a dataset with 8 dimensions and a filter key \code{"M......G_2024_01."} means
#' dimension 1 is \code{"M"}, dimension 7 is \code{"G_2024_01"}, and all other
#' dimensions are unrestricted.
#'
#' @param n_dims Integer. Total number of dimensions in the dataset.
#'   Must be a positive integer.
#' @param dim_values Named list mapping dimension positions (as character strings)
#'   to filter values. Position numbering starts at 1. For example,
#'   \code{list("1" = "M", "7" = "G_2024_01")} sets dimension 1 to \code{"M"}
#'   and dimension 7 to \code{"G_2024_01"}.
#'
#' @return Character string containing the dot-separated filter key.
#' @export
#'
#' @examples
#' # Set dimension 1 to "M" and dimension 7 to "G_2024_01" in an 8-dimension dataset
#' build_sdmx_filter_key(8, list("1" = "M", "7" = "G_2024_01"))
#' # Returns: "M......G_2024_01."
#'
#' # Single dimension filter
#' build_sdmx_filter_key(5, list("3" = "IT"))
#' # Returns: "..IT.."
#'
#' # All wildcards (equivalent to "ALL")
#' build_sdmx_filter_key(4, list())
#' # Returns: "..."
build_sdmx_filter_key <- function(n_dims, dim_values) {
  # 1. Input validation -----
  if (
    !is.numeric(n_dims) ||
      length(n_dims) != 1 ||
      is.na(n_dims) ||
      n_dims != as.integer(n_dims) ||
      n_dims < 1
  ) {
    stop("n_dims must be a positive integer, got: ", deparse(n_dims))
  }
  n_dims <- as.integer(n_dims)

  if (!is.list(dim_values)) {
    stop("dim_values must be a named list, got: ", class(dim_values)[1])
  }

  # Empty list is valid (all wildcards)
  if (length(dim_values) == 0) {
    return(paste(rep("", n_dims), collapse = "."))
  }

  # Validate names are present and represent valid positions
  positions <- names(dim_values)
  if (is.null(positions) || any(positions == "")) {
    stop("All elements of dim_values must be named with position numbers")
  }

  numeric_positions <- suppressWarnings(as.integer(positions))
  if (any(is.na(numeric_positions))) {
    stop(
      "dim_values names must be integer position numbers, got: ",
      paste(positions[is.na(numeric_positions)], collapse = ", ")
    )
  }

  out_of_range <- numeric_positions < 1 | numeric_positions > n_dims
  if (any(out_of_range)) {
    stop(
      "Position(s) out of range [1, ",
      n_dims,
      "]: ",
      paste(numeric_positions[out_of_range], collapse = ", ")
    )
  }

  # 2. Build filter key -----
  parts <- rep("", n_dims)
  for (i in seq_along(dim_values)) {
    pos <- numeric_positions[i]
    parts[pos] <- as.character(dim_values[[i]])
  }

  paste(parts, collapse = ".")
}

#' Merge Dimension Values into an Existing SDMX Filter
#'
#' Takes an existing SDMX filter string and fills in additional dimension values
#' without overwriting positions already specified by the user. When the base
#' filter is \code{NULL} or \code{"ALL"}, a new filter key is built from scratch
#' using \code{\link{build_sdmx_filter_key}}.
#'
#' @param base_filter Character string with an existing dot-separated filter,
#'   or \code{NULL} / \code{"ALL"} to indicate no existing filter.
#' @param n_dims Integer. Total number of dimensions in the dataset.
#' @param dim_values Named list mapping dimension positions (as character strings)
#'   to filter values. Same format as in \code{\link{build_sdmx_filter_key}}.
#'   Values are only inserted into positions that are empty (wildcard) in
#'   \code{base_filter}; existing user-specified values are preserved.
#'
#' @return Character string containing the merged dot-separated filter key.
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' # Fill position 7 into an 8-dimension filter that has positions 1 and 3 set
#' merge_sdmx_filters("M..IT.....", 8, list("7" = "G_2024_01"))
#' # Returns: "M..IT....G_2024_01."
#'
#' # User-specified values are not overwritten
#' merge_sdmx_filters("M..IT.....", 8, list("1" = "Q", "7" = "G_2024_01"))
#' # Returns: "M..IT....G_2024_01." (position 1 keeps "M", not overwritten)
#'
#' # NULL base_filter builds from scratch
#' merge_sdmx_filters(NULL, 8, list("1" = "M", "7" = "G_2024_01"))
#' # Returns: "M......G_2024_01."
#' }
merge_sdmx_filters <- function(base_filter, n_dims, dim_values) {
  # 1. Delegate to build_sdmx_filter_key when no base filter -----
  if (is.null(base_filter) || base_filter == "ALL") {
    return(build_sdmx_filter_key(n_dims, dim_values))
  }

  # 2. Validate n_dims -----
  if (
    !is.numeric(n_dims) ||
      length(n_dims) != 1 ||
      is.na(n_dims) ||
      n_dims != as.integer(n_dims) ||
      n_dims < 1
  ) {
    stop("n_dims must be a positive integer, got: ", deparse(n_dims))
  }
  n_dims <- as.integer(n_dims)

  # 3. Split existing filter into parts -----
  parts <- strsplit(base_filter, "\\.", perl = TRUE)[[1]]

  # Trailing dots produce no entries from strsplit; pad to n_dims
  if (length(parts) < n_dims) {
    parts <- c(parts, rep("", n_dims - length(parts)))
  }

  # 4. Validate dim_values -----
  if (!is.list(dim_values)) {
    stop("dim_values must be a named list, got: ", class(dim_values)[1])
  }

  if (length(dim_values) == 0) {
    return(paste(parts, collapse = "."))
  }

  positions <- names(dim_values)
  if (is.null(positions) || any(positions == "")) {
    stop("All elements of dim_values must be named with position numbers")
  }

  numeric_positions <- suppressWarnings(as.integer(positions))
  if (any(is.na(numeric_positions))) {
    stop(
      "dim_values names must be integer position numbers, got: ",
      paste(positions[is.na(numeric_positions)], collapse = ", ")
    )
  }

  out_of_range <- numeric_positions < 1 | numeric_positions > n_dims
  if (any(out_of_range)) {
    stop(
      "Position(s) out of range [1, ",
      n_dims,
      "]: ",
      paste(numeric_positions[out_of_range], collapse = ", ")
    )
  }

  # 5. Merge: fill only empty positions -----
  for (i in seq_along(dim_values)) {
    pos <- numeric_positions[i]
    if (parts[pos] == "") {
      parts[pos] <- as.character(dim_values[[i]])
    }
  }

  paste(parts, collapse = ".")
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
    stop(
      "Unknown category: ",
      category,
      ". Available categories: ",
      paste(names(config$dataset_categories), collapse = ", ")
    )
  }

  config$dataset_categories[[category]]
}
