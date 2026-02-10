# Process Editions

Handles multiple editions in ISTAT data by keeping only the latest
edition. This ensures data consistency when ISTAT has published multiple
versions of the same dataset with different publication dates.

## Usage

``` r
process_editions(data)
```

## Arguments

- data:

  A data.table with EDITION column containing edition dates in ISTAT
  format (e.g., "G_2023_03" for March 2023)

## Value

The data.table filtered to contain only observations from the latest
edition
