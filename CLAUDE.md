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

## Version Management Workflow

### Semantic Versioning
The istatlab package follows semantic versioning (SemVer) with the format MAJOR.MINOR.PATCH:
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality in a backwards compatible manner
- **PATCH**: Backwards compatible bug fixes

### Git and renv Integration
1. **Before making changes**: Always check `renv::status()` and `git status`
2. **After adding new dependencies**: Run `renv::snapshot()` to update renv.lock
3. **Before commits**: Ensure all tests pass with `devtools::check()`
4. **Commit workflow**: 
   - Use conventional commit format: `type(scope): description`
   - Common types: feat, fix, docs, style, refactor, test, chore
   - Always commit renv.lock when dependencies change

### Version Release Process
1. Update version number in DESCRIPTION file
2. Update Date field in DESCRIPTION to release date
3. Add release notes to NEWS.md
4. Run `devtools::check()` to ensure package integrity
5. Run `renv::snapshot()` if dependencies changed
6. Commit changes with message: `chore: release version X.Y.Z`
7. Create git tag: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
8. Push commits and tags to GitHub

### File Management
- **Never commit**: renv/library/, renv/local/, renv/cellar/, .Rhistory
- **Always commit**: DESCRIPTION, NEWS.md, renv.lock (when changed), all R/ files
- **Selectively commit**: Documentation updates in man/ (auto-generated from roxygen2)

### Branch Strategy
- **main**: Stable releases only
- **develop**: Integration of new features
- **feature/***: Individual feature development
- **hotfix/***: Critical bug fixes for production

### Pre-commit Checklist
- [ ] Package builds successfully (`devtools::build()`)
- [ ] All tests pass (`devtools::test()`)
- [ ] Documentation is current (`devtools::document()`)
- [ ] renv is synchronized (`renv::status()`)
- [ ] NEWS.md is updated for user-facing changes
- [ ] Version number updated if needed
- always use agents