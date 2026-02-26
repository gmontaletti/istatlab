# Build HVD v1 (SDMX 2.1) URL

Constructs request URLs for the ISTAT HVD v1 API surface, which follows
the SDMX 2.1 RESTful specification. Supports the `data`,
`availableconstraint`, `structure`, and `dataflow` endpoints. For the
`data` endpoint, both GET and POST URL shapes are available (POST places
the filter key in the request body rather than in the URL path).

## Usage

``` r
build_hvd_v1_url(
  endpoint,
  dataset_id = NULL,
  filter = "ALL",
  provider = "all",
  start_time = NULL,
  end_time = NULL,
  updated_after = NULL,
  lastNObservations = NULL,
  detail = NULL,
  includeHistory = NULL,
  method = "GET"
)
```

## Arguments

- endpoint:

  Character string specifying the endpoint type. One of `"data"`,
  `"availableconstraint"`, `"structure"`, or `"dataflow"`.

- dataset_id:

  Character string specifying the ISTAT dataset (flow) identifier (e.g.,
  `"150_908"`). Required for `"data"`, `"availableconstraint"`, and
  `"structure"` endpoints.

- filter:

  Character string with the SDMX positional key filter. Default `"ALL"`
  (no filtering). Ignored when `method = "POST"`.

- provider:

  Character string identifying the data provider. Default `"all"`.

- start_time:

  Character string specifying the start period for data retrieval (e.g.,
  `"2020"`, `"2020-Q1"`, `"2020-01"`).

- end_time:

  Character string specifying the end period for data retrieval.

- updated_after:

  Character string in ISO 8601 format (e.g., `"2025-01-01T00:00:00Z"`).
  When provided, the server returns only observations updated after this
  timestamp.

- lastNObservations:

  Integer. Limits the response to the last N observations per time
  series.

- detail:

  Character string controlling the amount of information returned (e.g.,
  `"full"`, `"dataonly"`, `"nodata"`).

- includeHistory:

  Logical. When `TRUE`, historical revisions of data points are
  included.

- method:

  Character string, either `"GET"` (default) or `"POST"`. Controls the
  URL shape for the `data` endpoint.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# GET data URL with time filter
build_hvd_v1_url("data", dataset_id = "150_908",
                 start_time = "2020", end_time = "2024")

# POST data URL (filter key sent in body, not in URL)
build_hvd_v1_url("data", dataset_id = "150_908", method = "POST")

# Available constraint URL
build_hvd_v1_url("availableconstraint", dataset_id = "150_908")

# Dataflow listing URL (no dataset_id needed)
build_hvd_v1_url("dataflow")
} # }
```
