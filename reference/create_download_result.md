# Create Download Result

Creates a standardized result object for download operations.

## Usage

``` r
create_download_result(
  success,
  data = NULL,
  exit_code = 0L,
  message = "",
  md5 = NA_character_,
  is_timeout = FALSE
)
```

## Arguments

- success:

  Logical indicating if operation succeeded

- data:

  data.table with downloaded data (or NULL on failure)

- exit_code:

  Integer exit code (0=success, 1=error, 2=timeout)

- message:

  Character message describing result

- md5:

  Character MD5 checksum of data (optional)

- is_timeout:

  Logical indicating if failure was due to timeout

## Value

A list with class "istat_result"
