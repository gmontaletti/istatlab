# Download Binary File to Disk

Core transport function for downloading binary files (ZIP archives) from
demo.istat.it. Uses httr as the primary method with curl as fallback.

## Usage

``` r
http_download_binary(url, dest_path, timeout = 120, verbose = TRUE)
```

## Arguments

- url:

  Character string with the full URL to download.

- dest_path:

  Character string with the local file path to write to.

- timeout:

  Numeric timeout in seconds. Default 120.

- verbose:

  Logical whether to log status messages. Default TRUE.

## Value

A list with components:

- success:

  Logical indicating if download succeeded

- dest_path:

  Character path where file was written

- status_code:

  HTTP status code (integer), or NA on connection error

- error:

  Error message string, or NULL on success

- method:

  Character indicating which method succeeded ("httr" or "curl")

- file_size:

  Numeric file size in bytes (only present on success)

## Details

Unlike
[`http_get()`](https://gmontaletti.github.io/istatlab/reference/http_get.md)
which returns text content for SDMX responses, this function writes
binary data directly to disk using
[`httr::write_disk()`](https://httr.r-lib.org/reference/write_disk.html).
