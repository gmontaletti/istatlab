# hvd_download.R - Download functions for ISTAT HVD (High-Value Datasets) API
# Supports both SDMX 2.1 (v1) and SDMX 3.0 (v2) endpoints

# 1. Internal dispatcher -----

#' Download Data via HVD API
#'
#' Internal dispatcher that routes HVD download requests to the appropriate
#' version-specific handler. Called by existing download functions when the
#' api surface is not `"legacy"`.
#'
#' @param dataset_id Character string specifying the ISTAT dataset ID
#' @param api_version Character string: `"hvd_v1"` (SDMX 2.1) or `"hvd_v2"`
#'   (SDMX 3.0)
#' @param filter Character string specifying data filters (default `"ALL"`)
#' @param start_time Character string specifying the start period
#' @param end_time Character string specifying the end period
#' @param timeout Numeric timeout in seconds
#' @param verbose Logical whether to log status messages
#' @param method Character string: `"GET"` (default) or `"POST"`
#' @param ... Additional arguments passed to version-specific handlers
#'
#' @return An `istat_result` object (same structure as [process_api_response()])
#' @keywords internal
hvd_download_data <- function(
  dataset_id,
  api_version,
  filter = "ALL",
  start_time = "",
  end_time = "",
  timeout = NULL,
  verbose = TRUE,
  method = "GET",
  ...
) {
  # 1.1. Input validation -----
  if (
    !is.character(dataset_id) ||
      length(dataset_id) != 1 ||
      nchar(dataset_id) == 0
  ) {
    stop("dataset_id must be a non-empty single character string")
  }

  if (!api_version %in% c("hvd_v1", "hvd_v2")) {
    stop(
      "api_version must be 'hvd_v1' or 'hvd_v2', got: ",
      deparse(api_version)
    )
  }

  method <- toupper(method)
  if (!method %in% c("GET", "POST")) {
    stop("method must be 'GET' or 'POST', got: ", deparse(method))
  }

  config <- get_istat_config()
  if (is.null(timeout)) {
    timeout <- config$defaults$timeout
  }

  # 1.2. Dispatch to version-specific handler -----
  istat_log(
    paste0(
      "HVD download [",
      api_version,
      "/",
      method,
      "]: dataset ",
      dataset_id
    ),
    "INFO",
    verbose
  )

  if (api_version == "hvd_v1") {
    hvd_v1_download(
      dataset_id = dataset_id,
      filter = filter,
      start_time = start_time,
      end_time = end_time,
      timeout = timeout,
      verbose = verbose,
      method = method,
      ...
    )
  } else {
    hvd_v2_download(
      dataset_id = dataset_id,
      filter = filter,
      start_time = start_time,
      end_time = end_time,
      timeout = timeout,
      verbose = verbose,
      method = method,
      ...
    )
  }
}

# 2. HVD v1 download (SDMX 2.1) -----

#' Download Data via HVD v1 API (SDMX 2.1)
#'
#' Retrieves data from the ISTAT HVD SDMX 2.1 endpoint. Supports both GET
#' requests (filter in URL path) and POST requests (filter in request body).
#'
#' @param dataset_id Character string specifying the ISTAT dataset ID
#' @param filter Character string specifying data filters (default `"ALL"`)
#' @param start_time Character string specifying the start period
#' @param end_time Character string specifying the end period
#' @param timeout Numeric timeout in seconds
#' @param verbose Logical whether to log status messages
#' @param method Character string: `"GET"` (default) or `"POST"`
#' @param updated_after Character string in ISO 8601 format for incremental
#'   retrieval. If provided, only data updated after this timestamp is returned.
#' @param lastNObservations Integer limiting response to the last N observations
#'   per time series
#' @param detail Character string controlling response detail level
#'   (e.g., `"full"`, `"dataonly"`, `"nodata"`)
#' @param includeHistory Logical whether to include revision history
#'
#' @return An `istat_result` object
#' @keywords internal
hvd_v1_download <- function(
  dataset_id,
  filter = "ALL",
  start_time = "",
  end_time = "",
  timeout = 240,
  verbose = TRUE,
  method = "GET",
  updated_after = NULL,
  lastNObservations = NULL,
  detail = NULL,
  includeHistory = NULL
) {
  # 2.1. Build URL -----
  url <- build_hvd_v1_url(
    endpoint = "data",
    dataset_id = dataset_id,
    filter = if (method == "GET") filter else NULL,
    start_time = start_time,
    end_time = end_time,
    updated_after = updated_after,
    lastNObservations = lastNObservations,
    detail = detail,
    includeHistory = includeHistory
  )

  accept <- get_hvd_accept_header("hvd_v1", "csv")

  istat_log(
    paste0("HVD v1 ", method, " request: ", url),
    "INFO",
    verbose
  )

  # 2.2. Execute HTTP request -----
  http_result <- if (method == "GET") {
    http_get_with_retry(
      url = url,
      timeout = timeout,
      accept = accept,
      verbose = verbose
    )
  } else {
    http_post_with_retry(
      url = url,
      body = filter,
      timeout = timeout,
      accept = accept,
      content_type = "application/x-www-form-urlencoded",
      verbose = verbose
    )
  }

  # 2.3. Process response -----
  process_api_response(http_result, verbose)
}

# 3. HVD v2 download (SDMX 3.0) -----

#' Download Data via HVD v2 API (SDMX 3.0)
#'
#' Retrieves data from the ISTAT HVD SDMX 3.0 endpoint. Supports both GET
#' requests (filter in URL path) and POST requests (filter in request body).
#' Applies v2-specific column normalization to ensure consistent output
#' regardless of API version.
#'
#' @param dataset_id Character string specifying the ISTAT dataset ID
#' @param filter Character string specifying data filters (default `"ALL"`)
#' @param start_time Character string specifying the start period
#' @param end_time Character string specifying the end period
#' @param timeout Numeric timeout in seconds
#' @param verbose Logical whether to log status messages
#' @param method Character string: `"GET"` (default) or `"POST"`
#' @param context Character string specifying the SDMX 3.0 context
#' @param agency_id Character string specifying the data provider agency
#' @param version Character string specifying the dataflow version
#' @param dim_filters Named list of dimension filters for v2 URL construction
#' @param updated_after Character string in ISO 8601 format for incremental
#'   retrieval
#' @param lastNObservations Integer limiting response to the last N observations
#'   per time series
#'
#' @return An `istat_result` object
#' @keywords internal
hvd_v2_download <- function(
  dataset_id,
  filter = "ALL",
  start_time = "",
  end_time = "",
  timeout = 240,
  verbose = TRUE,
  method = "GET",
  context = NULL,
  agency_id = NULL,
  version = NULL,
  dim_filters = NULL,
  updated_after = NULL,
  lastNObservations = NULL
) {
  # 3.1. Build URL -----
  url <- build_hvd_v2_url(
    endpoint = "data",
    dataset_id = dataset_id,
    context = context,
    agency_id = agency_id,
    version = version,
    filter = if (method == "GET") filter else NULL,
    start_time = start_time,
    end_time = end_time,
    dim_filters = dim_filters,
    updated_after = updated_after,
    lastNObservations = lastNObservations
  )

  accept <- get_hvd_accept_header("hvd_v2", "csv")

  istat_log(
    paste0("HVD v2 ", method, " request: ", url),
    "INFO",
    verbose
  )

  # 3.2. Execute HTTP request -----
  http_result <- if (method == "GET") {
    http_get_with_retry(
      url = url,
      timeout = timeout,
      accept = accept,
      verbose = verbose
    )
  } else {
    http_post_with_retry(
      url = url,
      body = filter,
      timeout = timeout,
      accept = accept,
      content_type = "application/x-www-form-urlencoded",
      verbose = verbose
    )
  }

  # 3.3. Apply v2 column normalization before standard processing -----
  # SDMX 3.0 CSV may use different column names than 2.1. We normalize

  # the raw CSV text is not accessible here; normalization happens after
  # process_api_response() parses the CSV into a data.table.
  result <- process_api_response(http_result, verbose)

  if (result$success && !is.null(result$data)) {
    result$data <- normalize_csv_columns_v2(result$data)
  }

  result
}

# 4. Column normalization for SDMX 3.0 -----

#' Normalize SDMX 3.0 CSV Column Names
#'
#' Maps column names from the SDMX 3.0 CSV format to the legacy naming
#' convention used throughout istatlab. The SDMX 3.0 specification may use
#' different column names than SDMX 2.1. This function ensures that downstream
#' code receives consistent column names regardless of the API version used.
#'
#' If columns already follow the legacy naming convention, the data.table is
#' returned unchanged. Operates by reference (modifies in place).
#'
#' Column mappings (v2 -> legacy):
#' - `TIME_PERIOD` -> `ObsDimension`
#' - `OBS_VALUE` -> `ObsValue`
#' - `STRUCTURE` -> removed (v2 metadata, equivalent to v1 DATAFLOW)
#' - `STRUCTURE_ID` -> removed
#' - `STRUCTURE_NAME` -> removed
#' - `ACTION` -> removed (v2-only column)
#'
#' @param dt data.table from CSV parsing
#'
#' @return data.table with normalized column names (modified in place)
#' @keywords internal
normalize_csv_columns_v2 <- function(dt) {
  if (!data.table::is.data.table(dt)) {
    data.table::setDT(dt)
  }

  current_names <- names(dt)

  # 4.1. Check if already normalized -----
  # If ObsDimension and ObsValue already exist, columns follow legacy naming
  if ("ObsDimension" %in% current_names && "ObsValue" %in% current_names) {
    # Still remove v2-specific metadata columns if present
    v2_meta_cols <- intersect(
      c("STRUCTURE", "STRUCTURE_ID", "STRUCTURE_NAME", "ACTION"),
      current_names
    )
    if (length(v2_meta_cols) > 0) {
      dt[, (v2_meta_cols) := NULL]
    }
    return(dt)
  }

  # 4.2. Apply v2-specific column renames -----
  # SDMX 3.0 CSV column name mapping to legacy convention
  name_map <- c(
    "TIME_PERIOD" = "ObsDimension",
    "OBS_VALUE" = "ObsValue"
  )

  for (old_name in names(name_map)) {
    if (old_name %in% current_names) {
      data.table::setnames(dt, old_name, name_map[old_name])
    }
  }

  # 4.3. Remove v2-specific metadata columns -----
  # SDMX 3.0 CSV includes additional structural metadata columns
  v2_remove_cols <- intersect(
    c("DATAFLOW", "STRUCTURE", "STRUCTURE_ID", "STRUCTURE_NAME", "ACTION"),
    names(dt)
  )
  if (length(v2_remove_cols) > 0) {
    dt[, (v2_remove_cols) := NULL]
  }

  dt
}

# 5. Exported user-facing function -----

#' Download Data from ISTAT HVD API
#'
#' Downloads statistical data from the ISTAT High-Value Datasets (HVD) API.
#' Provides direct access to HVD endpoints for users who want explicit control
#' over the API version and request method. Supports both SDMX 2.1 (v1) and
#' SDMX 3.0 (v2) interfaces.
#'
#' The HVD API is the newer ISTAT data delivery platform. Version v1 (SDMX 2.1)
#' is the stable interface; v2 (SDMX 3.0) is experimental. Both versions return
#' data normalized to the same column naming convention for compatibility with
#' the rest of istatlab.
#'
#' @param dataset_id Character string specifying the ISTAT dataset ID
#'   (e.g., `"534_50"`)
#' @param version Character string: `"v1"` (default, SDMX 2.1) or `"v2"`
#'   (SDMX 3.0, experimental)
#' @param filter Character string specifying data filters. Default `"ALL"`
#'   retrieves all available data.
#' @param start_time Character string specifying the start period
#'   (e.g., `"2019"`, `"2020-Q1"`, `"2020-01"`)
#' @param end_time Character string specifying the end period
#' @param method Character string: `"GET"` (default) or `"POST"`. Use POST
#'   for complex filter keys that may exceed URL length limits.
#' @param timeout Numeric timeout in seconds. Default uses the centralized
#'   configuration value.
#' @param verbose Logical whether to print status messages. Default `TRUE`.
#' @param ... Additional arguments passed to version-specific handlers
#'   (e.g., `updated_after`, `lastNObservations`, `detail`, `context`,
#'   `agency_id`)
#'
#' @return A data.table with the downloaded data and an additional `id` column
#'   containing the dataset identifier, or `NULL` if the download fails.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download via HVD v1 (default, stable)
#' dt <- download_hvd_data("534_50", start_time = "2020")
#'
#' # Download via HVD v2 (experimental)
#' dt <- download_hvd_data("534_50", version = "v2", start_time = "2020")
#'
#' # Use POST method for complex filters
#' dt <- download_hvd_data(
#'   "150_908",
#'   filter = "M..........",
#'   method = "POST",
#'   start_time = "2023"
#' )
#'
#' # Limit to last 5 observations per series
#' dt <- download_hvd_data("534_50", lastNObservations = 5)
#' }
download_hvd_data <- function(
  dataset_id,
  version = "v1",
  filter = "ALL",
  start_time = "",
  end_time = "",
  method = "GET",
  timeout = NULL,
  verbose = TRUE,
  ...
) {
  # 5.1. Input validation -----
  if (
    !is.character(dataset_id) ||
      length(dataset_id) != 1 ||
      nchar(dataset_id) == 0
  ) {
    stop("dataset_id must be a non-empty single character string")
  }

  if (!is.character(version) || length(version) != 1) {
    stop("version must be a single character string")
  }

  # Map user-friendly version names to internal api_version values
  version_map <- c("v1" = "hvd_v1", "v2" = "hvd_v2")
  api_version <- version_map[version]

  if (is.na(api_version)) {
    stop(
      "version must be 'v1' or 'v2', got: ",
      deparse(version),
      ". Use 'v1' for SDMX 2.1 (stable) or 'v2' for SDMX 3.0 (experimental)."
    )
  }

  method <- toupper(method)
  if (!method %in% c("GET", "POST")) {
    stop("method must be 'GET' or 'POST', got: ", deparse(method))
  }

  # 5.2. Delegate to internal dispatcher -----
  result <- hvd_download_data(
    dataset_id = dataset_id,
    api_version = api_version,
    filter = filter,
    start_time = start_time,
    end_time = end_time,
    timeout = timeout,
    verbose = verbose,
    method = method,
    ...
  )

  # 5.3. Handle failure -----
  if (!result$success) {
    warning(
      "Failed to download HVD data for dataset: ",
      dataset_id,
      " - ",
      result$message
    )
    return(NULL)
  }

  # 5.4. Add dataset identifier and return data.table -----
  result$data[, id := dataset_id]

  istat_log(
    paste(
      "HVD download complete:",
      nrow(result$data),
      "rows for dataset",
      dataset_id
    ),
    "INFO",
    verbose
  )

  result$data
}

# 6. HVD API information -----

#' Get HVD API Information
#'
#' Returns a summary of the ISTAT HVD (High-Value Datasets) API capabilities
#' for both the v1 (SDMX 2.1) and v2 (SDMX 3.0) interfaces. Useful for
#' checking available endpoints, supported methods, and stability status.
#'
#' @return A list with two elements:
#'   \describe{
#'     \item{v1}{List with `base_url`, `status`, `sdmx_version`, `methods`,
#'       and `description` for the SDMX 2.1 interface}
#'     \item{v2}{List with `base_url`, `status`, `sdmx_version`, `methods`,
#'       and `description` for the SDMX 3.0 interface}
#'   }
#' @export
#'
#' @examples
#' info <- get_hvd_info()
#' info$v1$base_url
#' info$v2$status
get_hvd_info <- function() {
  list(
    v1 = list(
      base_url = get_hvd_base_url(),
      status = "stable",
      sdmx_version = "2.1",
      methods = c("GET", "POST"),
      description = paste(
        "ISTAT HVD SDMX 2.1 REST API.",
        "Stable interface for accessing High-Value Datasets.",
        "Supports data, dataflow, datastructure, and codelist queries."
      )
    ),
    v2 = list(
      base_url = get_hvd_base_url(),
      status = "experimental",
      sdmx_version = "3.0",
      methods = c("GET", "POST"),
      description = paste(
        "ISTAT HVD SDMX 3.0 REST API.",
        "Experimental interface with expanded query capabilities.",
        "Supports context-based queries and richer filtering options."
      )
    )
  )
}
