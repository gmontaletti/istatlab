# Tests for demo.istat.it download module
# Covers: demo_registry.R, demo_url_builder.R, demo_transport.R,
#         demo_cache.R, demo_download.R

# 1. Registry completeness -----

test_that("get_demo_registry returns a data.table", {
  reg <- get_demo_registry()
  expect_s3_class(reg, "data.table")
})

test_that("registry contains exactly 30 datasets", {
  reg <- get_demo_registry()
  expect_equal(nrow(reg), 30L)
})

test_that("registry has no duplicate codes", {
  reg <- get_demo_registry()
  expect_equal(anyDuplicated(reg$code), 0L)
})

test_that("registry has all required columns including new ones", {
  reg <- get_demo_registry()
  required_cols <- c(
    "code",
    "url_pattern",
    "base_path",
    "file_code",
    "category",
    "description_it",
    "description_en",
    "year_start",
    "year_end",
    "territories",
    "levels",
    "types",
    "data_types",
    "geo_levels",
    "subtypes",
    "downloadable",
    "file_extension",
    "static_filename"
  )
  for (col in required_cols) {
    expect_true(col %in% names(reg), info = paste("Missing column:", col))
  }
})

test_that("pattern distribution is correct: A=2, A1=1, B=4, C=1, D=4, E=1, F=1, G=1, NA=15", {
  reg <- get_demo_registry()
  pattern_counts <- table(reg$url_pattern, useNA = "ifany")

  expect_equal(as.integer(pattern_counts[["A"]]), 2L)
  expect_equal(as.integer(pattern_counts[["A1"]]), 1L)
  expect_equal(as.integer(pattern_counts[["B"]]), 4L)
  expect_equal(as.integer(pattern_counts[["C"]]), 1L)
  expect_equal(as.integer(pattern_counts[["D"]]), 4L)
  expect_equal(as.integer(pattern_counts[["E"]]), 1L)
  expect_equal(as.integer(pattern_counts[["F"]]), 1L)
  expect_equal(as.integer(pattern_counts[["G"]]), 1L)

  # Interactive-only datasets have NA pattern
  na_count <- sum(is.na(reg$url_pattern))
  expect_equal(na_count, 15L)
})

test_that("all downloadable datasets have a url_pattern", {
  reg <- get_demo_registry()
  downloadable <- reg[reg$downloadable == TRUE, ]
  expect_true(all(!is.na(downloadable$url_pattern)))
})

test_that("all interactive-only datasets have url_pattern NA and downloadable FALSE", {
  reg <- get_demo_registry()
  interactive <- reg[is.na(reg$url_pattern), ]
  expect_true(all(interactive$downloadable == FALSE))
})

test_that("every category is non-empty", {
  reg <- get_demo_registry()
  expect_false(any(is.na(reg$category)))
  expect_false(any(nchar(reg$category) == 0L))
})

# 2. Registry discovery functions -----

test_that("list_demo_datasets returns all 30 when no filter", {
  result <- list_demo_datasets()
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 30L)
})

test_that("list_demo_datasets returns downloadable column", {
  result <- list_demo_datasets()
  expect_true("downloadable" %in% names(result))
})

test_that("list_demo_datasets with category 'popolazione' returns correct count", {
  result <- list_demo_datasets("popolazione")
  expect_true(nrow(result) > 0L)
  expect_true(all(result$category == "popolazione"))
})

test_that("list_demo_datasets errors on invalid category", {
  expect_error(list_demo_datasets("invalid"), "Unknown category")
})

test_that("search_demo_datasets finds results for 'popolazione'", {
  result <- search_demo_datasets("popolazione")
  expect_s3_class(result, "data.table")
  expect_gt(nrow(result), 0L)
})

test_that("search_demo_datasets returns downloadable column", {
  result <- search_demo_datasets("popolazione")
  expect_true("downloadable" %in% names(result))
})

test_that("search_demo_datasets finds mortality tables in English descriptions", {
  result <- search_demo_datasets("mortality", fields = "description_en")
  expect_gt(nrow(result), 0L)
  found_codes <- result$code
  expect_true(any(c("TVM", "TVA") %in% found_codes))
})

test_that("search_demo_datasets errors on empty keyword", {
  expect_error(search_demo_datasets(""), "non-empty")
})

test_that("search_demo_datasets returns correct columns", {
  result <- search_demo_datasets("bilancio")
  expected_cols <- c(
    "code",
    "category",
    "description_it",
    "description_en",
    "url_pattern",
    "downloadable"
  )
  expect_identical(names(result), expected_cols)
})

test_that("search_demo_datasets with invalid fields errors", {
  expect_error(
    search_demo_datasets("test", fields = "nonexistent"),
    "Invalid field"
  )
})

test_that("search_demo_datasets case-sensitive search works", {
  result_ci <- search_demo_datasets("aire", ignore_case = TRUE)
  result_cs <- search_demo_datasets("AIRE", ignore_case = FALSE)
  expect_gt(nrow(result_cs), 0L)
  expect_true("AIR" %in% result_cs$code)
})

test_that("get_demo_dataset_info returns 1 row for D7B with correct code", {
  info <- get_demo_dataset_info("D7B")
  expect_s3_class(info, "data.table")
  expect_equal(nrow(info), 1L)
  expect_equal(info$code, "D7B")
})

test_that("get_demo_dataset_info errors on invalid code", {
  expect_error(get_demo_dataset_info("INVALID"), "not found")
})

test_that("get_demo_dataset_info errors on empty string", {
  expect_error(get_demo_dataset_info(""), "non-empty")
})

test_that("get_demo_categories returns sorted character with expected count", {
  cats <- get_demo_categories()
  expect_type(cats, "character")
  expect_gt(length(cats), 0L)
  expect_identical(cats, sort(cats))
})

test_that("list_demo_datasets returns correct columns", {
  result <- list_demo_datasets()
  expected_cols <- c(
    "code",
    "category",
    "description_it",
    "description_en",
    "url_pattern",
    "downloadable"
  )
  expect_identical(names(result), expected_cols)
})

# 3. Pattern A URL builder -----

test_that("build_demo_url for D7B year 2024 returns correct URL", {
  url <- build_demo_url("D7B", year = 2024)
  expect_equal(url, "https://demo.istat.it/data/d7b/D7B2024.csv.zip")
})

test_that("build_demo_url for RBD returns correct URL", {
  url <- build_demo_url("RBD", year = 2018)
  expect_equal(
    url,
    "https://demo.istat.it/data/ricostruzione/RBD-Dataset-2018.csv.zip"
  )
})

test_that("build_demo_url for RBD enforces year_end", {
  expect_error(build_demo_url("RBD", year = 2019), "out of range")
})

test_that("build_demo_url for D7B without year errors", {
  expect_error(build_demo_url("D7B"), "year.*required", ignore.case = TRUE)
})

test_that("build_demo_url for D7B with out-of-range year errors", {
  expect_error(build_demo_url("D7B", year = 1900), "out of range")
})

test_that("build_demo_url with unknown code errors", {
  expect_error(build_demo_url("INVALID", year = 2024), "not found")
})

test_that("build_demo_url errors on NULL code", {
  expect_error(build_demo_url(NULL, year = 2024), "code")
})

# 4. Pattern A1 URL builder -----

test_that("build_demo_url for AIR year 2024 returns correct URL", {
  url <- build_demo_url("AIR", year = 2024)
  expect_equal(
    url,
    "https://demo.istat.it/data/aire/AIRE_2024_it.csv.zip"
  )
})

test_that("build_demo_url for AIR without year errors", {
  expect_error(build_demo_url("AIR"), "year.*required", ignore.case = TRUE)
})

test_that("build_demo_url for AIR with out-of-range year errors", {
  expect_error(build_demo_url("AIR", year = 2000), "out of range")
})

# 5. Pattern B URL builder -----

test_that("build_demo_url for POS with Comuni returns correct URL", {
  url <- build_demo_url("POS", year = 2025, territory = "Comuni")
  expect_equal(
    url,
    "https://demo.istat.it/data/posas/POSAS_2025_it_Comuni.zip"
  )
})

test_that("build_demo_url for STR with Comuni returns correct URL", {
  url <- build_demo_url("STR", year = 2025, territory = "Comuni")
  expect_equal(
    url,
    "https://demo.istat.it/data/strasa/STRASA_2025_it_Comuni.zip"
  )
})

test_that("build_demo_url for P02 with Regioni returns correct URL", {
  url <- build_demo_url("P02", year = 2024, territory = "Regioni")
  expect_equal(
    url,
    "https://demo.istat.it/data/p2/P2_2024_it_Regioni.zip"
  )
})

test_that("build_demo_url for P03 with Province returns correct URL", {
  url <- build_demo_url("P03", year = 2024, territory = "Province")
  expect_equal(
    url,
    "https://demo.istat.it/data/p3/P3_2024_it_Province.zip"
  )
})

test_that("build_demo_url for POS without territory errors", {
  expect_error(
    build_demo_url("POS", year = 2025),
    "territory.*required",
    ignore.case = TRUE
  )
})

test_that("build_demo_url for POS with invalid territory errors", {
  expect_error(
    build_demo_url("POS", year = 2025, territory = "Invalid"),
    "not valid"
  )
})

# 6. Pattern C URL builder -----

test_that("build_demo_url for TVM regionali completi returns correct URL", {
  url <- build_demo_url(
    "TVM",
    year = 2024,
    level = "regionali",
    type = "completi"
  )
  expect_equal(
    url,
    "https://demo.istat.it/data/tvm/datiregionalicompleti2024.zip"
  )
})

test_that("build_demo_url for TVM provinciali ridotti returns correct URL", {
  url <- build_demo_url(
    "TVM",
    year = 2024,
    level = "provinciali",
    type = "ridotti"
  )
  expect_equal(
    url,
    "https://demo.istat.it/data/tvm/datiprovincialiridotti2024.zip"
  )
})

test_that("build_demo_url for TVM ripartizione completi returns correct URL", {
  url <- build_demo_url(
    "TVM",
    year = 2024,
    level = "ripartizione",
    type = "completi"
  )
  expect_equal(
    url,
    "https://demo.istat.it/data/tvm/datiripartizionecompleti2024.zip"
  )
})

test_that("build_demo_url for TVM with old sintetici type errors", {
  expect_error(
    build_demo_url("TVM", year = 2024, level = "regionali", type = "sintetici"),
    "not valid"
  )
})

test_that("build_demo_url for TVM with old comunali level errors", {
  expect_error(
    build_demo_url("TVM", year = 2024, level = "comunali", type = "completi"),
    "not valid"
  )
})

test_that("build_demo_url for TVM without level errors", {
  expect_error(
    build_demo_url("TVM", year = 2024),
    "level.*required",
    ignore.case = TRUE
  )
})

test_that("build_demo_url for TVM with invalid level errors", {
  expect_error(
    build_demo_url("TVM", year = 2024, level = "invalid", type = "completi"),
    "not valid"
  )
})

# 7. Pattern D URL builder -----

test_that("build_demo_url for PPR with Regioni returns correct URL", {
  url <- build_demo_url(
    "PPR",
    data_type = "Previsioni-Popolazione_per_eta",
    geo_level = "Regioni"
  )
  expect_equal(
    url,
    "https://demo.istat.it/data/previsioni/Previsioni-Popolazione_per_eta-Regioni.zip"
  )
})

test_that("build_demo_url for PPR with Ripartizioni returns correct URL", {
  url <- build_demo_url(
    "PPR",
    data_type = "Indicatori",
    geo_level = "Ripartizioni"
  )
  expect_equal(
    url,
    "https://demo.istat.it/data/previsioni/Indicatori-Ripartizioni.zip"
  )
})

test_that("build_demo_url for PPC with Province returns correct URL", {
  url <- build_demo_url(
    "PPC",
    data_type = "Previsioni_comunali_popolazione_per_eta",
    geo_level = "Province"
  )
  expect_equal(
    url,
    "https://demo.istat.it/data/previsionicomunali/Previsioni_comunali_popolazione_per_eta-Province.csv.zip"
  )
})

test_that("build_demo_url for RIC with Regioni returns correct URL", {
  url <- build_demo_url(
    "RIC",
    data_type = "PopolazioneEta-Territorio",
    geo_level = "Regioni"
  )
  expect_equal(
    url,
    "https://demo.istat.it/data/ricostruzione/PopolazioneEta-Territorio-Regioni.zip"
  )
})

test_that("build_demo_url for PRF without geo_level returns correct URL", {
  url <- build_demo_url(
    "PRF",
    data_type = "Famiglie_per_tipologia_familiare"
  )
  expect_equal(
    url,
    "https://demo.istat.it/data/previsionifamiliari/Famiglie_per_tipologia_familiare.csv.zip"
  )
})

test_that("build_demo_url for PPR without data_type errors", {
  expect_error(
    build_demo_url("PPR"),
    "data_type.*required",
    ignore.case = TRUE
  )
})

test_that("build_demo_url for PPR with invalid data_type errors", {
  expect_error(
    build_demo_url("PPR", data_type = "invalid", geo_level = "Regioni"),
    "not valid"
  )
})

test_that("build_demo_url for PPR with invalid geo_level errors", {
  expect_error(
    build_demo_url(
      "PPR",
      data_type = "Previsioni-Popolazione_per_eta",
      geo_level = "Comuni"
    ),
    "not valid"
  )
})

# 8. Pattern E URL builder -----

test_that("build_demo_url for RCS cittadinanza returns correct URL", {
  url <- build_demo_url("RCS", year = 2025, subtype = "cittadinanza")
  expect_equal(
    url,
    "https://demo.istat.it/data/rcs/Dati_RCS_cittadinanza_2025.zip"
  )
})

test_that("build_demo_url for RCS nascita returns correct URL", {
  url <- build_demo_url("RCS", year = 2025, subtype = "nascita")
  expect_equal(
    url,
    "https://demo.istat.it/data/rcs/Dati_RCS_nascita_2025.zip"
  )
})

test_that("build_demo_url for RCS without subtype errors", {
  expect_error(
    build_demo_url("RCS", year = 2025),
    "subtype.*required",
    ignore.case = TRUE
  )
})

test_that("build_demo_url for RCS without year errors", {
  expect_error(
    build_demo_url("RCS", subtype = "cittadinanza"),
    "year.*required",
    ignore.case = TRUE
  )
})

test_that("build_demo_url for RCS with invalid subtype errors", {
  expect_error(
    build_demo_url("RCS", year = 2025, subtype = "invalid"),
    "not valid"
  )
})

test_that("build_demo_url for RCS with out-of-range year errors", {
  expect_error(
    build_demo_url("RCS", year = 1990, subtype = "cittadinanza"),
    "out of range"
  )
})

# 9. Pattern F URL builder -----

test_that("build_demo_url for TVA returns correct URL", {
  url <- build_demo_url("TVA")
  expect_equal(
    url,
    "https://demo.istat.it/data/tva/tavole%20attuariali.zip"
  )
})

test_that("build_demo_url for TVA requires no parameters", {
  # Should succeed without year or any other parameter
  expect_no_error(build_demo_url("TVA"))
})

# 10. Pattern G URL builder -----

test_that("build_demo_url for ISM year 2024 returns correct URL", {
  url <- build_demo_url("ISM", year = 2024)
  expect_equal(
    url,
    "https://demo.istat.it/data/ism/Decessi-Tassi-Anno_2024.csv"
  )
})

test_that("build_demo_url for ISM without year errors", {
  expect_error(
    build_demo_url("ISM"),
    "year.*required",
    ignore.case = TRUE
  )
})

test_that("build_demo_url for ISM with out-of-range year errors", {
  expect_error(build_demo_url("ISM", year = 2000), "out of range")
})

# 11. Interactive-only tests -----

test_that("build_demo_url for interactive-only code errors", {
  expect_error(
    build_demo_url("MA1"),
    "interactive portal"
  )
})

test_that("download_demo_data for interactive-only code errors with portal link", {
  expect_error(
    download_demo_data("MA1"),
    "interactive portal"
  )
  expect_error(
    download_demo_data("MA1"),
    "list_demo_datasets"
  )
})

test_that("download_demo_data_multi for interactive-only code errors", {
  expect_error(
    download_demo_data_multi("MA1", years = 2020:2024),
    "interactive portal"
  )
})

# 12. Filename extraction -----

test_that("get_demo_filename for Pattern A returns correct filename", {
  filename <- get_demo_filename("D7B", year = 2024)
  expect_equal(filename, "D7B2024.csv.zip")
})

test_that("get_demo_filename for Pattern B returns correct filename", {
  filename <- get_demo_filename("POS", year = 2025, territory = "Comuni")
  expect_equal(filename, "POSAS_2025_it_Comuni.zip")
})

test_that("get_demo_filename for Pattern E returns correct filename", {
  filename <- get_demo_filename("RCS", year = 2025, subtype = "cittadinanza")
  expect_equal(filename, "Dati_RCS_cittadinanza_2025.zip")
})

test_that("get_demo_filename for Pattern F returns URL-encoded filename", {
  filename <- get_demo_filename("TVA")
  expect_equal(filename, "tavole%20attuariali.zip")
})

test_that("get_demo_filename for Pattern G returns CSV filename", {
  filename <- get_demo_filename("ISM", year = 2024)
  expect_equal(filename, "Decessi-Tassi-Anno_2024.csv")
})

test_that("get_demo_filename for TVM returns correct filename", {
  filename <- get_demo_filename(
    "TVM",
    year = 2024,
    level = "regionali",
    type = "completi"
  )
  expect_equal(filename, "datiregionalicompleti2024.zip")
})

test_that("get_demo_filename for PPR returns correct filename", {
  filename <- get_demo_filename(
    "PPR",
    data_type = "Previsioni-Popolazione_per_eta",
    geo_level = "Regioni"
  )
  expect_equal(filename, "Previsioni-Popolazione_per_eta-Regioni.zip")
})

# 13. Cache path computation -----

test_that("get_demo_cache_path returns default path layout", {
  path <- get_demo_cache_path("D7B", "D7B2024.csv.zip")
  expect_equal(path, file.path("demo_data", "d7b", "D7B2024.csv.zip"))
})

test_that("get_demo_cache_path respects custom cache_dir", {
  path <- get_demo_cache_path("D7B", "D7B2024.csv.zip", cache_dir = "my_cache")
  expect_equal(path, file.path("my_cache", "d7b", "D7B2024.csv.zip"))
})

test_that("get_demo_cache_path errors on NULL code", {
  expect_error(
    get_demo_cache_path(NULL, "file.zip"),
    "code.*must be a single character string",
    ignore.case = TRUE
  )
})

test_that("get_demo_cache_path errors on NULL filename", {
  expect_error(
    get_demo_cache_path("D7B", NULL),
    "filename.*must be a single character string",
    ignore.case = TRUE
  )
})

# 14. Cache status on empty/nonexistent dir -----

test_that("demo_cache_status on nonexistent dir returns empty data.table", {
  result <- demo_cache_status(
    cache_dir = file.path(tempdir(), "nonexistent_cache_dir")
  )
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
  expected_cols <- c("code", "file", "size_mb", "modified", "age_days")
  expect_identical(names(result), expected_cols)
})

test_that("demo_cache_status on tempdir returns a data.table", {
  result <- demo_cache_status(cache_dir = tempdir())
  expect_s3_class(result, "data.table")
})

test_that("demo_cache_status empty result has correct column types", {
  result <- demo_cache_status(cache_dir = file.path(tempdir(), "empty_demo"))
  expect_type(result$code, "character")
  expect_type(result$file, "character")
  expect_type(result$size_mb, "double")
  expect_type(result$age_days, "double")
})

# 15. Download function parameter validation -----

test_that("download_demo_data errors on NULL code", {
  expect_error(download_demo_data(NULL), "code")
})

test_that("download_demo_data errors on empty string code", {
  expect_error(download_demo_data(""), "code")
})

test_that("download_demo_data_multi errors on NULL years", {
  expect_error(download_demo_data_multi("D7B", years = NULL), "years")
})

test_that("download_demo_data_multi errors on empty years vector", {
  expect_error(download_demo_data_multi("D7B", years = integer(0)), "years")
})

test_that("download_demo_data_batch errors on empty codes vector", {
  expect_error(download_demo_data_batch(character(0)), "codes")
})

test_that("download_demo_data_batch errors on codes with NA", {
  expect_error(download_demo_data_batch(c("D7B", NA)), "NA")
})

# 16. Transport tests (skip if offline) -----

test_that("http_head_demo returns a list with success field", {
  skip_if_offline(host = "demo.istat.it")

  result <- http_head_demo("https://demo.istat.it")
  expect_type(result, "list")
  expect_true("success" %in% names(result))
})

test_that("http_head_demo to demo.istat.it returns appropriate status", {
  skip_if_offline(host = "demo.istat.it")

  result <- http_head_demo("https://demo.istat.it/data/d7b/D7B2024.csv.zip")
  expect_type(result, "list")
  expect_true("status_code" %in% names(result))
  # Server should respond (either 200 or redirect; not a connection failure)
  expect_false(is.na(result$status_code))
})

# 17. Demo rate limiter -----

test_that("demo_throttle first call does not sleep when no previous timestamp", {
  reset_demo_rate_limiter()
  on.exit(reset_demo_rate_limiter())

  test_config <- list(delay = 1, jitter_fraction = 0)

  start <- Sys.time()
  demo_throttle(config_override = test_config)
  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs"))

  expect_lt(elapsed, 0.5)
})

test_that("reset_demo_rate_limiter clears last_request_time", {
  reset_demo_rate_limiter()
  expect_null(.demo_rate_limiter$last_request_time)
})

test_that("demo_throttle updates last_request_time", {
  reset_demo_rate_limiter()
  on.exit(reset_demo_rate_limiter())

  test_config <- list(delay = 0, jitter_fraction = 0)
  demo_throttle(config_override = test_config)
  expect_s3_class(.demo_rate_limiter$last_request_time, "POSIXct")
})

# 18. Cache cleanup in isolated directory -----

test_that("clean_demo_cache returns 0 for nonexistent directory", {
  result <- clean_demo_cache(
    cache_dir = file.path(tempdir(), "no_such_demo_cache")
  )
  expect_equal(result, 0L)
})

test_that("clean_demo_cache removes files and returns correct count", {
  withr::with_tempdir({
    cache_root <- file.path(getwd(), "test_cache")
    sub_dir <- file.path(cache_root, "d7b")
    dir.create(sub_dir, recursive = TRUE)

    # Create dummy cached files
    writeLines("data1", file.path(sub_dir, "D7B2023.csv.zip"))
    writeLines("data2", file.path(sub_dir, "D7B2024.csv.zip"))

    removed <- clean_demo_cache(code = "D7B", cache_dir = cache_root)
    expect_equal(removed, 2L)

    # Subdirectory should be cleaned up
    expect_false(dir.exists(sub_dir))
  })
})

test_that("clean_demo_cache validates code parameter", {
  withr::with_tempdir({
    cache_root <- file.path(getwd(), "test_cache_code_val")
    dir.create(cache_root, recursive = TRUE)
    expect_error(
      clean_demo_cache(code = 123, cache_dir = cache_root),
      "code.*must be a single character string",
      ignore.case = TRUE
    )
  })
})

test_that("clean_demo_cache validates max_age_days parameter", {
  withr::with_tempdir({
    cache_root <- file.path(getwd(), "test_cache2")
    dir.create(cache_root, recursive = TRUE)
    # Need files present so the function reaches the max_age_days check
    writeLines("dummy", file.path(cache_root, "dummy.zip"))
    expect_error(
      clean_demo_cache(cache_dir = cache_root, max_age_days = -1),
      "non-negative"
    )
  })
})
