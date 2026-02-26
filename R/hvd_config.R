# hvd_config.R - URL builders and validation for ISTAT HVD (High Value Datasets)
# endpoints at https://esploradati.istat.it/hvd. Supports both HVD v1 (SDMX 2.1)
# and HVD v2 (SDMX 3.0) API surfaces alongside the legacy SDMX web service.

# 1. API surface validation -----

#' Validate API Surface Identifier
#'
#' Checks that the supplied API surface identifier is one of the three supported
#' values: `"legacy"` (the existing SDMX 2.1 service at
#' `esploradati.istat.it/SDMXWS`), `"hvd_v1"` (HVD SDMX 2.1), or `"hvd_v2"`
#' (HVD SDMX 3.0). Stops with an informative error when an unrecognized value
#' is provided.
#'
#' @param api Character string identifying the API surface. Must be one of
#'   `"legacy"`, `"hvd_v1"`, or `"hvd_v2"`.
#'
#' @return The validated `api` string, returned invisibly. This allows the
#'   function to be used inline: `api <- validate_api_surface(api)`.
#'
#' @export
#'
#' @examples
#' validate_api_surface("legacy")
#' validate_api_surface("hvd_v1")
#' validate_api_surface("hvd_v2")
#'
#' \dontrun{
#' # Triggers an error
#' validate_api_surface("v3")
#' }
validate_api_surface <- function(api) {
  valid_surfaces <- c("legacy", "hvd_v1", "hvd_v2")

  if (missing(api) || is.null(api) || length(api) != 1L || !is.character(api)) {
    stop(
      "'api' must be a single character string. ",
      "Valid values: ",
      paste(valid_surfaces, collapse = ", ")
    )
  }

  if (!api %in% valid_surfaces) {
    stop(
      "Unknown API surface: '",
      api,
      "'. Valid values: ",
      paste(valid_surfaces, collapse = ", ")
    )
  }

  invisible(api)
}

# 2. HVD base URL -----

#' Get HVD Base URL
#'
#' Returns the base URL for the ISTAT HVD (High Value Datasets) service. Both
#' HVD v1 and HVD v2 share the same base URL; the version-specific path prefix
#' (`/rest/` vs `/rest/v2/`) is appended by the respective URL builders.
#'
#' @return Character string containing the HVD base URL.
#'
#' @keywords internal
get_hvd_base_url <- function() {
  "https://esploradati.istat.it/hvd"
}

# 3. HVD v1 URL builder (SDMX 2.1) -----

#' Build HVD v1 (SDMX 2.1) URL
#'
#' Constructs request URLs for the ISTAT HVD v1 API surface, which follows the
#' SDMX 2.1 RESTful specification. Supports the `data`, `availableconstraint`,
#' `structure`, and `dataflow` endpoints. For the `data` endpoint, both GET and
#' POST URL shapes are available (POST places the filter key in the request body
#' rather than in the URL path).
#'
#' @param endpoint Character string specifying the endpoint type. One of
#'   `"data"`, `"availableconstraint"`, `"structure"`, or `"dataflow"`.
#' @param dataset_id Character string specifying the ISTAT dataset (flow)
#'   identifier (e.g., `"150_908"`). Required for `"data"`,
#'   `"availableconstraint"`, and `"structure"` endpoints.
#' @param filter Character string with the SDMX positional key filter.
#'   Default `"ALL"` (no filtering). Ignored when `method = "POST"`.
#' @param provider Character string identifying the data provider. Default
#'   `"all"`.
#' @param start_time Character string specifying the start period for data
#'   retrieval (e.g., `"2020"`, `"2020-Q1"`, `"2020-01"`).
#' @param end_time Character string specifying the end period for data
#'   retrieval.
#' @param updated_after Character string in ISO 8601 format
#'   (e.g., `"2025-01-01T00:00:00Z"`). When provided, the server returns only
#'   observations updated after this timestamp.
#' @param lastNObservations Integer. Limits the response to the last N
#'   observations per time series.
#' @param detail Character string controlling the amount of information
#'   returned (e.g., `"full"`, `"dataonly"`, `"nodata"`).
#' @param includeHistory Logical. When `TRUE`, historical revisions of data
#'   points are included.
#' @param method Character string, either `"GET"` (default) or `"POST"`.
#'   Controls the URL shape for the `data` endpoint.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # GET data URL with time filter
#' build_hvd_v1_url("data", dataset_id = "150_908",
#'                  start_time = "2020", end_time = "2024")
#'
#' # POST data URL (filter key sent in body, not in URL)
#' build_hvd_v1_url("data", dataset_id = "150_908", method = "POST")
#'
#' # Available constraint URL
#' build_hvd_v1_url("availableconstraint", dataset_id = "150_908")
#'
#' # Dataflow listing URL (no dataset_id needed)
#' build_hvd_v1_url("dataflow")
#' }
#'
#' @keywords internal
build_hvd_v1_url <- function(
  endpoint,
  dataset_id = NULL,
  filter = "ALL",
  provider = "all",
  start_time = NULL,
  end_time = NULL,
  updated_after = NULL,
  lastNObservations = NULL,
  detail = NULL,
  includeHistory = NULL,
  method = "GET"
) {
  # 3a. Input validation -----
  valid_endpoints <- c("data", "availableconstraint", "structure", "dataflow")

  if (
    missing(endpoint) ||
      !is.character(endpoint) ||
      length(endpoint) != 1L
  ) {
    stop(
      "'endpoint' must be a single character string. ",
      "Valid values: ",
      paste(valid_endpoints, collapse = ", ")
    )
  }

  if (!endpoint %in% valid_endpoints) {
    stop(
      "Unknown HVD v1 endpoint: '",
      endpoint,
      "'. Valid values: ",
      paste(valid_endpoints, collapse = ", ")
    )
  }

  if (endpoint %in% c("data", "availableconstraint", "structure")) {
    if (
      is.null(dataset_id) ||
        !is.character(dataset_id) ||
        length(dataset_id) != 1L
    ) {
      stop(
        "'dataset_id' is required for the '",
        endpoint,
        "' endpoint and must be a single character string"
      )
    }
  }

  method <- toupper(method)
  if (!method %in% c("GET", "POST")) {
    stop("'method' must be either 'GET' or 'POST', got: '", method, "'")
  }

  base <- get_hvd_base_url()

  # 3b. Endpoint dispatch -----
  switch(
    EXPR = endpoint,

    "data" = {
      if (method == "POST") {
        # POST: key goes in the request body
        # {base}/rest/data/{dataset_id}/body/{provider}
        paste0(base, "/rest/data/", dataset_id, "/body/", provider)
      } else {
        # GET: key in URL path, query params appended
        # {base}/rest/data/{dataset_id}/{filter}/{provider}?{params}
        path <- paste0(
          base,
          "/rest/data/",
          dataset_id,
          "/",
          filter,
          "/",
          provider
        )
        query_params <- .build_v1_query_params(
          start_time = start_time,
          end_time = end_time,
          updated_after = updated_after,
          lastNObservations = lastNObservations,
          detail = detail,
          includeHistory = includeHistory
        )
        if (length(query_params) > 0L) {
          paste0(path, "?", paste(query_params, collapse = "&"))
        } else {
          path
        }
      }
    },

    "availableconstraint" = {
      # {base}/rest/availableconstraint/{dataset_id}/{filter}/{provider}/all
      paste0(
        base,
        "/rest/availableconstraint/",
        dataset_id,
        "/",
        filter,
        "/",
        provider,
        "/all"
      )
    },

    "structure" = {
      # {base}/rest/datastructure/IT1/{dataset_id}/1.0?references=children
      paste0(
        base,
        "/rest/datastructure/IT1/",
        dataset_id,
        "/1.0?references=children"
      )
    },

    "dataflow" = {
      # {base}/rest/dataflow
      paste0(base, "/rest/dataflow")
    }
  )
}

# 4. HVD v1 query parameter builder -----

#' Build HVD v1 Query Parameter Strings
#'
#' Assembles the query string parameters for HVD v1 GET data requests. Only
#' non-NULL parameters are included in the output.
#'
#' @param start_time Character start period.
#' @param end_time Character end period.
#' @param updated_after Character ISO 8601 timestamp.
#' @param lastNObservations Integer observation limit.
#' @param detail Character detail level.
#' @param includeHistory Logical include-history flag.
#'
#' @return Character vector of `name=value` query parameter strings.
#'
#' @keywords internal
.build_v1_query_params <- function(
  start_time = NULL,
  end_time = NULL,
  updated_after = NULL,
  lastNObservations = NULL,
  detail = NULL,
  includeHistory = NULL
) {
  params <- character(0L)

  if (!is.null(start_time) && nzchar(start_time)) {
    params <- c(params, paste0("startPeriod=", start_time))
  }

  if (!is.null(end_time) && nzchar(end_time)) {
    params <- c(params, paste0("endPeriod=", end_time))
  }

  if (!is.null(updated_after) && nzchar(updated_after)) {
    params <- c(
      params,
      paste0(
        "updatedAfter=",
        utils::URLencode(updated_after, reserved = TRUE)
      )
    )
  }

  if (!is.null(lastNObservations)) {
    params <- c(
      params,
      paste0(
        "lastNObservations=",
        as.integer(lastNObservations)
      )
    )
  }

  if (!is.null(detail) && nzchar(detail)) {
    params <- c(params, paste0("detail=", detail))
  }

  if (!is.null(includeHistory)) {
    params <- c(
      params,
      paste0(
        "includeHistory=",
        tolower(as.character(as.logical(includeHistory)))
      )
    )
  }

  params
}

# 5. HVD v2 URL builder (SDMX 3.0) -----

#' Build HVD v2 (SDMX 3.0) URL
#'
#' Constructs request URLs for the ISTAT HVD v2 API surface, which follows the
#' SDMX 3.0 RESTful specification. The key differences from v1 are: (1) the
#' `/rest/v2/` path prefix, (2) an explicit `{context}/{agencyId}/{resourceId}/{version}`
#' path structure, and (3) the `c[DIM]=value` query parameter syntax for
#' dimension filtering (replacing `startPeriod` / `endPeriod`).
#'
#' @param endpoint Character string specifying the endpoint type. One of
#'   `"data"`, `"availability"`, or `"structure"`.
#' @param dataset_id Character string specifying the ISTAT dataset (resource)
#'   identifier (e.g., `"150_908"`). Required for all endpoints.
#' @param context Character string specifying the structural metadata context.
#'   Default `"dataflow"`.
#' @param agency_id Character string identifying the maintenance agency.
#'   Default `"IT1"` (ISTAT).
#' @param version Character string specifying the resource version. Default
#'   `"~"` (latest available version).
#' @param filter Character string with the SDMX 3.0 key filter. Default `"*"`
#'   (all keys). Ignored when `method = "POST"`.
#' @param component_id Character string specifying the component to constrain
#'   in availability queries. Default `"all"`. Only used for the `"availability"`
#'   endpoint.
#' @param start_time Character string specifying the start period (e.g.,
#'   `"2020"`). Translated to `c[TIME_PERIOD]=ge:2020` syntax by
#'   [build_sdmx3_filters()].
#' @param end_time Character string specifying the end period (e.g., `"2025"`).
#'   Translated to `c[TIME_PERIOD]=le:2025` syntax by [build_sdmx3_filters()].
#' @param dim_filters Named list of dimension filters where names are dimension
#'   IDs and values are filter expressions (e.g.,
#'   `list(FREQ = "M", REF_AREA = "IT")`). Translated to `c[FREQ]=M` syntax.
#' @param updated_after Character string in ISO 8601 format for incremental
#'   retrieval.
#' @param lastNObservations Integer limiting the response to the last N
#'   observations per time series.
#' @param method Character string, either `"GET"` (default) or `"POST"`.
#'   Controls the URL shape for the `data` endpoint.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # GET data URL with time range and dimension filter
#' build_hvd_v2_url("data", dataset_id = "150_908",
#'                  start_time = "2020", end_time = "2025",
#'                  dim_filters = list(FREQ = "M"))
#'
#' # POST data URL
#' build_hvd_v2_url("data", dataset_id = "150_908", method = "POST")
#'
#' # Availability URL
#' build_hvd_v2_url("availability", dataset_id = "150_908")
#'
#' # Structure URL
#' build_hvd_v2_url("structure", dataset_id = "150_908")
#' }
#'
#' @keywords internal
build_hvd_v2_url <- function(
  endpoint,
  dataset_id = NULL,
  context = "dataflow",
  agency_id = "IT1",
  version = "~",
  filter = "*",
  component_id = "all",
  start_time = NULL,
  end_time = NULL,
  dim_filters = NULL,
  updated_after = NULL,
  lastNObservations = NULL,
  method = "GET"
) {
  # 5a. Input validation -----
  valid_endpoints <- c("data", "availability", "structure")

  if (
    missing(endpoint) ||
      !is.character(endpoint) ||
      length(endpoint) != 1L
  ) {
    stop(
      "'endpoint' must be a single character string. ",
      "Valid values: ",
      paste(valid_endpoints, collapse = ", ")
    )
  }

  if (!endpoint %in% valid_endpoints) {
    stop(
      "Unknown HVD v2 endpoint: '",
      endpoint,
      "'. Valid values: ",
      paste(valid_endpoints, collapse = ", ")
    )
  }

  if (
    is.null(dataset_id) || !is.character(dataset_id) || length(dataset_id) != 1L
  ) {
    stop(
      "'dataset_id' is required and must be a single character string"
    )
  }

  method <- toupper(method)
  if (!method %in% c("GET", "POST")) {
    stop("'method' must be either 'GET' or 'POST', got: '", method, "'")
  }

  if (!is.null(dim_filters) && !is.list(dim_filters)) {
    stop("'dim_filters' must be a named list or NULL")
  }

  if (!is.null(dim_filters) && length(dim_filters) > 0L) {
    if (is.null(names(dim_filters)) || any(names(dim_filters) == "")) {
      stop("All elements of 'dim_filters' must be named with dimension IDs")
    }
  }

  base <- get_hvd_base_url()

  # 5b. Endpoint dispatch -----
  switch(
    EXPR = endpoint,

    "data" = {
      if (method == "POST") {
        # POST: key in body
        # {base}/rest/v2/data/{context}/{agency_id}/{dataset_id}/{version}/body
        paste0(
          base,
          "/rest/v2/data/",
          context,
          "/",
          agency_id,
          "/",
          dataset_id,
          "/",
          version,
          "/body"
        )
      } else {
        # GET: key in path, c[DIM] filters as query params
        # {base}/rest/v2/data/{context}/{agency_id}/{dataset_id}/{version}/{filter}?{params}
        path <- paste0(
          base,
          "/rest/v2/data/",
          context,
          "/",
          agency_id,
          "/",
          dataset_id,
          "/",
          version,
          "/",
          filter
        )
        query_params <- .build_v2_query_params(
          start_time = start_time,
          end_time = end_time,
          dim_filters = dim_filters,
          updated_after = updated_after,
          lastNObservations = lastNObservations
        )
        if (length(query_params) > 0L) {
          paste0(path, "?", paste(query_params, collapse = "&"))
        } else {
          path
        }
      }
    },

    "availability" = {
      # {base}/rest/v2/availability/{context}/{agency_id}/{dataset_id}/{version}/{filter}/{component_id}
      paste0(
        base,
        "/rest/v2/availability/",
        context,
        "/",
        agency_id,
        "/",
        dataset_id,
        "/",
        version,
        "/",
        filter,
        "/",
        component_id
      )
    },

    "structure" = {
      # {base}/rest/v2/structure/dataflow/{agency_id}/{dataset_id}/{version}
      paste0(
        base,
        "/rest/v2/structure/dataflow/",
        agency_id,
        "/",
        dataset_id,
        "/",
        version
      )
    }
  )
}

# 6. HVD v2 query parameter builder -----

#' Build HVD v2 Query Parameter Strings
#'
#' Assembles query string parameters for HVD v2 GET data requests. Delegates
#' dimension and time period filter construction to [build_sdmx3_filters()].
#'
#' @param start_time Character start period.
#' @param end_time Character end period.
#' @param dim_filters Named list of dimension filters.
#' @param updated_after Character ISO 8601 timestamp.
#' @param lastNObservations Integer observation limit.
#'
#' @return Character vector of query parameter strings (URL-encoded where
#'   needed).
#'
#' @keywords internal
.build_v2_query_params <- function(
  start_time = NULL,
  end_time = NULL,
  dim_filters = NULL,
  updated_after = NULL,
  lastNObservations = NULL
) {
  params <- character(0L)

  # Build c[DIM] filters (time period + dimension filters)
  sdmx3_filters <- build_sdmx3_filters(
    start_time = start_time,
    end_time = end_time,
    dim_filters = dim_filters
  )
  params <- c(params, sdmx3_filters)

  if (!is.null(updated_after) && nzchar(updated_after)) {
    params <- c(
      params,
      paste0(
        "updatedAfter=",
        utils::URLencode(updated_after, reserved = TRUE)
      )
    )
  }

  if (!is.null(lastNObservations)) {
    params <- c(
      params,
      paste0(
        "lastNObservations=",
        as.integer(lastNObservations)
      )
    )
  }

  params
}

# 7. SDMX 3.0 dimension filter builder -----

#' Build SDMX 3.0 Dimension Filter Parameters
#'
#' Translates time period boundaries and dimension constraints into the SDMX
#' 3.0 query parameter syntax. Time periods are expressed as
#' `c[TIME_PERIOD]=ge:{start}+le:{end}` and arbitrary dimension filters as
#' `c[{DIM}]={value}`.
#'
#' @param start_time Character string specifying the start period (e.g.,
#'   `"2020"`, `"2020-Q1"`, `"2020-01"`). Translated to a `ge:` (greater or
#'   equal) constraint on `TIME_PERIOD`. If `NULL`, no lower bound is applied.
#' @param end_time Character string specifying the end period. Translated to a
#'   `le:` (less or equal) constraint on `TIME_PERIOD`. If `NULL`, no upper
#'   bound is applied.
#' @param dim_filters Named list where names are SDMX dimension identifiers and
#'   values are the corresponding filter expressions. For example,
#'   `list(FREQ = "M", REF_AREA = "IT")` produces `c[FREQ]=M` and
#'   `c[REF_AREA]=IT`. Can be `NULL` for no dimension filtering.
#'
#' @return Character vector of query parameter strings suitable for appending
#'   to a URL query string. Returns a zero-length character vector when no
#'   filters are specified.
#'
#' @examples
#' \dontrun{
#' # Time range only
#' build_sdmx3_filters(start_time = "2020", end_time = "2025")
#' # "c[TIME_PERIOD]=ge:2020+le:2025"
#'
#' # Open-ended time range (no end)
#' build_sdmx3_filters(start_time = "2020")
#' # "c[TIME_PERIOD]=ge:2020"
#'
#' # Dimension filters only
#' build_sdmx3_filters(dim_filters = list(FREQ = "M", REF_AREA = "IT"))
#' # c("c[FREQ]=M", "c[REF_AREA]=IT")
#'
#' # Combined time and dimension filters
#' build_sdmx3_filters(start_time = "2020", end_time = "2025",
#'                     dim_filters = list(FREQ = "M"))
#' # c("c[TIME_PERIOD]=ge:2020+le:2025", "c[FREQ]=M")
#'
#' # No filters
#' build_sdmx3_filters()
#' # character(0)
#' }
#'
#' @keywords internal
build_sdmx3_filters <- function(
  start_time = NULL,
  end_time = NULL,
  dim_filters = NULL
) {
  params <- character(0L)

  # 7a. TIME_PERIOD filter -----
  has_start <- !is.null(start_time) && nzchar(start_time)
  has_end <- !is.null(end_time) && nzchar(end_time)

  if (has_start || has_end) {
    time_parts <- character(0L)

    if (has_start) {
      time_parts <- c(time_parts, paste0("ge:", start_time))
    }

    if (has_end) {
      time_parts <- c(time_parts, paste0("le:", end_time))
    }

    params <- c(
      params,
      paste0(
        "c[TIME_PERIOD]=",
        paste(time_parts, collapse = "+")
      )
    )
  }

  # 7b. Dimension filters -----
  if (
    !is.null(dim_filters) && is.list(dim_filters) && length(dim_filters) > 0L
  ) {
    if (is.null(names(dim_filters)) || any(names(dim_filters) == "")) {
      stop("All elements of 'dim_filters' must be named with dimension IDs")
    }

    dim_params <- vapply(
      names(dim_filters),
      function(dim_name) {
        paste0("c[", dim_name, "]=", dim_filters[[dim_name]])
      },
      character(1L)
    )

    params <- c(params, dim_params)
  }

  params
}

# 8. Accept header builder -----

#' Get HVD Accept Header
#'
#' Returns the appropriate HTTP `Accept` header value for the specified HVD API
#' version, content type, and response format. The SDMX standard uses distinct
#' media types for data and structure endpoints:
#' - Data endpoints: `application/vnd.sdmx.data+{format}`
#' - Structure endpoints: `application/vnd.sdmx.structure+{format}`
#'
#' The version suffix differs between SDMX 2.1 (`1.0.0`) and SDMX 3.0
#' (`2.0.0`).
#'
#' @param api_version Character string, either `"hvd_v1"` or `"hvd_v2"`.
#' @param format Character string specifying the desired response format. One
#'   of `"csv"` (default), `"json"`, or `"xml"`.
#' @param type Character string specifying the content type category. One of
#'   `"data"` (default) for data retrieval endpoints, or `"structure"` for
#'   metadata and structure definition endpoints (dataflow listing, DSD
#'   retrieval, available values). Default `"data"` preserves backward
#'   compatibility.
#'
#' @return Character string containing the Accept header value.
#'
#' @examples
#' \dontrun{
#' # Data headers (default)
#' get_hvd_accept_header("hvd_v1", "csv")
#' # "application/vnd.sdmx.data+csv;version=1.0.0"
#'
#' get_hvd_accept_header("hvd_v2", "json")
#' # "application/vnd.sdmx.data+json;version=2.0.0"
#'
#' # Structure headers for metadata endpoints
#' get_hvd_accept_header("hvd_v1", "json", type = "structure")
#' # "application/vnd.sdmx.structure+json;version=1.0.0"
#'
#' get_hvd_accept_header("hvd_v2", "json", type = "structure")
#' # "application/vnd.sdmx.structure+json;version=2.0.0"
#' }
#'
#' @keywords internal
get_hvd_accept_header <- function(api_version, format = "csv", type = "data") {
  # 8a. Input validation -----
  valid_versions <- c("hvd_v1", "hvd_v2")
  valid_formats <- c("csv", "json", "xml")
  valid_types <- c("data", "structure")

  if (
    missing(api_version) ||
      !is.character(api_version) ||
      length(api_version) != 1L
  ) {
    stop(
      "'api_version' must be a single character string. ",
      "Valid values: ",
      paste(valid_versions, collapse = ", ")
    )
  }

  if (!api_version %in% valid_versions) {
    stop(
      "Unknown API version: '",
      api_version,
      "'. Valid values: ",
      paste(valid_versions, collapse = ", ")
    )
  }

  if (!is.character(format) || length(format) != 1L) {
    stop("'format' must be a single character string")
  }

  format <- tolower(format)
  if (!format %in% valid_formats) {
    stop(
      "Unknown format: '",
      format,
      "'. Valid values: ",
      paste(valid_formats, collapse = ", ")
    )
  }

  if (!is.character(type) || length(type) != 1L) {
    stop("'type' must be a single character string")
  }

  type <- tolower(type)
  if (!type %in% valid_types) {
    stop(
      "Unknown type: '",
      type,
      "'. Valid values: ",
      paste(valid_types, collapse = ", ")
    )
  }

  # 8b. Version string lookup -----
  sdmx_version <- switch(
    EXPR = api_version,
    "hvd_v1" = "1.0.0",
    "hvd_v2" = "2.0.0"
  )

  # 8c. Media type lookup -----
  if (type == "data") {
    media_type <- switch(
      EXPR = format,
      "csv" = "application/vnd.sdmx.data+csv",
      "json" = "application/vnd.sdmx.data+json",
      "xml" = "application/vnd.sdmx.structurespecificdata+xml"
    )
  } else {
    # type == "structure"
    media_type <- switch(
      EXPR = format,
      "csv" = "application/vnd.sdmx.structure+csv",
      "json" = "application/vnd.sdmx.structure+json",
      "xml" = "application/vnd.sdmx.structure+xml"
    )
  }

  paste0(media_type, ";version=", sdmx_version)
}
