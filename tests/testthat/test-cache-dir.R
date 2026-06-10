# Tests for .istatlab_cache_dir() — resolution of the metadata cache directory
# via the ISTATLAB_CACHE_DIR environment variable. No network calls.

test_that(".istatlab_cache_dir() resolves ISTATLAB_CACHE_DIR when set", {
  skip_if_not_installed("withr")

  shared_dir <- file.path(withr::local_tempdir(), "shared_meta")
  withr::local_envvar(ISTATLAB_CACHE_DIR = shared_dir)

  expect_identical(.istatlab_cache_dir(), shared_dir)

  # The configuration default must reflect the environment variable
  config <- get_istat_config()
  expect_identical(config$defaults$cache_dir, shared_dir)
})

test_that(".istatlab_cache_dir() falls back to 'meta' when unset", {
  skip_if_not_installed("withr")

  withr::local_envvar(ISTATLAB_CACHE_DIR = NA)

  expect_identical(.istatlab_cache_dir(), "meta")

  config <- get_istat_config()
  expect_identical(config$defaults$cache_dir, "meta")
})

test_that(".istatlab_cache_dir() treats empty string as unset", {
  skip_if_not_installed("withr")

  withr::local_envvar(ISTATLAB_CACHE_DIR = "")

  expect_identical(.istatlab_cache_dir(), "meta")
})

test_that("cache-reading functions honor ISTATLAB_CACHE_DIR", {
  skip_if_not_installed("withr")

  cache_dir <- withr::local_tempdir()
  withr::local_envvar(ISTATLAB_CACHE_DIR = cache_dir)

  # save_codelist_metadata() writes into the configured directory
  metadata <- list(
    CL_FREQ = list(
      first_download = Sys.time(),
      last_refresh = Sys.time(),
      ttl_days = 14
    )
  )
  save_codelist_metadata(metadata)

  config <- get_istat_config()
  expect_true(
    file.exists(file.path(cache_dir, config$cache$codelist_metadata_file))
  )

  # load_codelist_metadata() reads back from the same directory
  loaded <- load_codelist_metadata()
  expect_identical(names(loaded), "CL_FREQ")
  expect_identical(loaded$CL_FREQ$ttl_days, 14)
})
