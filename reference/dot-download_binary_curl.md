# Download Binary File Using curl

Fallback function using
[`curl::curl_download()`](https://jeroen.r-universe.dev/curl/reference/curl_download.html)
for binary downloads when httr encounters transport-level errors.

## Usage

``` r
.download_binary_curl(url, dest_path, timeout, config)
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

## Value

A list with success, dest_path, status_code, error, and file_size.
