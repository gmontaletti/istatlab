# Filter Data by Time Period

Filters ISTAT data by a specified time period. Handles different date
formats based on frequency (A=Annual, Q=Quarterly, M=Monthly) when
filtering raw data.

## Usage

``` r
filter_by_time(
  data,
  start_date = NULL,
  end_date = NULL,
  time_col = "ObsDimension"
)
```

## Arguments

- data:

  A data.table with time information

- start_date:

  Date or character string specifying start date (e.g., "2020-01-01")

- end_date:

  Date or character string specifying end date

- time_col:

  Character string specifying the time column name. Default is
  "ObsDimension" for raw ISTAT data.

## Value

Filtered data.table

## Examples

``` r
if (FALSE) { # \dontrun{
# Filter raw data from 2020 onwards
filtered_data <- filter_by_time(data, start_date = "2020-01-01")

# Filter quarterly data
q_data <- download_istat_data_by_freq("151_914")$Q
filtered_q <- filter_by_time(q_data, start_date = "2024-01-01")
} # }
```
