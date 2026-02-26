# test-hvd-config.R - Unit tests for HVD URL builders and validation (hvd_config.R)

# 1. validate_api_surface tests -----

test_that("validate_api_surface returns 'legacy' when given 'legacy'", {
  result <- validate_api_surface("legacy")
  expect_equal(result, "legacy")
})

test_that("validate_api_surface returns 'hvd_v1' when given 'hvd_v1'", {
  result <- validate_api_surface("hvd_v1")
  expect_equal(result, "hvd_v1")
})

test_that("validate_api_surface returns 'hvd_v2' when given 'hvd_v2'", {
  result <- validate_api_surface("hvd_v2")
  expect_equal(result, "hvd_v2")
})

test_that("validate_api_surface errors on invalid string values", {
  expect_error(validate_api_surface("v1"), "Unknown API surface")
  expect_error(validate_api_surface("hvd"), "Unknown API surface")
  expect_error(validate_api_surface("invalid"), "Unknown API surface")
})

test_that("validate_api_surface errors on non-character inputs", {
  expect_error(validate_api_surface(NULL), "must be a single character string")
  expect_error(validate_api_surface(NA), "must be a single character string")
  expect_error(validate_api_surface(42), "must be a single character string")
})

test_that("validate_api_surface returns the value invisibly", {
  out <- withVisible(validate_api_surface("legacy"))
  expect_false(out$visible)
  expect_equal(out$value, "legacy")
})

# 2. build_hvd_v1_url tests -----

test_that("v1 data GET URL contains correct path segments", {
  url <- build_hvd_v1_url("data", dataset_id = "150_908")
  expect_true(grepl("/rest/data/150_908/ALL/all", url, fixed = TRUE))
})

test_that("v1 data GET URL includes startPeriod and endPeriod query params", {
  url <- build_hvd_v1_url(
    "data",
    dataset_id = "150_908",
    start_time = "2020",
    end_time = "2024"
  )
  expect_true(grepl("startPeriod=2020", url, fixed = TRUE))
  expect_true(grepl("endPeriod=2024", url, fixed = TRUE))
})

test_that("v1 data GET URL has no query params when times are not specified", {
  url <- build_hvd_v1_url("data", dataset_id = "150_908")
  expect_false(grepl("\\?", url))
})

test_that("v1 data POST URL contains /body/ in the path", {
  url <- build_hvd_v1_url("data", dataset_id = "150_908", method = "POST")
  expect_true(grepl("/rest/data/150_908/body/all", url, fixed = TRUE))
})

test_that("v1 availableconstraint URL is correct", {
  url <- build_hvd_v1_url("availableconstraint", dataset_id = "150_908")
  expect_true(
    grepl("/rest/availableconstraint/150_908/ALL/all/all", url, fixed = TRUE)
  )
})

test_that("v1 dataflow URL does not require dataset_id", {
  url <- build_hvd_v1_url("dataflow")
  expect_true(grepl("/rest/dataflow$", url))
})

test_that("v1 structure URL includes DSD path", {
  url <- build_hvd_v1_url("structure", dataset_id = "150_908")
  expect_true(grepl("/rest/datastructure/IT1/150_908/1.0", url, fixed = TRUE))
  expect_true(grepl("references=children", url, fixed = TRUE))
})

test_that("v1 URL builder errors on invalid endpoint name", {
  expect_error(
    build_hvd_v1_url("invalid_endpoint", dataset_id = "150_908"),
    "Unknown HVD v1 endpoint"
  )
})

test_that("v1 URL builder errors when dataset_id is missing for data endpoint", {
  expect_error(
    build_hvd_v1_url("data"),
    "dataset_id.*is required"
  )
  expect_error(
    build_hvd_v1_url("data", dataset_id = NULL),
    "dataset_id.*is required"
  )
})

test_that("v1 URL builder errors when dataset_id is missing for structure", {
  expect_error(
    build_hvd_v1_url("structure"),
    "dataset_id.*is required"
  )
})

test_that("v1 URL builder accepts custom filter and provider", {
  url <- build_hvd_v1_url(
    "data",
    dataset_id = "150_908",
    filter = "M....",
    provider = "IT1"
  )
  expect_true(grepl("/rest/data/150_908/M..../IT1", url, fixed = TRUE))
})

test_that("v1 URL builder includes optional query params when provided", {
  url <- build_hvd_v1_url(
    "data",
    dataset_id = "150_908",
    lastNObservations = 5,
    detail = "dataonly",
    includeHistory = TRUE
  )
  expect_true(grepl("lastNObservations=5", url, fixed = TRUE))
  expect_true(grepl("detail=dataonly", url, fixed = TRUE))
  expect_true(grepl("includeHistory=true", url, fixed = TRUE))
})

# 3. build_hvd_v2_url tests -----

test_that("v2 data GET URL contains correct path segments", {
  url <- build_hvd_v2_url("data", dataset_id = "150_908")
  expect_true(
    grepl("/rest/v2/data/dataflow/IT1/150_908/~/\\*", url)
  )
})

test_that("v2 data POST URL contains /body in the path", {
  url <- build_hvd_v2_url("data", dataset_id = "150_908", method = "POST")
  expect_true(
    grepl("/rest/v2/data/dataflow/IT1/150_908/~/body", url, fixed = TRUE)
  )
})

test_that("v2 availability URL contains correct segments", {
  url <- build_hvd_v2_url("availability", dataset_id = "150_908")
  expect_true(
    grepl(
      "/rest/v2/availability/dataflow/IT1/150_908/~/\\*/all",
      url
    )
  )
})

test_that("v2 structure URL is correct", {
  url <- build_hvd_v2_url("structure", dataset_id = "150_908")
  expect_true(
    grepl(
      "/rest/v2/structure/dataflow/IT1/150_908/~",
      url,
      fixed = TRUE
    )
  )
})

test_that("v2 URL builder supports custom context, agency_id, and version", {
  url <- build_hvd_v2_url(
    "data",
    dataset_id = "150_908",
    context = "datastructure",
    agency_id = "ECB",
    version = "1.0"
  )
  expect_true(grepl("/datastructure/ECB/150_908/1.0/", url, fixed = TRUE))
})

test_that("v2 URL builder errors on invalid endpoint", {
  expect_error(
    build_hvd_v2_url("dataflow", dataset_id = "150_908"),
    "Unknown HVD v2 endpoint"
  )
})

test_that("v2 URL builder errors when dataset_id is NULL", {
  expect_error(
    build_hvd_v2_url("data"),
    "dataset_id.*is required"
  )
})

test_that("v2 URL builder errors on invalid dim_filters", {
  expect_error(
    build_hvd_v2_url("data", dataset_id = "150_908", dim_filters = "not_list"),
    "dim_filters.*must be a named list"
  )
})

test_that("v2 URL builder errors on unnamed dim_filters elements", {
  expect_error(
    build_hvd_v2_url(
      "data",
      dataset_id = "150_908",
      dim_filters = list("M")
    ),
    "dim_filters.*must be named"
  )
})

# 4. build_sdmx3_filters tests -----

test_that("build_sdmx3_filters returns empty character with no filters", {
  result <- build_sdmx3_filters()
  expect_identical(result, character(0L))
})

test_that("build_sdmx3_filters handles start_time only", {
  result <- build_sdmx3_filters(start_time = "2020")
  expect_length(result, 1L)
  expect_equal(result, "c[TIME_PERIOD]=ge:2020")
})

test_that("build_sdmx3_filters handles end_time only", {
  result <- build_sdmx3_filters(end_time = "2025")
  expect_length(result, 1L)
  expect_equal(result, "c[TIME_PERIOD]=le:2025")
})

test_that("build_sdmx3_filters handles both start_time and end_time", {
  result <- build_sdmx3_filters(start_time = "2020", end_time = "2025")
  expect_length(result, 1L)
  expect_equal(result, "c[TIME_PERIOD]=ge:2020+le:2025")
})

test_that("build_sdmx3_filters handles single dim_filter", {
  result <- build_sdmx3_filters(dim_filters = list(FREQ = "M"))
  expect_length(result, 1L)
  expect_equal(unname(result), "c[FREQ]=M")
})

test_that("build_sdmx3_filters handles multiple dim_filters", {
  result <- build_sdmx3_filters(
    dim_filters = list(FREQ = "M", REF_AREA = "IT")
  )
  expect_length(result, 2L)
  expect_true("c[FREQ]=M" %in% result)
  expect_true("c[REF_AREA]=IT" %in% result)
})

test_that("build_sdmx3_filters combines time and dim filters", {
  result <- build_sdmx3_filters(
    start_time = "2020",
    end_time = "2025",
    dim_filters = list(FREQ = "M")
  )
  expect_length(result, 2L)
  expect_equal(unname(result[1]), "c[TIME_PERIOD]=ge:2020+le:2025")
  expect_equal(unname(result[2]), "c[FREQ]=M")
})

test_that("build_sdmx3_filters ignores empty string time values", {
  result <- build_sdmx3_filters(start_time = "", end_time = "")
  expect_identical(result, character(0L))
})

test_that("build_sdmx3_filters errors on unnamed dim_filters elements", {
  expect_error(
    build_sdmx3_filters(dim_filters = list("M")),
    "must be named"
  )
})

# 5. get_hvd_accept_header tests -----

test_that("v1 csv returns correct SDMX 2.1 CSV accept header", {
  header <- get_hvd_accept_header("hvd_v1", "csv")
  expect_equal(header, "application/vnd.sdmx.data+csv;version=1.0.0")
})

test_that("v2 csv returns correct SDMX 3.0 CSV accept header", {
  header <- get_hvd_accept_header("hvd_v2", "csv")
  expect_equal(header, "application/vnd.sdmx.data+csv;version=2.0.0")
})

test_that("v1 json returns correct SDMX 2.1 JSON accept header", {
  header <- get_hvd_accept_header("hvd_v1", "json")
  expect_equal(header, "application/vnd.sdmx.data+json;version=1.0.0")
})

test_that("v2 json returns correct SDMX 3.0 JSON accept header", {
  header <- get_hvd_accept_header("hvd_v2", "json")
  expect_equal(header, "application/vnd.sdmx.data+json;version=2.0.0")
})

test_that("xml format returns correct accept header", {
  header_v1 <- get_hvd_accept_header("hvd_v1", "xml")
  expect_true(grepl("structurespecificdata\\+xml", header_v1))
  expect_true(grepl("version=1.0.0", header_v1, fixed = TRUE))

  header_v2 <- get_hvd_accept_header("hvd_v2", "xml")
  expect_true(grepl("version=2.0.0", header_v2, fixed = TRUE))
})

test_that("get_hvd_accept_header errors on invalid api_version", {
  expect_error(
    get_hvd_accept_header("legacy", "csv"),
    "Unknown API version"
  )
  expect_error(
    get_hvd_accept_header("v1", "csv"),
    "Unknown API version"
  )
})

test_that("get_hvd_accept_header errors on invalid format", {
  expect_error(
    get_hvd_accept_header("hvd_v1", "yaml"),
    "Unknown format"
  )
  expect_error(
    get_hvd_accept_header("hvd_v1", "tsv"),
    "Unknown format"
  )
})

test_that("get_hvd_accept_header is case-insensitive for format", {
  header <- get_hvd_accept_header("hvd_v1", "CSV")
  expect_equal(header, "application/vnd.sdmx.data+csv;version=1.0.0")
})

# 6. get_hvd_accept_header structure type tests -----

test_that("default type='data' preserves backward compatibility", {
  header_default <- get_hvd_accept_header("hvd_v1", "json")
  header_explicit <- get_hvd_accept_header("hvd_v1", "json", type = "data")
  expect_identical(header_default, header_explicit)
})

test_that("v1 structure json returns correct SDMX 2.1 structure header", {
  header <- get_hvd_accept_header("hvd_v1", "json", type = "structure")
  expect_equal(
    header,
    "application/vnd.sdmx.structure+json;version=1.0.0"
  )
})

test_that("v2 structure json returns correct SDMX 3.0 structure header", {
  header <- get_hvd_accept_header("hvd_v2", "json", type = "structure")
  expect_equal(
    header,
    "application/vnd.sdmx.structure+json;version=2.0.0"
  )
})

test_that("v1 structure csv returns correct structure CSV header", {
  header <- get_hvd_accept_header("hvd_v1", "csv", type = "structure")
  expect_equal(
    header,
    "application/vnd.sdmx.structure+csv;version=1.0.0"
  )
})

test_that("v2 structure csv returns correct structure CSV header", {
  header <- get_hvd_accept_header("hvd_v2", "csv", type = "structure")
  expect_equal(
    header,
    "application/vnd.sdmx.structure+csv;version=2.0.0"
  )
})

test_that("v1 structure xml returns correct structure XML header", {
  header <- get_hvd_accept_header("hvd_v1", "xml", type = "structure")
  expect_equal(
    header,
    "application/vnd.sdmx.structure+xml;version=1.0.0"
  )
})

test_that("v2 structure xml returns correct structure XML header", {
  header <- get_hvd_accept_header("hvd_v2", "xml", type = "structure")
  expect_equal(
    header,
    "application/vnd.sdmx.structure+xml;version=2.0.0"
  )
})

test_that("data type does not use structure media type", {
  header <- get_hvd_accept_header("hvd_v1", "json", type = "data")
  expect_false(grepl("structure\\+json", header))
  expect_true(grepl("data\\+json", header))
})

test_that("structure type does not use data media type", {
  header <- get_hvd_accept_header("hvd_v1", "json", type = "structure")
  expect_false(grepl("data\\+json", header))
  expect_true(grepl("structure\\+json", header))
})

test_that("get_hvd_accept_header errors on invalid type", {
  expect_error(
    get_hvd_accept_header("hvd_v1", "json", type = "metadata"),
    "Unknown type"
  )
  expect_error(
    get_hvd_accept_header("hvd_v1", "json", type = "query"),
    "Unknown type"
  )
})

test_that("get_hvd_accept_header is case-insensitive for type", {
  header <- get_hvd_accept_header("hvd_v1", "json", type = "STRUCTURE")
  expect_equal(
    header,
    "application/vnd.sdmx.structure+json;version=1.0.0"
  )
})
