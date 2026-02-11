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

test_that("registry has all required columns", {
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
    "geo_levels"
  )
  for (col in required_cols) {
    expect_true(col %in% names(reg), info = paste("Missing column:", col))
  }
})

test_that("pattern distribution is correct: A=21, B=3, C=2, D=4", {
  reg <- get_demo_registry()
  pattern_counts <- table(reg$url_pattern)
  expect_equal(as.integer(pattern_counts[["A"]]), 21L)
  expect_equal(as.integer(pattern_counts[["B"]]), 3L)
  expect_equal(as.integer(pattern_counts[["C"]]), 2L)
  expect_equal(as.integer(pattern_counts[["D"]]), 4L)
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

test_that("list_demo_datasets with category 'popolazione' returns 6 datasets", {
  result <- list_demo_datasets("popolazione")
  expect_equal(nrow(result), 6L)
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

test_that("search_demo_datasets finds mortality tables in English descriptions", {
  result <- search_demo_datasets("mortality", fields = "description_en")
  expect_gt(nrow(result), 0L)
  # TVM and/or TVA should appear
  found_codes <- result$code
  expect_true(any(c("TVM", "TVA") %in% found_codes))
})

test_that("search_demo_datasets errors on empty keyword", {
  expect_error(search_demo_datasets(""), "non-empty")
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

test_that("get_demo_categories returns sorted character with 8 categories", {
  cats <- get_demo_categories()
  expect_type(cats, "character")
  expect_equal(length(cats), 8L)
  expect_identical(cats, sort(cats))
})

# 3. URL builder - Pattern A -----

test_that("build_demo_url for D7B year 2024 returns correct URL", {
  url <- build_demo_url("D7B", year = 2024)
  expect_equal(url, "https://demo.istat.it/data/d7b/D7B2024.csv.zip")
})

test_that("build_demo_url for P02 year 2020 returns correct URL", {
  url <- build_demo_url("P02", year = 2020)
  expect_equal(url, "https://demo.istat.it/data/p02/P022020.csv.zip")
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

# 4. URL builder - Pattern B -----

test_that("build_demo_url for POS with territory Comuni returns correct URL", {
  url <- build_demo_url("POS", year = 2025, territory = "Comuni")
  expect_equal(url, "https://demo.istat.it/data/posas/POSAS_2025_it_Comuni.zip")
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

# 5. URL builder - Pattern C -----

test_that("build_demo_url for TVM with level and type returns correct URL", {
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

# 6. URL builder - Pattern D -----

test_that("build_demo_url for PPR with data_type and geo_level returns correct URL", {
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

# 7. Filename extraction -----

test_that("get_demo_filename for D7B returns correct filename", {
  filename <- get_demo_filename("D7B", year = 2024)
  expect_equal(filename, "D7B2024.csv.zip")
})

test_that("get_demo_filename for POS with territory returns correct filename", {
  filename <- get_demo_filename("POS", year = 2025, territory = "Comuni")
  expect_equal(filename, "POSAS_2025_it_Comuni.zip")
})

# 8. Cache path computation -----

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

# 9. Cache status on empty/nonexistent dir -----

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

# 10. Parameter validation -----

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

# 11. Transport tests (skip if offline) -----

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

# 12. Demo rate limiter -----

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

# 13. Cache cleanup in isolated directory -----

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

# 14. Additional edge cases -----

test_that("search_demo_datasets returns correct columns", {
  result <- search_demo_datasets("bilancio")
  expected_cols <- c(
    "code",
    "category",
    "description_it",
    "description_en",
    "url_pattern"
  )
  expect_identical(names(result), expected_cols)
})

test_that("search_demo_datasets with invalid fields errors", {
  expect_error(
    search_demo_datasets("test", fields = "nonexistent"),
    "Invalid field"
  )
})

test_that("list_demo_datasets returns correct columns", {
  result <- list_demo_datasets()
  expected_cols <- c(
    "code",
    "category",
    "description_it",
    "description_en",
    "url_pattern"
  )
  expect_identical(names(result), expected_cols)
})

test_that("build_demo_url errors on NULL code", {
  expect_error(build_demo_url(NULL, year = 2024), "code")
})

test_that("get_demo_dataset_info errors on empty string", {
  expect_error(get_demo_dataset_info(""), "non-empty")
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

test_that("search_demo_datasets case-sensitive search works", {
  result_ci <- search_demo_datasets("aire", ignore_case = TRUE)
  result_cs <- search_demo_datasets("AIRE", ignore_case = FALSE)
  expect_gt(nrow(result_cs), 0L)
  expect_true("AIR" %in% result_cs$code)
})

test_that("demo_cache_status empty result has correct column types", {
  result <- demo_cache_status(cache_dir = file.path(tempdir(), "empty_demo"))
  expect_type(result$code, "character")
  expect_type(result$file, "character")
  expect_type(result$size_mb, "double")
  expect_type(result$age_days, "double")
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
