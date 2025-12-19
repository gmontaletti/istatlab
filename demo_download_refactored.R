# Demo: Refactored Download Functions (istatlab 0.2.0)
# Interactive testing of new modular architecture

# Load development version
devtools::load_all()

istatlab::download_codelists()


# 1. Basic download (backward compatible) -----
cat("=== 1. Basic Download (Backward Compatible) ===\n")
data <- download_istat_data("150_908", start_time = "2000", verbose = TRUE)
if (!is.null(data)) {
  cat("Rows:", nrow(data), "\n")
  cat("Columns:", paste(names(data), collapse = ", "), "\n\n")
}

# 2. Full result with metadata -----
cat("=== 2. Full Result with Metadata ===\n")
result <- download_istat_data("150_908", start_time = "2000", verbose = FALSE, return_result = TRUE)
print(result)
cat("\n")

# 3. Check structured result components -----
cat("=== 3. Result Components ===\n")
cat("Success:", result$success, "\n")
cat("Exit code:", result$exit_code, "(0=success, 1=error, 2=timeout)\n")
cat("Is timeout:", result$is_timeout, "\n")
cat("MD5:", ifelse(is.na(result$md5), "Not computed (install digest)", result$md5), "\n")
cat("Message:", result$message, "\n")
cat("Timestamp:", format(result$timestamp), "\n\n")

# 4. Error handling demo -----
cat("=== 4. Error Detection Functions ===\n")
cat("is_timeout_error('connection timed out'):", is_timeout_error("connection timed out"), "\n")
cat("is_timeout_error('file not found'):", is_timeout_error("file not found"), "\n")
cat("is_connectivity_error('cannot resolve host'):", is_connectivity_error("cannot resolve host"), "\n\n")

# 5. Error classification -----
cat("=== 5. Error Classification ===\n")
timeout_err <- classify_api_error("gateway timeout 504")
cat("Timeout error -> type:", timeout_err$type, ", exit_code:", timeout_err$exit_code, "\n")

conn_err <- classify_api_error("connection refused")
cat("Connection error -> type:", conn_err$type, ", exit_code:", conn_err$exit_code, "\n\n")

# 6. Logging demo -----
cat("=== 6. Timestamped Logging ===\n")
istat_log("This is an INFO message", "INFO", verbose = TRUE)
istat_log("This is a WARNING", "WARNING", verbose = TRUE)
istat_log("This is an ERROR", "ERROR", verbose = TRUE)

cat("\n=== Demo Complete ===\n")

