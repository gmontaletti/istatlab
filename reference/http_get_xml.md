# HTTP GET with XML Content

Fetches a URL through the throttled transport layer and returns the raw
text content for XML parsing. Replaces direct httr::GET calls for XML
endpoints.

## Usage

``` r
http_get_xml(url, timeout = 120, verbose = TRUE)
```

## Arguments

- url:

  Character string with the full URL

- timeout:

  Numeric timeout in seconds

- verbose:

  Logical whether to log status messages

## Value

Character string with XML content, or signals an error on failure
