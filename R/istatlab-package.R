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
#' @importFrom data.table copy
#' @importFrom data.table %chin%
#' @importFrom zoo as.yearqtr
#' @importFrom parallel mclapply
#' @importFrom parallel detectCores
#' @importFrom stats setNames
#' @importFrom utils globalVariables
#' @importFrom utils tail
## usethis namespace: end

# Suppress R CMD check notes for data.table syntax
utils::globalVariables(c(".", ".N", ".SD", ":=", "ObsDimension", "ObsValue",
                         "FREQ", "EDITION", "EDITION_new", "DATA_TYPE", "id", "base", "tempo_temp",
                         "tempo_label", "valore_label", "it_description", "id_description",
                         "en_description", "agencyID", "version",
                         "..label_cols", "..group_vars", "..varying_cols", "cl", "var", "DATAFLOW"))

#' istatlab: Download and Process Italian Labour Market Data from ISTAT
#'
#' The istatlab package provides a toolkit for downloading and processing
#' Italian labour market data from ISTAT (Istituto Nazionale di Statistica)
#' through their SDMX API.
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
#' }
#'
#' @section Package workflow:
#' A typical workflow with istatlab involves:
#' \enumerate{
#'   \item Download metadata and identify datasets of interest
#'   \item Download the actual data using dataset IDs
#'   \item Process and label the data
#' }
#'
#' @name istatlab-package
#' @aliases istatlab
"_PACKAGE"
