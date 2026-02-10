# Compute Staggered TTL for Codelist

Computes a deterministic TTL for a codelist based on a hash of its ID.
This distributes codelist expirations across a time window to prevent
all codelists from expiring simultaneously (thundering herd problem).

## Usage

``` r
compute_codelist_ttl(codelist_id, base_ttl = NULL, jitter_days = NULL)
```

## Arguments

- codelist_id:

  Character string, codelist ID (e.g., "CL_FREQ")

- base_ttl:

  Numeric, minimum TTL in days. Default from config (14)

- jitter_days:

  Numeric, distribution window in days. Default from config (14)

## Value

Numeric TTL in days (base_ttl to base_ttl + jitter_days - 1)

## Examples

``` r
if (FALSE) { # \dontrun{
# Compute TTL for a codelist
ttl <- compute_codelist_ttl("CL_FREQ")
# Returns a value between 14 and 27 days

# Different codelists get different TTLs
ttl1 <- compute_codelist_ttl("CL_FREQ")
ttl2 <- compute_codelist_ttl("CL_ITTER107")
# ttl1 and ttl2 are deterministic but likely different
} # }
```
