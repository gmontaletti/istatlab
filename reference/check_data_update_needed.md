# Check if Data Update is Needed

Compares ISTAT's LAST_UPDATE timestamp with our download log to
determine if data needs to be re-downloaded.

## Usage

``` r
check_data_update_needed(dataset_id, cache_dir = "meta", verbose = TRUE)
```

## Arguments

- dataset_id:

  Character string specifying the dataset ID

- cache_dir:

  Character string specifying cache directory

- verbose:

  Logical for status messages

## Value

List with needs_update (logical), istat_last_update, last_download
timestamps
