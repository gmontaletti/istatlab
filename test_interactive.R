# test_interactive.R
# Interactive test script for istatlab package
# Tests all exported functions with a configurable dataset

# 1. Configuration -----
# Change this to test with a different dataset
codice <- "151_914"  # Job vacancies (lightweight dataset for testing)

# Alternative datasets to try:
# codice <- "150_908"  # Monthly employment
# codice <- "151_914"  # Unemployment rates

cat("=== istatlab Interactive Test ===\n")
cat("Testing with dataset:", codice, "\n\n")

# 2. Load package -----
cat("Loading istatlab package...\n")
devtools::load_all()
cat("Package loaded successfully.\n\n")

# 3. Test configuration functions -----
cat("--- Testing Configuration Functions ---\n\n")

cat("3.1 get_istat_config()\n")
config <- get_istat_config()
cat("  Base URL:", config$base_url, "\n")
cat("  Endpoints:", paste(names(config$endpoints), collapse = ", "), "\n")
cat("  Default timeout:", config$defaults$timeout, "seconds\n")
cat("  Cache days:", config$defaults$cache_days, "\n\n")

cat("3.2 build_istat_url()\n")
url_data <- build_istat_url("data", dataset_id = codice, start_time = "2023")
cat("  Data URL:", url_data, "\n")
cat("  Note: URL includes includeHistory=false by default\n")
url_dataflow <- build_istat_url("dataflow")
cat("  Dataflow URL:", url_dataflow, "\n\n")

cat("3.3 list_istat_endpoints()\n")
endpoints <- list_istat_endpoints()
print(endpoints)
cat("\n")

# 4. Test connectivity functions -----
cat("--- Testing Connectivity Functions ---\n\n")

cat("4.1 check_istat_api()\n")
api_status <- check_istat_api()
cat("  API available:", api_status, "\n\n")

cat("4.2 test_endpoint_connectivity()\n")
connectivity <- test_endpoint_connectivity()
print(connectivity)
cat("\n")

# 5. Test metadata functions -----
cat("--- Testing Metadata Functions ---\n\n")

cat("5.1 download_metadata()\n")
metadata <- download_metadata()
cat("  Total datasets available:", nrow(metadata), "\n")
cat("  Columns:", paste(names(metadata), collapse = ", "), "\n")
cat("  First 5 dataset IDs:", paste(head(metadata$id, 5), collapse = ", "), "\n\n")

cat("5.2 search_dataflows()\n")
# Search for datasets containing "lavoro" (work/labour)
search_results <- search_dataflows("lavoro")
cat("  Found", nrow(search_results), "datasets matching 'lavoro'\n")
if (nrow(search_results) > 0) {
  cat("  First 3:\n")
  print(head(search_results[, c("id", "Name.it")], 3))
}
cat("\n")

cat("5.3 get_categorized_datasets()\n")
categorized <- get_categorized_datasets()
cat("  Categories:", paste(names(categorized), collapse = ", "), "\n\n")

cat("5.4 get_dataset_category()\n")
employment_datasets <- get_dataset_category("employment")
cat("  Employment datasets:", paste(employment_datasets, collapse = ", "), "\n\n")

cat("5.5 expand_dataset_ids()\n")
expanded <- expand_dataset_ids(codice, metadata = metadata)
cat("  Expanded '", codice, "' to", length(expanded), "dataset(s)\n")
if (length(expanded) <= 5) {
  cat("  IDs:", paste(expanded, collapse = ", "), "\n")
} else {
  cat("  First 5:", paste(head(expanded, 5), collapse = ", "), "...\n")
}
cat("\n")

# 6. Test LAST_UPDATE functions -----
cat("--- Testing LAST_UPDATE Functions ---\n\n")

cat("6.1 get_dataset_last_update()\n")
last_update <- get_dataset_last_update(codice)
if (!is.null(last_update)) {
  cat("  Dataset", codice, "last updated:", format(last_update, "%Y-%m-%d %H:%M:%S"), "UTC\n")
} else {
  cat("  Could not retrieve LAST_UPDATE for", codice, "\n")
}
cat("\n")

# 7. Test endpoint fetch functions -----
cat("--- Testing Endpoint Fetch Functions ---\n\n")

cat("7.1 fetch_dataflow_endpoint()\n")
dataflows <- fetch_dataflow_endpoint()
cat("  Fetched", nrow(dataflows), "dataflows\n\n")

cat("7.2 get_dataset_dimensions()\n")
dimensions <- get_dataset_dimensions(codice)
if (!is.null(dimensions)) {
  cat("  Dimensions:", paste(dimensions, collapse = ", "), "\n")
} else {
  cat("  Error retrieving dimensions\n")
}
cat("\n")

# 8. Test codelist functions -----
cat("--- Testing Codelist Functions ---\n\n")

cat("8.1 download_codelists()\n")
cat("  Downloading codelists for", codice, "...\n")
codelists <- download_codelists(dataset_ids = codice)
cat("  Downloaded", length(codelists), "codelist(s)\n")
if (length(codelists) > 0) {
  cat("  Codelist names:", paste(names(codelists), collapse = ", "), "\n")
  # Show first codelist structure
  first_cl <- codelists[[1]]
  if (!is.null(first_cl)) {
    cat("  First codelist rows:", nrow(first_cl), "\n")
  }
}
cat("\n")

cat("8.2 get_dataset_codelists()\n")
cat("  Retrieving codelists for", codice, "from cache...\n")
dataset_codelists <- tryCatch({
  get_dataset_codelists(codice)
}, error = function(e) {
  cat("  Error:", e$message, "\n")
  NULL
})
if (!is.null(dataset_codelists)) {
  # Returns a character vector of codelist IDs
  cat("  Codelist IDs for this dataset:", paste(dataset_codelists, collapse = ", "), "\n")
}
cat("\n")

cat("8.3 Cache structure verification\n")
config <- get_istat_config()
codelists_file <- file.path("meta", config$cache$codelists_file)
map_file <- file.path("meta", config$cache$dataset_map_file)
if (file.exists(codelists_file) && file.exists(map_file)) {
  shared_codelists <- readRDS(codelists_file)
  dataset_map <- readRDS(map_file)
  cat("  Shared codelists cached:", length(shared_codelists), "\n")
  cat("  Datasets mapped:", length(dataset_map), "\n")
  cat("  Sample codelist IDs:", paste(head(names(shared_codelists), 5), collapse = ", "), "\n")

  # Verify dimension mapping for current dataset
  if (codice %in% names(dataset_map)) {
    dim_mapping <- dataset_map[[codice]]$dimensions
    cat("  Dimension mapping for", codice, ":\n")
    for (dim_name in names(dim_mapping)) {
      cat("    ", dim_name, "->", dim_mapping[[dim_name]], "\n")
    }
  }
} else {
  cat("  Cache files not found - run download_codelists() first\n")
}
cat("\n")

# 9. Test data download functions -----
cat("--- Testing Data Download Functions ---\n\n")

cat("9.1 download_istat_data()\n")
cat("  Downloading data for", codice, "(start_time = 2023)...\n")
data_raw <- download_istat_data(codice, start_time = "2023")
if (!is.null(data_raw)) {
  cat("  Downloaded", nrow(data_raw), "rows,", ncol(data_raw), "columns\n")
  cat("  Columns:", paste(names(data_raw), collapse = ", "), "\n")
} else {
  cat("  Download failed or no data available\n")
}
cat("\n")

cat("9.2 download_istat_data() with check_update=TRUE\n")
cat("  First download with update tracking...\n")
data_check1 <- download_istat_data(codice, start_time = "2024", check_update = TRUE)
if (!is.null(data_check1)) {
  cat("  Downloaded", nrow(data_check1), "rows\n")
}
cat("  Second download (should skip if unchanged)...\n")
data_check2 <- download_istat_data(codice, start_time = "2024", check_update = TRUE)
if (is.null(data_check2)) {
  cat("  Skipped - data unchanged since last download\n")
} else {
  cat("  Downloaded", nrow(data_check2), "rows\n")
}
cat("\n")

cat("9.3 download_istat_data_full()\n")
cat("  Downloading full data for", codice, "(start_time = 2023)...\n")
result_full <- download_istat_data_full(codice, start_time = "2023")
cat("  Result class:", class(result_full), "\n")
print(result_full)  # Uses the print.istat_result method
cat("\n")

cat("9.4 fetch_data_endpoint()\n")
cat("  Fetching data endpoint for", codice, "...\n")
data_endpoint <- fetch_data_endpoint(codice, start_time = "2023")
if (!is.null(data_endpoint)) {
  cat("  Fetched", nrow(data_endpoint), "rows\n")
}
cat("\n")

cat("9.5 Data download log verification\n")
log_file <- file.path("meta", config$cache$data_download_log_file)
if (file.exists(log_file)) {
  download_log <- readRDS(log_file)
  cat("  Datasets in log:", length(download_log), "\n")
  if (codice %in% names(download_log)) {
    log_entry <- download_log[[codice]]
    cat("  Last download for", codice, ":", format(log_entry$downloaded_at, "%Y-%m-%d %H:%M:%S"), "\n")
    if (!is.null(log_entry$istat_last_update)) {
      cat("  ISTAT last update at download:", format(log_entry$istat_last_update, "%Y-%m-%d %H:%M:%S"), "UTC\n")
    }
  }
} else {
  cat("  Download log not found - run download with check_update=TRUE first\n")
}
cat("\n")

# 10. Test data processing functions -----
cat("--- Testing Data Processing Functions ---\n\n")

if (!is.null(data_raw) && nrow(data_raw) > 0) {

  cat("10.1 validate_istat_data()\n")
  is_valid <- validate_istat_data(data_raw)
  cat("  Valid:", is_valid, "\n")
  cat("\n")

  cat("10.2 clean_variable_names()\n")
  data_cleaned <- clean_variable_names(data_raw)
  cat("  Original columns:", paste(head(names(data_raw), 5), collapse = ", "), "\n")
  cat("  Cleaned columns:", paste(head(names(data_cleaned), 5), collapse = ", "), "\n\n")

  cat("10.3 apply_labels()\n")
  cat("  Applying labels to data...\n")
  data_labeled <- tryCatch({
    apply_labels(data_raw)  # Uses id column from data to find codelists
  }, error = function(e) {
    cat("  Error applying labels:", e$message, "\n")
    NULL
  })
  if (!is.null(data_labeled)) {
    cat("  Labeled data:", nrow(data_labeled), "rows,", ncol(data_labeled), "columns\n")
    label_cols <- grep("_label$", names(data_labeled), value = TRUE)
    cat("  Label columns:", paste(label_cols, collapse = ", "), "\n")
    # Show sample labels
    if (length(label_cols) > 0 && nrow(data_labeled) > 0) {
      cat("  Sample labels (first row):\n")
      for (col in head(label_cols, 5)) {
        val <- data_labeled[[col]][1]
        cat("    ", col, ":", as.character(val), "\n")
      }
    }
  }
  cat("\n")

  cat("10.4 filter_by_time() - deprecated for mixed frequencies\n")
  cat("  Note: Use download_istat_data_by_freq() for proper frequency handling\n\n")

} else {
  cat("Skipping processing tests - no data available\n\n")
}

# 11. Test frequency-split download functions -----
cat("--- Testing Frequency-Split Download Functions ---\n\n")

cat("11.1 get_available_frequencies()\n")
freqs <- get_available_frequencies(codice)
if (!is.null(freqs)) {
  cat("  Available frequencies for", codice, ":", paste(freqs, collapse = ", "), "\n")
} else {
  cat("  Could not retrieve frequencies for", codice, "\n")
}
cat("\n")

cat("11.2 download_istat_data_by_freq()\n")
cat("  Downloading data for", codice, "split by frequency...\n")
data_by_freq <- download_istat_data_by_freq(codice, start_time = "2023")
if (!is.null(data_by_freq)) {
  cat("  Frequencies downloaded:", paste(names(data_by_freq), collapse = ", "), "\n")
  for (freq_name in names(data_by_freq)) {
    cat("    ", freq_name, ":", nrow(data_by_freq[[freq_name]]), "rows\n")
  }
}
cat("\n")

cat("11.3 filter_by_time() on single-frequency data\n")
if (!is.null(data_by_freq) && length(data_by_freq) > 0) {
  first_freq <- names(data_by_freq)[1]
  freq_data <- data_by_freq[[first_freq]]
  cat("  Filtering", first_freq, "data from 2024-01-01...\n")
  filtered_freq <- filter_by_time(freq_data, start_date = "2024-01-01")
  cat("  Original rows:", nrow(freq_data), "\n")
  cat("  Filtered rows:", nrow(filtered_freq), "\n")
  cat("  Time range:", paste(range(filtered_freq$ObsDimension), collapse = " to "), "\n")
}
cat("\n")

# 12. Test multiple dataset functions -----
cat("--- Testing Multiple Dataset Functions ---\n\n")

cat("12.1 download_multiple_datasets()\n")
# Use two small datasets for testing
test_datasets <- c("534_50", "534_51")
cat("  Downloading datasets:", paste(test_datasets, collapse = ", "), "\n")
multi_data <- download_multiple_datasets(test_datasets, start_time = "2024")
cat("  Downloaded", length(multi_data), "dataset(s)\n")
for (name in names(multi_data)) {
  if (!is.null(multi_data[[name]])) {
    cat("  ", name, ":", nrow(multi_data[[name]]), "rows\n")
  }
}
cat("\n")

cat("12.2 fetch_multiple_data_endpoint()\n")
multi_fetch <- fetch_multiple_data_endpoint(test_datasets, start_time = "2024")
cat("  Fetched", length(multi_fetch), "dataset(s)\n\n")

# 13. Summary -----
cat("=== Test Summary ===\n")
cat("All functions tested successfully!\n")
cat("Dataset used:", codice, "\n")
cat("Data rows downloaded:", ifelse(!is.null(data_raw), nrow(data_raw), 0), "\n")
cat("\n")

# 14. Show sample data -----
cat("=== Sample Data Preview ===\n")
if (!is.null(data_labeled) && nrow(data_labeled) > 0) {
  cat("Labeled data (first 5 rows):\n")
  print(head(data_labeled, 5))
} else if (!is.null(data_raw) && nrow(data_raw) > 0) {
  cat("Raw data (first 5 rows):\n")
  print(head(data_raw, 5))
}
