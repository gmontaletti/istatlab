# Resolve the Metadata Cache Directory

Internal helper returning the root directory for the ISTAT metadata
cache (`codelists.rds`, `flussi_istat.rds`, `codelist_metadata.rds`,
`dataset_codelist_map.rds`, `data_download_log.rds`). The directory is
resolved from the `ISTATLAB_CACHE_DIR` environment variable via
`Sys.getenv("ISTATLAB_CACHE_DIR", unset = "meta")`, so multiple projects
can share a single cache. When the variable is unset (or empty), the
historical default `"meta"` (relative to the working directory) is used,
preserving backward compatibility.

## Usage

``` r
.istatlab_cache_dir()
```

## Value

Character scalar with the cache directory path.
