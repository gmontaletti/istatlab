# Download Single Codelist

Internal function to download codelist for a single dataset. Fetches
JSON from the datastructure endpoint to get both codelist data and the
correct dimension-to-codelist mapping.

## Usage

``` r
download_single_codelist(dataset_id)
```

## Arguments

- dataset_id:

  Character string specifying the dataset ID

## Value

A list with two elements:

- codelist: data.table containing the codelist with id, id_description,
  en_description, it_description, version, agencyID columns

- dimension_mapping: named list mapping dimension IDs (e.g., REF_AREA)
  to codelist references (e.g., "IT1/CL_ITTER107/1.0")

Returns NULL if download fails.
