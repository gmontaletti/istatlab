# Normalize CSV Columns

Normalizes CSV column names to match expected SDMX naming conventions.
Provides backward compatibility with existing code that expects
SDMX-style names.

## Usage

``` r
normalize_csv_columns(dt)
```

## Arguments

- dt:

  data.table from CSV parsing

## Value

data.table with normalized column names (modified in place)

## Details

Column mappings:

- TIME_PERIOD -\> ObsDimension (time dimension)

- OBS_VALUE -\> ObsValue (observation value)

Also removes the DATAFLOW column which contains redundant metadata.
