# istatlab: Download and Process Italian Statistical Data from ISTAT

A toolkit for downloading and processing Italian statistical data from
ISTAT (Istituto Nazionale di Statistica). Supports both the SDMX API
(esploradati.istat.it) for any published dataset and static CSV
downloads (demo.istat.it) for demographic data including population,
births, deaths, migrations, and projections. Provides functions for data
retrieval, metadata handling, caching, and data processing with
automatic label application.

The istatlab package provides a toolkit for downloading and processing
Italian statistical data from ISTAT (Istituto Nazionale di Statistica).
It supports both the SDMX API (esploradati.istat.it) for any published
dataset and static CSV downloads (demo.istat.it) for demographic data
including population, births, deaths, migrations, and projections.

## Statistical Data (SDMX API)

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

## Demographic Data (demo.istat.it)

- Dataset Discovery::

  [`list_demo_datasets()`](https://gmontaletti.github.io/istatlab/reference/list_demo_datasets.md),
  [`search_demo_datasets()`](https://gmontaletti.github.io/istatlab/reference/search_demo_datasets.md),
  [`get_demo_dataset_info()`](https://gmontaletti.github.io/istatlab/reference/get_demo_dataset_info.md),
  [`get_demo_categories()`](https://gmontaletti.github.io/istatlab/reference/get_demo_categories.md)

- Data Download::

  [`download_demo_data()`](https://gmontaletti.github.io/istatlab/reference/download_demo_data.md),
  [`download_demo_data_multi()`](https://gmontaletti.github.io/istatlab/reference/download_demo_data_multi.md),
  [`download_demo_data_batch()`](https://gmontaletti.github.io/istatlab/reference/download_demo_data_batch.md)

- Cache Management::

  [`demo_cache_status()`](https://gmontaletti.github.io/istatlab/reference/demo_cache_status.md),
  [`clean_demo_cache()`](https://gmontaletti.github.io/istatlab/reference/clean_demo_cache.md)

## Package workflow

A typical workflow with istatlab involves:

1.  Download metadata and identify datasets of interest

2.  Download the actual data using dataset IDs

3.  Process and label the data

## See also

Useful links:

- <https://gmontaletti.github.io/istatlab/>

- <https://github.com/gmontaletti/istatlab>

- Report bugs at <https://github.com/gmontaletti/istatlab/issues>

Useful links:

- <https://gmontaletti.github.io/istatlab/>

- <https://github.com/gmontaletti/istatlab>

- Report bugs at <https://github.com/gmontaletti/istatlab/issues>

## Author

**Maintainer**: Giampaolo Montaletti <giampaolo.montaletti@gmail.com>
([ORCID](https://orcid.org/0009-0002-5327-1122))
