# 1. Input validation -----

test_that("check_bulk_updates rejects non-character dataset_ids", {
  expect_error(
    check_bulk_updates(123),
    "dataset_ids"
  )
  expect_error(
    check_bulk_updates(list("534_50")),
    "dataset_ids"
  )
})

test_that("check_bulk_updates rejects empty character vector", {
  expect_error(
    check_bulk_updates(character(0)),
    "dataset_ids"
  )
})

test_that("check_bulk_updates rejects NA values in dataset_ids", {
  expect_error(
    check_bulk_updates(c("534_50", NA_character_)),
    "NA"
  )
  expect_error(
    check_bulk_updates(NA_character_),
    "NA"
  )
})

test_that("check_bulk_updates rejects non-POSIXct cutoff", {
  expect_error(
    check_bulk_updates("534_50", cutoff = "2026-04-01"),
    "cutoff"
  )
  expect_error(
    check_bulk_updates("534_50", cutoff = as.Date("2026-04-01")),
    "cutoff"
  )
})

test_that("check_bulk_updates rejects invalid api value", {
  expect_error(
    check_bulk_updates("534_50", api = "invalid_api"),
    "api"
  )
})

# 2. Core logic with mocked metadata -----

test_that("recently updated dataset is included in result", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      # recent timestamp, after cutoff -> needs update
      as.POSIXct("2026-04-05 10:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates("150_908", cutoff = cutoff, verbose = FALSE)
  expect_true("150_908" %in% result)
})

test_that("dataset not updated since cutoff is NOT in result", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      # old timestamp, before cutoff -> up to date locally
      as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates("534_50", cutoff = cutoff, verbose = FALSE)
  expect_false("534_50" %in% result)
})

test_that("failed dataset IS in update result (conservative)", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      NULL
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates("999_99", cutoff = cutoff, verbose = FALSE)
  expect_true("999_99" %in% result)
})

test_that("mixed scenario returns correct datasets needing update", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      switch(
        dataset_id,
        "534_50" = as.POSIXct("2026-04-05 10:00:00", tz = "UTC"),
        "150_908" = as.POSIXct("2026-01-01 00:00:00", tz = "UTC"),
        "999_99" = NULL
      )
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates(
    c("534_50", "150_908", "999_99"),
    cutoff = cutoff,
    verbose = FALSE
  )

  expect_true("534_50" %in% result) # updated after cutoff
  expect_true("999_99" %in% result) # check_failed, included conservatively
  expect_false("150_908" %in% result) # old, before cutoff
  expect_length(result, 2)
})

# 3. Update details attribute -----

test_that("output has update_details attribute", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      switch(
        dataset_id,
        "534_50" = as.POSIXct("2026-04-05 10:00:00", tz = "UTC"),
        "150_908" = as.POSIXct("2026-01-01 00:00:00", tz = "UTC"),
        "999_99" = NULL
      )
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates(
    c("534_50", "150_908", "999_99"),
    cutoff = cutoff,
    verbose = FALSE
  )

  details <- attr(result, "update_details")
  expect_false(is.null(details))
})

test_that("update_details is a data.table", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      as.POSIXct("2026-04-05 10:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates("534_50", cutoff = cutoff, verbose = FALSE)
  details <- attr(result, "update_details")
  expect_true(data.table::is.data.table(details))
})

test_that("update_details has correct columns", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      as.POSIXct("2026-04-05 10:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates("534_50", cutoff = cutoff, verbose = FALSE)
  details <- attr(result, "update_details")
  expect_true(all(c("dataset_id", "last_update", "status") %in% names(details)))
})

test_that("update_details row count matches input length", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      switch(
        dataset_id,
        "534_50" = as.POSIXct("2026-04-05 10:00:00", tz = "UTC"),
        "150_908" = as.POSIXct("2026-01-01 00:00:00", tz = "UTC"),
        "999_99" = NULL
      )
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates(
    c("534_50", "150_908", "999_99"),
    cutoff = cutoff,
    verbose = FALSE
  )
  details <- attr(result, "update_details")
  expect_equal(nrow(details), 3)
})

test_that("update_details status values are correct per dataset", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      switch(
        dataset_id,
        "534_50" = as.POSIXct("2026-04-05 10:00:00", tz = "UTC"),
        "150_908" = as.POSIXct("2026-01-01 00:00:00", tz = "UTC"),
        "999_99" = NULL
      )
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates(
    c("534_50", "150_908", "999_99"),
    cutoff = cutoff,
    verbose = FALSE
  )
  details <- attr(result, "update_details")

  expect_equal(
    details[dataset_id == "534_50", status],
    "needs_update"
  )
  expect_equal(
    details[dataset_id == "150_908", status],
    "up_to_date"
  )
  expect_equal(
    details[dataset_id == "999_99", status],
    "check_failed"
  )
})

# 4. De-duplication -----

test_that("duplicate dataset codes produce unique entries in output", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  call_count <- 0L
  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      call_count <<- call_count + 1L
      as.POSIXct("2026-04-05 10:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates(
    c("150_908", "150_908", "150_908"),
    cutoff = cutoff,
    verbose = FALSE
  )

  expect_length(result, 1)
  expect_equal(result[[1]], "150_908")
  expect_equal(call_count, 1L)
})

test_that("details table has de-duplicated rows", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates(
    c("534_50", "534_50", "150_908"),
    cutoff = cutoff,
    verbose = FALSE
  )
  details <- attr(result, "update_details")
  expect_equal(nrow(details), 2)
  expect_equal(sort(details$dataset_id), c("150_908", "534_50"))
})

# 5. Edge cases -----

test_that("single dataset input works", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      as.POSIXct("2026-04-05 10:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates("150_908", cutoff = cutoff, verbose = FALSE)
  expect_length(result, 1)
  expect_equal(result[[1]], "150_908")
})

test_that("all datasets up-to-date returns length-0 vector", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  result <- check_bulk_updates(
    c("534_50", "150_908"),
    cutoff = cutoff,
    verbose = FALSE
  )
  expect_length(result, 0)
  expect_type(result, "character")
})

test_that("all datasets need update returns full vector", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      as.POSIXct("2026-04-05 10:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  ids <- c("534_50", "150_908", "151_914")
  result <- check_bulk_updates(ids, cutoff = cutoff, verbose = FALSE)
  expect_length(result, 3)
  expect_setequal(result, ids)
})

# 6. Verbose output -----

test_that("messages appear when verbose is TRUE", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  expect_message(
    check_bulk_updates("534_50", cutoff = cutoff, verbose = TRUE)
  )
})

test_that("no messages when verbose is FALSE", {
  cutoff <- as.POSIXct("2026-04-01 00:00:00", tz = "UTC")

  local_mocked_bindings(
    get_dataset_last_update = function(dataset_id, timeout = 30) {
      as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
    },
    throttle = function(config_override = NULL) invisible(NULL)
  )

  expect_silent(
    check_bulk_updates("534_50", cutoff = cutoff, verbose = FALSE)
  )
})
