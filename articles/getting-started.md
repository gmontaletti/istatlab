# Getting Started with istatlab

``` r
library(istatlab)
library(data.table)
```

## Introduction

The **istatlab** package provides tools for downloading, processing, and
analyzing Italian labour market data from ISTAT (Istituto Nazionale di
Statistica) through its SDMX API.

This vignette covers the basic workflow for retrieving and labeling
ISTAT data. More advanced features such as forecasting and visualization
are documented separately.

## Workflow Overview

Working with istatlab follows a 6-step workflow:

    +-------------+     +---------------+     +------------------+
    | 1. Check    | --> | 2. Download   | --> | 3. Identify      |
    |    API      |     |    Metadata   |     |    Dataset       |
    +-------------+     +---------------+     +------------------+
                                                       |
                                                       v
    +-------------+     +---------------+     +------------------+
    | 6. Apply    | <-- | 5. Download   | <-- | 4. Get Codelists |
    |    Labels   |     |    Data       |     |                  |
    +-------------+     +---------------+     +------------------+
           |
           v
      [Labeled Data Ready for Analysis]

Each step builds on the previous one. The package caches metadata and
codelists to minimize API calls in subsequent sessions.

## Step 1: Check API Connectivity

Before starting, verify that the ISTAT API is accessible:

``` r
status <- test_endpoint_connectivity("data", verbose = FALSE)
if (status$accessible[1]) {
  message("ISTAT API is accessible")
} else {
  message("ISTAT API is not accessible. Check your internet connection.")
}
```

This function tests the API endpoint and reports whether it responds
correctly. Running this check first helps diagnose connectivity issues
before attempting data downloads.

## Step 2: Download Metadata

The metadata catalog contains information about all available datasets:

``` r
metadata <- download_metadata()
```

The metadata includes:

- `id`: Dataset identifier (e.g., “150_908”)
- `Name.it`: Italian name of the dataset
- `Name.en`: English name of the dataset

``` r
head(metadata[, .(id, Name.it)])
```

Metadata is cached locally with a 14-day refresh cycle. Subsequent calls
return the cached version unless expired.

## Step 3: Identify Your Dataset

You can search for datasets by filtering the metadata or using
[`search_dataflows()`](https://gmontaletti.github.io/istatlab/reference/search_dataflows.md):

``` r
# Method 1: Filter metadata directly
employment_datasets <- metadata[grepl("occupati|employment", Name.it, ignore.case = TRUE)]
employment_datasets[1:5, .(id, Name.it)]
```

``` r
# Method 2: Use search_dataflows for keyword search
search_results <- search_dataflows("occupati")
head(search_results[, .(id, Name.it)])
```

For this vignette, we use dataset **“150_908”** (monthly employment
data).

Some datasets have multiple variants (base dataset plus sub-datasets).
Use
[`expand_dataset_ids()`](https://gmontaletti.github.io/istatlab/reference/expand_dataset_ids.md)
to discover related datasets:

``` r
related <- expand_dataset_ids("150_908")
print(related)
```

## Step 4: Get Codelists

ISTAT data uses coded values (e.g., “IT” for Italy, “M” for male).
Codelists map these codes to human-readable labels.

First, examine the dataset dimensions:

``` r
dimensions <- get_dataset_dimensions("150_908")
print(dimensions)
```

Then download the codelists for each dimension:

``` r
codelists <- download_codelists("150_908")
names(codelists)
```

Each codelist is a data.table with `id` (the code) and `name` (the
label):

``` r
# View a sample codelist (e.g., territory)
if ("ITTER107" %in% names(codelists)) {
  head(codelists[["ITTER107"]])
}
```

You can verify all required codelists are available with
[`ensure_codelists()`](https://gmontaletti.github.io/istatlab/reference/ensure_codelists.md):

``` r
ensure_codelists("150_908")
```

Codelists are cached to avoid repeated downloads. The cache uses a
staggered TTL system to spread refresh times.

## Step 5: Download Data

Download the actual data using
[`download_istat_data()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data.md):

``` r
raw_data <- download_istat_data("150_908", start_time = "2023")
```

The raw data contains coded values, not labels:

``` r
dim(raw_data)
head(raw_data)
```

Key parameters for
[`download_istat_data()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data.md):

- `dataset_id`: The dataset identifier
- `start_time`: Filter data from this time period onwards
- `end_time`: Filter data up to this time period
- `incremental`: If TRUE, only download data newer than cached version

## Step 6: Apply Labels

Transform coded values into readable labels with
[`apply_labels()`](https://gmontaletti.github.io/istatlab/reference/apply_labels.md):

``` r
labeled_data <- apply_labels(raw_data)
```

The labeled data includes:

- Original columns preserved
- `tempo`: Date column (converted from TIME_PERIOD)
- `valore`: Numeric value column (converted from OBS_VALUE)
- `*_label` columns: Human-readable labels for each dimension

``` r
head(labeled_data)
```

Compare the original codes with applied labels:

``` r
# Show transformation from codes to labels
cols_to_show <- grep("label$|tempo|valore", names(labeled_data), value = TRUE)
head(labeled_data[, ..cols_to_show])
```

## Working with the Result

The labeled data is a data.table ready for analysis:

``` r
# Basic statistics
summary(labeled_data$valore)
```

``` r
# Time range
range(labeled_data$tempo)
```

### Filtering by Time

Use
[`filter_by_time()`](https://gmontaletti.github.io/istatlab/reference/filter_by_time.md)
to extract specific periods:

``` r
recent_data <- filter_by_time(labeled_data, start_date = "2024-01-01", time_col = "tempo")
nrow(recent_data)
```

### Validating Data

Use
[`validate_istat_data()`](https://gmontaletti.github.io/istatlab/reference/validate_istat_data.md)
to check data structure and quality:

``` r
validation <- validate_istat_data(labeled_data)
print(validation)
```

## Complete Workflow Example

Here is the complete workflow in a single code block:

``` r
library(istatlab)

# 1. Check API connectivity
test_endpoint_connectivity("data", verbose = TRUE)

# 2. Download metadata
metadata <- download_metadata()

# 3. Identify dataset (e.g., monthly employment data)
dataset_id <- "150_908"

# 4. Get codelists
ensure_codelists(dataset_id)

# 5. Download data
raw_data <- download_istat_data(dataset_id, start_time = "2023")

# 6. Apply labels
labeled_data <- apply_labels(raw_data)

# Result: labeled data ready for analysis
head(labeled_data)
```

## Next Steps

After completing this basic workflow:

- Use
  [`download_multiple_datasets()`](https://gmontaletti.github.io/istatlab/reference/download_multiple_datasets.md)
  for batch operations across multiple datasets
- Explore
  [`forecast_series()`](https://gmontaletti.github.io/istatlab/reference/forecast_series.md)
  for time series forecasting
- Check the package documentation for additional functions:
  [`?istatlab`](https://gmontaletti.github.io/istatlab/reference/istatlab-package.md)

For the full list of available datasets, refer to the [ISTAT SDMX
catalog](https://www.istat.it/it/metodi-e-strumenti/web-service-sdmx).
