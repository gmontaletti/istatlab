#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom data.table :=
#' @importFrom data.table .N
#' @importFrom data.table .SD
#' @importFrom data.table data.table
#' @importFrom data.table is.data.table
#' @importFrom data.table rbindlist
#' @importFrom data.table setDT
#' @importFrom data.table setnames
#' @importFrom data.table setorderv
#' @importFrom data.table tstrsplit
## usethis namespace: end

# Suppress R CMD check notes for data.table syntax
utils::globalVariables(c(".", ".N", ".SD", ":=", "ObsDimension", "ObsValue", 
                         "FREQ", "EDITION", "DATA_TYPE", "id", "base", "tempo_temp",
                         "tempo_label", "valore_label", "it_description", "id_description"))

#' istatlab: Download and Analyze Italian Labour Market Data from ISTAT
#'
#' The istatlab package provides a comprehensive toolkit for downloading,
#' processing, analyzing, and visualizing Italian labour market data from
#' ISTAT (Istituto Nazionale di Statistica) through their SDMX API.
#'
#' @section Main functions:
#' \describe{
#'   \item{Data Download:}{
#'     \code{\link{download_istat_data}()}, \code{\link{download_multiple_datasets}()},
#'     \code{\link{check_istat_api}()}
#'   }
#'   \item{Metadata Management:}{
#'     \code{\link{download_metadata}()}, \code{\link{download_codelists}()},
#'     \code{\link{get_dataset_dimensions}()}
#'   }
#'   \item{Data Processing:}{
#'     \code{\link{apply_labels}()}, \code{\link{filter_by_time}()},
#'     \code{\link{validate_istat_data}()}
#'   }
#'   \item{Analysis:}{
#'     \code{\link{analyze_trends}()}, \code{\link{calculate_growth_rates}()},
#'     \code{\link{calculate_summary_stats}()}, \code{\link{detect_structural_breaks}()}
#'   }
#'   \item{Forecasting:}{
#'     \code{\link{forecast_series}()}, \code{\link{evaluate_forecast_accuracy}()}
#'   }
#'   \item{Visualization:}{
#'     \code{\link{create_time_series_plot}()}, \code{\link{create_forecast_plot}()},
#'     \code{\link{create_comparison_plot}()}, \code{\link{create_dashboard_plot}()}
#'   }
#' }
#'
#' @section Package workflow:
#' A typical workflow with istatlab involves:
#' \enumerate{
#'   \item Download metadata and identify datasets of interest
#'   \item Download the actual data using dataset IDs
#'   \item Process and label the data
#'   \item Perform analysis (trends, growth rates, structural breaks)
#'   \item Generate forecasts if needed
#'   \item Create publication-ready visualizations
#' }
#'
#' @docType package
#' @name istatlab
NULL