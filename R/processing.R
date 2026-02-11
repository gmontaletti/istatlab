#' Extract Root Dataset ID from Compound ID
#'
#' Extracts the root dataset ID from compound ISTAT dataset IDs.
#' For example: "534_49_DF_DCSC_GI_ORE_10" -> "534_49"
#'
#' @param dataset_id Character string with full dataset ID
#' @return Character string with root dataset ID
#' @keywords internal
extract_root_dataset_id <- function(dataset_id) {
  # Pattern: root IDs are numeric parts before "_DF_" suffix
  # Examples:
  #   "534_49_DF_DCSC_GI_ORE_10" -> "534_49"
  #   "168_756_DF_DCSP_IPCATC1B2015_1" -> "168_756"
  #   "534_50" -> "534_50" (unchanged, no _DF_ suffix)

  if (grepl("_DF_", dataset_id)) {
    # Extract everything before _DF_
    root_id <- sub("_DF_.*$", "", dataset_id)
    return(root_id)
  }

  # No compound suffix, return as-is
  return(dataset_id)
}

#' Apply Labels to ISTAT Data
#'
#' Processes raw ISTAT data by applying dimension labels and formatting time variables.
#' This function has been heavily optimized using data.table's advanced features for
#' maximum performance on large datasets.
#'
#' @param data A data.table containing raw ISTAT data
#' @param codelists A named list of codelists for dimension labeling.
#'   If NULL, attempts to load from cache
#' @param var_dimensions A list of variable dimensions mapping.
#'   If NULL, attempts to load from cache
#' @param timing Logical indicating whether to track execution time.
#'   If TRUE, adds execution_time attribute to result
#' @param verbose Logical indicating whether to print detailed timing information.
#'   Only used when timing = TRUE
#'
#' @return A processed data.table with labels applied. If timing = TRUE,
#'   includes an execution_time attribute with total runtime in seconds
#' @export
#'
#' @details
#' **Performance Optimizations:**
#' \itemize{
#'   \item Metadata caching to avoid repeated file I/O
#'   \item Vectorized data.table joins instead of iterative merges
#'   \item Key-based operations for ultra-fast lookups
#'   \item Reference semantics to minimize memory copying
#'   \item Optimized column filtering using uniqueN()
#'   \item In-place factor conversion using set() operations
#' }
#'
#' For large datasets (>100K rows), this optimized version can be 5-10x faster
#' than the original implementation.
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' raw_data <- download_istat_data("150_908")
#' labeled_data <- apply_labels(raw_data)
#'
#' # With performance timing
#' labeled_data <- apply_labels(raw_data, timing = TRUE, verbose = TRUE)
#' execution_time <- attr(labeled_data, "execution_time")
#' }
apply_labels <- function(
  data,
  codelists = NULL,
  var_dimensions = NULL,
  timing = FALSE,
  verbose = FALSE
) {
  # Initialize timing
  if (timing) {
    start_time <- Sys.time()
  }

  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }

  # Work with reference to avoid copying
  df <- data.table::copy(data)

  if (timing && verbose) {
    message("Setup time: ", round(as.numeric(Sys.time() - start_time), 3), "s")
    metadata_start <- Sys.time()
  }

  # Optimized metadata loading with static caching
  metadata <- load_metadata_cached(codelists, var_dimensions)
  codelists <- metadata$codelists
  var_dimensions <- metadata$var_dimensions

  if (timing && verbose) {
    message(
      "Metadata loading time: ",
      round(as.numeric(Sys.time() - metadata_start), 3),
      "s"
    )
    processing_start <- Sys.time()
  }

  # Get dimension names (exclude standard columns) - vectorized
  standard_cols <- c("ObsDimension", "ObsValue", "id")
  dimension_names <- setdiff(names(df), standard_cols)

  # Convert dimension columns to character - single operation
  if (length(dimension_names) > 0) {
    df[,
      (dimension_names) := lapply(.SD, as.character),
      .SDcols = dimension_names
    ]
  }

  # Get dataset-specific codelists and dimensions
  dataset_id <- df$id[1L] # Use first element instead of unique() for speed
  if (is.na(dataset_id)) {
    stop("Data contains no dataset ID")
  }

  dataset_key <- paste0("X", dataset_id)
  dataset_codelists <- codelists[[dataset_key]]
  dataset_dimensions <- var_dimensions[[dataset_key]]

  # Fallback to root ID if exact match not found
  if (is.null(dataset_codelists) || is.null(dataset_dimensions)) {
    root_id <- extract_root_dataset_id(dataset_id)
    if (root_id != dataset_id) {
      root_key <- paste0("X", root_id)
      if (is.null(dataset_codelists)) {
        dataset_codelists <- codelists[[root_key]]
      }
      if (is.null(dataset_dimensions)) {
        dataset_dimensions <- var_dimensions[[root_key]]
      }
      if (!is.null(dataset_codelists) || !is.null(dataset_dimensions)) {
        message("Using codelists from root dataset: ", root_id)
      }
    }
  }

  if (is.null(dataset_codelists) || is.null(dataset_dimensions)) {
    warning(
      "Codelists or dimensions not available for dataset: ",
      dataset_id,
      " (also tried root: ",
      extract_root_dataset_id(dataset_id),
      ")"
    )
    return(df)
  }

  # Create dimension mapping - optimized
  dim_mapping <- create_dimension_mapping_optimized(dataset_dimensions)

  if (timing && verbose) {
    message(
      "Preprocessing time: ",
      round(as.numeric(Sys.time() - processing_start), 3),
      "s"
    )
    labeling_start <- Sys.time()
  }

  # Apply labels - VECTORIZED APPROACH (biggest optimization)
  df <- apply_labels_vectorized(
    df,
    dim_mapping,
    dataset_codelists,
    dimension_names
  )

  if (timing && verbose) {
    message(
      "Label application time: ",
      round(as.numeric(Sys.time() - labeling_start), 3),
      "s"
    )
    postprocess_start <- Sys.time()
  }

  # Process time dimension
  df <- process_time_dimension(df)

  # Process observation values - use set for in-place modification
  data.table::set(df, j = "valore_label", value = as.numeric(df$ObsValue))

  # Handle editions (keep only latest)
  if ("EDITION" %in% names(df)) {
    df <- process_editions(df)
  }

  # Optimized column filtering - use data.table operations
  df <- filter_varying_columns_optimized(df)

  # Handle data types with bases
  if ("DATA_TYPE" %in% names(df) && any(grepl("base", df$DATA_TYPE))) {
    df <- process_data_types(df)
  }

  # Keep both code columns and label columns
  # No filtering needed - data.table already has both FREQ (code) and FREQ_label (label)

  # Rename specific label columns for cleaner output
  if ("tempo_label" %in% names(df)) {
    data.table::setnames(df, "tempo_label", "tempo")
  }
  if ("valore_label" %in% names(df)) {
    data.table::setnames(df, "valore_label", "valore")
  }

  # Convert character columns to factors - optimized with set operations
  char_cols <- setdiff(
    names(df),
    c("tempo", "valore", "tempo_temp", "ObsValue", "id")
  )
  if (length(char_cols) > 0) {
    for (col in char_cols) {
      if (is.character(df[[col]])) {
        data.table::set(df, j = col, value = factor(df[[col]]))
      }
    }
  }

  if (timing && verbose) {
    message(
      "Post-processing time: ",
      round(as.numeric(Sys.time() - postprocess_start), 3),
      "s"
    )
  }

  if (timing) {
    total_time <- as.numeric(Sys.time() - start_time)
    if (verbose) {
      message("Total execution time: ", round(total_time, 3), "s")
    }
    attr(df, "execution_time") <- total_time
  }

  return(df)
}

# Performance-optimized helper functions

#' In-memory metadata cache environment
#' @keywords internal
.metadata_cache <- new.env(parent = emptyenv())

#' Load Metadata from Cache
#'
#' Loads codelists and variable dimensions from the deduplicated cache structure.
#' Codelists are stored by codelist ID (e.g., CL_FREQ) and reassembled per-dataset
#' for backward compatibility with apply_labels().
#'
#' @param codelists Optional pre-loaded codelists. If NULL, loads from cache
#' @param var_dimensions Optional pre-loaded variable dimensions. If NULL, loads from cache
#' @param cache_dir Character string specifying cache directory
#'
#' @return List with codelists (keyed by dataset) and var_dimensions
#' @keywords internal
load_metadata_cached <- function(
  codelists = NULL,
  var_dimensions = NULL,
  cache_dir = "meta"
) {
  # Return pre-loaded data if provided
  if (!is.null(codelists) && !is.null(var_dimensions)) {
    return(list(codelists = codelists, var_dimensions = var_dimensions))
  }

  # Check in-memory cache first
  cache_key <- cache_dir
  if (exists(cache_key, envir = .metadata_cache)) {
    cached <- get(cache_key, envir = .metadata_cache)
    result <- cached
    if (!is.null(codelists)) {
      result$codelists <- codelists
    }
    if (!is.null(var_dimensions)) {
      result$var_dimensions <- var_dimensions
    }
    return(result)
  }

  config <- get_istat_config()
  codelists_file <- file.path(cache_dir, config$cache$codelists_file)
  map_file <- file.path(cache_dir, config$cache$dataset_map_file)

  # Check if cache files exist
  if (!file.exists(codelists_file) || !file.exists(map_file)) {
    stop("Codelists not available. Run download_codelists() first.")
  }

  # Load shared codelists and dataset mapping
  shared_codelists <- readRDS(codelists_file)
  dataset_map <- readRDS(map_file)

  # Reassemble per-dataset codelists for apply_labels() compatibility
  assembled_codelists <- list()
  assembled_var_dimensions <- list()

  for (dataset_id in names(dataset_map)) {
    mapping <- dataset_map[[dataset_id]]
    dataset_key <- paste0("X", dataset_id)

    # Assemble codelist data.table for this dataset
    dataset_cl_list <- lapply(mapping$codelists, function(cl_id) {
      if (cl_id %in% names(shared_codelists)) {
        dt <- data.table::copy(shared_codelists[[cl_id]])
        dt[, id := cl_id]
        return(dt)
      }
      NULL
    })

    # Combine into single data.table
    dataset_cl_list <- Filter(Negate(is.null), dataset_cl_list)
    if (length(dataset_cl_list) > 0) {
      assembled_codelists[[dataset_key]] <- data.table::rbindlist(
        dataset_cl_list,
        fill = TRUE
      )
    }

    # Set var_dimensions from mapping
    assembled_var_dimensions[[dataset_key]] <- mapping$dimensions
  }

  # Store in in-memory cache
  result <- list(
    codelists = assembled_codelists,
    var_dimensions = assembled_var_dimensions
  )
  assign(cache_key, result, envir = .metadata_cache)

  # Override with pre-loaded values if provided
  if (!is.null(codelists)) {
    result$codelists <- codelists
  }
  if (!is.null(var_dimensions)) {
    result$var_dimensions <- var_dimensions
  }

  result
}

#' Create optimized dimension mapping
#' @keywords internal
create_dimension_mapping_optimized <- function(dataset_dimensions) {
  if (length(dataset_dimensions) == 0) {
    return(data.table::data.table())
  }

  dim_mapping <- data.table::data.table(
    cl = unlist(dataset_dimensions),
    var = names(dataset_dimensions)
  )

  # Optimized string splitting
  dim_mapping[,
    c("agency", "codelist", "version") := data.table::tstrsplit(
      cl,
      "/",
      fixed = TRUE
    )
  ]

  # Set key for fast lookups
  data.table::setkey(dim_mapping, var)

  return(dim_mapping)
}

#' Apply labels using vectorized operations - MAIN OPTIMIZATION
#' @keywords internal
apply_labels_vectorized <- function(
  df,
  dim_mapping,
  dataset_codelists,
  dimension_names
) {
  if (!data.table::is.data.table(dataset_codelists) || nrow(dim_mapping) == 0) {
    return(df)
  }

  # Process all dimensions using match() instead of merge()
  for (dim_name in dimension_names) {
    # Fast key-based lookup
    codelist_id <- dim_mapping[.(dim_name)]$codelist

    if (length(codelist_id) > 0 && !is.na(codelist_id)) {
      # Pre-filter codelists once
      relevant_labels <- dataset_codelists[id %chin% codelist_id]

      if (nrow(relevant_labels) > 0) {
        label_col <- paste0(dim_name, "_label")
        # Use match() + set() instead of merge() to avoid data.table allocation
        idx <- match(df[[dim_name]], relevant_labels$id_description)
        data.table::set(
          df,
          j = label_col,
          value = relevant_labels$it_description[idx]
        )
      }
    }
  }

  return(df)
}

#' Optimized column filtering using data.table operations
#' @keywords internal
filter_varying_columns_optimized <- function(df) {
  # Only filter constant columns when there are multiple rows to compare
  # With 1 row, all columns would have uniqueN==1 and be removed
  if (nrow(df) <= 1) {
    return(df)
  }

  # Use vapply for vectorized uniqueness check
  col_names <- names(df)
  varying_mask <- vapply(
    col_names,
    function(cn) {
      data.table::uniqueN(df[[cn]]) > 1L
    },
    logical(1),
    USE.NAMES = FALSE
  )

  varying_cols <- col_names[varying_mask]

  if (length(varying_cols) < length(col_names)) {
    df <- df[, ..varying_cols]
  }

  return(df)
}

#' Process Time Dimension
#'
#' Processes the time dimension in ISTAT data, converting SDMX time codes to
#' appropriate R Date objects. Handles monthly (M), quarterly (Q), and annual (A)
#' frequency data with proper date formatting.
#'
#' @param data A data.table with ObsDimension column containing SDMX time codes
#'   and FREQ column indicating frequency
#'
#' @return The data.table with processed tempo_label column containing Date objects
#' @keywords internal
process_time_dimension <- function(data) {
  data.table::setnames(data, "ObsDimension", "tempo_temp")

  # Hoist FREQ check once
  has_freq <- "FREQ" %in% names(data)
  if (has_freq) {
    freq_vals <- data$FREQ
  }

  # Monthly data
  if (has_freq && any(freq_vals == "M")) {
    data[FREQ == "M", tempo_label := as.Date(paste0(tempo_temp, "-01"))]
  }

  # Quarterly data (format: 2024-Q1 or 2024Q1)
  if (has_freq && any(freq_vals == "Q")) {
    data[FREQ == "Q", tempo_temp := gsub("-", " ", tempo_temp)]
    data[
      FREQ == "Q",
      tempo_label := zoo::as.Date.yearqtr(zoo::as.yearqtr(tempo_temp))
    ]
  }

  # Annual data
  if (has_freq && any(freq_vals == "A")) {
    data[FREQ == "A", tempo_label := as.Date(paste0(tempo_temp, "-01-01"))]
  }

  return(data)
}

#' Process Editions
#'
#' Handles multiple editions in ISTAT data by keeping only the latest edition.
#' This ensures data consistency when ISTAT has published multiple versions
#' of the same dataset with different publication dates.
#'
#' @param data A data.table with EDITION column containing edition dates
#'   in ISTAT format (e.g., "G_2023_03" for March 2023)
#'
#' @return The data.table filtered to contain only observations from the latest edition
#' @keywords internal
process_editions <- function(data) {
  # Clean and convert edition dates
  data[, EDITION_new := gsub("[GM_]", "-", EDITION)]
  data[nchar(EDITION_new) < 9, EDITION_new := paste0(EDITION_new, "-01")]
  data[, EDITION_new := as.Date(EDITION_new)]

  # Keep only the latest edition
  latest_edition <- max(data$EDITION)
  data <- data[EDITION == latest_edition]

  return(data)
}

#' Process Data Types
#'
#' Handles data types with different base years by keeping only the latest base year.
#' This is important for index series where ISTAT may provide data with multiple
#' base years (e.g., 2015=100, 2020=100) to ensure consistency.
#'
#' @param data A data.table with DATA_TYPE column containing base year information
#'   (e.g., "base2020=100")
#'
#' @return The data.table filtered to contain only data from the latest base year
#' @keywords internal
process_data_types <- function(data) {
  if (any(grepl("base", data$DATA_TYPE))) {
    # Extract base year
    data[, base := sub("=.*", "", DATA_TYPE)]
    data[, base := as.numeric(substring(base, nchar(base) - 3))]

    # Keep only the latest base
    latest_base <- max(data$base, na.rm = TRUE)
    data <- data[base == latest_base]
    data[, base := NULL]
  }

  return(data)
}

#' Clean Variable Names
#'
#' Cleans and standardizes variable names for consistency.
#'
#' @param names Character vector of variable names
#'
#' @return Character vector of cleaned names
#' @export
#'
#' @examples
#' clean_variable_names(c("var.1", "var..2", "var...3"))
clean_variable_names <- function(names) {
  # Replace multiple dots with single dot
  cleaned <- gsub("(\\.)\\1+", "\\1", make.names(names))
  return(cleaned)
}

#' Validate ISTAT Data
#'
#' Validates the structure and content of ISTAT data.
#'
#' @param data A data.table to validate
#' @param required_cols Character vector of required column names
#'
#' @return Logical indicating if data is valid
#' @export
#'
#' @examples
#' \dontrun{
#' is_valid <- validate_istat_data(my_data, c("tempo", "valore"))
#' }
validate_istat_data <- function(
  data,
  required_cols = c("ObsDimension", "ObsValue")
) {
  if (!data.table::is.data.table(data)) {
    warning("Data is not a data.table")
    return(FALSE)
  }

  if (nrow(data) == 0) {
    warning("Data has zero rows")
    return(FALSE)
  }

  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    warning("Missing required columns: ", paste(missing_cols, collapse = ", "))
    return(FALSE)
  }

  return(TRUE)
}

#' Filter Data by Time Period
#'
#' Filters ISTAT data by a specified time period. Handles different date formats
#' based on frequency (A=Annual, Q=Quarterly, M=Monthly) when filtering raw data.
#'
#' @param data A data.table with time information
#' @param start_date Date or character string specifying start date (e.g., "2020-01-01")
#' @param end_date Date or character string specifying end date
#' @param time_col Character string specifying the time column name.
#'   Default is "ObsDimension" for raw ISTAT data.
#'
#' @return Filtered data.table
#' @export
#'
#' @examples
#' \dontrun{
#' # Filter raw data from 2020 onwards
#' filtered_data <- filter_by_time(data, start_date = "2020-01-01")
#'
#' # Filter quarterly data
#' q_data <- download_istat_data_by_freq("151_914")$Q
#' filtered_q <- filter_by_time(q_data, start_date = "2024-01-01")
#' }
filter_by_time <- function(
  data,
  start_date = NULL,
  end_date = NULL,
  time_col = "ObsDimension"
) {
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }

  if (!time_col %in% names(data)) {
    stop("Time column '", time_col, "' not found in data")
  }

  # Return early if no filters specified
  if (is.null(start_date) && is.null(end_date)) {
    return(data)
  }

  # Convert filter dates to Date objects
  if (!is.null(start_date) && is.character(start_date)) {
    start_date <- as.Date(start_date)
  }
  if (!is.null(end_date) && is.character(end_date)) {
    end_date <- as.Date(end_date)
  }

  # Check if time column is already Date type
  if (inherits(data[[time_col]], "Date")) {
    # Direct comparison for Date columns
    if (!is.null(start_date)) {
      data <- data[get(time_col) >= start_date]
    }
    if (!is.null(end_date)) {
      data <- data[get(time_col) <= end_date]
    }
    return(data)
  }

  # Handle raw ObsDimension with frequency-specific parsing
  if ("FREQ" %in% names(data)) {
    freq <- unique(data$FREQ)[1] # Should be single frequency after split

    # Parse dates based on frequency
    parsed_dates <- switch(
      freq,
      "A" = as.Date(paste0(data[[time_col]], "-01-01")),
      "Q" = zoo::as.Date.yearqtr(zoo::as.yearqtr(gsub(
        "-",
        " ",
        data[[time_col]]
      ))),
      "M" = as.Date(paste0(data[[time_col]], "-01")),
      # Fallback: try direct conversion
      tryCatch(as.Date(data[[time_col]]), error = function(e) NULL)
    )

    if (is.null(parsed_dates)) {
      warning("Could not parse dates for frequency: ", freq)
      return(data)
    }

    # Apply filters using parsed dates
    keep <- rep(TRUE, nrow(data))
    if (!is.null(start_date)) {
      keep <- keep & (parsed_dates >= start_date)
    }
    if (!is.null(end_date)) {
      keep <- keep & (parsed_dates <= end_date)
    }

    return(data[keep])
  }

  # Fallback: try direct comparison (may fail for non-Date columns)
  if (!is.null(start_date)) {
    data <- data[get(time_col) >= start_date]
  }
  if (!is.null(end_date)) {
    data <- data[get(time_col) <= end_date]
  }

  return(data)
}
