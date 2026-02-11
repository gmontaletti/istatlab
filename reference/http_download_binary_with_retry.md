# Download Binary File with Retry and Rate Limiting

Wraps
[`http_download_binary()`](https://gmontaletti.github.io/istatlab/reference/http_download_binary.md)
with demo-specific throttling and exponential backoff retry logic. Uses
configuration from `get_istat_config()$demo_rate_limit`.

## Usage

``` r
http_download_binary_with_retry(url, dest_path, timeout = 120, verbose = TRUE)
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

A list with same structure as
[`http_download_binary()`](https://gmontaletti.github.io/istatlab/reference/http_download_binary.md).

## Details

Retries are attempted on HTTP 429 (rate limited) and 503 (service
unavailable) responses. Non-retryable errors (e.g., 404) are returned
immediately.
