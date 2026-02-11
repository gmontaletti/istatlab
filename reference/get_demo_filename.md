# Get Demo Filename from URL Parameters

Extracts the filename portion of the download URL for a given dataset.
This is useful for computing cache paths without constructing the full
URL.

## Usage

``` r
get_demo_filename(
  code,
  year = NULL,
  territory = NULL,
  level = NULL,
  type = NULL,
  data_type = NULL,
  geo_level = NULL
)
```

## Arguments

- code:

  Character string identifying the dataset in the demo registry.

- year:

  Integer year for the data file (patterns A, B, C).

- territory:

  Character string specifying geographic territory (Pattern B).

- level:

  Character string specifying aggregation level (Pattern C).

- type:

  Character string specifying data type (Pattern C).

- data_type:

  Character string specifying forecast category (Pattern D).

- geo_level:

  Character string specifying geographic resolution (Pattern D).

## Value

Character string containing the filename (e.g., `"D7B2024.csv.zip"`).

## Examples

``` r
if (FALSE) { # \dontrun{
get_demo_filename("d7b", year = 2024)
# "D7B2024.csv.zip"

get_demo_filename("posas", year = 2025, territory = "Comuni")
# "POSAS_2025_it_Comuni.zip"
} # }
```
