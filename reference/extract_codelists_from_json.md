# Extract Codelists from JSON Response

Internal function to extract codelist data from the JSON datastructure
response.

## Usage

``` r
extract_codelists_from_json(json_data)
```

## Arguments

- json_data:

  Parsed JSON from datastructure endpoint (as list)

## Value

data.table with codelist data (id, id_description, en_description,
it_description, version, agencyID columns)
