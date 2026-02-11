# demo_download.R - User-facing download functions for demo.istat.it demographic data
# Provides high-level functions for downloading, caching, and extracting demographic
# datasets published as CSV-in-ZIP files on demo.istat.it.

# 1. Single dataset download -----

#' Download Demographic Data from Demo.istat.it
#'
#' Downloads and extracts a single demographic dataset from ISTAT's demo.istat.it
#' portal. Files are cached locally as ZIP archives; subsequent calls for the
#' same parameters reuse the cached file unless the remote has been updated or
#' \code{force_download = TRUE} is set.
#'
#' The function resolves the dataset code through the internal demo registry,
#' builds the download URL for the appropriate file-naming pattern, and extracts
#' the CSV content from the downloaded ZIP archive.
#'
#' @param code Character string identifying the dataset in the demo registry
#'   (e.g., \code{"D7B"}, \code{"POS"}, \code{"TVM"}, \code{"PPR"}). Use
#'   \code{\link{list_demo_datasets}} to see available codes.
#' @param year Integer year for the data file. Required for patterns A, B, and C.
#' @param territory Character string specifying geographic territory (Pattern B
#'   only, e.g., \code{"Comuni"}, \code{"Province"}, \code{"Regioni"}).
#' @param level Character string specifying geographic aggregation level
#'   (Pattern C only, e.g., \code{"regionali"}, \code{"provinciali"}).
#' @param type Character string specifying data completeness type (Pattern C
#'   only, e.g., \code{"completi"}, \code{"sintetici"}).
#' @param data_type Character string specifying forecast data category
#'   (Pattern D only).
#' @param geo_level Character string specifying geographic resolution
#'   (Pattern D only, e.g., \code{"Regioni"}, \code{"Italia"}).
#' @param cache_dir Character string specifying directory for cached files.
#'   If \code{NULL} (default), uses the value from
#'   \code{get_istat_config()$demo$cache_dir}.
#' @param force_download Logical indicating whether to bypass cache and
#'   re-download the file. Default \code{FALSE}.
#' @param verbose Logical indicating whether to print status messages.
#'   Default \code{TRUE}.
#'
#' @return A \code{data.table} containing the extracted CSV data.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download monthly demographic balance for 2024
#' dt <- download_demo_data("D7B", year = 2024)
#'
#' # Download population by territory
#' dt <- download_demo_data("POS", year = 2025, territory = "Comuni")
#'
#' # Download mortality tables
#' dt <- download_demo_data("TVM", year = 2024, level = "regionali", type = "completi")
#'
#' # Force re-download
#' dt <- download_demo_data("D7B", year = 2024, force_download = TRUE)
#' }
download_demo_data <- function(
  code,
  year = NULL,
  territory = NULL,
  level = NULL,
  type = NULL,
  data_type = NULL,
  geo_level = NULL,
  cache_dir = NULL,
  force_download = FALSE,
  verbose = TRUE
) {
  # 1a. Validate code -----
  if (!is.character(code) || length(code) != 1L || nchar(code) == 0L) {
    stop("'code' must be a non-empty single character string.")
  }

  dataset_info <- get_demo_dataset_info(code)

  # 1b. Resolve cache directory -----
  if (is.null(cache_dir)) {
    cache_dir <- get_istat_config()$demo$cache_dir
  }

  # 1c. Build URL and filename -----
  url <- build_demo_url(
    code = code,
    year = year,
    territory = territory,
    level = level,
    type = type,
    data_type = data_type,
    geo_level = geo_level
  )

  filename <- get_demo_filename(
    code = code,
    year = year,
    territory = territory,
    level = level,
    type = type,
    data_type = data_type,
    geo_level = geo_level
  )

  cache_path <- get_demo_cache_path(
    code = code,
    filename = filename,
    cache_dir = cache_dir
  )

  # 1d. Ensure cache directory exists -----
  dir.create(dirname(cache_path), recursive = TRUE, showWarnings = FALSE)

  # 1e. Build description for log messages -----
  desc <- dataset_info$description_en
  year_label <- if (!is.null(year)) paste0(" for year ", year) else ""

  istat_log(
    paste0("Downloading ", code, " (", desc, ")", year_label, "..."),
    "INFO",
    verbose
  )

  # 1f. Determine whether download is needed -----
  needs_download <- force_download

  if (!needs_download) {
    update_check <- check_demo_update(
      url = url,
      cached_file_path = cache_path,
      verbose = verbose
    )

    if (!update_check$needs_update) {
      istat_log(
        paste0("Using cached file: ", cache_path),
        "INFO",
        verbose
      )
    } else {
      needs_download <- TRUE
    }
  }

  # 1g. Download ZIP if needed -----
  if (needs_download) {
    dl_result <- http_download_binary_with_retry(
      url = url,
      dest_path = cache_path,
      timeout = 120,
      verbose = verbose
    )

    if (!dl_result$success) {
      error_info <- classify_api_error(dl_result$error)
      stop(
        "Failed to download dataset '",
        code,
        "' from demo.istat.it: ",
        error_info$message
      )
    }

    istat_log(
      paste0("Download complete: ", dl_result$file_size, " bytes"),
      "INFO",
      verbose
    )
  }

  # 1h. Extract CSV from ZIP -----
  dt <- extract_demo_csv(zip_path = cache_path, verbose = verbose)

  istat_log(
    paste0("Extracted ", nrow(dt), " rows from ", filename),
    "INFO",
    verbose
  )

  dt
}

# 2. Multi-year download -----

#' Download Demographic Data for Multiple Years
#'
#' Downloads the same demographic dataset across multiple years and combines
#' the results into a single \code{data.table}. Each year is downloaded
#' independently; failures for individual years are captured as warnings and
#' the remaining successful results are still returned.
#'
#' @param code Character string identifying the dataset in the demo registry
#'   (e.g., \code{"D7B"}).
#' @param years Integer vector of years to download.
#' @param territory Character string specifying geographic territory (Pattern B
#'   only).
#' @param level Character string specifying geographic aggregation level
#'   (Pattern C only).
#' @param type Character string specifying data completeness type (Pattern C
#'   only).
#' @param cache_dir Character string specifying directory for cached files.
#'   If \code{NULL}, uses the config default.
#' @param force_download Logical indicating whether to bypass cache.
#'   Default \code{FALSE}.
#' @param verbose Logical indicating whether to print status messages.
#'   Default \code{TRUE}.
#'
#' @return A \code{data.table} combining data from all successfully downloaded
#'   years. A \code{year} column is added if not already present in the data.
#'   Returns an empty \code{data.table} if all years fail.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download 3 years of demographic balance
#' dt <- download_demo_data_multi("D7B", years = 2022:2024)
#' }
download_demo_data_multi <- function(
  code,
  years,
  territory = NULL,
  level = NULL,
  type = NULL,
  cache_dir = NULL,
  force_download = FALSE,
  verbose = TRUE
) {
  # 2a. Input validation -----
  if (!is.character(code) || length(code) != 1L || nchar(code) == 0L) {
    stop("'code' must be a non-empty single character string.")
  }

  if (!is.numeric(years) || length(years) == 0L) {
    stop("'years' must be a non-empty integer vector.")
  }

  years <- as.integer(years)

  if (anyNA(years)) {
    stop("'years' must not contain NA values.")
  }

  # 2b. Download each year -----
  results <- vector("list", length(years))
  failed_years <- character(0)

  for (i in seq_along(years)) {
    yr <- years[i]

    istat_log(
      paste0("Processing year ", yr, " (", i, "/", length(years), ")"),
      "INFO",
      verbose
    )

    dt_year <- tryCatch(
      {
        download_demo_data(
          code = code,
          year = yr,
          territory = territory,
          level = level,
          type = type,
          cache_dir = cache_dir,
          force_download = force_download,
          verbose = verbose
        )
      },
      error = function(e) {
        warning(
          "Failed to download ",
          code,
          " for year ",
          yr,
          ": ",
          e$message,
          call. = FALSE
        )
        failed_years <<- c(failed_years, as.character(yr))
        NULL
      }
    )

    if (!is.null(dt_year)) {
      # Add year column if not present
      if (!"year" %in% names(dt_year)) {
        dt_year[, year := yr]
      }
      results[[i]] <- dt_year
    }
  }

  # 2c. Combine results -----
  results <- Filter(Negate(is.null), results)

  if (length(results) == 0L) {
    warning(
      "All years failed for dataset '",
      code,
      "'. ",
      "No data returned.",
      call. = FALSE
    )
    return(data.table::data.table())
  }

  combined <- data.table::rbindlist(results, use.names = TRUE, fill = TRUE)

  if (length(failed_years) > 0L) {
    istat_log(
      paste0(
        "Completed with ",
        length(failed_years),
        " failed year(s): ",
        paste(failed_years, collapse = ", ")
      ),
      "WARNING",
      verbose
    )
  }

  istat_log(
    paste0(
      "Combined ",
      nrow(combined),
      " rows across ",
      length(results),
      " year(s)"
    ),
    "INFO",
    verbose
  )

  combined
}

# 3. Batch dataset download -----

#' Download Multiple Demographic Datasets
#'
#' Downloads several different demographic datasets for the same set of
#' parameters. Each dataset is downloaded independently; failures are captured
#' as warnings and the remaining successful results are still returned.
#'
#' @param codes Character vector of dataset codes to download.
#' @param year Integer year for the data file (patterns A, B, C).
#' @param territory Character string specifying geographic territory (Pattern B
#'   only).
#' @param level Character string specifying geographic aggregation level
#'   (Pattern C only).
#' @param type Character string specifying data completeness type (Pattern C
#'   only).
#' @param data_type Character string specifying forecast data category
#'   (Pattern D only).
#' @param geo_level Character string specifying geographic resolution
#'   (Pattern D only).
#' @param cache_dir Character string specifying directory for cached files.
#'   If \code{NULL}, uses the config default.
#' @param force_download Logical indicating whether to bypass cache.
#'   Default \code{FALSE}.
#' @param verbose Logical indicating whether to print status messages.
#'   Default \code{TRUE}.
#'
#' @return A named list of \code{data.table} objects, one per dataset code.
#'   Names correspond to the codes. Datasets that failed to download are
#'   excluded from the list.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download multiple demographic balance datasets
#' results <- download_demo_data_batch(c("D7B", "P02", "P03"), year = 2024)
#' }
download_demo_data_batch <- function(
  codes,
  year = NULL,
  territory = NULL,
  level = NULL,
  type = NULL,
  data_type = NULL,
  geo_level = NULL,
  cache_dir = NULL,
  force_download = FALSE,
  verbose = TRUE
) {
  # 3a. Input validation -----
  if (!is.character(codes) || length(codes) == 0L) {
    stop("'codes' must be a non-empty character vector.")
  }

  if (anyNA(codes) || any(nchar(codes) == 0L)) {
    stop("'codes' must not contain NA or empty values.")
  }

  # 3b. Download each dataset -----
  results <- stats::setNames(
    vector("list", length(codes)),
    codes
  )

  succeeded <- character(0)
  failed <- character(0)

  for (i in seq_along(codes)) {
    cd <- codes[i]

    istat_log(
      paste0("Batch download: dataset ", cd, " (", i, "/", length(codes), ")"),
      "INFO",
      verbose
    )

    dt <- tryCatch(
      {
        download_demo_data(
          code = cd,
          year = year,
          territory = territory,
          level = level,
          type = type,
          data_type = data_type,
          geo_level = geo_level,
          cache_dir = cache_dir,
          force_download = force_download,
          verbose = verbose
        )
      },
      error = function(e) {
        warning(
          "Failed to download dataset '",
          cd,
          "': ",
          e$message,
          call. = FALSE
        )
        NULL
      }
    )

    if (!is.null(dt)) {
      results[[cd]] <- dt
      succeeded <- c(succeeded, cd)
    } else {
      results[[cd]] <- NULL
      failed <- c(failed, cd)
    }
  }

  # 3c. Remove failed entries and report -----
  results <- Filter(Negate(is.null), results)

  if (length(failed) > 0L) {
    istat_log(
      paste0(
        "Batch complete. Succeeded: ",
        length(succeeded),
        "/",
        length(codes),
        ". Failed: ",
        paste(failed, collapse = ", ")
      ),
      "WARNING",
      verbose
    )
  } else {
    istat_log(
      paste0(
        "Batch complete. All ",
        length(codes),
        " dataset(s) downloaded successfully."
      ),
      "INFO",
      verbose
    )
  }

  results
}
