# demo_url_builder.R - URL construction for demographic data from demo.istat.it
# Builds download URLs for the file-naming patterns used by ISTAT demographic
# datasets: year-indexed, year+locale, territory-indexed, level+type+year,
# datatype-geolevel, subtype+year, static file, and year-indexed CSV.

# 1. Main dispatcher -----

#' Build Demo URL for ISTAT Demographic Data
#'
#' Constructs the download URL for a given demographic dataset by looking up its
#' code in the demo registry and dispatching to the appropriate pattern builder.
#' The URL patterns correspond to different file-naming conventions used on
#' demo.istat.it:
#' \itemize{
#'   \item **Pattern A**: Year-indexed CSV ZIP (\code{{base_url}/{base_path}/{file_code}{year}.csv.zip})
#'   \item **Pattern A1**: Year+locale CSV ZIP (\code{{base_url}/{base_path}/{file_code}_{year}_it.csv.zip})
#'   \item **Pattern B**: Territory-indexed ZIP (\code{{base_url}/{base_path}/{file_code}_{year}_it_{territory}.zip})
#'   \item **Pattern C**: Level+type+year ZIP (\code{{base_url}/{base_path}/dati{level}{type}{year}.zip})
#'   \item **Pattern D**: Datatype-geolevel (\code{{base_url}/{base_path}/{data_type}-{geo_level}{ext}})
#'   \item **Pattern E**: Subtype+year ZIP (\code{{base_url}/{base_path}/{file_code}_{subtype}_{year}.zip})
#'   \item **Pattern F**: Static file (\code{{base_url}/{base_path}/{static_filename}})
#'   \item **Pattern G**: Year-indexed plain CSV (\code{{base_url}/{base_path}/{file_code}{year}.csv})
#' }
#'
#' @param code Character string identifying the dataset in the demo registry
#'   (e.g., \code{"D7B"}, \code{"POS"}, \code{"TVM"}, \code{"PPR"}).
#' @param year Integer year for the data file. Required for patterns A, A1, B,
#'   C, E, and G.
#' @param territory Character string specifying geographic territory (Pattern B only).
#'   Valid values are defined per dataset in the demo registry.
#' @param level Character string specifying geographic aggregation level (Pattern C
#'   only). Valid values are defined per dataset in the demo registry.
#' @param type Character string specifying data completeness type (Pattern C only).
#'   Valid values are defined per dataset in the demo registry.
#' @param data_type Character string specifying forecast data category (Pattern D
#'   only). Valid values are defined per dataset in the demo registry.
#' @param geo_level Character string specifying geographic resolution (Pattern D
#'   only). Valid values are defined per dataset in the demo registry. May be
#'   \code{NULL} for datasets without geographic levels.
#' @param subtype Character string specifying the data subtype (Pattern E only,
#'   e.g., \code{"nascita"}, \code{"cittadinanza"}). Valid values are defined
#'   per dataset in the demo registry.
#'
#' @return Character string containing the full download URL.
#'
#' @examples
#' \dontrun{
#' # Pattern A (year-indexed)
#' build_demo_url("D7B", year = 2024)
#'
#' # Pattern A1 (year+locale)
#' build_demo_url("AIR", year = 2023)
#'
#' # Pattern B (territory-indexed)
#' build_demo_url("POS", year = 2025, territory = "Comuni")
#'
#' # Pattern C (level+type+year)
#' build_demo_url("TVM", year = 2024, level = "regionali", type = "completi")
#'
#' # Pattern D (datatype-geolevel)
#' build_demo_url("PPR", data_type = "Previsioni-Popolazione_per_eta",
#'                geo_level = "Regioni")
#'
#' # Pattern D without geo_level
#' build_demo_url("PRF", data_type = "Famiglie_per_tipologia_familiare")
#'
#' # Pattern E (subtype-indexed)
#' build_demo_url("RCS", year = 2025, subtype = "cittadinanza")
#'
#' # Pattern F (static file)
#' build_demo_url("TVA")
#'
#' # Pattern G (year-indexed CSV)
#' build_demo_url("ISM", year = 2020)
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
  geo_level = NULL,
  subtype = NULL
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

  # Check if dataset is downloadable
  if (isFALSE(info$downloadable)) {
    stop(
      "Dataset '",
      code,
      "' is only available through the interactive portal at ",
      "https://demo.istat.it/app/?i=",
      code,
      "&l=it"
    )
  }

  config <- get_istat_config()
  base_url <- config$demo$base_url

  switch(
    EXPR = info$url_pattern,
    "A" = build_demo_url_a(info, year, base_url),
    "A1" = build_demo_url_a1(info, year, base_url),
    "B" = build_demo_url_b(info, year, territory, base_url),
    "C" = build_demo_url_c(info, year, level, type, base_url),
    "D" = build_demo_url_d(info, data_type, geo_level, base_url),
    "E" = build_demo_url_e(info, year, subtype, base_url),
    "F" = build_demo_url_f(info, base_url),
    "G" = build_demo_url_g(info, year, base_url),
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
#' info <- registry[registry$code == "D7B", ][1L, ]
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

  year_end <- if (is.na(info$year_end)) current_year else info$year_end
  if (year < info$year_start || year > year_end) {
    stop(
      "Year ",
      year,
      " is out of range for dataset '",
      info$code,
      "'. Valid range: ",
      info$year_start,
      "-",
      year_end
    )
  }

  # {base_url}/{base_path}/{FILE_CODE}{YEAR}.csv.zip
  paste0(base_url, "/", info$base_path, "/", info$file_code, year, ".csv.zip")
}

# 3. Pattern A1 - year+locale -----

#' Build Demo URL for Pattern A1 (Year + Locale)
#'
#' Constructs URLs of the form
#' \code{{base_url}/{base_path}/{FILE_CODE}_{YEAR}_it.csv.zip}, used by datasets
#' that publish one ZIP file per year with an \code{_it} locale suffix.
#'
#' @param info Single-row data.table from the demo registry.
#' @param year Integer year for the data file.
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # Returns: "https://demo.istat.it/data/aire/AIRE_2023_it.csv.zip"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "AIR", ][1L, ]
#' build_demo_url_a1(info, year = 2023,
#'                   base_url = get_istat_config()$demo$base_url)
#' }
#'
#' @keywords internal
build_demo_url_a1 <- function(info, year, base_url) {
  if (is.null(year)) {
    stop(
      "Parameter 'year' is required for dataset '",
      info$code,
      "' (Pattern A1)"
    )
  }

  year <- as.integer(year)
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  year_end <- if (is.na(info$year_end)) current_year else info$year_end
  if (year < info$year_start || year > year_end) {
    stop(
      "Year ",
      year,
      " is out of range for dataset '",
      info$code,
      "'. Valid range: ",
      info$year_start,
      "-",
      year_end
    )
  }

  # {base_url}/{base_path}/{FILE_CODE}_{YEAR}_it.csv.zip
  paste0(
    base_url,
    "/",
    info$base_path,
    "/",
    info$file_code,
    "_",
    year,
    "_it.csv.zip"
  )
}

# 4. Pattern B - territory-indexed -----

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
#' info <- registry[registry$code == "POS", ][1L, ]
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

# 5. Pattern C - level+type+year -----

#' Build Demo URL for Pattern C (Level, Type, and Year)
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
#' info <- registry[registry$code == "TVM", ][1L, ]
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

# 6. Pattern D - datatype-geolevel -----

#' Build Demo URL for Pattern D (Datatype-Geolevel)
#'
#' Constructs URLs of the form
#' \code{{base_url}/{base_path}/{DataType}-{GeoLevel}{ext}} or
#' \code{{base_url}/{base_path}/{DataType}{ext}} (when no geo_level applies),
#' used by forecast and reconstruction datasets that publish static files keyed
#' by data category and optional geographic resolution.
#'
#' @param info Single-row data.table from the demo registry.
#' @param data_type Character string specifying the forecast data category.
#' @param geo_level Character string specifying the geographic resolution.
#'   May be \code{NULL} for datasets that have no geographic segmentation.
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # With geo_level:
#' # Returns: "https://demo.istat.it/data/previsioni/Previsioni-Popolazione_per_eta-Regioni.zip"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "PPR", ][1L, ]
#' build_demo_url_d(info, data_type = "Previsioni-Popolazione_per_eta",
#'                  geo_level = "Regioni",
#'                  base_url = get_istat_config()$demo$base_url)
#'
#' # Without geo_level:
#' # Returns: "https://demo.istat.it/data/previsionifamiliari/Famiglie_per_tipologia_familiare.csv.zip"
#' info <- registry[registry$code == "PRF", ][1L, ]
#' build_demo_url_d(info, data_type = "Famiglie_per_tipologia_familiare",
#'                  geo_level = NULL,
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

  has_geo_levels <- !is.na(info$geo_levels)

  if (has_geo_levels) {
    # geo_level is required when the dataset defines geo_levels
    if (is.null(geo_level)) {
      stop(
        "Parameter 'geo_level' is required for dataset '",
        info$code,
        "' (Pattern D). Valid values: ",
        info$geo_levels
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

    # {base_url}/{base_path}/{DataType}-{GeoLevel}{ext}
    paste0(
      base_url,
      "/",
      info$base_path,
      "/",
      data_type,
      "-",
      geo_level,
      info$file_extension
    )
  } else {
    # No geo_level: {base_url}/{base_path}/{DataType}{ext}
    paste0(
      base_url,
      "/",
      info$base_path,
      "/",
      data_type,
      info$file_extension
    )
  }
}

# 7. Pattern E - subtype+year -----

#' Build Demo URL for Pattern E (Subtype-Indexed)
#'
#' Constructs URLs of the form
#' \code{{base_url}/{base_path}/{file_code}_{subtype}_{year}.zip}, used by
#' datasets that publish separate ZIP files per data subtype and year.
#'
#' @param info Single-row data.table from the demo registry.
#' @param year Integer year for the data file.
#' @param subtype Character string specifying the data subtype (e.g.,
#'   \code{"nascita"}, \code{"cittadinanza"}).
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # Returns: "https://demo.istat.it/data/rcs/Dati_RCS_cittadinanza_2025.zip"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "RCS", ][1L, ]
#' build_demo_url_e(info, year = 2025, subtype = "cittadinanza",
#'                  base_url = get_istat_config()$demo$base_url)
#' }
#'
#' @keywords internal
build_demo_url_e <- function(info, year, subtype, base_url) {
  if (is.null(year)) {
    stop(
      "Parameter 'year' is required for dataset '",
      info$code,
      "' (Pattern E)"
    )
  }

  if (is.null(subtype)) {
    stop(
      "Parameter 'subtype' is required for dataset '",
      info$code,
      "' (Pattern E). ",
      "Valid subtypes: ",
      info$subtypes
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

  valid_subtypes <- trimws(strsplit(info$subtypes, ",")[[1]])
  if (!subtype %in% valid_subtypes) {
    stop(
      "Subtype '",
      subtype,
      "' is not valid for dataset '",
      info$code,
      "'. Valid values: ",
      paste(valid_subtypes, collapse = ", ")
    )
  }

  # {base_url}/{base_path}/{file_code}_{subtype}_{year}.zip
  paste0(
    base_url,
    "/",
    info$base_path,
    "/",
    info$file_code,
    "_",
    subtype,
    "_",
    year,
    ".zip"
  )
}

# 8. Pattern F - static file -----

#' Build Demo URL for Pattern F (Static File)
#'
#' Constructs URLs of the form
#' \code{{base_url}/{base_path}/{static_filename}}, used by datasets that
#' provide a single downloadable file with no year or parameter variation.
#'
#' @param info Single-row data.table from the demo registry.
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # Returns: "https://demo.istat.it/data/tva/tavole%20attuariali.zip"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "TVA", ][1L, ]
#' build_demo_url_f(info, base_url = get_istat_config()$demo$base_url)
#' }
#'
#' @keywords internal
build_demo_url_f <- function(info, base_url) {
  # {base_url}/{base_path}/{static_filename}
  paste0(
    base_url,
    "/",
    info$base_path,
    "/",
    utils::URLencode(info$static_filename)
  )
}

# 9. Pattern G - year-indexed CSV (no ZIP) -----

#' Build Demo URL for Pattern G (Year-Indexed CSV)
#'
#' Constructs URLs of the form
#' \code{{base_url}/{base_path}/{file_code}{year}.csv}, used by datasets that
#' publish plain CSV files (not zipped) with the year appended to the file code.
#'
#' @param info Single-row data.table from the demo registry.
#' @param year Integer year for the data file.
#' @param base_url Character string with the demo.istat.it base URL.
#'
#' @return Character string containing the constructed URL.
#'
#' @examples
#' \dontrun{
#' # Returns: "https://demo.istat.it/data/ism/Decessi-Tassi-Anno_2020.csv"
#' registry <- get_demo_registry()
#' info <- registry[registry$code == "ISM", ][1L, ]
#' build_demo_url_g(info, year = 2020,
#'                  base_url = get_istat_config()$demo$base_url)
#' }
#'
#' @keywords internal
build_demo_url_g <- function(info, year, base_url) {
  if (is.null(year)) {
    stop(
      "Parameter 'year' is required for dataset '",
      info$code,
      "' (Pattern G)"
    )
  }

  year <- as.integer(year)
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  year_end <- if (is.na(info$year_end)) current_year else info$year_end
  if (year < info$year_start || year > year_end) {
    stop(
      "Year ",
      year,
      " is out of range for dataset '",
      info$code,
      "'. Valid range: ",
      info$year_start,
      "-",
      year_end
    )
  }

  # {base_url}/{base_path}/{file_code}{year}.csv
  paste0(base_url, "/", info$base_path, "/", info$file_code, year, ".csv")
}

# 10. Filename extraction -----

#' Get Demo Filename from URL Parameters
#'
#' Extracts the filename portion of the download URL for a given dataset.
#' This is useful for computing cache paths without constructing the full URL.
#'
#' @param code Character string identifying the dataset in the demo registry.
#' @param year Integer year for the data file (patterns A, A1, B, C, E, G).
#' @param territory Character string specifying geographic territory (Pattern B).
#' @param level Character string specifying aggregation level (Pattern C).
#' @param type Character string specifying data type (Pattern C).
#' @param data_type Character string specifying forecast category (Pattern D).
#' @param geo_level Character string specifying geographic resolution (Pattern D).
#' @param subtype Character string specifying data subtype (Pattern E).
#'
#' @return Character string containing the filename (e.g., \code{"D7B2024.csv.zip"}).
#'
#' @examples
#' \dontrun{
#' get_demo_filename("D7B", year = 2024)
#' # "D7B2024.csv.zip"
#'
#' get_demo_filename("POS", year = 2025, territory = "Comuni")
#' # "POSAS_2025_it_Comuni.zip"
#'
#' get_demo_filename("RCS", year = 2025, subtype = "cittadinanza")
#' # "Dati_RCS_cittadinanza_2025.zip"
#'
#' get_demo_filename("TVA")
#' # "tavole%20attuariali.zip"
#'
#' get_demo_filename("ISM", year = 2020)
#' # "Decessi-Tassi-Anno_2020.csv"
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
  geo_level = NULL,
  subtype = NULL
) {
  url <- build_demo_url(
    code = code,
    year = year,
    territory = territory,
    level = level,
    type = type,
    data_type = data_type,
    geo_level = geo_level,
    subtype = subtype
  )

  basename(url)
}
