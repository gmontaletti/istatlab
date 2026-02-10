# Integrate Downloaded Data with Existing Data

Merges newly downloaded data with existing data, deduplicating on all
dimension columns plus ObsDimension.

## Usage

``` r
integrate_downloaded_data(existing_data, new_data)
```

## Arguments

- existing_data:

  data.table of previously downloaded data

- new_data:

  data.table of newly downloaded data

## Value

data.table with merged and deduplicated rows
