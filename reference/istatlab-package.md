# istatlab: Download and Process Italian Labour Market Data from ISTAT

A toolkit for downloading and processing Italian labour market data from
ISTAT (Istituto Nazionale di Statistica) through their SDMX API. The
package provides functions for data retrieval, metadata handling, and
data processing with automatic label application.

The istatlab package provides a toolkit for downloading and processing
Italian labour market data from ISTAT (Istituto Nazionale di Statistica)
through their SDMX API.

## Main functions

- Data Download::

  [`download_istat_data()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data.md),
  [`download_multiple_datasets()`](https://gmontaletti.github.io/istatlab/reference/download_multiple_datasets.md),
  [`test_endpoint_connectivity()`](https://gmontaletti.github.io/istatlab/reference/test_endpoint_connectivity.md)

- Metadata Management::

  [`download_metadata()`](https://gmontaletti.github.io/istatlab/reference/download_metadata.md),
  [`download_codelists()`](https://gmontaletti.github.io/istatlab/reference/download_codelists.md),
  [`get_dataset_dimensions()`](https://gmontaletti.github.io/istatlab/reference/get_dataset_dimensions.md)

- Data Processing::

  [`apply_labels()`](https://gmontaletti.github.io/istatlab/reference/apply_labels.md),
  [`filter_by_time()`](https://gmontaletti.github.io/istatlab/reference/filter_by_time.md),
  [`validate_istat_data()`](https://gmontaletti.github.io/istatlab/reference/validate_istat_data.md)

## Package workflow

A typical workflow with istatlab involves:

1.  Download metadata and identify datasets of interest

2.  Download the actual data using dataset IDs

3.  Process and label the data

## See also

Useful links:

- <https://github.com/gmontaletti/istatlab>

- Report bugs at <https://github.com/gmontaletti/istatlab/issues>

Useful links:

- <https://github.com/gmontaletti/istatlab>

- Report bugs at <https://github.com/gmontaletti/istatlab/issues>

## Author

**Maintainer**: Giampaolo Montaletti <giampaolo.montaletti@gmail.com>
([ORCID](https://orcid.org/0009-0002-5327-1122))
