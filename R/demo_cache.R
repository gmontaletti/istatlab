# demo_cache.R - Cache management for demo.istat.it demographic data
# Provides cache path computation, update checking, ZIP extraction,
# cache status reporting, and cache cleanup.

# 1. Cache path computation -----

#' Compute Cache Path for a Demo Dataset File
#'
#' Builds the full file path where a demo.istat.it download should be
#' cached. The layout is \code{{cache_dir}/{tolower(code)}/{filename}}.
#' This function does not create any directories on disk.
#'
#' @param code Character string identifying the dataset (e.g., \code{"D7B"}).
#' @param filename Character string with the file name
#'   (e.g., \code{"D7B2024.csv.zip"}).
#' @param cache_dir Character string with the root cache directory. If
#'   \code{NULL} (default), the value from
#'   \code{get_istat_config()$demo$cache_dir} is used.
#'
#' @return Character string with the full cache file path.
#'
#' @examples
#' \dontrun{
#' path <- get_demo_cache_path("D7B", "D7B2024.csv.zip")
#' # "demo_data/d7b/D7B2024.csv.zip"
#' }
#'
#' @keywords internal
get_demo_cache_path <- function(code, filename, cache_dir = NULL) {
  if (is.null(code) || !is.character(code) || length(code) != 1L) {
    stop("'code' must be a single character string.")
  }

  if (is.null(filename) || !is.character(filename) || length(filename) != 1L) {
    stop("'filename' must be a single character string.")
  }

  if (is.null(cache_dir)) {
    cache_dir <- get_istat_config()$demo$cache_dir
  }

  file.path(cache_dir, tolower(code), filename)
}

# 2. Update checking -----

#' Check Whether a Cached Demo File Needs Re-downloading
#'
#' Determines if a locally cached file should be refreshed by comparing
#' the server's \code{Last-Modified} header (via \code{http_head_demo()})
#' with the file's modification time. When the HEAD request fails or the
#' server does not provide a \code{Last-Modified} header, the function
#' falls back to an age-based check using
#' \code{get_istat_config()$demo$cache_max_age_days}.
#'
#' @param url Character string with the remote URL of the file.
#' @param cached_file_path Character string with the local path to the
#'   cached file.
#' @param verbose Logical whether to log status messages. Default
#'   \code{TRUE}.
#'
#' @return A list with components:
#'   \describe{
#'     \item{needs_update}{Logical indicating if a re-download is needed.}
#'     \item{reason}{Character string describing the decision:
#'       \code{"not_cached"}, \code{"server_newer"},
#'       \code{"up_to_date"}, \code{"age_exceeded"}, or
#'       \code{"within_age_limit"}.}
#'   }
#'
#' @examples
#' \dontrun{
#' status <- check_demo_update(
#'   url = "https://demo.istat.it/data/d7b/D7B2024.csv.zip",
#'   cached_file_path = "demo_data/d7b/D7B2024.csv.zip"
#' )
#' if (status$needs_update) message("Re-download required: ", status$reason)
#' }
#'
#' @keywords internal
check_demo_update <- function(url, cached_file_path, verbose = TRUE) {
  if (is.null(url) || !is.character(url) || length(url) != 1L) {
    stop("'url' must be a single character string.")
  }

  if (
    is.null(cached_file_path) ||
      !is.character(cached_file_path) ||
      length(cached_file_path) != 1L
  ) {
    stop("'cached_file_path' must be a single character string.")
  }

  # File not present on disk: always download
  if (!file.exists(cached_file_path)) {
    istat_log("Cached file not found, download required", "INFO", verbose)
    return(list(needs_update = TRUE, reason = "not_cached"))
  }

  # Attempt HEAD request for Last-Modified comparison
  head_result <- http_head_demo(url)

  if (head_result$success && !is.na(head_result$last_modified)) {
    local_mtime <- file.mtime(cached_file_path)

    if (head_result$last_modified > local_mtime) {
      istat_log(
        paste0(
          "Server file is newer (server: ",
          format(head_result$last_modified, "%Y-%m-%d %H:%M:%S"),
          ", local: ",
          format(local_mtime, "%Y-%m-%d %H:%M:%S"),
          ")"
        ),
        "INFO",
        verbose
      )
      return(list(needs_update = TRUE, reason = "server_newer"))
    }

    istat_log("Cached file is up to date", "INFO", verbose)
    return(list(needs_update = FALSE, reason = "up_to_date"))
  }

  # Fallback: age-based check
  if (!head_result$success) {
    istat_log(
      "HEAD request failed, falling back to age-based check",
      "WARNING",
      verbose
    )
  } else {
    istat_log(
      "No Last-Modified header, falling back to age-based check",
      "WARNING",
      verbose
    )
  }

  max_age_days <- get_istat_config()$demo$cache_max_age_days
  local_mtime <- file.mtime(cached_file_path)
  age_days <- as.numeric(difftime(Sys.time(), local_mtime, units = "days"))

  if (age_days > max_age_days) {
    istat_log(
      paste0(
        "Cached file age (",
        round(age_days, 1),
        " days) exceeds maximum (",
        max_age_days,
        " days)"
      ),
      "INFO",
      verbose
    )
    return(list(needs_update = TRUE, reason = "age_exceeded"))
  }

  istat_log(
    paste0(
      "Cached file age (",
      round(age_days, 1),
      " days) is within limit (",
      max_age_days,
      " days)"
    ),
    "INFO",
    verbose
  )
  list(needs_update = FALSE, reason = "within_age_limit")
}

# 3. ZIP extraction -----

#' Extract CSV Data from a Demo ZIP Archive
#'
#' Extracts CSV files from a ZIP archive downloaded from demo.istat.it
#' and returns the contents as a \code{data.table}. When the archive
#' contains multiple CSV files they are combined with
#' \code{data.table::rbindlist()}.
#'
#' Encoding is attempted first as UTF-8; if that fails (common with
#' older ISTAT files), Latin-1 is used as fallback.
#'
#' @param zip_path Character string with the path to the ZIP file.
#' @param verbose Logical whether to log status messages. Default
#'   \code{TRUE}.
#'
#' @return A \code{data.table} with the contents of the CSV file(s).
#'
#' @examples
#' \dontrun{
#' dt <- extract_demo_csv("demo_data/d7b/D7B2024.csv.zip")
#' str(dt)
#' }
#'
#' @keywords internal
extract_demo_csv <- function(zip_path, verbose = TRUE) {
  if (is.null(zip_path) || !is.character(zip_path) || length(zip_path) != 1L) {
    stop("'zip_path' must be a single character string.")
  }

  if (!file.exists(zip_path)) {
    stop("ZIP file not found: ", zip_path)
  }

  # List archive contents
  zip_contents <- utils::unzip(zip_path, list = TRUE)

  # Filter CSV files
  csv_files <- zip_contents$Name[grepl(
    "\\.csv$",
    zip_contents$Name,
    ignore.case = TRUE
  )]

  if (length(csv_files) == 0L) {
    stop(
      "No CSV files found inside ZIP archive: ",
      zip_path,
      ". Archive contains: ",
      paste(zip_contents$Name, collapse = ", ")
    )
  }

  # Extract to a temporary directory
  temp_dir <- tempfile(pattern = "demo_extract_")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  utils::unzip(zip_path, files = csv_files, exdir = temp_dir)

  istat_log(
    paste0(
      "Extracting ",
      length(csv_files),
      " CSV file(s) from ",
      basename(zip_path)
    ),
    "INFO",
    verbose
  )

  # Read each CSV file
  dt_list <- lapply(csv_files, function(csv_name) {
    csv_full_path <- file.path(temp_dir, csv_name)
    .read_demo_csv(csv_full_path, csv_name, verbose)
  })

  # Combine if multiple files
  if (length(dt_list) == 1L) {
    return(dt_list[[1L]])
  }

  istat_log(
    paste0("Combining ", length(dt_list), " CSV files with rbindlist()"),
    "INFO",
    verbose
  )

  data.table::rbindlist(dt_list, use.names = TRUE, fill = TRUE)
}

#' Read a Single CSV File with Encoding Fallback
#'
#' Helper that reads a CSV file using \code{data.table::fread()},
#' trying UTF-8 first and falling back to Latin-1 on encoding errors.
#'
#' @param csv_path Character string with the full path to the CSV file.
#' @param csv_name Character string with the original filename (for logging).
#' @param verbose Logical whether to log status messages.
#'
#' @return A \code{data.table}.
#' @keywords internal
.read_demo_csv <- function(csv_path, csv_name, verbose) {
  # Try UTF-8 first
  dt <- tryCatch(
    data.table::fread(csv_path, encoding = "UTF-8"),
    error = function(e) {
      NULL
    },
    warning = function(w) {
      # Some encoding warnings can be safely caught
      if (grepl("encoding|invalid", tolower(w$message))) {
        return(NULL)
      }
      # Re-issue non-encoding warnings and continue
      warning(w)
      suppressWarnings(data.table::fread(csv_path, encoding = "UTF-8"))
    }
  )

  if (!is.null(dt)) {
    return(dt)
  }

  # Fallback to Latin-1
  istat_log(
    paste0("UTF-8 failed for '", csv_name, "', retrying with Latin-1"),
    "WARNING",
    verbose
  )

  data.table::fread(csv_path, encoding = "Latin-1")
}

# 4. Cache status reporting -----

#' List Cached Demo.istat.it Data Files
#'
#' Returns a summary table of all files present in the demo.istat.it
#' cache directory, including file size, modification time, and age.
#'
#' @param cache_dir Character string with the root cache directory. If
#'   \code{NULL} (default), the value from
#'   \code{get_istat_config()$demo$cache_dir} is used.
#'
#' @return A \code{data.table} with columns:
#'   \describe{
#'     \item{code}{Dataset code extracted from the subdirectory name
#'       (uppercase).}
#'     \item{file}{Filename.}
#'     \item{size_mb}{File size in megabytes (rounded to 2 decimals).}
#'     \item{modified}{File modification time as \code{POSIXct}.}
#'     \item{age_days}{Number of days since the file was last modified
#'       (rounded to 1 decimal).}
#'   }
#'   If the cache directory does not exist or contains no files, an empty
#'   \code{data.table} with the same columns is returned.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Show all cached demo files
#' status <- demo_cache_status()
#' print(status)
#'
#' # Check a specific cache directory
#' status <- demo_cache_status(cache_dir = "my_cache")
#' }
demo_cache_status <- function(cache_dir = NULL) {
  if (is.null(cache_dir)) {
    cache_dir <- get_istat_config()$demo$cache_dir
  }

  # Empty result template
  empty_result <- data.table::data.table(
    code = character(0L),
    file = character(0L),
    size_mb = numeric(0L),
    modified = as.POSIXct(character(0L)),
    age_days = numeric(0L)
  )

  if (!dir.exists(cache_dir)) {
    return(empty_result)
  }

  # List all files recursively
  all_files <- list.files(cache_dir, recursive = TRUE, full.names = TRUE)

  if (length(all_files) == 0L) {
    return(empty_result)
  }

  # Get file metadata
  finfo <- file.info(all_files)

  # Extract subdirectory name as dataset code
  rel_paths <- sub(
    paste0("^", normalizePath(cache_dir, mustWork = FALSE), .Platform$file.sep),
    "",
    normalizePath(all_files, mustWork = FALSE)
  )

  # The code is the first path component (subdirectory name)
  codes <- vapply(
    strsplit(rel_paths, .Platform$file.sep),
    function(parts) {
      if (length(parts) >= 2L) {
        toupper(parts[1L])
      } else {
        NA_character_
      }
    },
    character(1L)
  )

  now <- Sys.time()

  data.table::data.table(
    code = codes,
    file = basename(all_files),
    size_mb = round(finfo$size / (1024 * 1024), 2L),
    modified = finfo$mtime,
    age_days = round(
      as.numeric(difftime(now, finfo$mtime, units = "days")),
      1L
    )
  )
}

# 5. Cache cleanup -----

#' Remove Cached Demo.istat.it Data Files
#'
#' Deletes files from the demo.istat.it cache directory. Filtering by
#' dataset code and/or maximum file age is supported. When both
#' \code{code} and \code{max_age_days} are \code{NULL}, all cached
#' files are removed.
#'
#' @param code Character string with the dataset code to clean (e.g.,
#'   \code{"D7B"}). If \code{NULL} (default), files for all datasets
#'   are considered.
#' @param cache_dir Character string with the root cache directory. If
#'   \code{NULL} (default), the value from
#'   \code{get_istat_config()$demo$cache_dir} is used.
#' @param max_age_days Numeric maximum file age in days. Only files
#'   whose modification time is older than this threshold are removed.
#'   If \code{NULL} (default), no age filtering is applied.
#'
#' @return Invisible integer count of files removed.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Remove all cached files for dataset D7B
#' clean_demo_cache(code = "D7B")
#'
#' # Remove files older than 60 days
#' clean_demo_cache(max_age_days = 60)
#'
#' # Remove all cached demo files
#' clean_demo_cache()
#' }
clean_demo_cache <- function(
  code = NULL,
  cache_dir = NULL,
  max_age_days = NULL
) {
  # Validate inputs early
  if (!is.null(code)) {
    if (!is.character(code) || length(code) != 1L) {
      stop("'code' must be a single character string.")
    }
  }

  if (!is.null(max_age_days)) {
    if (
      !is.numeric(max_age_days) ||
        length(max_age_days) != 1L ||
        max_age_days < 0
    ) {
      stop("'max_age_days' must be a single non-negative number.")
    }
  }

  if (is.null(cache_dir)) {
    cache_dir <- get_istat_config()$demo$cache_dir
  }

  if (!dir.exists(cache_dir)) {
    istat_log("Cache directory does not exist, nothing to clean", "INFO", TRUE)
    return(invisible(0L))
  }

  # Determine search path
  if (!is.null(code)) {
    search_dir <- file.path(cache_dir, tolower(code))

    if (!dir.exists(search_dir)) {
      istat_log(
        paste0("No cached files for dataset '", code, "'"),
        "INFO",
        TRUE
      )
      return(invisible(0L))
    }

    all_files <- list.files(search_dir, recursive = TRUE, full.names = TRUE)
  } else {
    all_files <- list.files(cache_dir, recursive = TRUE, full.names = TRUE)
  }

  if (length(all_files) == 0L) {
    istat_log("No cached files found", "INFO", TRUE)
    return(invisible(0L))
  }

  # Filter by age if requested
  if (!is.null(max_age_days)) {
    finfo <- file.info(all_files)
    age_days <- as.numeric(difftime(Sys.time(), finfo$mtime, units = "days"))
    all_files <- all_files[age_days > max_age_days]
  }

  if (length(all_files) == 0L) {
    istat_log("No files match the removal criteria", "INFO", TRUE)
    return(invisible(0L))
  }

  # Warn when removing everything (no code or age filter)
  if (is.null(code) && is.null(max_age_days)) {
    istat_log(
      paste0(
        "Removing ALL ",
        length(all_files),
        " cached demo file(s) from '",
        cache_dir,
        "'"
      ),
      "WARNING",
      TRUE
    )
  }

  # Remove files
  removed_count <- 0L
  for (f in all_files) {
    result <- tryCatch(
      {
        unlink(f)
        TRUE
      },
      error = function(e) {
        istat_log(
          paste0("Failed to remove '", f, "': ", e$message),
          "WARNING",
          TRUE
        )
        FALSE
      }
    )
    if (result) {
      removed_count <- removed_count + 1L
    }
  }

  # Clean up empty subdirectories
  if (!is.null(code)) {
    sub_dir <- file.path(cache_dir, tolower(code))
    remaining <- list.files(sub_dir, recursive = TRUE, all.files = TRUE)
    if (length(remaining) == 0L && dir.exists(sub_dir)) {
      unlink(sub_dir, recursive = TRUE)
    }
  } else {
    # Check all subdirectories
    sub_dirs <- list.dirs(cache_dir, recursive = FALSE, full.names = TRUE)
    for (d in sub_dirs) {
      remaining <- list.files(d, recursive = TRUE, all.files = TRUE)
      if (length(remaining) == 0L) {
        unlink(d, recursive = TRUE)
      }
    }
  }

  istat_log(
    paste0("Removed ", removed_count, " cached demo file(s)"),
    "INFO",
    TRUE
  )

  invisible(removed_count)
}
