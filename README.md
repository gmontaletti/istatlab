# istatlab

<!-- badges: start -->
[![R-CMD-check](https://github.com/gmontaletti/istatlab/workflows/R-CMD-check/badge.svg)](https://github.com/gmontaletti/istatlab/actions)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**istatlab** is a comprehensive R package for downloading, processing, analyzing, and visualizing Italian labour market data from ISTAT (Istituto Nazionale di Statistica) through their SDMX API.

## Features

- **Data Download**: Streamlined access to ISTAT's SDMX API with automatic retry and error handling
- **Metadata Management**: Comprehensive metadata handling including codelists and dimensions
- **Data Processing**: Automatic labeling, time formatting, and data validation
- **Time Series Analysis**: Trend analysis, growth rate calculations, and structural break detection
- **Forecasting**: Multiple forecasting methods including ARIMA, ETS, and linear trends
- **Visualization**: Publication-ready plots with ggplot2 integration

## Installation

You can install the development version of istatlab from [GitHub](https://github.com/) with:

```r
# install.packages("devtools")
devtools::install_github("gmontaletti/istatlab")
```

## Quick Start

```r
library(istatlab)

# Check API connectivity
test_endpoint_connectivity("data")

# Download metadata to explore available datasets
metadata <- download_metadata()
head(metadata)

# Download data for a specific dataset
data <- download_istat_data("150_908", start_time = "2020")

# Apply labels and process the data
processed_data <- apply_labels(data)

# Create a time series plot
create_time_series_plot(processed_data, 
                       title = "Italian Labour Market Data",
                       subtitle = "Source: ISTAT")
```

## Main Functions

### Data Download
- `download_istat_data()`: Download data for a single dataset
- `download_multiple_datasets()`: Download multiple datasets in parallel
- `test_endpoint_connectivity()`: Check API endpoint connectivity

### Metadata Management
- `download_metadata()`: Download dataset metadata
- `download_codelists()`: Download codelists for dimension labeling
- `get_dataset_dimensions()`: Get dimensions for a specific dataset

### Data Processing
- `apply_labels()`: Apply dimension labels to raw data
- `filter_by_time()`: Filter data by time period
- `validate_istat_data()`: Validate data structure

### Analysis
- `analyze_trends()`: Perform trend analysis using various methods
- `calculate_growth_rates()`: Calculate period, annual, or cumulative growth rates
- `calculate_summary_stats()`: Generate comprehensive summary statistics
- `detect_structural_breaks()`: Detect structural breaks in time series

### Forecasting
- `forecast_series()`: Generate forecasts using multiple methods
- `evaluate_forecast_accuracy()`: Evaluate forecast performance
- `create_forecast_summary()`: Create forecast summary tables

### Visualization
- `create_time_series_plot()`: Standard time series plots
- `create_forecast_plot()`: Plots with forecasts and confidence intervals
- `create_comparison_plot()`: Compare multiple series or groups
- `create_growth_plot()`: Growth rate visualization
- `create_dashboard_plot()`: Multi-panel dashboard plots

## Workflow Example

```r
library(istatlab)

# 1. Explore available datasets
metadata <- download_metadata()
print(metadata[grepl("employment", Name.it, ignore.case = TRUE), .(id, Name.it)])

# 2. Download data for employment statistics
employment_data <- download_istat_data("150_915", start_time = "2015")

# 3. Process and label the data
processed_employment <- apply_labels(employment_data)

# 4. Calculate growth rates
employment_with_growth <- calculate_growth_rates(processed_employment, 
                                               type = "annual")

# 5. Analyze trends
trend_analysis <- analyze_trends(processed_employment, method = "linear")

# 6. Generate forecasts
forecast_results <- forecast_series(processed_employment, 
                                   periods = 12, 
                                   method = "auto.arima")

# 7. Create visualizations
ts_plot <- create_time_series_plot(processed_employment,
                                  title = "Italian Employment Trends",
                                  subtitle = "Source: ISTAT")

forecast_plot <- create_forecast_plot(processed_employment, forecast_results,
                                     title = "Employment Forecast")

# 8. Create a dashboard
dashboard <- create_dashboard_plot(processed_employment,
                                  panels = c("timeseries", "growth"),
                                  title = "Employment Dashboard")
```

## Dataset IDs

Common ISTAT dataset IDs for labour market data:

- `150_908`: Monthly employment data
- `150_915`: Quarterly employment statistics  
- `150_916`: Annual employment indicators
- `151_914`: Unemployment rates
- `152_913`: Labour force participation
- `534_50`: Job vacancies
- `532_930`: Working hours

## Configuration

The package automatically handles:
- API timeouts and connection issues
- Metadata caching (refreshes every 14 days)
- Data validation and error handling
- Memory-efficient data processing with data.table

## Dependencies

Core dependencies:
- `data.table`: Fast data manipulation
- `httr`: HTTP requests
- `jsonlite`: JSON parsing
- `readsdmx`: SDMX data parsing
- `zoo`: Time series handling

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Citation

To cite istatlab in publications:

```r
citation("istatlab")
```

Montaletti, G. (2026). istatlab: Download and Process Italian Labour Market Data from ISTAT. R package version 0.5.0. https://github.com/gmontaletti/istatlab

## Author

Giampaolo Montaletti (giampaolo.montaletti@gmail.com)  
ORCID: [0009-0002-5327-1122](https://orcid.org/0009-0002-5327-1122)  
GitHub: [gmontaletti](https://github.com/gmontaletti)

## Acknowledgments

- ISTAT for providing comprehensive labour market data through their SDMX API
- The R community for excellent packages that make this work possible