# Extract Dimension to Codelist Mapping

Internal function to extract dimension name to codelist reference
mapping. This is a wrapper that handles different input types for
backward compatibility.

## Usage

``` r
extract_dimension_mapping(raw_codelist, json_data = NULL)
```

## Arguments

- raw_codelist:

  data.table containing raw codelist data with id, version, agencyID
  columns. This is used as a fallback when JSON parsing is not
  available.

- json_data:

  Optional parsed JSON from datastructure endpoint (preferred source)

## Value

Named list mapping dimension names to codelist references (e.g.,
"IT1/CL_FREQ/1.0")
