# demo_url_builder.R - URL construction for demographic data from demo.istat.it
# Builds download URLs for the four file-naming patterns used by ISTAT demographic
# datasets (year-indexed, territory-indexed, type+level, and category-level).

# 1. Main dispatcher -----

#' Build Demo URL for ISTAT Demographic Data
#'
#' Constructs the download URL for a given demographic dataset by looking up its
#' code in the demo registry and dispatching to the appropriate pattern builder.
#' The four URL patterns correspond to different file-naming conventions used on
#' demo.istat.it.
#'
#' @param code Character string identifying the dataset in the demo registry
#'   (e.g., \code{"d7b"}, \code{"posas"}, \code{"tvm"}, \code{"prev"}).
#' @param year Integer year for the data file. Required for patterns A, B, and C.
#' @param territory Character string specifying geographic territory (Pattern B only).
#'   Valid values are defined per dataset in the demo registry.
#' @param level Character string specifying geographic aggregation level (Pattern C
#'   only). Valid values are defined per dataset in the demo registry.
#' @param type Character string specifying data completeness type (Pattern C only).
#'   Valid values are defined per dataset in the demo registry.
#' @param data_type Character string specifying forecast data category (Pattern D
#'   only). Valid values are defined per dataset in the demo registry.
#' @param geo_level Character string specifying geographic resolution (Pattern D
#'   only). Valid values are defined per dataset in the demo registry.
#'
#' @return Character string containing the full download URL.
#'
#' @examples
#' \dontrun{
#' # Pattern A (year-indexed)
#' build_demo_url("d7b", year = 2024)
#'
#' # Pattern B (territory-indexed)
#' build_demo_url("posas", year = 2025, territory = "Comuni")
#'
#' # Pattern C (type+level)
#' build_demo_url("tvm", year = 2024, level = "regionali", type = "completi")
#'
#' # Pattern D (category-level)
#' build_demo_url("prev", data_type = "Previsioni-Popolazione_per_eta",
#'                geo_level = "Regioni")
#' }
#'
#' @keywords internal
build_demo_url <- function(
  code,
  year = NULL,
  territory = NULL,
  level = NULL,
  type = NULL,
  data_type = NULL,
  geo_level = NULL
) {
  # Validate code
  if (is.null(code) || !is.character(code) || length(code) != 1L) {
    stop("Parameter 'code' must be a single character string")
  }

  registry <- get_demo_registry()
  target_code <- code
  info <- registry[registry[["code"]] == target_code, ]

  if (nrow(info) == 0L) {
    available_codes <- paste(registry[["code"]], collapse = ", ")
    stop(
      "Dataset code '",
      code,
      "' not found in demo registry. ",
      "Available codes: ",
      available_codes
    )
  }

  # Ensure single row

  info <- info[1L, ]

  config <- get_istat_config()
  base_url <- config$demo$base_url

  switch(
    info$url_pattern,
    "A" = build_demo_url_a(info, year, base_url),
    "B" = build_demo_url_b(info, year, territory, base_url),
    "C" = build_demo_url_c(info, year, level, type, base_url),
    "D" = build_demo_url_d(info, data_type, geo_level, base_url),
    stop(
      "Unknown URL pattern '",
      info$url_pattern,
      "' for dataset '",
      code,
      "'"
    )
  )
}

# 2. Pattern A - year-indexed -----

#' Build Demo URL for Pattern A (Year-Indexed)
#'
#' Constructs URLs of the form
#' \code{{base_url}/{base_path}/{FILE_CODE}{YEAR}.csv.zip}, used by datasets
#' that publish one ZIP file per year with the year appended to the file code.
#'
#' @param info Single-row data.table from the demo registry.
#' @param year Integer year for the data file.
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # Returns: "https://demo.istat.it/data/d7b/D7B2024.csv.zip"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "d7b", ][1L, ]
#' build_demo_url_a(info, year = 2024,
#'                  base_url = get_istat_config()$demo$base_url)
#' }
#'
#' @keywords internal
build_demo_url_a <- function(info, year, base_url) {
  if (is.null(year)) {
    stop(
      "Parameter 'year' is required for dataset '",
      info$code,
      "' (Pattern A)"
    )
  }

  year <- as.integer(year)
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  if (year < info$year_start || year > current_year) {
    stop(
      "Year ",
      year,
      " is out of range for dataset '",
      info$code,
      "'. Valid range: ",
      info$year_start,
      "-",
      current_year
    )
  }

  # {base_url}/{base_path}/{FILE_CODE}{YEAR}.csv.zip
  paste0(base_url, "/", info$base_path, "/", info$file_code, year, ".csv.zip")
}

# 3. Pattern B - territory-indexed -----

#' Build Demo URL for Pattern B (Territory-Indexed)
#'
#' Constructs URLs of the form
#' \code{{base_url}/{base_path}/{FILE_CODE}_{YEAR}_it_{TERRITORY}.zip}, used by
#' datasets that publish separate ZIP files per geographic territory.
#'
#' @param info Single-row data.table from the demo registry.
#' @param year Integer year for the data file.
#' @param territory Character string specifying the geographic territory.
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # Returns: "https://demo.istat.it/data/posas/POSAS_2025_it_Comuni.zip"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "posas", ][1L, ]
#' build_demo_url_b(info, year = 2025, territory = "Comuni",
#'                  base_url = get_istat_config()$demo$base_url)
#' }
#'
#' @keywords internal
build_demo_url_b <- function(info, year, territory, base_url) {
  if (is.null(year)) {
    stop(
      "Parameter 'year' is required for dataset '",
      info$code,
      "' (Pattern B)"
    )
  }

  if (is.null(territory)) {
    stop(
      "Parameter 'territory' is required for dataset '",
      info$code,
      "' (Pattern B)"
    )
  }

  year <- as.integer(year)
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  if (year < info$year_start || year > current_year) {
    stop(
      "Year ",
      year,
      " is out of range for dataset '",
      info$code,
      "'. Valid range: ",
      info$year_start,
      "-",
      current_year
    )
  }

  valid_territories <- trimws(strsplit(info$territories, ",")[[1]])
  if (!territory %in% valid_territories) {
    stop(
      "Territory '",
      territory,
      "' is not valid for dataset '",
      info$code,
      "'. Valid values: ",
      paste(valid_territories, collapse = ", ")
    )
  }

  # {base_url}/{base_path}/{FILE_CODE}_{YEAR}_it_{TERRITORY}.zip
  paste0(
    base_url,
    "/",
    info$base_path,
    "/",
    info$file_code,
    "_",
    year,
    "_it_",
    territory,
    ".zip"
  )
}

# 4. Pattern C - type+level -----

#' Build Demo URL for Pattern C (Type and Level)
#'
#' Constructs URLs of the form
#' \code{{base_url}/{base_path}/dati{level}{type}{year}.zip}, used by datasets
#' that publish files segmented by geographic level and data type.
#'
#' @param info Single-row data.table from the demo registry.
#' @param year Integer year for the data file.
#' @param level Character string specifying the geographic aggregation level.
#' @param type Character string specifying the data completeness type.
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # Returns: "https://demo.istat.it/data/tvm/datiregionalicompleti2024.zip"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "tvm", ][1L, ]
#' build_demo_url_c(info, year = 2024, level = "regionali",
#'                  type = "completi", base_url = get_istat_config()$demo$base_url)
#' }
#'
#' @keywords internal
build_demo_url_c <- function(info, year, level, type, base_url) {
  if (is.null(year)) {
    stop(
      "Parameter 'year' is required for dataset '",
      info$code,
      "' (Pattern C)"
    )
  }

  if (is.null(level)) {
    stop(
      "Parameter 'level' is required for dataset '",
      info$code,
      "' (Pattern C)"
    )
  }

  if (is.null(type)) {
    stop(
      "Parameter 'type' is required for dataset '",
      info$code,
      "' (Pattern C)"
    )
  }

  year <- as.integer(year)
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  if (year < info$year_start || year > current_year) {
    stop(
      "Year ",
      year,
      " is out of range for dataset '",
      info$code,
      "'. Valid range: ",
      info$year_start,
      "-",
      current_year
    )
  }

  valid_levels <- trimws(strsplit(info$levels, ",")[[1]])
  if (!level %in% valid_levels) {
    stop(
      "Level '",
      level,
      "' is not valid for dataset '",
      info$code,
      "'. Valid values: ",
      paste(valid_levels, collapse = ", ")
    )
  }

  valid_types <- trimws(strsplit(info$types, ",")[[1]])
  if (!type %in% valid_types) {
    stop(
      "Type '",
      type,
      "' is not valid for dataset '",
      info$code,
      "'. Valid values: ",
      paste(valid_types, collapse = ", ")
    )
  }

  # {base_url}/{base_path}/dati{level}{type}{year}.zip
  paste0(
    base_url,
    "/",
    info$base_path,
    "/",
    "dati",
    level,
    type,
    year,
    ".zip"
  )
}

# 5. Pattern D - category-level -----

#' Build Demo URL for Pattern D (Category-Level)
#'
#' Constructs URLs of the form
#' \code{{base_url}/previsioni/{DataType}-{GeoLevel}.zip}, used by forecast
#' datasets that publish static files keyed by data category and geographic
#' resolution rather than by year.
#'
#' @param info Single-row data.table from the demo registry.
#' @param data_type Character string specifying the forecast data category.
#' @param geo_level Character string specifying the geographic resolution.
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # Returns: "https://demo.istat.it/data/previsioni/Previsioni-Popolazione_per_eta-Regioni.zip"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "prev", ][1L, ]
#' build_demo_url_d(info, data_type = "Previsioni-Popolazione_per_eta",
#'                  geo_level = "Regioni",
#'                  base_url = get_istat_config()$demo$base_url)
#' }
#'
#' @keywords internal
build_demo_url_d <- function(info, data_type, geo_level, base_url) {
  if (is.null(data_type)) {
    stop(
      "Parameter 'data_type' is required for dataset '",
      info$code,
      "' (Pattern D)"
    )
  }

  if (is.null(geo_level)) {
    stop(
      "Parameter 'geo_level' is required for dataset '",
      info$code,
      "' (Pattern D)"
    )
  }

  valid_data_types <- trimws(strsplit(info$data_types, ",")[[1]])
  if (!data_type %in% valid_data_types) {
    stop(
      "Data type '",
      data_type,
      "' is not valid for dataset '",
      info$code,
      "'. Valid values: ",
      paste(valid_data_types, collapse = ", ")
    )
  }

  valid_geo_levels <- trimws(strsplit(info$geo_levels, ",")[[1]])
  if (!geo_level %in% valid_geo_levels) {
    stop(
      "Geographic level '",
      geo_level,
      "' is not valid for dataset '",
      info$code,
      "'. Valid values: ",
      paste(valid_geo_levels, collapse = ", ")
    )
  }

  # {base_url}/previsioni/{DataType}-{GeoLevel}.zip
  paste0(base_url, "/previsioni/", data_type, "-", geo_level, ".zip")
}

# 6. Filename extraction -----

#' Get Demo Filename from URL Parameters
#'
#' Extracts the filename portion of the download URL for a given dataset.
#' This is useful for computing cache paths without constructing the full URL.
#'
#' @param code Character string identifying the dataset in the demo registry.
#' @param year Integer year for the data file (patterns A, B, C).
#' @param territory Character string specifying geographic territory (Pattern B).
#' @param level Character string specifying aggregation level (Pattern C).
#' @param type Character string specifying data type (Pattern C).
#' @param data_type Character string specifying forecast category (Pattern D).
#' @param geo_level Character string specifying geographic resolution (Pattern D).
#'
#' @return Character string containing the filename (e.g., \code{"D7B2024.csv.zip"}).
#'
#' @examples
#' \dontrun{
#' get_demo_filename("d7b", year = 2024)
#' # "D7B2024.csv.zip"
#'
#' get_demo_filename("posas", year = 2025, territory = "Comuni")
#' # "POSAS_2025_it_Comuni.zip"
#' }
#'
#' @keywords internal
get_demo_filename <- function(
  code,
  year = NULL,
  territory = NULL,
  level = NULL,
  type = NULL,
  data_type = NULL,
  geo_level = NULL
) {
  url <- build_demo_url(
    code = code,
    year = year,
    territory = territory,
    level = level,
    type = type,
    data_type = data_type,
    geo_level = geo_level
  )

  basename(url)
}
