test_that("check_istat_api works correctly", {
  skip_on_cran()
  skip_if_offline()
  
  # Test API check function
  result <- check_istat_api(timeout = 5)
  expect_type(result, "logical")
})

test_that("download_istat_data validates inputs correctly", {
  # Test input validation
  expect_error(download_istat_data(c("534_50", "534_51")), 
               "dataset_id must be a single character string")
  
  expect_error(download_istat_data(123), 
               "dataset_id must be a single character string")
})

test_that("download_multiple_datasets validates inputs", {
  expect_error(download_multiple_datasets(character(0)), 
               "dataset_ids must be a non-empty character vector")
  
  expect_error(download_multiple_datasets(123), 
               "dataset_ids must be a non-empty character vector")
})

# Mock test for successful data download (to avoid actual API calls in tests)
test_that("download_istat_data returns expected structure", {
  skip("Requires actual API connection - create mock test")
  
  # This test would be implemented with mocked API responses
  # to avoid dependencies on external services during testing
})