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
  
  # Check if update is needed
  file_age <- Sys.time() - file.info(metadata_file)$mtime
  needs_update <- force_update || (file_age > 14)
  
  if (needs_update) {
    message("Downloading ISTAT metadata...")
    
    tryCatch({
      # Set up ISTAT provider
      if (!requireNamespace("rsdmx", quietly = TRUE)) {
        stop("Package 'rsdmx' is required for metadata download")
      }
      
      istat_provider <- rsdmx::SDMXServiceProvider(
        agencyId = "ISTAT2",
        name = "Istituto nazionale di statistica (Italia)",
        scale = "national",
        country = "ITA",
        builder = rsdmx::SDMXREST21RequestBuilder(
          regUrl = "https://esploradati.istat.it/SDMXWS/rest",
          repoUrl = "https://esploradati.istat.it/SDMXWS/rest",
          compliant = TRUE
        )
      )
      
      rsdmx::addSDMXServiceProvider(istat_provider)
      
      # Download dataflows
      istat_flussi <- rsdmx::readSDMX(providerId = "ISTAT2", resource = "dataflow")
      istat_flussi <- data.table::as.data.table(istat_flussi)
      
      # Save metadata
      saveRDS(istat_flussi, metadata_file)
      message("Metadata downloaded and cached successfully")
      
    }, error = function(e) {
      stop("Failed to download metadata: ", e$message)
    })
    
  } else {
    message("Using cached metadata (", round(file_age, 1), " days old)")
  }
  
  # Load and return metadata
  readRDS(metadata_file)
}

#' Get Dataset Dimensions
#'
#' Retrieves the dimensions for a specific ISTAT dataset.
#'
#' @param dataset_id Character string specifying the dataset ID
#'
#' @return A list of dimensions for the dataset
#' @export
#'
#' @examples
#' \dontrun{
#' # Get dimensions for a dataset
#' dims <- get_dataset_dimensions("150_908")
#' }
get_dataset_dimensions <- function(dataset_id) {
  
  if (!is.character(dataset_id) || length(dataset_id) != 1) {
    stop("dataset_id must be a single character string")
  }
  
  tryCatch({
    if (requireNamespace("RJSDMX", quietly = TRUE)) {
      RJSDMX::getDimensions("ISTAT_RI", as.character(dataset_id))
    } else {
      warning("RJSDMX package not available. Cannot retrieve dimensions.")
      return(NULL)
    }
  }, error = function(e) {
    stop("Failed to get dataset dimensions: ", e$message)
  })
}

#' Download Codelists
#'
#' Downloads codelists for ISTAT datasets.
#'
#' @param dataset_ids Character vector of dataset IDs. If NULL, downloads for all available datasets
#' @param force_update Logical indicating whether to force update of cached codelists
#' @param cache_dir Character string specifying the directory for caching codelists
#'
#' @return A named list of codelists
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
  
  codelist_file <- file.path(cache_dir, "cl_all.rds")
  
  # Create file if it doesn't exist
  if (!file.exists(codelist_file)) {
    file.create(codelist_file)
    Sys.setFileTime(codelist_file, "1980-12-04")
  }
  
  # Check if update is needed
  file_age <- Sys.time() - file.info(codelist_file)$mtime
  needs_update <- force_update || (file_age > 14)
  
  if (needs_update) {
    message("Downloading ISTAT codelists...")
    
    # Get metadata if dataset_ids not provided
    if (is.null(dataset_ids)) {
      metadata <- download_metadata(cache_dir = cache_dir)
      dataset_ids <- metadata$id
    }
    
    tryCatch({
      # Download codelists
      codelists <- parallel::mclapply(dataset_ids, download_single_codelist)
      names(codelists) <- paste0("X", dataset_ids)
      
      # Filter out NULL results and warn user
      valid_codelists <- codelists[!sapply(codelists, is.null)]
      failed_count <- length(codelists) - length(valid_codelists)
      
      if (failed_count > 0) {
        warning(failed_count, " dataset(s) failed to download due to connectivity issues.")
        warning("Successfully downloaded ", length(valid_codelists), " out of ", length(codelists), " datasets.")
      }
      
      if (length(valid_codelists) > 0) {
        # Save valid codelists
        saveRDS(valid_codelists, codelist_file)
        message("Codelists downloaded and cached successfully (", length(valid_codelists), " datasets)")
      } else {
        warning("No codelists could be downloaded. Please check your internet connection and try again later.")
        return(NULL)
      }
      
    }, error = function(e) {
      stop("Failed to download codelists: ", e$message)
    })
    
  } else {
    message("Using cached codelists (", round(file_age, 1), " days old)")
  }
  
  # Load and return codelists
  readRDS(codelist_file)
}

#' Download Single Codelist
#'
#' Internal function to download codelist for a single dataset.
#'
#' @param dataset_id Character string specifying the dataset ID
#'
#' @return A data.table containing the codelist
#' @keywords internal
download_single_codelist <- function(dataset_id) {
  
  # Get metadata to find dsdRef
  metadata <- download_metadata()
  data.table::setDT(metadata)
  
  dsd_ref <- metadata[id == dataset_id]$dsdRef
  
  if (length(dsd_ref) == 0) {
    stop("Dataset ID not found in metadata: ", dataset_id)
  }
  
  # Construct API URL for codelist
  api_url <- paste0(
    "https://esploradati.istat.it/SDMXWS/rest/datastructure/IT1/",
    dsd_ref,
    "/1.0?references=children"
  )
  
  tryCatch({
    # Test URL connectivity first with timeout
    test_result <- tryCatch({
      # Use httr or curl with timeout to test connectivity
      if (requireNamespace("httr", quietly = TRUE)) {
        httr::GET(api_url, httr::timeout(30))
      } else {
        # Fallback: try direct connection with shorter timeout
        readsdmx::read_sdmx(api_url)
      }
    }, error = function(e) {
      stop("Cannot connect to ISTAT API. The server may be temporarily unavailable. Please try again later or check your internet connection. Error: ", e$message)
    })
    
    # If httr was used for testing, now use readsdmx
    if (requireNamespace("httr", quietly = TRUE) && inherits(test_result, "response")) {
      if (httr::status_code(test_result) == 200) {
        result <- readsdmx::read_sdmx(api_url)
        data.table::setDT(result)
        return(result)
      } else {
        stop("ISTAT API returned status code: ", httr::status_code(test_result))
      }
    } else {
      # test_result is already the readsdmx result
      data.table::setDT(test_result)
      return(test_result)
    }
    
  }, error = function(e) {
    warning("Failed to download codelist for dataset ", dataset_id, ": ", e$message)
    warning("This might be a temporary connectivity issue with ISTAT's servers.")
    warning("Returning NULL for this dataset. You can try again later.")
    return(NULL)
  })
}

#' Cache Dataset Configuration
#'
#' Creates and caches dataset configurations from configuration files.
#'
#' @param config_path Character string specifying the path to configuration files.
#'   Default is "conf"
#'
#' @return A named list of dataset configurations
#' @export
#'
#' @examples
#' \dontrun{
#' # Load dataset configurations
#' configs <- cache_dataset_configs("conf")
#' }
cache_dataset_configs <- function(config_path = "conf") {
  
  if (!dir.exists(config_path)) {
    stop("Configuration directory does not exist: ", config_path)
  }
  
  config_files <- list.files(path = config_path, full.names = TRUE)
  
  if (length(config_files) == 0) {
    stop("No configuration files found in: ", config_path)
  }
  
  # Source all configuration files
  flussi <- list()
  for (file in config_files) {
    source(file, local = TRUE)
  }
  
  # Clean names
  if (exists("flussi")) {
    names(flussi) <- make.names(flussi)
    return(flussi)
  } else {
    stop("No 'flussi' object found in configuration files")
  }
}