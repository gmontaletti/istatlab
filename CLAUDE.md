# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**istatlab** is an R package for downloading, processing, analyzing, and visualizing Italian labour market data from ISTAT's SDMX API. The package is authored by Giampaolo Montaletti (giampaolo.montaletti@gmail.com, GitHub: gmontaletti).

## Package Structure

This is a standard R package with the following core structure:

- `R/`: Main source code organized by functionality
  - `download.R`: API data retrieval functions
  - `metadata.R`: Metadata management and caching
  - `processing.R`: Data processing and labeling functions
  - `analysis.R`: Time series analysis and trend detection
  - `forecast.R`: Forecasting methods (ARIMA, ETS, linear, naive)
  - `visualize.R`: ggplot2-based visualization functions
- `tests/testthat/`: Test suite using testthat framework
- `man/`: Auto-generated documentation from roxygen2 comments
- `data-raw/`: Raw data processing scripts
- `vignettes/`: Package vignettes and tutorials

## Development Commands

### Building and Checking
```r
# Load package for development
devtools::load_all()

# Check package
devtools::check()

# Build package
devtools::build()

# Install package
devtools::install()
```

### Testing
```r
# Run all tests
devtools::test()

# Run specific test file
testthat::test_file("tests/testthat/test-download.R")

# Test coverage
covr::package_coverage()
```

### Documentation
```r
# Generate documentation from roxygen2 comments
devtools::document()

# Build vignettes
devtools::build_vignettes()

# Check examples
devtools::run_examples()
```

## Code Architecture

### Core Dependencies
- **data.table**: Primary data manipulation framework for performance
- **readsdmx**: SDMX API integration for ISTAT data
- **ggplot2**: All visualization functions
- **zoo**: Time series data handling
- **forecast**: Advanced forecasting methods

### Data Flow Pattern
1. **Download**: Raw SDMX data retrieval with error handling and retries
2. **Metadata**: Cached metadata management (14-day refresh cycle)
3. **Processing**: Label application and data validation
4. **Analysis**: Time series analysis, growth rates, structural breaks
5. **Forecasting**: Multiple forecasting methods with accuracy evaluation
6. **Visualization**: Publication-ready plots with consistent theming

### Key Design Principles
- All functions use data.table for performance on large datasets
- Comprehensive input validation with informative error messages
- Metadata caching to minimize API calls
- Consistent roxygen2 documentation with examples
- Error handling with graceful fallbacks throughout

### Important Notes
- **NEVER modify the original `moneca()` function** (mentioned in global instructions)
- Functions are designed for Italian labour market data but architecture supports extension
- API connectivity checking is built into download functions
- Time series functions handle both quarterly and monthly data automatically

### Testing Strategy
- Unit tests for all major functions
- API connectivity tests (with appropriate mocking)
- Data validation tests
- Forecast accuracy validation
- Plot generation tests (using vdiffr for visual regression)

### Common Dataset IDs (for testing/examples)
- `150_908`: Monthly employment data
- `150_915`: Quarterly employment statistics  
- `151_914`: Unemployment rates
- `534_50`: Job vacancies