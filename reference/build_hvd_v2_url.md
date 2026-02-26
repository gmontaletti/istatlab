# Build HVD v2 (SDMX 3.0) URL

Constructs request URLs for the ISTAT HVD v2 API surface, which follows
the SDMX 3.0 RESTful specification. The key differences from v1 are: (1)
the `/rest/v2/` path prefix, (2) an explicit
`{context}/{agencyId}/{resourceId}/{version}` path structure, and (3)
the `c[DIM]=value` query parameter syntax for dimension filtering
(replacing `startPeriod` / `endPeriod`).

## Usage

``` r
build_hvd_v2_url(
  endpoint,
  dataset_id = NULL,
  context = "dataflow",
  agency_id = "IT1",
  version = "~",
  filter = "*",
  component_id = "all",
  start_time = NULL,
  end_time = NULL,
  dim_filters = NULL,
  updated_after = NULL,
  lastNObservations = NULL,
  method = "GET"
)
```

## Arguments

- endpoint:

  Character string specifying the endpoint type. One of `"data"`,
  `"availability"`, or `"structure"`.

- dataset_id:

  Character string specifying the ISTAT dataset (resource) identifier
  (e.g., `"150_908"`). Required for all endpoints.

- context:

  Character string specifying the structural metadata context. Default
  `"dataflow"`.

- agency_id:

  Character string identifying the maintenance agency. Default `"IT1"`
  (ISTAT).

- version:

  Character string specifying the resource version. Default `"~"`
  (latest available version).

- filter:

  Character string with the SDMX 3.0 key filter. Default `"*"` (all
  keys). Ignored when `method = "POST"`.

- component_id:

  Character string specifying the component to constrain in availability
  queries. Default `"all"`. Only used for the `"availability"` endpoint.

- start_time:

  Character string specifying the start period (e.g., `"2020"`).
  Translated to `c[TIME_PERIOD]=ge:2020` syntax by
  [`build_sdmx3_filters()`](https://gmontaletti.github.io/istatlab/reference/build_sdmx3_filters.md).

- end_time:

  Character string specifying the end period (e.g., `"2025"`).
  Translated to `c[TIME_PERIOD]=le:2025` syntax by
  [`build_sdmx3_filters()`](https://gmontaletti.github.io/istatlab/reference/build_sdmx3_filters.md).

- dim_filters:

  Named list of dimension filters where names are dimension IDs and
  values are filter expressions (e.g.,
  `list(FREQ = "M", REF_AREA = "IT")`). Translated to `c[FREQ]=M`
  syntax.

- updated_after:

  Character string in ISO 8601 format for incremental retrieval.

- lastNObservations:

  Integer limiting the response to the last N observations per time
  series.

- method:

  Character string, either `"GET"` (default) or `"POST"`. Controls the
  URL shape for the `data` endpoint.

## Value

Character string containing the constructed URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# GET data URL with time range and dimension filter
build_hvd_v2_url("data", dataset_id = "150_908",
                 start_time = "2020", end_time = "2025",
                 dim_filters = list(FREQ = "M"))

# POST data URL
build_hvd_v2_url("data", dataset_id = "150_908", method = "POST")

# Availability URL
build_hvd_v2_url("availability", dataset_id = "150_908")

# Structure URL
build_hvd_v2_url("structure", dataset_id = "150_908")
} # }
```
