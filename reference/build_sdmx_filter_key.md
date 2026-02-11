# Build SDMX Positional Filter Key

Constructs a dot-separated positional filter key for SDMX API queries.
The ISTAT SDMX API uses positional filters where each dimension is
separated by a dot. Empty positions act as wildcards (match all values).
For example, a dataset with 8 dimensions and a filter key
`"M......G_2024_01."` means dimension 1 is `"M"`, dimension 7 is
`"G_2024_01"`, and all other dimensions are unrestricted.

## Usage

``` r
build_sdmx_filter_key(n_dims, dim_values)
```

## Arguments

- n_dims:

  Integer. Total number of dimensions in the dataset. Must be a positive
  integer.

- dim_values:

  Named list mapping dimension positions (as character strings) to
  filter values. Position numbering starts at 1. For example,
  `list("1" = "M", "7" = "G_2024_01")` sets dimension 1 to `"M"` and
  dimension 7 to `"G_2024_01"`.

## Value

Character string containing the dot-separated filter key.

## Examples

``` r
# Set dimension 1 to "M" and dimension 7 to "G_2024_01" in an 8-dimension dataset
build_sdmx_filter_key(8, list("1" = "M", "7" = "G_2024_01"))
#> [1] "M......G_2024_01."
# Returns: "M......G_2024_01."

# Single dimension filter
build_sdmx_filter_key(5, list("3" = "IT"))
#> [1] "..IT.."
# Returns: "..IT.."

# All wildcards (equivalent to "ALL")
build_sdmx_filter_key(4, list())
#> [1] "..."
# Returns: "..."
```
