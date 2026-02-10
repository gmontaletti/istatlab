# Check Which Codelists Need Renewal

Checks each codelist against its staggered TTL and returns a list of
codelists that need to be refreshed.

## Usage

``` r
check_codelist_expiration(
  codelist_ids = NULL,
  cache_dir = "meta",
  force_check = FALSE
)
```

## Arguments

- codelist_ids:

  Character vector of codelist IDs to check. If NULL, checks all cached
  codelists.

- cache_dir:

  Character, cache directory path. Default "meta"

- force_check:

  Logical, if TRUE returns all codelists as expired. Default FALSE

## Value

Character vector of codelist IDs that need renewal

## Examples

``` r
if (FALSE) { # \dontrun{
# Check which codelists are expired
expired <- check_codelist_expiration()
message("Expired codelists: ", paste(expired, collapse = ", "))

# Check specific codelists
expired <- check_codelist_expiration(c("CL_FREQ", "CL_ITTER107"))

# Force check all as expired
all_cls <- check_codelist_expiration(force_check = TRUE)
} # }
```
