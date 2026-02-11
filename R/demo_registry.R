#' Demo.istat.it Dataset Registry
#'
#' Functions for browsing and querying the catalog of demographic datasets
#' available from ISTAT's demo.istat.it portal. The registry covers population,
#' vital statistics, marriages, civil unions, mortality tables, and demographic
#' forecasts.
#'
#' @name demo_registry
NULL

# 1. Internal registry builder -----

#' Build the Demo.istat.it Dataset Registry
#'
#' Constructs a \code{data.table} containing metadata for all datasets
#' published on demo.istat.it. The registry is built in memory from
#' hard-coded entries that mirror the portal's file structure.
#'
#' @return A \code{data.table} with one row per dataset and the following
#'   columns:
#'   \describe{
#'     \item{code}{Short registry code (e.g., \code{"D7B"}, \code{"POS"})}
#'     \item{url_pattern}{Download URL pattern identifier: \code{"A"}, \code{"B"}, \code{"C"}, or \code{"D"}}
#'     \item{base_path}{URL path segment used in the download URL}
#'     \item{file_code}{Code used in filenames (may differ from \code{code})}
#'     \item{category}{Thematic category string}
#'     \item{description_it}{Italian-language description}
#'     \item{description_en}{English-language description}
#'     \item{year_start}{First available year (integer)}
#'     \item{year_end}{Last available year (integer or \code{NA} for ongoing series)}
#'     \item{territories}{Comma-separated territory levels (Pattern B only, \code{NA} otherwise)}
#'     \item{levels}{Comma-separated geographic levels (Pattern C only, \code{NA} otherwise)}
#'     \item{types}{Comma-separated data types (Pattern C only, \code{NA} otherwise)}
#'     \item{data_types}{Comma-separated data types (Pattern D only, \code{NA} otherwise)}
#'     \item{geo_levels}{Comma-separated geographic levels (Pattern D only, \code{NA} otherwise)}
#'   }
#' @keywords internal
get_demo_registry <- function() {
  # 1a. Pattern A datasets (year-indexed) -----
  pattern_a <- data.table::data.table(
    code = c(
      "D7B",
      "P02",
      "P03",
      "RBD",
      "R91",
      "AIR",
      "FE1",
      "FE3",
      "ISM",
      "RIC",
      "R92",
      "SSC",
      "MA1",
      "MA2",
      "MA3",
      "MA4",
      "NU1",
      "UC1",
      "UC2",
      "UC3",
      "UC4"
    ),
    url_pattern = "A",
    base_path = c(
      "d7b",
      "p02",
      "p03",
      "rbd",
      "r91",
      "air",
      "fe1",
      "fe3",
      "ism",
      "ric",
      "r92",
      "ssc",
      "ma1",
      "ma2",
      "ma3",
      "ma4",
      "nu1",
      "uc1",
      "uc2",
      "uc3",
      "uc4"
    ),
    file_code = c(
      "D7B",
      "P02",
      "P03",
      "RBD",
      "R91",
      "AIR",
      "FE1",
      "FE3",
      "ISM",
      "RIC",
      "R92",
      "SSC",
      "MA1",
      "MA2",
      "MA3",
      "MA4",
      "NU1",
      "UC1",
      "UC2",
      "UC3",
      "UC4"
    ),
    category = c(
      "dinamica",
      "dinamica",
      "dinamica",
      "dinamica",
      "dinamica",
      "dinamica",
      "natalita",
      "natalita",
      "mortalita",
      "popolazione",
      "popolazione",
      "popolazione",
      "matrimoni",
      "matrimoni",
      "matrimoni",
      "matrimoni",
      "matrimoni",
      "unioni_civili",
      "unioni_civili",
      "unioni_civili",
      "unioni_civili"
    ),
    description_it = c(
      "Bilancio demografico mensile",
      "Bilancio demografico annuale",
      "Bilancio demografico stranieri",
      "Bilancio demografico ricostruito 2002-2019",
      "Bilancio demografico 1991-2001",
      "Italiani residenti all'estero (AIRE)",
      "Indicatori di fecondita'",
      "Nati per comune",
      "Cancellati per decesso",
      "Popolazione residente ricostruita 2002-2019",
      "Popolazione residente 1992-2001",
      "Popolazione semi-supercentenaria (105+ anni)",
      "Matrimoni - indicatori di nuzialita'",
      "Matrimoni - caratteristiche degli sposi",
      "Matrimoni per cittadinanza degli sposi",
      "Matrimoni - serie storiche",
      "Tavole di primo-nuzialita'",
      "Unioni civili - principali indicatori",
      "Unioni civili - caratteristiche",
      "Unioni civili - cittadinanza",
      "Unioni civili - serie storiche"
    ),
    description_en = c(
      "Monthly demographic balance",
      "Annual demographic balance",
      "Foreign population demographic balance",
      "Reconstructed demographic balance 2002-2019",
      "Demographic balance 1991-2001",
      "Italians residing abroad (AIRE registry)",
      "Fertility indicators",
      "Births by municipality",
      "Deaths (cancelled due to death)",
      "Reconstructed resident population 2002-2019",
      "Resident population 1992-2001",
      "Semi-supercentenarian population (105+ years)",
      "Marriages - nuptiality indicators",
      "Marriages - characteristics of spouses",
      "Marriages by citizenship of spouses",
      "Marriages - historical time series",
      "First-nuptiality tables",
      "Civil unions - main indicators",
      "Civil unions - characteristics",
      "Civil unions - citizenship",
      "Civil unions - historical time series"
    ),
    year_start = c(
      2019L,
      2002L,
      2002L,
      2002L,
      1991L,
      2012L,
      2002L,
      2002L,
      2011L,
      2002L,
      1992L,
      2009L,
      2004L,
      2004L,
      2004L,
      2004L,
      2004L,
      2016L,
      2016L,
      2016L,
      2016L
    ),
    year_end = NA_integer_,
    territories = NA_character_,
    levels = NA_character_,
    types = NA_character_,
    data_types = NA_character_,
    geo_levels = NA_character_
  )

  # 1b. Pattern B datasets (territory-indexed) -----
  pattern_b <- data.table::data.table(
    code = c("POS", "STR", "RCS"),
    url_pattern = "B",
    base_path = c("posas", "stras", "rcist"),
    file_code = c("POSAS", "STRAS", "RCIST"),
    category = "popolazione",
    description_it = c(
      "Popolazione residente per eta' e sesso",
      "Popolazione straniera residente per eta' e sesso",
      "Popolazione residente per cittadinanza"
    ),
    description_en = c(
      "Resident population by age and sex",
      "Foreign resident population by age and sex",
      "Resident population by citizenship"
    ),
    year_start = c(2002L, 2003L, 2003L),
    year_end = NA_integer_,
    territories = "Comuni,Province,Regioni,Ripartizioni,Italia",
    levels = NA_character_,
    types = NA_character_,
    data_types = NA_character_,
    geo_levels = NA_character_
  )

  # 1c. Pattern C datasets (type+level) -----
  pattern_c <- data.table::data.table(
    code = c("TVM", "TVA"),
    url_pattern = "C",
    base_path = c("tvm", "tva"),
    file_code = NA_character_,
    category = "indicatori",
    description_it = c(
      "Tavole di mortalita'",
      "Tavole attuariali di mortalita'"
    ),
    description_en = c(
      "Life tables (mortality tables)",
      "Actuarial mortality tables"
    ),
    year_start = c(1974L, 1974L),
    year_end = NA_integer_,
    territories = NA_character_,
    levels = "comunali,provinciali,regionali",
    types = "completi,sintetici",
    data_types = NA_character_,
    geo_levels = NA_character_
  )

  # 1d. Pattern D datasets (category-level) -----
  pattern_d <- data.table::data.table(
    code = c("PPR", "PRF", "PPC", "PFL"),
    url_pattern = "D",
    base_path = "previsioni",
    file_code = NA_character_,
    category = "previsioni",
    description_it = c(
      "Previsioni della popolazione residente",
      "Previsioni delle famiglie",
      "Previsioni della popolazione comunale",
      "Previsioni delle forze di lavoro"
    ),
    description_en = c(
      "Resident population projections",
      "Household projections",
      "Municipal population projections",
      "Labour force projections"
    ),
    year_start = NA_integer_,
    year_end = NA_integer_,
    territories = NA_character_,
    levels = NA_character_,
    types = NA_character_,
    data_types = c(
      "Previsioni-Popolazione_per_eta,Previsioni-Indicatori_demografici",
      "Previsioni-Famiglie,Previsioni-Nuclei_familiari",
      "Previsioni-Popolazione_comunale",
      "Previsioni-Forze_lavoro"
    ),
    geo_levels = c(
      "Regioni,Italia",
      "Regioni,Italia",
      "Italia",
      "Italia"
    )
  )

  # 1e. Combine all patterns -----
  registry <- data.table::rbindlist(
    list(pattern_a, pattern_b, pattern_c, pattern_d),
    use.names = TRUE,
    fill = TRUE
  )

  registry
}

# 2. list_demo_datasets -----

#' List Demographic Datasets from Demo.istat.it
#'
#' Returns a summary table of all available demographic datasets from
#' demo.istat.it, optionally filtered by thematic category.
#'
#' @param category Optional character string specifying a thematic category
#'   to filter by (e.g., \code{"popolazione"}, \code{"dinamica"},
#'   \code{"matrimoni"}). If \code{NULL} (default), all datasets are returned.
#'   Use \code{\link{get_demo_categories}} to see valid categories.
#'
#' @return A \code{data.table} with columns: \code{code}, \code{category},
#'   \code{description_it}, \code{description_en}, \code{url_pattern}.
#' @export
#'
#' @examples
#' # List all demographic datasets
#' all_datasets <- list_demo_datasets()
#' print(all_datasets)
#'
#' # List only population datasets
#' pop_datasets <- list_demo_datasets(category = "popolazione")
#'
#' # List marriage-related datasets
#' marriage_datasets <- list_demo_datasets(category = "matrimoni")
list_demo_datasets <- function(category = NULL) {
  registry <- get_demo_registry()

  if (!is.null(category)) {
    if (!is.character(category) || length(category) != 1L) {
      stop("'category' must be a single character string.")
    }

    available_cats <- unique(registry$category)

    if (!category %in% available_cats) {
      stop(
        "Unknown category: '",
        category,
        "'. ",
        "Available categories: ",
        paste(sort(available_cats), collapse = ", ")
      )
    }

    target_cat <- category
    registry <- registry[registry[["category"]] == target_cat, ]
  }

  cols <- c(
    "code",
    "category",
    "description_it",
    "description_en",
    "url_pattern"
  )
  registry[, ..cols]
}

# 3. search_demo_datasets -----

#' Search Demographic Datasets by Keyword
#'
#' Searches the demo.istat.it dataset registry by matching a keyword against
#' one or more text fields. Useful for locating datasets when the exact code
#' or category is not known.
#'
#' @param keyword Character string containing the search term.
#' @param fields Character vector of column names to search in. Default is
#'   \code{c("description_it", "description_en", "code")}.
#' @param ignore_case Logical indicating whether the search should be
#'   case-insensitive. Default is \code{TRUE}.
#'
#' @return A \code{data.table} with matching rows, containing columns:
#'   \code{code}, \code{category}, \code{description_it},
#'   \code{description_en}, \code{url_pattern}.
#' @export
#'
#' @examples
#' # Search for population-related datasets
#' search_demo_datasets("popolazione")
#'
#' # Search in English descriptions only
#' search_demo_datasets("mortality", fields = "description_en")
#'
#' # Case-sensitive search
#' search_demo_datasets("AIRE", ignore_case = FALSE)
search_demo_datasets <- function(
  keyword,
  fields = c("description_it", "description_en", "code"),
  ignore_case = TRUE
) {
  if (!is.character(keyword) || length(keyword) != 1L || nchar(keyword) == 0L) {
    stop("'keyword' must be a non-empty single character string.")
  }

  if (!is.character(fields) || length(fields) == 0L) {
    stop("'fields' must be a non-empty character vector.")
  }

  registry <- get_demo_registry()

  invalid_fields <- setdiff(fields, names(registry))
  if (length(invalid_fields) > 0L) {
    stop(
      "Invalid field(s): ",
      paste(invalid_fields, collapse = ", "),
      ". Available fields: ",
      paste(names(registry), collapse = ", ")
    )
  }

  # Build a logical mask across all requested fields
  match_mask <- Reduce(
    `|`,
    lapply(fields, function(f) {
      grepl(keyword, registry[[f]], ignore.case = ignore_case)
    })
  )

  result <- registry[match_mask, ]

  cols <- c(
    "code",
    "category",
    "description_it",
    "description_en",
    "url_pattern"
  )
  result[, ..cols]
}

# 4. get_demo_dataset_info -----

#' Get Detailed Information for a Demographic Dataset
#'
#' Returns the full registry row for a single dataset identified by its
#' short code. All metadata columns are included (territories, levels,
#' types, etc.).
#'
#' @param code Character string with the dataset code (e.g., \code{"D7B"},
#'   \code{"POS"}, \code{"TVM"}, \code{"PPR"}).
#'
#' @return A single-row \code{data.table} with all registry columns for the
#'   requested dataset.
#' @export
#'
#' @examples
#' # Get info for the monthly demographic balance
#' info <- get_demo_dataset_info("D7B")
#' print(info)
#'
#' # Get info for resident population by age and sex
#' info <- get_demo_dataset_info("POS")
#' print(info$territories)
get_demo_dataset_info <- function(code) {
  if (!is.character(code) || length(code) != 1L || nchar(code) == 0L) {
    stop("'code' must be a non-empty single character string.")
  }

  registry <- get_demo_registry()
  target_code <- code
  row <- registry[registry[["code"]] == target_code, ]

  if (nrow(row) == 0L) {
    available_codes <- paste(sort(registry$code), collapse = ", ")
    stop(
      "Dataset code '",
      code,
      "' not found in the demo.istat.it registry. ",
      "Available codes: ",
      available_codes
    )
  }

  row
}

# 5. get_demo_categories -----

#' List Available Demographic Dataset Categories
#'
#' Returns a sorted character vector of the thematic categories present in
#' the demo.istat.it dataset registry. These categories can be passed to
#' \code{\link{list_demo_datasets}} for filtering.
#'
#' @return A character vector of unique category names, sorted alphabetically.
#' @export
#'
#' @examples
#' # See all available categories
#' cats <- get_demo_categories()
#' print(cats)
get_demo_categories <- function() {
  registry <- get_demo_registry()
  sort(unique(registry$category))
}
