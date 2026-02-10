# Package index

## Configuration

Configure API endpoints and package settings.

- [`istat_config`](https://gmontaletti.github.io/istatlab/reference/istat_config.md)
  : ISTAT SDMX Web Service Configuration
- [`get_istat_config()`](https://gmontaletti.github.io/istatlab/reference/get_istat_config.md)
  : Get ISTAT SDMX Service Configuration
- [`endpoints`](https://gmontaletti.github.io/istatlab/reference/endpoints.md)
  : ISTAT SDMX Endpoint Functions
- [`list_istat_endpoints()`](https://gmontaletti.github.io/istatlab/reference/list_istat_endpoints.md)
  : List Available ISTAT Endpoints
- [`build_istat_url()`](https://gmontaletti.github.io/istatlab/reference/build_istat_url.md)
  : Build ISTAT API URL
- [`test_endpoint_connectivity()`](https://gmontaletti.github.io/istatlab/reference/test_endpoint_connectivity.md)
  : Test ISTAT Endpoint Connectivity

## Data Download

Download data from ISTAT SDMX API.

- [`download_istat_data()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data.md)
  : Download Data from ISTAT SDMX API
- [`download_istat_data_by_freq()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data_by_freq.md)
  : Download ISTAT Data Split by Frequency
- [`download_multiple_datasets()`](https://gmontaletti.github.io/istatlab/reference/download_multiple_datasets.md)
  : Download Multiple Datasets
- [`istat_result`](https://gmontaletti.github.io/istatlab/reference/istat_result.md)
  : ISTAT Download Result Structure

## Metadata

Manage dataset metadata, search, and explore structure.

- [`download_metadata()`](https://gmontaletti.github.io/istatlab/reference/download_metadata.md)
  : Download Dataset Metadata
- [`search_dataflows()`](https://gmontaletti.github.io/istatlab/reference/search_dataflows.md)
  : Search Dataflows by Keywords
- [`expand_dataset_ids()`](https://gmontaletti.github.io/istatlab/reference/expand_dataset_ids.md)
  : Expand Dataset IDs to Include All Matching Variants
- [`get_dataset_dimensions()`](https://gmontaletti.github.io/istatlab/reference/get_dataset_dimensions.md)
  : Get Dataset Dimensions
- [`get_dataset_last_update()`](https://gmontaletti.github.io/istatlab/reference/get_dataset_last_update.md)
  : Get Dataset Last Update Timestamp from ISTAT API
- [`get_available_frequencies()`](https://gmontaletti.github.io/istatlab/reference/get_available_frequencies.md)
  : Get Available Frequencies for Dataset
- [`get_categorized_datasets()`](https://gmontaletti.github.io/istatlab/reference/get_categorized_datasets.md)
  : Get Dataset Information by Category
- [`get_dataset_category()`](https://gmontaletti.github.io/istatlab/reference/get_dataset_category.md)
  : Get Dataset Category
- [`fetch_registry_dimensions()`](https://gmontaletti.github.io/istatlab/reference/fetch_registry_dimensions.md)
  : Get Dataset Dimensions from Registry Endpoint

## Cache & TTL

Codelist caching and time-to-live management.

- [`download_codelists()`](https://gmontaletti.github.io/istatlab/reference/download_codelists.md)
  : Download Codelists
- [`get_dataset_codelists()`](https://gmontaletti.github.io/istatlab/reference/get_dataset_codelists.md)
  : Get Codelists Used by Dataset
- [`ensure_codelists()`](https://gmontaletti.github.io/istatlab/reference/ensure_codelists.md)
  : Ensure Codelists Are Available for Dataset
- [`load_codelist_metadata()`](https://gmontaletti.github.io/istatlab/reference/load_codelist_metadata.md)
  : Load Codelist Metadata Cache
- [`save_codelist_metadata()`](https://gmontaletti.github.io/istatlab/reference/save_codelist_metadata.md)
  : Save Codelist Metadata Cache
- [`compute_codelist_ttl()`](https://gmontaletti.github.io/istatlab/reference/compute_codelist_ttl.md)
  : Compute Staggered TTL for Codelist
- [`check_codelist_expiration()`](https://gmontaletti.github.io/istatlab/reference/check_codelist_expiration.md)
  : Check Which Codelists Need Renewal
- [`refresh_expired_codelists()`](https://gmontaletti.github.io/istatlab/reference/refresh_expired_codelists.md)
  : Refresh Expired Codelists

## Data Processing

Label, filter, validate, and clean downloaded data.

- [`apply_labels()`](https://gmontaletti.github.io/istatlab/reference/apply_labels.md)
  : Apply Labels to ISTAT Data
- [`filter_by_time()`](https://gmontaletti.github.io/istatlab/reference/filter_by_time.md)
  : Filter Data by Time Period
- [`validate_istat_data()`](https://gmontaletti.github.io/istatlab/reference/validate_istat_data.md)
  : Validate ISTAT Data
- [`clean_variable_names()`](https://gmontaletti.github.io/istatlab/reference/clean_variable_names.md)
  : Clean Variable Names

## Forecasting

Time series forecasting methods.

- [`forecast_series()`](https://gmontaletti.github.io/istatlab/reference/forecast_series.md)
  : Forecast a time series using multiple models
- [`print(`*`<istat_forecast>`*`)`](https://gmontaletti.github.io/istatlab/reference/print.istat_forecast.md)
  : Print method for istat_forecast objects
- [`plot(`*`<istat_forecast>`*`)`](https://gmontaletti.github.io/istatlab/reference/plot.istat_forecast.md)
  : Plot method for istat_forecast objects

## Visualization Preparation

Prepare data for plotting.

- [`prepare_for_plotting()`](https://gmontaletti.github.io/istatlab/reference/prepare_for_plotting.md)
  : Prepare ISTAT Data for Plotting
- [`print(`*`<istat_plot_ready>`*`)`](https://gmontaletti.github.io/istatlab/reference/print.istat_plot_ready.md)
  : Print Method for istat_plot_ready
