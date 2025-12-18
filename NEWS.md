# istatlab 0.2.2

## Maintenance Release

* Updated test infrastructure and test file organization
* Enhanced test coverage and validation

# istatlab 0.2.1

## Maintenance Release

* Enhanced error handling and HTTP transport layer implementation
* Improved robustness and code quality in download architecture
* Updated dependencies and internal refactoring for better maintainability

# istatlab 0.2.0

## New Features

* New modular architecture for download functions with clear separation of concerns:
  - `error_handling.R`: Structured error types, exit codes, and timestamped logging
  - `http_transport.R`: HTTP layer with httr primary and curl fallback
  - `response_processor.R`: CSV parsing, column normalization, and checksum computation

* New `download_istat_data_full()` function returns structured `istat_result` object with:
  - `success`: Boolean success indicator
  - `data`: Downloaded data.table
  - `exit_code`: Integer (0=success, 1=error, 2=timeout)
  - `md5`: MD5 checksum for data integrity (requires digest package)
  - `is_timeout`: Boolean timeout indicator
  - `message`: Descriptive status message

* New `return_result` parameter for `download_istat_data()` enables structured results while maintaining backward compatibility

* Enhanced error classification with exit codes following standard conventions:
  - 0: Success
  - 1: Generic error (connectivity, HTTP, parsing)
  - 2: Timeout error

* Timestamped logging with format: `YYYY-MM-DD HH:MM:SS TZ [LEVEL] - message`

* MD5 checksums for data integrity verification (optional, requires digest package)

## Deprecations

* `istat_http_get()`: Use `http_get()` instead
* `istat_fetch_data_csv()`: Use `http_get()` + `process_api_response()` instead
* `istat_fetch_with_curl()`: Use `http_get_curl()` instead

These deprecated functions remain functional but will be removed in version 1.0.0.

## Dependencies

* Added `digest` to Suggests for optional MD5 checksum computation

# istatlab 0.1.5

* Maintenance release with dependency synchronization
* Updated package documentation and roxygen2 comments
* Enhanced API connectivity and error handling

# istatlab 0.1.4

* Added `expand_dataset_ids()` function for automatic dataset code expansion
* Added `extract_root_dataset_id()` function for root ID extraction from compound IDs
* Added fallback codelist lookup using root dataset IDs

# istatlab 0.1.3

* Reorganized project structure and cleaned up main directory
* Moved non-package files to reference directory for better maintainability
* Maintained all core R package functionality and tests

# istatlab 0.1.1

* Enhanced and improved package documentation
* Updated roxygen2 comments for better clarity and completeness
* Improved function examples and parameter descriptions
* Enhanced vignettes and user guides

# istatlab 0.1.0

* Initial release of istatlab package
* Added core functionality for downloading ISTAT data via SDMX API
* Implemented comprehensive data processing and labeling functions
* Added time series analysis capabilities including trend analysis and growth rate calculations
* Included forecasting functionality with multiple methods (ARIMA, ETS, linear, naive)
* Created publication-ready visualization functions using ggplot2
* Established comprehensive testing framework with testthat
* Added extensive documentation with roxygen2
* Implemented structural break detection
* Added dashboard plotting capabilities
* Included data validation and error handling throughout