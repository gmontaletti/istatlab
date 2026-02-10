# Process Time Dimension

Processes the time dimension in ISTAT data, converting SDMX time codes
to appropriate R Date objects. Handles monthly (M), quarterly (Q), and
annual (A) frequency data with proper date formatting.

## Usage

``` r
process_time_dimension(data)
```

## Arguments

- data:

  A data.table with ObsDimension column containing SDMX time codes and
  FREQ column indicating frequency

## Value

The data.table with processed tempo_label column containing Date objects
