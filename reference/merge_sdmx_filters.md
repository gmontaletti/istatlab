# Merge Dimension Values into an Existing SDMX Filter

Takes an existing SDMX filter string and fills in additional dimension
values without overwriting positions already specified by the user. When
the base filter is `NULL` or `"ALL"`, a new filter key is built from
scratch using
[`build_sdmx_filter_key`](https://gmontaletti.github.io/istatlab/reference/build_sdmx_filter_key.md).

## Usage

``` r
merge_sdmx_filters(base_filter, n_dims, dim_values)
```

## Arguments

- base_filter:

  Character string with an existing dot-separated filter, or `NULL` /
  `"ALL"` to indicate no existing filter.

- n_dims:

  Integer. Total number of dimensions in the dataset.

- dim_values:

  Named list mapping dimension positions (as character strings) to
  filter values. Same format as in
  [`build_sdmx_filter_key`](https://gmontaletti.github.io/istatlab/reference/build_sdmx_filter_key.md).
  Values are only inserted into positions that are empty (wildcard) in
  `base_filter`; existing user-specified values are preserved.

## Value

Character string containing the merged dot-separated filter key.

## Examples

``` r
if (FALSE) { # \dontrun{
# Fill position 7 into an 8-dimension filter that has positions 1 and 3 set
merge_sdmx_filters("M..IT.....", 8, list("7" = "G_2024_01"))
# Returns: "M..IT....G_2024_01."

# User-specified values are not overwritten
merge_sdmx_filters("M..IT.....", 8, list("1" = "Q", "7" = "G_2024_01"))
# Returns: "M..IT....G_2024_01." (position 1 keeps "M", not overwritten)

# NULL base_filter builds from scratch
merge_sdmx_filters(NULL, 8, list("1" = "M", "7" = "G_2024_01"))
# Returns: "M......G_2024_01."
} # }
```
