# test-hvd-metadata.R - Tests for HVD metadata parsing (hvd_metadata.R)

# 1. .parse_hvd_dataflows v1 standard path -----

test_that("v1 parser handles Structure$Dataflows$Dataflow path", {
  json_data <- list(
    Structure = list(
      Dataflows = list(
        Dataflow = list(
          list(
            id = "DS_001",
            agencyID = "IT1",
            Name = "Dataset One",
            Description = "First dataset"
          ),
          list(
            id = "DS_002",
            agencyID = "IT1",
            Name = "Dataset Two",
            Description = "Second dataset"
          )
        )
      )
    )
  )
  result <- .parse_hvd_dataflows(json_data, "hvd_v1")
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2L)
  expect_equal(result$id, c("DS_001", "DS_002"))
  expect_equal(result$agency, c("IT1", "IT1"))
})

# 2. .parse_hvd_dataflows v1 alternative path -----

test_that("v1 parser handles Dataflows$Dataflow path", {
  json_data <- list(
    Dataflows = list(
      Dataflow = list(
        list(
          id = "DS_003",
          agencyID = "IT1",
          Name = "Dataset Three",
          Description = "Third dataset"
        )
      )
    )
  )
  result <- .parse_hvd_dataflows(json_data, "hvd_v1")
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1L)
  expect_equal(result$id, "DS_003")
})

# 3. .parse_hvd_dataflows v1 references path -----

test_that("v1 parser handles references path from HVD server", {
  json_data <- list(
    resources = list(),
    references = list(
      "urn:sdmx:org.sdmx.infomodel.datastructure.Dataflow=IT1:BCS_TOR_M(1.0)" = list(
        id = "BCS_TOR_M",
        name = "BCS_TOR_M",
        description = "Volume of retail trade",
        agencyID = "IT1",
        version = "1.0",
        isFinal = TRUE
      ),
      "urn:sdmx:org.sdmx.infomodel.datastructure.Dataflow=IT1:POP_RES(1.0)" = list(
        id = "POP_RES",
        name = "POP_RES",
        description = "Resident population",
        agencyID = "IT1",
        version = "1.0",
        isFinal = TRUE
      )
    )
  )
  result <- .parse_hvd_dataflows(json_data, "hvd_v1")
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2L)
  expect_true("BCS_TOR_M" %in% result$id)
  expect_true("POP_RES" %in% result$id)
  expect_equal(result$agency, c("IT1", "IT1"))
})

test_that("v1 references path extracts description correctly", {
  json_data <- list(
    resources = list(),
    references = list(
      "urn:key" = list(
        id = "FLOW_1",
        name = "FLOW_1",
        description = "A test dataflow",
        agencyID = "IT1"
      )
    )
  )
  result <- .parse_hvd_dataflows(json_data, "hvd_v1")
  expect_equal(result$description, "A test dataflow")
})

# 4. .parse_hvd_dataflows v2 standard path -----

test_that("v2 parser handles data$dataflows path", {
  json_data <- list(
    data = list(
      dataflows = list(
        list(
          id = "DS_V2",
          agencyID = "IT1",
          name = "V2 Dataset",
          description = "A v2 dataset"
        )
      )
    )
  )
  result <- .parse_hvd_dataflows(json_data, "hvd_v2")
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1L)
  expect_equal(result$id, "DS_V2")
})

# 5. .parse_hvd_dataflows v2 references path -----

test_that("v2 parser handles references path from HVD server", {
  json_data <- list(
    resources = list(),
    references = list(
      "urn:sdmx:v2:Dataflow=IT1:CPI_M(1.0)" = list(
        id = "CPI_M",
        name = "CPI_M",
        description = "Consumer price index",
        agencyID = "IT1",
        version = "1.0"
      )
    )
  )
  result <- .parse_hvd_dataflows(json_data, "hvd_v2")
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1L)
  expect_equal(result$id, "CPI_M")
  expect_equal(result$description, "Consumer price index")
})

# 6. .parse_hvd_dataflows empty responses -----

test_that("parser returns empty data.table for empty references", {
  json_data <- list(
    resources = list(),
    references = list()
  )
  expect_warning(
    result <- .parse_hvd_dataflows(json_data, "hvd_v1"),
    "No dataflows found"
  )
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
  expect_true(all(c("id", "name", "description", "agency") %in% names(result)))
})

test_that("parser returns empty data.table for unrecognized structure", {
  json_data <- list(unknown_key = list(other = 42))
  expect_warning(
    result <- .parse_hvd_dataflows(json_data, "hvd_v1"),
    "No dataflows found"
  )
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0L)
})

# 7. .parse_hvd_dataflows references path priority -----

test_that("v1 parser prefers Structure$Dataflows$Dataflow over references", {
  json_data <- list(
    Structure = list(
      Dataflows = list(
        Dataflow = list(
          list(id = "FROM_STANDARD", agencyID = "IT1", Name = "Standard")
        )
      )
    ),
    references = list(
      "urn:key" = list(id = "FROM_REFS", agencyID = "IT1", name = "Refs")
    )
  )
  result <- .parse_hvd_dataflows(json_data, "hvd_v1")
  expect_equal(nrow(result), 1L)
  expect_equal(result$id, "FROM_STANDARD")
})
