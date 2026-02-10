# Apply Labels to ISTAT Data

Processes raw ISTAT data by applying dimension labels and formatting
time variables. This function has been heavily optimized using
data.table's advanced features for maximum performance on large
datasets.

## Usage

``` r
apply_labels(
  data,
  codelists = NULL,
  var_dimensions = NULL,
  timing = FALSE,
  verbose = FALSE
)
```

## Arguments

- data:

  A data.table containing raw ISTAT data

- codelists:

  A named list of codelists for dimension labeling. If NULL, attempts to
  load from cache

- var_dimensions:

  A list of variable dimensions mapping. If NULL, attempts to load from
  cache

- timing:

  Logical indicating whether to track execution time. If TRUE, adds
  execution_time attribute to result

- verbose:

  Logical indicating whether to print detailed timing information. Only
  used when timing = TRUE

## Value

A processed data.table with labels applied. If timing = TRUE, includes
an execution_time attribute with total runtime in seconds

## Details

**Performance Optimizations:**

- Metadata caching to avoid repeated file I/O

- Vectorized data.table joins instead of iterative merges

- Key-based operations for ultra-fast lookups

- Reference semantics to minimize memory copying

- Optimized column filtering using uniqueN()

- In-place factor conversion using set() operations

For large datasets (\>100K rows), this optimized version can be 5-10x
faster than the original implementation.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
raw_data <- download_istat_data("150_908")
labeled_data <- apply_labels(raw_data)

# With performance timing
labeled_data <- apply_labels(raw_data, timing = TRUE, verbose = TRUE)
execution_time <- attr(labeled_data, "execution_time")
} # }
```
