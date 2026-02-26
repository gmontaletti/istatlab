# istatlab 0.6.0

## Breaking Changes

* **Demo registry overhaul**: ISTAT restructured the demo.istat.it portal. URL patterns for most datasets changed. The registry now reflects the current portal structure with 8 URL patterns (A, A1, B, C, D, E, F, G) covering 15 downloadable datasets and 15 interactive-only datasets.

## New Features

* New URL patterns for the restructured demo.istat.it portal:
  - **Pattern A1**: Year+locale URLs for AIR (AIRE registry) dataset.
  - **Pattern F**: Static file download for TVA (actuarial mortality tables).
  - **Pattern G**: Plain CSV download (no ZIP) for ISM (deaths by municipality).
* `download_demo_data()` now handles plain CSV files (Pattern G) in addition to ZIP archives.
* Non-downloadable (interactive-only) datasets return informative errors pointing to the portal URL.
* `list_demo_datasets()` and `search_demo_datasets()` include a `downloadable` column.
* Pattern D now supports per-dataset `base_path`, `file_extension`, and optional `geo_level`, enabling PPR, PPC, RIC, and PRF datasets with their distinct URL structures.

## Bug Fixes

* Fixed STR (foreign resident population) download: base_path changed from `stras` to `strasa`, file_code from `STRAS` to `STRASA`.
* Fixed RCS (population by citizenship): moved from Pattern B to Pattern E (subtype-indexed) to match new `rcs/Dati_RCS_{subtype}_{year}.zip` URL structure.
* Fixed P02 and P03: moved from Pattern A to Pattern B (territory-indexed) with updated paths.
* Fixed TVM: updated levels (removed `comunali`, added `ripartizione`) and types (renamed `sintetici` to `ridotti`).
* Fixed PPR: updated data_types and geo_levels to match current portal.
* Fixed TVA: changed from Pattern C to Pattern F (single static file).
* Fixed RBD: updated base_path to `ricostruzione` and file_code to `RBD-Dataset-`.
* Fixed AIR: updated base_path to `aire` and file_code to `AIRE`, year range to 2022-present.

## Internal

* 15 datasets marked as interactive-only (R91, R92, FE1, FE3, SSC, MA1-MA4, NU1, UC1-UC4, PFL) — no longer offer bulk CSV downloads.
* Test suite expanded from ~60 to 143 demo-specific tests covering all 8 URL patterns.
* Fixed `switch()` partial argument match NOTE in `build_demo_url()`.

# istatlab 0.5.0

## New Features

* New `download_istat_data_latest_edition()` function for edition-aware dataset downloading. Detects the EDITION dimension at the API level and downloads only the latest edition via SDMX key filtering, reducing bandwidth usage.
* New `get_available_editions()` function to query available editions for a dataset from the availableconstraint endpoint.
* New `get_dataset_dimension_positions()` function to retrieve ordered dimension positions for a dataset.
* New `build_sdmx_filter_key()` function for constructing positional SDMX filter keys programmatically.
* Added `parse_edition_date()` and `determine_latest_edition()` internal helpers for edition date parsing.

## Bug Fixes

* Fixed `process_editions()` to use date-based comparison instead of alphabetical string comparison when determining the latest edition.
* Fixed edition date parsing to handle double-hyphen artifacts from G/M prefix replacement.

## Documentation

* Updated pkgdown reference index with edition-aware download functions and demographic data functions.

# istatlab 0.3.2

## New Features

* Added `incremental` parameter to download functions (`download_istat_data()`, `download_multiple_datasets()`, `download_istat_data_by_freq()`) for time period filtering using the SDMX startPeriod URL parameter
* The `incremental` parameter accepts FALSE (default), Date objects, or strings in "YYYY", "YYYY-MM", or "YYYY-MM-DD" format for flexible data retrieval

# istatlab 0.3.1

## Improvements

* Refactored connectivity testing to use curl R package instead of system() calls, improving portability across platforms
* Consolidated API function implementations and simplified connectivity testing logic for better maintainability

# istatlab 0.3.0

## New Features

* New `download_istat_data_by_freq()` function for frequency-split download capability enabling parallel retrieval of data by time frequency (monthly, quarterly, annual)
* New `get_available_frequencies()` function to query available frequencies for a dataset before download
* Enhanced `filter_by_time()` to handle single-frequency data with improved efficiency

## Improvements

* Optimized download architecture for better performance on multi-frequency datasets
* Improved time series filtering with frequency detection and validation

# istatlab 0.2.3

## Maintenance Release

* Removed deprecated `fetch_datastructure_endpoint()` function (redundant wrapper around `download_codelists()`)
* Cleaned up package by removing duplicate and unused functions
* Code quality improvements

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

* New `return_result` parameter for `download_istat_data()` returns structured `istat_result` object with:
  - `success`: Boolean success indicator
  - `data`: Downloaded data.table
  - `exit_code`: Integer (0=success, 1=error, 2=timeout)
  - `md5`: MD5 checksum for data integrity (requires digest package)
  - `is_timeout`: Boolean timeout indicator
  - `message`: Descriptive status message

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