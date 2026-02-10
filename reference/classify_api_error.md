# Classify API Error

Classifies an API error into standard categories with exit codes. Exit
codes follow the reference implementation:

- 0: Success

- 1: Generic error (connectivity, HTTP, parsing)

- 2: Timeout error

- 3: Rate limited (HTTP 429)

## Usage

``` r
classify_api_error(error_message)
```

## Arguments

- error_message:

  Character string containing error message

## Value

A list with type, exit_code, and formatted message
