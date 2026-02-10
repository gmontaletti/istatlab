# HTTP GET using httr Package

Internal function that performs HTTP GET using the httr package.

## Usage

``` r
http_get_httr(url, timeout, accept, verbose)
```

## Arguments

- url:

  Character string with the full URL

- timeout:

  Numeric timeout in seconds

- accept:

  Character string with Accept header value

- verbose:

  Logical whether to log status messages

## Value

A list with success, content, status_code, and error components
