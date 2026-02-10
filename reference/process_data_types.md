# Process Data Types

Handles data types with different base years by keeping only the latest
base year. This is important for index series where ISTAT may provide
data with multiple base years (e.g., 2015=100, 2020=100) to ensure
consistency.

## Usage

``` r
process_data_types(data)
```

## Arguments

- data:

  A data.table with DATA_TYPE column containing base year information
  (e.g., "base2020=100")

## Value

The data.table filtered to contain only data from the latest base year
