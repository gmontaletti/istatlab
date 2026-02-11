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
#' @importFrom grDevices rgb
#' @importFrom graphics legend lines polygon
#' @importFrom stats coef lm median quantile sd setNames time ts window
#' @importFrom utils globalVariables head tail
#' @importFrom zoo as.yearqtr
#' @importFrom parallel mclapply
#' @importFrom parallel detectCores
## usethis namespace: end

# Suppress R CMD check notes for data.table syntax
utils::globalVariables(c(
  ".",
  ".N",
  ".SD",
  ":=",
  "ObsDimension",
  "ObsValue",
  "FREQ",
  "EDITION",
  "EDITION_new",
  "DATA_TYPE",
  "id",
  "base",
  "tempo_temp",
  "tempo_label",
  "valore_label",
  "it_description",
  "id_description",
  "en_description",
  "agencyID",
  "version",
  "..label_cols",
  "..group_vars",
  "..varying_cols",
  "cl",
  "var",
  "DATAFLOW",
  "..cols",
  "..code_cols",
  "valore",
  "tempo",
  "year"
))

#' istatlab: Download and Process Italian Statistical Data from ISTAT
#'
#' The istatlab package provides a toolkit for downloading and processing
#' Italian statistical data from ISTAT (Istituto Nazionale di Statistica).
#' It supports both the SDMX API (esploradati.istat.it) for any published
#' dataset and static CSV downloads (demo.istat.it) for demographic data
#' including population, births, deaths, migrations, and projections.
#'
#' @section Statistical Data (SDMX API):
#' \describe{
#'   \item{Data Download:}{
#'     \code{\link{download_istat_data}()}, \code{\link{download_multiple_datasets}()},
#'     \code{\link{test_endpoint_connectivity}()}
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
#' @section Demographic Data (demo.istat.it):
#' \describe{
#'   \item{Dataset Discovery:}{
#'     \code{\link{list_demo_datasets}()}, \code{\link{search_demo_datasets}()},
#'     \code{\link{get_demo_dataset_info}()}, \code{\link{get_demo_categories}()}
#'   }
#'   \item{Data Download:}{
#'     \code{\link{download_demo_data}()}, \code{\link{download_demo_data_multi}()},
#'     \code{\link{download_demo_data_batch}()}
#'   }
#'   \item{Cache Management:}{
#'     \code{\link{demo_cache_status}()}, \code{\link{clean_demo_cache}()}
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
