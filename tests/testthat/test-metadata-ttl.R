# test-metadata-ttl.R
# Unit tests for staggered TTL codelist functions
# Author: Giampaolo Montaletti

test_that("compute_codelist_ttl returns consistent values", {
  # Same codelist ID should always return same TTL
  ttl1 <- compute_codelist_ttl("CL_FREQ")
  ttl2 <- compute_codelist_ttl("CL_FREQ")
  expect_equal(ttl1, ttl2)

  # Deterministic - running multiple times gives same result
  ttl3 <- compute_codelist_ttl("CL_FREQ")
  expect_equal(ttl1, ttl3)
})

test_that("compute_codelist_ttl returns values within bounds", {
  # Default config: base=14, jitter=14, so range is 14-27
  config <- get_istat_config()
  base <- config$cache$codelist_base_ttl_days
  jitter <- config$cache$codelist_jitter_days

  # Test multiple codelist IDs
  test_ids <- c("CL_FREQ", "CL_ITTER107", "CL_ATECO_2007", "CL_SEXISTAT1", "CL_BASE_YEAR")

  for (cl_id in test_ids) {
    ttl <- compute_codelist_ttl(cl_id)
    expect_gte(ttl, base)
    expect_lt(ttl, base + jitter)
  }
})

test_that("compute_codelist_ttl distributes values across range", {
  # Generate TTLs for multiple codelist IDs
  test_ids <- paste0("CL_TEST_", 1:50)
  ttls <- sapply(test_ids, compute_codelist_ttl)

  # Should have variety (not all same value)
  expect_gt(length(unique(ttls)), 1)
})

test_that("compute_codelist_ttl respects custom parameters", {
  # Test with custom base and jitter
  ttl <- compute_codelist_ttl("CL_FREQ", base_ttl = 7, jitter_days = 3)
  expect_gte(ttl, 7)
  expect_lt(ttl, 10)

  # Test with different parameters
  ttl2 <- compute_codelist_ttl("CL_FREQ", base_ttl = 30, jitter_days = 10)
  expect_gte(ttl2, 30)
  expect_lt(ttl2, 40)
})

test_that("load_codelist_metadata returns empty list for missing file", {
  # Use temporary directory that doesn't have metadata file
  temp_dir <- tempdir()
  test_cache_dir <- file.path(temp_dir, "test_meta_nonexistent")

  # Clean up if exists
  if (dir.exists(test_cache_dir)) {
    unlink(test_cache_dir, recursive = TRUE)
  }

  result <- load_codelist_metadata(test_cache_dir)
  expect_type(result, "list")
  expect_length(result, 0)
})

test_that("save_codelist_metadata creates directory and saves file", {
  # Use temporary directory
  temp_dir <- tempdir()
  test_cache_dir <- file.path(temp_dir, "test_meta_save")

  # Clean up if exists
  if (dir.exists(test_cache_dir)) {
    unlink(test_cache_dir, recursive = TRUE)
  }

  # Create test metadata
  test_metadata <- list(
    CL_FREQ = list(
      first_download = Sys.time(),
      last_refresh = Sys.time(),
      ttl_days = 15
    )
  )

  # Save metadata
  save_codelist_metadata(test_metadata, test_cache_dir)

  # Verify directory and file exist
  expect_true(dir.exists(test_cache_dir))
  config <- get_istat_config()
  metadata_file <- file.path(test_cache_dir, config$cache$codelist_metadata_file)
  expect_true(file.exists(metadata_file))

  # Verify content
  loaded <- load_codelist_metadata(test_cache_dir)
  expect_equal(names(loaded), "CL_FREQ")
  expect_equal(loaded$CL_FREQ$ttl_days, 15)

  # Clean up
  unlink(test_cache_dir, recursive = TRUE)
})

test_that("check_codelist_expiration returns empty for empty cache", {
  # Use temporary directory without cache
  temp_dir <- tempdir()
  test_cache_dir <- file.path(temp_dir, "test_meta_empty")

  # Clean up if exists
  if (dir.exists(test_cache_dir)) {
    unlink(test_cache_dir, recursive = TRUE)
  }

  result <- check_codelist_expiration(cache_dir = test_cache_dir)
  expect_type(result, "character")
  expect_length(result, 0)
})

test_that("check_codelist_expiration respects force_check", {
  # Create a temporary cache with fresh metadata
  temp_dir <- tempdir()
  test_cache_dir <- file.path(temp_dir, "test_meta_force")

  # Clean up if exists
  if (dir.exists(test_cache_dir)) {
    unlink(test_cache_dir, recursive = TRUE)
  }
  dir.create(test_cache_dir, recursive = TRUE)

  config <- get_istat_config()

  # Create test codelists file
  test_codelists <- list(
    CL_FREQ = data.table::data.table(id_description = "M", it_description = "Mensile")
  )
  saveRDS(test_codelists, file.path(test_cache_dir, config$cache$codelists_file))

  # Create fresh metadata
  test_metadata <- list(
    CL_FREQ = list(
      first_download = Sys.time(),
      last_refresh = Sys.time(),  # Just now, so not expired
      ttl_days = 14
    )
  )
  save_codelist_metadata(test_metadata, test_cache_dir)

  # Without force_check, should return empty (not expired)
  result_normal <- check_codelist_expiration(
    codelist_ids = "CL_FREQ",
    cache_dir = test_cache_dir,
    force_check = FALSE
  )
  expect_length(result_normal, 0)

  # With force_check, should return the codelist
  result_forced <- check_codelist_expiration(
    codelist_ids = "CL_FREQ",
    cache_dir = test_cache_dir,
    force_check = TRUE
  )
  expect_equal(result_forced, "CL_FREQ")

  # Clean up
  unlink(test_cache_dir, recursive = TRUE)
})

test_that("extract_root_id handles compound IDs correctly", {
  # Test compound ID extraction
  expect_equal(extract_root_id("534_49_DF_DCSC_GI_ORE_10"), "534_49")
  expect_equal(extract_root_id("155_318_DF_DCSP_RETRIBCONTR"), "155_318")

  # Test simple IDs (should return unchanged)
  expect_equal(extract_root_id("534_50"), "534_50")
  expect_equal(extract_root_id("150_908"), "150_908")
})
