# Build Demo URL for ISTAT Demographic Data

Constructs the download URL for a given demographic dataset by looking
up its code in the demo registry and dispatching to the appropriate
pattern builder. The four URL patterns correspond to different
file-naming conventions used on demo.istat.it.

## Usage

``` r
build_demo_url(
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

  Character string identifying the dataset in the demo registry (e.g.,
  `"d7b"`, `"posas"`, `"tvm"`, `"prev"`).

- year:

  Integer year for the data file. Required for patterns A, B, and C.

- territory:

  Character string specifying geographic territory (Pattern B only).
  Valid values are defined per dataset in the demo registry.

- level:

  Character string specifying geographic aggregation level (Pattern C
  only). Valid values are defined per dataset in the demo registry.

- type:

  Character string specifying data completeness type (Pattern C only).
  Valid values are defined per dataset in the demo registry.

- data_type:

  Character string specifying forecast data category (Pattern D only).
  Valid values are defined per dataset in the demo registry.

- geo_level:

  Character string specifying geographic resolution (Pattern D only).
  Valid values are defined per dataset in the demo registry.

## Value

Character string containing the full download URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Pattern A (year-indexed)
build_demo_url("d7b", year = 2024)

# Pattern B (territory-indexed)
build_demo_url("posas", year = 2025, territory = "Comuni")

# Pattern C (type+level)
build_demo_url("tvm", year = 2024, level = "regionali", type = "completi")

# Pattern D (category-level)
build_demo_url("prev", data_type = "Previsioni-Popolazione_per_eta",
               geo_level = "Regioni")
} # }
```
