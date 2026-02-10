# Compute Data Checksum

Computes MD5 checksum for data integrity verification. Pattern from
reference implementation. Requires the digest package (optional
dependency).

## Usage

``` r
compute_data_checksum(dt)
```

## Arguments

- dt:

  data.table to compute checksum for

## Value

Character MD5 hash string, or NA_character\_ if digest is not available
