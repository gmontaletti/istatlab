# Extract Dimension to Codelist Mapping from JSON Response

Internal function to extract dimension ID to codelist reference mapping
from the JSON datastructure response. This correctly maps dimension IDs
(e.g., REF_AREA, SEX) to their corresponding codelists (e.g.,
CL_ITTER107, CL_SEXISTAT1).

## Usage

``` r
extract_dimension_mapping_from_json(json_data)
```

## Arguments

- json_data:

  Parsed JSON from datastructure endpoint (as list)

## Value

Named list mapping dimension IDs to codelist references (e.g.,
"IT1/CL_FREQ/1.0")
