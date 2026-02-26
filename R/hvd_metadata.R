# hvd_metadata.R - HVD metadata retrieval and connectivity testing
# Provides data structure discovery, dataflow listing, and endpoint health checks
# for the ISTAT Historical Data Vault (esploradati.istat.it/hvd)

# 1. Internal metadata retrieval -----

#' Retrieve HVD Data Structure Definition
#'
#' Fetches the data structure definition (DSD) for a dataset from the ISTAT
#' Historical Data Vault. The DSD describes dimensions, attributes, and measures
#' that compose the dataset.
#'
#' @param dataset_id Character string specifying the dataset identifier
#'   (e.g., `"22_289"`).
#' @param api_version Character string indicating the API surface to use.
#'   One of `"hvd_v1"` (default) or `"hvd_v2"`.
#' @param timeout Numeric timeout in seconds for the HTTP request. Default 120.
#' @param verbose Logical controlling structured logging output. Default TRUE.
#'
#' @return A parsed JSON list representing the data structure definition,
#'   or `NULL` if the request fails.
#' @keywords internal
hvd_get_structure <- function(
  dataset_id,
  api_version = "hvd_v1",
  timeout = 120,
  verbose = TRUE
) {
  # 1.1 Input validation -----
  if (
    !is.character(dataset_id) ||
      length(dataset_id) != 1 ||
      is.na(dataset_id) ||
      nchar(trimws(dataset_id)) == 0
  ) {
    stop(
      "dataset_id must be a non-empty character string, got: ",
      deparse(dataset_id)
    )
  }

  validate_api_surface(api_version)

  if (
    !is.numeric(timeout) ||
      length(timeout) != 1 ||
      is.na(timeout) ||
      timeout <= 0
  ) {
    stop("timeout must be a positive number, got: ", deparse(timeout))
  }

  # 1.2 Build URL -----
  base_url <- get_hvd_base_url()
  dsd_ref <- paste0("DSD_", dataset_id)

  url <- switch(
    api_version,
    "hvd_v1" = paste0(
      base_url,
      "/rest/datastructure/IT1/",
      dsd_ref,
      "/1.0?references=children"
    ),
    "hvd_v2" = paste0(
      base_url,
      "/rest/v2/structure/datastructure/IT1/",
      dsd_ref,
      "/~"
    )
  )

  accept_header <- get_hvd_accept_header(api_version, "json")

  istat_log(
    paste0(
      "Retrieving DSD for dataset '",
      dataset_id,
      "' via HVD ",
      api_version
    ),
    "INFO",
    verbose
  )

  # 1.3 Execute request -----
  result <- tryCatch(
    {
      resp <- http_get_with_retry(
        url,
        timeout = timeout,
        accept = accept_header,
        verbose = verbose
      )

      if (!resp$success) {
        warning(
          "Failed to retrieve DSD for dataset '",
          dataset_id,
          "': ",
          resp$error %||% paste("HTTP", resp$status_code),
          call. = FALSE
        )
        return(NULL)
      }

      jsonlite::fromJSON(resp$content, simplifyVector = FALSE)
    },
    error = function(e) {
      warning(
        "Error retrieving DSD for dataset '",
        dataset_id,
        "': ",
        e$message,
        call. = FALSE
      )
      NULL
    }
  )

  result
}

# 2. Available values retrieval -----

#' Retrieve Available Values for a Dimension
#'
#' Queries the HVD availability endpoint to discover valid values for one or
#' all dimensions of a dataset. This is useful for building filter keys before
#' downloading data.
#'
#' @param dataset_id Character string specifying the dataset identifier.
#' @param dimension Character string specifying the dimension to query, or
#'   `"all"` (default) to retrieve values for every dimension.
#' @param api_version Character string indicating the API surface to use.
#'   One of `"hvd_v1"` (default) or `"hvd_v2"`.
#' @param timeout Numeric timeout in seconds for the HTTP request. Default 120.
#' @param verbose Logical controlling structured logging output. Default TRUE.
#'
#' @return A parsed JSON list representing the available values,
#'   or `NULL` if the request fails.
#' @keywords internal
hvd_get_available_values <- function(
  dataset_id,
  dimension = "all",
  api_version = "hvd_v1",
  timeout = 120,
  verbose = TRUE
) {
  # 2.1 Input validation -----
  if (
    !is.character(dataset_id) ||
      length(dataset_id) != 1 ||
      is.na(dataset_id) ||
      nchar(trimws(dataset_id)) == 0
  ) {
    stop(
      "dataset_id must be a non-empty character string, got: ",
      deparse(dataset_id)
    )
  }

  if (
    !is.character(dimension) ||
      length(dimension) != 1 ||
      is.na(dimension) ||
      nchar(trimws(dimension)) == 0
  ) {
    stop(
      "dimension must be a non-empty character string, got: ",
      deparse(dimension)
    )
  }

  validate_api_surface(api_version)

  if (
    !is.numeric(timeout) ||
      length(timeout) != 1 ||
      is.na(timeout) ||
      timeout <= 0
  ) {
    stop("timeout must be a positive number, got: ", deparse(timeout))
  }

  # 2.2 Build URL -----
  url <- switch(
    api_version,
    "hvd_v1" = build_hvd_v1_url(
      "availableconstraint",
      dataset_id = dataset_id
    ),
    "hvd_v2" = build_hvd_v2_url(
      "availability",
      dataset_id = dataset_id,
      component_id = dimension
    )
  )

  accept_header <- get_hvd_accept_header(api_version, "json")

  istat_log(
    paste0(
      "Retrieving available values for dimension '",
      dimension,
      "' of dataset '",
      dataset_id,
      "' via HVD ",
      api_version
    ),
    "INFO",
    verbose
  )

  # 2.3 Execute request -----
  result <- tryCatch(
    {
      resp <- http_get_with_retry(
        url,
        timeout = timeout,
        accept = accept_header,
        verbose = verbose
      )

      if (!resp$success) {
        warning(
          "Failed to retrieve available values for dataset '",
          dataset_id,
          "', dimension '",
          dimension,
          "': ",
          resp$error %||% paste("HTTP", resp$status_code),
          call. = FALSE
        )
        return(NULL)
      }

      jsonlite::fromJSON(resp$content, simplifyVector = FALSE)
    },
    error = function(e) {
      warning(
        "Error retrieving available values for dataset '",
        dataset_id,
        "': ",
        e$message,
        call. = FALSE
      )
      NULL
    }
  )

  result
}

# 3. List HVD dataflows -----

#' List Available HVD Dataflows
#'
#' Retrieves the catalogue of all dataflows published on the ISTAT Historical
#' Data Vault. Each dataflow corresponds to a downloadable dataset with its
#' own data structure definition.
#'
#' @param api_version Character string indicating the API surface to use.
#'   One of `"hvd_v1"` (default) or `"hvd_v2"`.
#' @param timeout Numeric timeout in seconds for the HTTP request. Default 120.
#' @param verbose Logical controlling structured logging output. Default TRUE.
#'
#' @return A [data.table::data.table] with columns `id`, `name`, `description`,
#'   and `agency`, or `NULL` if the request fails. A warning is issued on
#'   failure.
#' @export
#'
#' @examples
#' \dontrun{
#' # List all HVD dataflows using the v1 API
#' flows <- list_hvd_dataflows()
#' print(flows)
#'
#' # List dataflows using the v2 API
#' flows_v2 <- list_hvd_dataflows(api_version = "hvd_v2")
#' }
list_hvd_dataflows <- function(
  api_version = "hvd_v1",
  timeout = 120,
  verbose = TRUE
) {
  # 3.1 Input validation -----
  validate_api_surface(api_version)

  if (
    !is.numeric(timeout) ||
      length(timeout) != 1 ||
      is.na(timeout) ||
      timeout <= 0
  ) {
    stop("timeout must be a positive number, got: ", deparse(timeout))
  }

  # 3.2 Build URL -----
  base_url <- get_hvd_base_url()

  url <- switch(
    api_version,
    "hvd_v1" = paste0(base_url, "/rest/dataflow"),
    "hvd_v2" = paste0(base_url, "/rest/v2/structure/dataflow/*/*/~")
  )

  accept_header <- get_hvd_accept_header(api_version, "json")

  istat_log(
    paste0("Listing HVD dataflows via ", api_version),
    "INFO",
    verbose
  )

  # 3.3 Execute request -----
  json_data <- tryCatch(
    {
      resp <- http_get_with_retry(
        url,
        timeout = timeout,
        accept = accept_header,
        verbose = verbose
      )

      if (!resp$success) {
        warning(
          "Failed to retrieve HVD dataflows: ",
          resp$error %||% paste("HTTP", resp$status_code),
          call. = FALSE
        )
        return(NULL)
      }

      jsonlite::fromJSON(resp$content, simplifyVector = FALSE)
    },
    error = function(e) {
      warning(
        "Error retrieving HVD dataflows: ",
        e$message,
        call. = FALSE
      )
      return(NULL)
    }
  )

  if (is.null(json_data)) {
    return(NULL)
  }

  # 3.4 Parse response into data.table -----
  dataflows <- tryCatch(
    .parse_hvd_dataflows(json_data, api_version),
    error = function(e) {
      warning(
        "Failed to parse HVD dataflow response: ",
        e$message,
        call. = FALSE
      )
      NULL
    }
  )

  if (!is.null(dataflows) && verbose) {
    istat_log(
      paste0("Retrieved ", nrow(dataflows), " HVD dataflows"),
      "INFO",
      verbose
    )
  }

  dataflows
}

# 4. Dataflow response parser -----

#' Parse HVD Dataflow JSON Response
#'
#' Extracts dataflow identifiers, names, descriptions, and agencies from a
#' parsed SDMX JSON response. Handles structural differences between v1 and
#' v2 response formats.
#'
#' @param json_data Parsed JSON list from the dataflow endpoint.
#' @param api_version Character string indicating the API version used.
#'
#' @return A [data.table::data.table] with columns `id`, `name`,
#'   `description`, and `agency`.
#' @keywords internal
.parse_hvd_dataflows <- function(json_data, api_version) {
  # Navigate SDMX JSON structure to find dataflow array
  flows <- NULL

  if (api_version == "hvd_v1") {
    # v1 path: $Structure$Dataflows$Dataflow (SDMX 2.1 JSON)
    flows <- json_data[["Structure"]][["Dataflows"]][["Dataflow"]]
    if (is.null(flows)) {
      # Alternative path for some SDMX implementations
      flows <- json_data[["Dataflows"]][["Dataflow"]]
    }
  } else if (api_version == "hvd_v2") {
    # v2 path: $data$dataflows (SDMX 3.0 JSON)
    flows <- json_data[["data"]][["dataflows"]]
    if (is.null(flows)) {
      flows <- json_data[["Dataflow"]]
    }
  }

  if (is.null(flows) || length(flows) == 0) {
    warning("No dataflows found in HVD response", call. = FALSE)
    return(data.table::data.table(
      id = character(),
      name = character(),
      description = character(),
      agency = character()
    ))
  }

  # Extract fields from each dataflow entry
  parsed <- lapply(flows, function(flow) {
    flow_id <- flow[["id"]] %||% NA_character_
    agency <- flow[["agencyID"]] %||% NA_character_

    # Names may be multilingual; prefer Italian, fall back to English
    name_obj <- flow[["Name"]] %||% flow[["name"]] %||% flow[["names"]]
    flow_name <- .extract_localized_text(name_obj)

    # Descriptions follow the same multilingual pattern
    desc_obj <- flow[["Description"]] %||%
      flow[["description"]] %||%
      flow[["descriptions"]]
    flow_desc <- .extract_localized_text(desc_obj)

    list(
      id = flow_id,
      name = flow_name,
      description = flow_desc,
      agency = agency
    )
  })

  data.table::rbindlist(parsed, use.names = TRUE, fill = TRUE)
}

# 5. Localized text extraction helper -----

#' Extract Localized Text from SDMX Multilingual Object
#'
#' SDMX responses encode names and descriptions in multiple languages.
#' This helper extracts the Italian text when available, falling back to
#' English and then to the first available language.
#'
#' @param text_obj An SDMX text object, which may be a character string, a
#'   named list (e.g., `list(it = "...", en = "...")`), or a list of
#'   `list(lang = "it", value = "...")` entries.
#'
#' @return A single character string with the extracted text,
#'   or `NA_character_` if no text is found.
#' @keywords internal
.extract_localized_text <- function(text_obj) {
  if (is.null(text_obj)) {
    return(NA_character_)
  }

  # Simple character string

  if (is.character(text_obj) && length(text_obj) == 1) {
    return(text_obj)
  }

  # Named list: list(it = "...", en = "...")
  if (is.list(text_obj) && !is.null(names(text_obj))) {
    if ("it" %in% names(text_obj)) {
      return(text_obj[["it"]])
    }
    if ("en" %in% names(text_obj)) {
      return(text_obj[["en"]])
    }
    # First available value
    first_val <- text_obj[[1]]
    if (is.character(first_val)) return(first_val)
  }

  # Array of {lang, value} objects (common in SDMX 2.1 JSON)
  if (is.list(text_obj) && is.null(names(text_obj)) && length(text_obj) > 0) {
    langs <- vapply(text_obj, function(x) x[["lang"]] %||% "", character(1))
    values <- vapply(text_obj, function(x) x[["value"]] %||% "", character(1))

    # Prefer Italian
    it_idx <- which(langs == "it")
    if (length(it_idx) > 0) {
      return(values[it_idx[1]])
    }

    # Fall back to English
    en_idx <- which(langs == "en")
    if (length(en_idx) > 0) {
      return(values[en_idx[1]])
    }

    # First available
    if (length(values) > 0 && nchar(values[1]) > 0) return(values[1])
  }

  NA_character_
}

# 6. HVD connectivity testing -----

#' Test HVD Endpoint Connectivity
#'
#' Performs lightweight HEAD-only requests against HVD API endpoints to verify
#' that the service is reachable. Tests both data and structure endpoints for
#' each requested API version.
#'
#' @param version Character vector specifying which API versions to test.
#'   Valid values are `"v1"` and `"v2"`. Defaults to `c("v1", "v2")`, which
#'   tests both.
#' @param timeout Numeric timeout in seconds for each individual connectivity
#'   check. Default 30.
#' @param verbose Logical controlling structured logging and summary output.
#'   Default TRUE.
#'
#' @return A data.frame with one row per tested endpoint and the following
#'   columns:
#'   \describe{
#'     \item{version}{Character. API version (`"v1"` or `"v2"`).}
#'     \item{endpoint}{Character. Endpoint type (`"data"` or `"structure"`).}
#'     \item{url}{Character. Full URL that was tested.}
#'     \item{accessible}{Logical. Whether the endpoint responded successfully.}
#'     \item{status_code}{Integer. HTTP status code, or `NA` on connection
#'       failure.}
#'     \item{response_time}{Numeric. Round-trip time in seconds.}
#'     \item{error_message}{Character. Error description, or empty string on
#'       success.}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' # Test both v1 and v2 endpoints
#' status <- test_hvd_connectivity()
#'
#' # Test only v1 endpoints
#' status <- test_hvd_connectivity(version = "v1")
#'
#' # Test with a shorter timeout
#' status <- test_hvd_connectivity(timeout = 10, verbose = FALSE)
#' }
test_hvd_connectivity <- function(
  version = c("v1", "v2"),
  timeout = 30,
  verbose = TRUE
) {
  # 6.1 Input validation -----
  valid_versions <- c("v1", "v2")
  invalid <- setdiff(version, valid_versions)
  if (length(invalid) > 0) {
    stop(
      "Invalid version(s): ",
      paste(invalid, collapse = ", "),
      ". Must be one or more of: ",
      paste(valid_versions, collapse = ", ")
    )
  }

  if (
    !is.numeric(timeout) ||
      length(timeout) != 1 ||
      is.na(timeout) ||
      timeout <= 0
  ) {
    stop("timeout must be a positive number, got: ", deparse(timeout))
  }

  # 6.2 Define endpoint URLs -----
  base_url <- get_hvd_base_url()

  endpoint_map <- list(
    v1 = list(
      data = paste0(base_url, "/rest/data"),
      structure = paste0(base_url, "/rest/dataflow")
    ),
    v2 = list(
      data = paste0(base_url, "/rest/v2/data"),
      structure = paste0(base_url, "/rest/v2/structure")
    )
  )

  # 6.3 Test each endpoint -----
  results <- data.frame(
    version = character(),
    endpoint = character(),
    url = character(),
    accessible = logical(),
    status_code = integer(),
    response_time = numeric(),
    error_message = character(),
    stringsAsFactors = FALSE
  )

  for (ver in version) {
    endpoints <- endpoint_map[[ver]]
    for (ep_name in names(endpoints)) {
      test_url <- endpoints[[ep_name]]

      if (verbose) {
        istat_log(
          paste0("Testing HVD ", ver, " ", ep_name, " endpoint..."),
          "INFO",
          verbose
        )
      }

      status <- check_endpoint_status(test_url, timeout = timeout)

      results <- rbind(
        results,
        data.frame(
          version = ver,
          endpoint = ep_name,
          url = test_url,
          accessible = status$accessible,
          status_code = status$status_code,
          response_time = status$response_time,
          error_message = status$error,
          stringsAsFactors = FALSE
        )
      )
    }
  }

  # 6.4 Print summary -----
  if (verbose) {
    istat_log("HVD endpoint connectivity summary:", "INFO", verbose)
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
        "  %-6s %-12s %s %s (%s)",
        results$version[i],
        results$endpoint[i],
        status_text,
        code_text,
        time_text
      ))
    }
  }

  results
}
