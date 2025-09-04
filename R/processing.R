#' Apply Labels to ISTAT Data
#'
#' Processes raw ISTAT data by applying dimension labels and formatting time variables.
#'
#' @param data A data.table containing raw ISTAT data
#' @param codelists A named list of codelists for dimension labeling.
#'   If NULL, attempts to load from cache
#' @param var_dimensions A list of variable dimensions mapping.
#'   If NULL, attempts to load from cache
#'
#' @return A processed data.table with labels applied
#' @export
#'
#' @examples
#' \dontrun{
#' # Apply labels to downloaded data
#' raw_data <- download_istat_data("150_908")
#' labeled_data <- apply_labels(raw_data)
#' }
apply_labels <- function(data, codelists = NULL, var_dimensions = NULL) {
  
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }
  
  df <- data.table::copy(data)
  
  # Load codelists and dimensions if not provided
  if (is.null(codelists)) {
    if (file.exists("meta/cl_all.rds")) {
      codelists <- readRDS("meta/cl_all.rds")
    } else {
      stop("Codelists not available. Run download_codelists() first.")
    }
  }
  
  if (is.null(var_dimensions)) {
    if (file.exists("meta/var_dim.rds")) {
      var_dimensions <- readRDS("meta/var_dim.rds")
    } else {
      stop("Variable dimensions not available. Run download_metadata() first.")
    }
  }
  
  # Get dimension names (exclude standard columns)
  standard_cols <- c("ObsDimension", "ObsValue", "id")
  dimension_names <- names(df)[!names(df) %in% standard_cols]
  
  # Convert dimension columns to character
  df[, (dimension_names) := lapply(.SD, as.character), .SDcols = dimension_names]
  
  # Get dataset-specific codelists and dimensions
  dataset_id <- unique(df$id)
  if (length(dataset_id) != 1) {
    stop("Data contains multiple or no dataset IDs")
  }
  
  dataset_codelists <- codelists[[paste0("X", dataset_id)]]
  dataset_dimensions <- var_dimensions[[paste0("X", dataset_id)]]
  
  if (is.null(dataset_codelists) || is.null(dataset_dimensions)) {
    warning("Codelists or dimensions not available for dataset: ", dataset_id)
    return(df)
  }
  
  # Create dimension mapping
  dim_mapping <- data.frame(
    cl = unlist(dataset_dimensions),
    var = names(dataset_dimensions)
  )
  data.table::setDT(dim_mapping)
  dim_mapping[, c("agency", "codelist", "version") := data.table::tstrsplit(cl, "/")]
  
  # Apply labels for each dimension
  for (dim_name in dimension_names) {
    
    codelist_id <- dim_mapping[var == dim_name]$codelist
    
    if (length(codelist_id) > 0) {
      # Get value labels
      if (data.table::is.data.table(dataset_codelists)) {
        value_labels <- dataset_codelists[id %in% codelist_id, 
                                        .(it_description, id_description)]
        data.table::setnames(value_labels, c(paste0(dim_name, "_label"), "id"))
        
        # Merge labels
        df <- merge(df, value_labels, 
                   by.x = dim_name, by.y = "id", 
                   all.x = TRUE, all.y = FALSE)
      }
    }
  }
  
  # Process time dimension
  df <- process_time_dimension(df)
  
  # Process observation values
  df[, valore_label := as.numeric(ObsValue)]
  
  # Handle editions (keep only latest)
  if ("EDITION" %in% names(df)) {
    df <- process_editions(df)
  }
  
  # Remove columns with single values
  varying_cols <- names(Filter(function(x) length(unique(x)) > 1, df))
  df <- df[, ..varying_cols]
  
  # Handle data types with bases
  if ("DATA_TYPE" %in% names(df) && any(grepl("base", df$DATA_TYPE))) {
    df <- process_data_types(df)
  }
  
  # Keep only label columns and clean up
  label_cols <- names(df)[grepl("_label$", names(df))]
  df <- df[, ..label_cols]
  names(df) <- gsub("_label$", "", names(df))
  
  # Convert character columns to factors
  char_cols <- names(df)[!names(df) %in% c("tempo", "valore")]
  df[, (char_cols) := lapply(.SD, factor), .SDcols = char_cols]
  
  return(df)
}

#' Process Time Dimension
#'
#' Processes the time dimension in ISTAT data, converting to appropriate date formats.
#'
#' @param data A data.table with time dimension
#'
#' @return The data.table with processed time dimension
#' @keywords internal
process_time_dimension <- function(data) {
  
  data.table::setnames(data, "ObsDimension", "tempo_temp")
  
  # Monthly data
  if ("FREQ" %in% names(data) && nrow(data[FREQ == "M"]) > 0) {
    data[FREQ == "M", tempo_label := as.Date(paste0(tempo_temp, "-01"))]
  }
  
  # Quarterly data
  if ("FREQ" %in% names(data) && nrow(data[FREQ == "Q"]) > 0) {
    data[FREQ == "Q", tempo_temp := gsub("-", "", tempo_temp)]
    data[FREQ == "Q", tempo_label := as.Date(zoo::as.yearqtr(tempo_temp, "%Y Q%q"))]
  }
  
  # Annual data
  if ("FREQ" %in% names(data) && nrow(data[FREQ == "A"]) > 0) {
    data[FREQ == "A", tempo_label := as.Date(paste0(tempo_temp, "-01-01"))]
  }
  
  return(data)
}

#' Process Editions
#'
#' Handles multiple editions in the data by keeping only the latest edition.
#'
#' @param data A data.table with EDITION column
#'
#' @return The data.table with only the latest edition
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
#' Handles data types with different base years by keeping only the latest base.
#'
#' @param data A data.table with DATA_TYPE column
#'
#' @return The data.table with latest base year data
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
validate_istat_data <- function(data, required_cols = c("ObsDimension", "ObsValue")) {
  
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
#' Filters ISTAT data by a specified time period.
#'
#' @param data A data.table with time information
#' @param start_date Date or character string specifying start date
#' @param end_date Date or character string specifying end date
#' @param time_col Character string specifying the time column name.
#'   Default is "tempo"
#'
#' @return Filtered data.table
#' @export
#'
#' @examples
#' \dontrun{
#' # Filter data from 2020 onwards
#' filtered_data <- filter_by_time(data, start_date = "2020-01-01")
#' }
filter_by_time <- function(data, start_date = NULL, end_date = NULL, time_col = "tempo") {
  
  if (!data.table::is.data.table(data)) {
    data.table::setDT(data)
  }
  
  if (!time_col %in% names(data)) {
    stop("Time column '", time_col, "' not found in data")
  }
  
  # Convert dates if necessary
  if (!is.null(start_date) && !inherits(data[[time_col]], "Date")) {
    if (is.character(start_date)) {
      start_date <- as.Date(start_date)
    }
  }
  
  if (!is.null(end_date) && !inherits(data[[time_col]], "Date")) {
    if (is.character(end_date)) {
      end_date <- as.Date(end_date)
    }
  }
  
  # Apply filters
  if (!is.null(start_date)) {
    data <- data[get(time_col) >= start_date]
  }
  
  if (!is.null(end_date)) {
    data <- data[get(time_col) <= end_date]
  }
  
  return(data)
}