## Code to prepare `sample_data` dataset goes here

# This script shows how to prepare package data
# Run this script to create sample datasets included with the package

library(data.table)

# Create sample metadata
sample_metadata <- data.table(
  id = c("150_908", "150_915", "150_916"),
  Name.it = c(
    "Occupati - dati mensili",
    "Occupati - dati trimestrali", 
    "Occupati - dati annuali"
  ),
  dsdRef = c("150_908", "150_915", "150_916"),
  stringsAsFactors = FALSE
)

# Create sample time series data
set.seed(123)
sample_dates <- seq.Date(from = as.Date("2020-01-01"), 
                        to = as.Date("2023-12-01"), 
                        by = "month")

sample_timeseries <- data.table(
  tempo = sample_dates,
  valore = 20000 + cumsum(rnorm(length(sample_dates), mean = 10, sd = 50)),
  region = sample(c("North", "Center", "South"), length(sample_dates), replace = TRUE),
  sector = sample(c("Manufacturing", "Services", "Agriculture"), length(sample_dates), replace = TRUE)
)

# Create sample forecast data
sample_forecast <- list(
  point_forecast = c(21500, 21600, 21700, 21800),
  forecast_dates = seq.Date(from = as.Date("2024-01-01"), 
                           to = as.Date("2024-04-01"), 
                           by = "month"),
  upper_bounds = matrix(c(21600, 21700, 21800, 21900, 
                         21700, 21800, 21900, 22000), ncol = 2),
  lower_bounds = matrix(c(21400, 21500, 21600, 21700,
                         21300, 21400, 21500, 21600), ncol = 2),
  method = "auto.arima",
  confidence_levels = c(0.8, 0.95)
)

colnames(sample_forecast$upper_bounds) <- c("upper_80", "upper_95")
colnames(sample_forecast$lower_bounds) <- c("lower_80", "lower_95")

# Save the datasets (uncomment to actually save them to the package)
# usethis::use_data(sample_metadata, overwrite = TRUE)
# usethis::use_data(sample_timeseries, overwrite = TRUE)
# usethis::use_data(sample_forecast, overwrite = TRUE)

# For demonstration purposes, we'll just print the data
print("Sample metadata:")
print(sample_metadata)

print("Sample time series (first 10 rows):")
print(head(sample_timeseries, 10))

print("Sample forecast structure:")
str(sample_forecast)