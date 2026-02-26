# Normalize SDMX 3.0 CSV Column Names

Maps column names from the SDMX 3.0 CSV format to the legacy naming
convention used throughout istatlab. The SDMX 3.0 specification may use
different column names than SDMX 2.1. This function ensures that
downstream code receives consistent column names regardless of the API
version used.

## Usage

``` r
normalize_csv_columns_v2(dt)
```

## Arguments

- dt:

  data.table from CSV parsing

## Value

data.table with normalized column names (modified in place)

## Details

If columns already follow the legacy naming convention, the data.table
is returned unchanged. Operates by reference (modifies in place).

Column mappings (v2 -\> legacy):

- `TIME_PERIOD` -\> `ObsDimension`

- `OBS_VALUE` -\> `ObsValue`

- `STRUCTURE` -\> removed (v2 metadata, equivalent to v1 DATAFLOW)

- `STRUCTURE_ID` -\> removed

- `STRUCTURE_NAME` -\> removed

- `ACTION` -\> removed (v2-only column)
