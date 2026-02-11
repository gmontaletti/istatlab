# Download Binary File Using httr

Internal function performing binary download with httr::write_disk().

## Usage

``` r
.download_binary_httr(url, dest_path, timeout, config, verbose)
```

## Arguments

- url:

  Character URL to download.

- dest_path:

  Character local file path.

- timeout:

  Numeric timeout in seconds.

- config:

  Configuration list from get_istat_config().

- verbose:

  Logical whether to show progress.

## Value

A list with success, dest_path, status_code, error, and file_size.
