#' Download Dataset Metadata
#'
#' Downloads metadata for ISTAT datasets including dataflows, codelists, and dimensions.
#'
#' @param force_update Logical indicating whether to force update of cached metadata.
#'   Default is FALSE, which uses cached data if available and less than 14 days old
#' @param cache_dir Character string specifying the directory for caching metadata.
#'   Default is "meta"
#'
#' @return A list containing dataflows metadata
#' @export
#'
#' @examples
#' \dontrun{
#' # Download metadata (uses cache if available)
#' metadata <- download_metadata()
#' 
#' # Force update of metadata
#' metadata <- download_metadata(force_update = TRUE)
#' }
download_metadata <- function(force_update = FALSE, cache_dir = "meta") {
  
  # Create cache directory if it doesn't exist
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  
  metadata_file <- file.path(cache_dir, "flussi_istat.rds")
  
  # Create file if it doesn't exist
  if (!file.exists(metadata_file)) {
    file.create(metadata_file)
    Sys.setFileTime(metadata_file, "1980-12-04")
  }
  
  # Check if update is needed (file_age in days)
  file_age <- as.numeric(difftime(Sys.time(), file.info(metadata_file)$mtime, units = "days"))
  needs_update <- force_update || (file_age > 14)
  
  if (needs_update) {
    message("Downloading ISTAT metadata...")

    download_result <- tryCatch({
      # Get dataflow endpoint URL from config
      config <- get_istat_config()
      dataflow_url <- config$endpoints$dataflow

      # Download dataflows as JSON and parse
      response <- httr::GET(
        dataflow_url,
        httr::add_headers(Accept = "application/json"),
        httr::timeout(config$defaults$timeout)
      )

      if (httr::status_code(response) != 200) {
        stop("HTTP error: ", httr::status_code(response))
      }

      json_content <- httr::content(response, as = "text", encoding = "UTF-8")
      json_data <- jsonlite::fromJSON(json_content, flatten = FALSE)

      dataflows <- json_data$data$dataflows
      names_df <- dataflows$names

      # Extract dsdRef from structure URN
      extract_dsdref <- function(urn) {
        if (is.null(urn) || is.na(urn)) return(NA_character_)
        m <- regmatches(urn, regexpr("DataStructure=IT1:([^(]+)", urn))
        if (length(m) > 0) gsub("DataStructure=IT1:", "", m) else NA_character_
      }

      # Build data.table with standard column names
      istat_flussi <- data.table::data.table(
        id = dataflows$id,
        agencyID = dataflows$agencyID,
        version = dataflows$version,
        Name.en = names_df$en,
        Name.it = names_df$it,
        dsdRef = sapply(dataflows$structure, extract_dsdref)
      )

      # Save metadata
      saveRDS(istat_flussi, metadata_file)
      message("Metadata downloaded and cached successfully (", nrow(istat_flussi), " datasets)")
      TRUE  # Success indicator

    }, error = function(e) {
      # Check if it's a timeout or connectivity issue
      if (grepl("timeout|Timeout|timed out", e$message, ignore.case = TRUE)) {
        warning("ISTAT metadata request timed out. The server may be experiencing ",
                "high load. Please try again later.")
      } else if (grepl("resolve|connection|network|internet", e$message, ignore.case = TRUE)) {
        warning("Cannot connect to ISTAT API for metadata. Please check your internet ",
                "connection or try again later. Error: ", e$message)
      } else {
        warning("Failed to download metadata: ", e$message)
      }
      FALSE  # Failure indicator
    })
    
    # If download failed, try to load existing cached metadata if available
    if (!download_result) {
      if (file.exists(metadata_file) && file.size(metadata_file) > 0) {
        warning("Download failed but using existing cached metadata")
      } else {
        stop("Cannot download metadata and no cached version available. Please check your internet connection and try again.")
      }
    }
    
  } else {
    message("Using cached metadata (", round(file_age, 1), " days old)")
  }
  
  # Load and return metadata
  if (file.exists(metadata_file) && file.size(metadata_file) > 0) {
    readRDS(metadata_file)
  } else {
    stop("No metadata file available. Please check your internet connection and try download_metadata() again.")
  }
}

#' Get Dataset Dimensions
#'
#' Retrieves the dimension names (codelists) for a specific ISTAT dataset
#' by querying the datastructure endpoint.
#'
#' @param dataset_id Character string specifying the dataset ID
#'
#' @return A character vector of dimension/codelist names for the dataset,
#'   or NULL if the dataset is not found or an error occurs
#' @export
#'
#' @examples
#' \dontrun{
#' # Get dimensions for a dataset
#' dims <- get_dataset_dimensions("534_50")
#' # Returns: c("ATECO_2007", "BASE_YEAR", "CORREZ", "FREQ", ...)
#' }
get_dataset_dimensions <- function(dataset_id) {

  if (!is.character(dataset_id) || length(dataset_id) != 1) {
    stop("dataset_id must be a single character string")
  }

  tryCatch({
    # Use datastructure endpoint to get dimension mapping
    result <- download_single_codelist(dataset_id)

    if (is.null(result) || is.null(result$dimension_mapping) ||
        length(result$dimension_mapping) == 0) {
      warning("No dimension data found for dataset: ", dataset_id)
      return(NULL)
    }

    # Dimension names are the keys of the dimension_mapping
    dimensions <- names(result$dimension_mapping)

    return(dimensions)

  }, error = function(e) {
    if (grepl("timeout|Timeout|timed out", e$message, ignore.case = TRUE)) {
      warning("Request for dataset dimensions timed out. Dataset: ", dataset_id,
              ". Please try again later.")
    } else if (grepl("resolve|connection|network|internet", e$message, ignore.case = TRUE)) {
      warning("Cannot connect to ISTAT API for dataset dimensions. Dataset: ", dataset_id,
              ". Please check your internet connection. Error: ", e$message)
    } else {
      warning("Failed to get dataset dimensions for ", dataset_id, ": ", e$message)
    }
    return(NULL)
  })
}

#' Download Codelists
#'
#' Downloads codelists for ISTAT datasets using a deduplicated cache structure.
#' Codelists are stored by their ID (e.g., CL_FREQ) rather than by dataset,
#' reducing redundant storage since many codelists are shared across datasets.
#'
#' @param dataset_ids Character vector of dataset IDs. If NULL, downloads for all available datasets
#' @param force_update Logical indicating whether to force update of cached codelists
#' @param cache_dir Character string specifying the directory for caching codelists
#'
#' @return A named list of codelists keyed by dataset ID (e.g., "X534_50"),
#'   where each element is a data.table with codelist information
#' @export
#'
#' @examples
#' \dontrun{
#' # Download codelists for specific datasets
#' codelists <- download_codelists(c("150_908", "150_915"))
#'
#' # Download all available codelists
#' all_codelists <- download_codelists()
#' }
download_codelists <- function(dataset_ids = NULL, force_update = FALSE, cache_dir = "meta") {

  # Create cache directory if it doesn't exist
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  config <- get_istat_config()
  codelists_file <- file.path(cache_dir, config$cache$codelists_file)
  map_file <- file.path(cache_dir, config$cache$dataset_map_file)

  # 1. Load existing cache -----
  shared_codelists <- list()
  dataset_map <- list()

  if (file.exists(codelists_file) && file.size(codelists_file) > 0) {
    shared_codelists <- tryCatch(readRDS(codelists_file), error = function(e) list())
  }
  if (file.exists(map_file) && file.size(map_file) > 0) {
    dataset_map <- tryCatch(readRDS(map_file), error = function(e) list())
  }

  # 2. Check cache freshness -----
  file_age <- if (file.exists(codelists_file)) {
    as.numeric(difftime(Sys.time(), file.info(codelists_file)$mtime, units = "days"))
  } else {
    Inf
  }

  # 3. Determine which datasets to process -----
  if (is.null(dataset_ids)) {
    metadata <- download_metadata(cache_dir = cache_dir)
    dataset_ids <- metadata$id
  }

  # Check which datasets are missing from map
  missing_datasets <- dataset_ids[!dataset_ids %in% names(dataset_map)]

  needs_update <- force_update || (file_age > 14) || (length(missing_datasets) > 0)

  if (!needs_update) {
    message("Using cached codelists (", round(file_age, 1), " days old)")
  } else {
    # Determine datasets to download
    datasets_to_download <- if (force_update || file_age > 14) {
      dataset_ids
    } else {
      missing_datasets
    }

    if (length(datasets_to_download) > 0) {
      message("Downloading ISTAT codelists for ", length(datasets_to_download), " dataset(s)...")

      success_count <- 0
      failed_count <- 0

      for (dataset_id in datasets_to_download) {
        result <- tryCatch({
          download_single_codelist(dataset_id)
        }, error = function(e) {
          warning("Failed to download codelist for ", dataset_id, ": ", e$message)
          NULL
        })

        # download_single_codelist now returns list(codelist, dimension_mapping)
        if (!is.null(result) && !is.null(result$codelist) && nrow(result$codelist) > 0) {
          raw_codelist <- result$codelist
          dimension_mapping <- result$dimension_mapping

          # Extract unique codelist IDs from this dataset
          unique_cl_ids <- unique(raw_codelist$id)

          # Store each codelist by its ID (deduplicated)
          for (cl_id in unique_cl_ids) {
            if (!(cl_id %in% names(shared_codelists)) || force_update) {
              cl_data <- raw_codelist[id == cl_id,
                .(id_description, en_description, it_description, version, agencyID)]
              shared_codelists[[cl_id]] <- cl_data
            }
          }

          # Update dataset-to-codelist mapping using the correct dimension mapping
          dataset_map[[dataset_id]] <- list(
            codelists = unique_cl_ids,
            dimensions = dimension_mapping,
            last_updated = Sys.time()
          )

          success_count <- success_count + 1
        } else {
          failed_count <- failed_count + 1
        }
      }

      if (failed_count > 0) {
        warning(failed_count, " dataset(s) failed to download.")
      }

      # 4. Save updated caches -----
      if (success_count > 0) {
        saveRDS(shared_codelists, codelists_file)
        saveRDS(dataset_map, map_file)
        message("Codelists cached: ", length(shared_codelists), " unique codelists for ",
                length(dataset_map), " datasets")
      } else if (length(shared_codelists) == 0) {
        warning("No codelists could be downloaded. Please check your internet connection.")
        return(NULL)
      }
    }
  }

  # 5. Assemble and return per-dataset codelists -----
  # Filter to only requested datasets
  requested_datasets <- dataset_ids[dataset_ids %in% names(dataset_map)]

  if (length(requested_datasets) == 0) {
    warning("No codelists found for requested datasets: ", paste(dataset_ids, collapse = ", "))
    return(NULL)
  }

  # Assemble codelists per dataset for backward compatibility
  result <- list()
  for (dataset_id in requested_datasets) {
    mapping <- dataset_map[[dataset_id]]
    dataset_key <- paste0("X", dataset_id)

    # Combine all codelists for this dataset into single data.table
    dataset_cl_list <- lapply(mapping$codelists, function(cl_id) {
      if (cl_id %in% names(shared_codelists)) {
        dt <- data.table::copy(shared_codelists[[cl_id]])
        dt[, id := cl_id]
        return(dt)
      }
      NULL
    })

    dataset_cl_list <- Filter(Negate(is.null), dataset_cl_list)
    if (length(dataset_cl_list) > 0) {
      result[[dataset_key]] <- data.table::rbindlist(dataset_cl_list, fill = TRUE)
    }
  }

  result
}

#' Download Single Codelist
#'
#' Internal function to download codelist for a single dataset.
#' Fetches JSON from the datastructure endpoint to get both codelist data
#' and the correct dimension-to-codelist mapping.
#'
#' @param dataset_id Character string specifying the dataset ID
#'
#' @return A list with two elements:
#'   \itemize{
#'     \item codelist: data.table containing the codelist with id, id_description,
#'       en_description, it_description, version, agencyID columns
#'     \item dimension_mapping: named list mapping dimension IDs (e.g., REF_AREA)
#'       to codelist references (e.g., "IT1/CL_ITTER107/1.0")
#'   }
#'   Returns NULL if download fails.
#' @keywords internal
download_single_codelist <- function(dataset_id) {

  # Get metadata to find dsdRef
  metadata <- download_metadata()
  data.table::setDT(metadata)

  dsd_ref <- metadata[id == dataset_id]$dsdRef

  if (length(dsd_ref) == 0) {
    stop("Dataset ID not found in metadata: ", dataset_id)
  }

  # Construct API URL for datastructure
  api_url <- build_istat_url("datastructure", dsd_ref = dsd_ref)

  tryCatch({
    # Fetch JSON response
    response <- httr::GET(
      api_url,
      httr::add_headers(Accept = "application/json"),
      httr::timeout(60)
    )

    if (httr::status_code(response) != 200) {
      warning("ISTAT API returned status code: ", httr::status_code(response),
              " for dataset ", dataset_id)
      return(NULL)
    }

    # Parse JSON
    json_content <- httr::content(response, as = "text", encoding = "UTF-8")
    json_data <- jsonlite::fromJSON(json_content, simplifyVector = FALSE)

    # 1. Extract dimension mapping from JSON
    dimension_mapping <- extract_dimension_mapping_from_json(json_data)

    # 2. Extract codelist data from JSON
    codelist_dt <- extract_codelists_from_json(json_data)

    if (is.null(codelist_dt) || nrow(codelist_dt) == 0) {
      warning("No codelist data found in response for dataset ", dataset_id)
      return(NULL)
    }

    return(list(
      codelist = codelist_dt,
      dimension_mapping = dimension_mapping
    ))

  }, error = function(e) {
    if (grepl("timeout|Timeout", e$message, ignore.case = TRUE)) {
      warning("Request timed out for dataset ", dataset_id, ". Please try again later.")
    } else {
      warning("Failed to download codelist for dataset ", dataset_id, ": ", e$message)
    }
    return(NULL)
  })
}

#' Extract Codelists from JSON Response
#'
#' Internal function to extract codelist data from the JSON datastructure response.
#'
#' @param json_data Parsed JSON from datastructure endpoint (as list)
#'
#' @return data.table with codelist data (id, id_description, en_description,
#'   it_description, version, agencyID columns)
#' @keywords internal
extract_codelists_from_json <- function(json_data) {
  result_list <- list()

  tryCatch({
    codelists <- json_data$data$codelists
    if (is.null(codelists)) return(data.table::data.table())

    for (cl in codelists) {
      cl_id <- cl$id
      version <- cl$version
      agency <- cl$agencyID
      codes <- cl$codes

      if (!is.null(codes) && length(codes) > 0) {
        for (code in codes) {
          code_id <- code$id
          names_list <- code$names

          en_desc <- if (!is.null(names_list$en)) names_list$en else code$name
          it_desc <- if (!is.null(names_list$it)) names_list$it else en_desc

          result_list[[length(result_list) + 1]] <- list(
            id = cl_id,
            id_description = code_id,
            en_description = en_desc,
            it_description = it_desc,
            version = version,
            agencyID = agency
          )
        }
      }
    }
  }, error = function(e) {
    warning("Failed to parse codelists from JSON: ", e$message)
  })

  if (length(result_list) == 0) {
    return(data.table::data.table())
  }

  data.table::rbindlist(result_list)
}

#' Expand Dataset IDs to Include All Matching Variants
#'
#' Expands root dataset IDs to include all related datasets from metadata.
#' For example: "534_49" expands to c("534_49", "534_49_DF_DCSC_GI_ORE_10", ...)
#'
#' @param dataset_codes Character vector of dataset codes to expand
#' @param metadata Optional data.table with metadata (fetched if NULL)
#' @param expand Logical, if FALSE returns codes unchanged (default TRUE)
#'
#' @return Character vector with all matching dataset IDs
#' @export
#'
#' @examples
#' \dontrun{
#' # Expand single code
#' ids <- expand_dataset_ids("534_49")
#' # Returns: c("534_49", "534_49_DF_DCSC_GI_ORE_10", ...)
#'
#' # Expand multiple codes
#' ids <- expand_dataset_ids(c("534_49", "155_318"))
#'
#' # Disable expansion
#' ids <- expand_dataset_ids("534_49", expand = FALSE)
#' # Returns: "534_49"
#' }
expand_dataset_ids <- function(dataset_codes, metadata = NULL, expand = TRUE) {
  # Return unchanged if expansion disabled
  if (!expand) {
    return(dataset_codes)
  }

  # Load metadata if not provided
  if (is.null(metadata)) {
    metadata <- download_metadata()
  }

  if (!data.table::is.data.table(metadata)) {
    data.table::setDT(metadata)
  }

  all_ids <- metadata$id
  expanded_ids <- character()

  for (code in dataset_codes) {
    if (grepl("_DF_", code)) {
      # Already a full compound ID, add as-is
      if (code %in% all_ids) {
        expanded_ids <- c(expanded_ids, code)
      } else {
        warning("Dataset not found in metadata: ", code)
      }
    } else {
      # Find all IDs starting with this pattern
      pattern <- paste0("^", code, "($|_)")
      matches <- all_ids[grepl(pattern, all_ids)]
      if (length(matches) > 0) {
        message("Expanded '", code, "' to ", length(matches), " datasets")
        expanded_ids <- c(expanded_ids, matches)
      } else {
        warning("No datasets found matching pattern: ", code)
      }
    }
  }

  unique(expanded_ids)
}

#' Extract Dimension to Codelist Mapping from JSON Response
#'
#' Internal function to extract dimension ID to codelist reference mapping
#' from the JSON datastructure response. This correctly maps dimension IDs
#' (e.g., REF_AREA, SEX) to their corresponding codelists (e.g., CL_ITTER107, CL_SEXISTAT1).
#'
#' @param json_data Parsed JSON from datastructure endpoint (as list)
#'
#' @return Named list mapping dimension IDs to codelist references (e.g., "IT1/CL_FREQ/1.0")
#' @keywords internal
extract_dimension_mapping_from_json <- function(json_data) {
  dimensions <- list()

  tryCatch({
    # Navigate to dimensionList in the JSON structure
    ds <- json_data$data$dataStructures[[1]]
    if (is.null(ds)) return(dimensions)

    dim_list <- ds$dataStructureComponents$dimensionList
    if (is.null(dim_list)) return(dimensions)

    # Process each dimension
    for (d in dim_list$dimensions) {
      dim_id <- d$id
      enum <- d$localRepresentation$enumeration

      if (!is.null(dim_id) && !is.null(enum)) {
        # Extract codelist info from URN
        # Format: urn:sdmx:org.sdmx.infomodel.codelist.Codelist=IT1:CL_FREQ(1.0)
        cl_match <- regmatches(enum, regexec("Codelist=([^:]+):([^(]+)[(]([^)]+)[)]", enum))[[1]]

        if (length(cl_match) == 4) {
          agency <- cl_match[2]
          cl_id <- cl_match[3]
          version <- cl_match[4]
          dimensions[[dim_id]] <- paste0(agency, "/", cl_id, "/", version)
        }
      }
    }
  }, error = function(e) {
    warning("Failed to parse dimension mapping from JSON: ", e$message)
  })

  return(dimensions)
}

#' Extract Dimension to Codelist Mapping
#'
#' Internal function to extract dimension name to codelist reference mapping.
#' This is a wrapper that handles different input types for backward compatibility.
#'
#' @param raw_codelist data.table containing raw codelist data with id, version, agencyID columns.
#'   This is used as a fallback when JSON parsing is not available.
#' @param json_data Optional parsed JSON from datastructure endpoint (preferred source)
#'
#' @return Named list mapping dimension names to codelist references (e.g., "IT1/CL_FREQ/1.0")
#' @keywords internal
extract_dimension_mapping <- function(raw_codelist, json_data = NULL) {
  # Prefer JSON data if available (accurate dimension ID mapping)
  if (!is.null(json_data)) {
    return(extract_dimension_mapping_from_json(json_data))
  }

  # Fallback: infer from codelist data (legacy behavior, may be inaccurate)
  if (!data.table::is.data.table(raw_codelist) || nrow(raw_codelist) == 0) {
    return(list())
  }

  codelist_ids <- unique(raw_codelist$id)
  dimensions <- list()

  for (cl_id in codelist_ids) {
    # Extract dimension name by removing CL_ prefix
    dim_name <- gsub("^CL_", "", cl_id)

    # Get version and agency from data
    cl_subset <- raw_codelist[id == cl_id]
    if (nrow(cl_subset) > 0) {
      version <- cl_subset$version[1]
      agency <- cl_subset$agencyID[1]
      dimensions[[dim_name]] <- paste0(agency, "/", cl_id, "/", version)
    }
  }

  return(dimensions)
}

#' Get Codelists Used by Dataset
#'
#' Retrieves the list of codelist IDs used by a specific dataset from the cache.
#'
#' @param dataset_id Character string specifying the dataset ID
#' @param cache_dir Character string specifying the cache directory
#'
#' @return Character vector of codelist IDs (e.g., c("CL_FREQ", "CL_ITTER107")),
#'   or NULL if dataset not found in cache
#' @export
#'
#' @examples
#' \dontrun{
#' # Get codelists for a dataset
#' codelists <- get_dataset_codelists("534_50")
#' # Returns: c("CL_FREQ", "CL_ITTER107", "CL_ATECO_2007", ...)
#' }
get_dataset_codelists <- function(dataset_id, cache_dir = "meta") {
  config <- get_istat_config()
  map_file <- file.path(cache_dir, config$cache$dataset_map_file)

  if (!file.exists(map_file)) {
    warning("Dataset codelist map not found. Run download_codelists() first.")
    return(NULL)
  }

  dataset_map <- readRDS(map_file)

  if (dataset_id %in% names(dataset_map)) {
    return(dataset_map[[dataset_id]]$codelists)
  }

  warning("Dataset not found in codelist map: ", dataset_id)
  NULL
}

#' Get Dataset Last Update Timestamp from ISTAT API
#'
#' Fetches the LAST_UPDATE timestamp from the ISTAT dataflow endpoint for a specific dataset.
#' This timestamp indicates when ISTAT last updated the dataset and can be used to determine
#' if cached data needs refreshing.
#'
#' @param dataset_id Character string specifying the dataset ID
#' @param timeout Numeric timeout in seconds for the API request. Default 30
#'
#' @return POSIXct timestamp of the last update, or NULL if not available
#' @export
#'
#' @examples
#' \dontrun{
#' # Get last update timestamp for a dataset
#' last_update <- get_dataset_last_update("534_50")
#' # Returns: POSIXct "2025-12-17 10:06:46 UTC"
#' }
get_dataset_last_update <- function(dataset_id, timeout = 30) {

  if (!is.character(dataset_id) || length(dataset_id) != 1) {
    stop("dataset_id must be a single character string")
  }

  config <- get_istat_config()
  url <- paste0(config$endpoints$dataflow, "/IT1/", dataset_id)

  tryCatch({
    # Request JSON response (default format from ISTAT API)
    response <- httr::GET(
      url,
      httr::add_headers(Accept = "application/json"),
      httr::timeout(timeout)
    )

    if (httr::status_code(response) != 200) {
      warning("Failed to fetch dataflow for ", dataset_id, ": HTTP ", httr::status_code(response))
      return(NULL)
    }

    json_content <- httr::content(response, as = "text", encoding = "UTF-8")
    json_data <- jsonlite::fromJSON(json_content, flatten = FALSE)

    # Navigate to annotations in the dataflow structure
    dataflows <- json_data$data$dataflows
    if (is.null(dataflows) || length(dataflows) == 0) {
      warning("No dataflow found in response for ", dataset_id)
      return(NULL)
    }

    annotations <- dataflows$annotations[[1]]
    if (is.null(annotations)) {
      warning("No annotations found for ", dataset_id)
      return(NULL)
    }

    # Find LAST_UPDATE annotation
    last_update_row <- annotations[annotations$id == "LAST_UPDATE", ]
    if (nrow(last_update_row) == 0) {
      warning("LAST_UPDATE annotation not found for ", dataset_id)
      return(NULL)
    }

    timestamp_str <- last_update_row$title[1]

    # Parse ISO 8601 timestamp
    # Handle format: 2025-12-17T10:06:46.972Z
    timestamp <- as.POSIXct(timestamp_str, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")

    if (is.na(timestamp)) {
      # Try without milliseconds
      timestamp <- as.POSIXct(timestamp_str, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    }

    return(timestamp)

  }, error = function(e) {
    if (grepl("timeout|Timeout", e$message, ignore.case = TRUE)) {
      warning("Request for LAST_UPDATE timed out for ", dataset_id)
    } else {
      warning("Failed to get LAST_UPDATE for ", dataset_id, ": ", e$message)
    }
    return(NULL)
  })
}

