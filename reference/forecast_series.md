# Forecast a time series using multiple models

Tests multiple forecasting models, selects the best one based on
accuracy metrics, and also provides an ensemble (average) forecast.

## Usage

``` r
forecast_series(
  data,
  time_col = "tempo",
  value_col = "valore",
  freq_col = "FREQ",
  horizon = NULL,
  models = c("auto.arima", "ets", "theta", "naive", "snaive"),
  metric = c("RMSE", "MAE", "MAPE"),
  test_size = 0.2,
  save_path = NULL,
  verbose = TRUE
)
```

## Arguments

- data:

  data.table with a single time series

- time_col:

  Column name for dates (default "tempo")

- value_col:

  Column name for values (default "valore")

- freq_col:

  Column name for frequency indicator (default "FREQ")

- horizon:

  Forecast periods. NULL for auto-detect (24 monthly, 8 quarterly, 2
  annual)

- models:

  Character vector of model names to test

- metric:

  Accuracy metric for model selection: "RMSE", "MAE", or "MAPE"

- test_size:

  Proportion of data to use for testing (default 0.2)

- save_path:

  Optional file path to save the forecast as RDS

- verbose:

  Print progress messages (default TRUE)

## Value

An S3 object of class "istat_forecast" containing:

- best_model: Best performing model with forecast and accuracy

- ensemble: Average forecast from all models

- all_models: Results from each individual model

- metadata: Forecast parameters and metadata

- original_data: Input data

## Examples

``` r
if (FALSE) { # \dontrun{
# Load some ISTAT data
data <- download_istat_data("534_50", start_time = "2015")
data <- apply_labels(data)

# Filter to a single series
series <- data[ECON_ACTIVITY_NACE_2007_label == "TOTALE INDUSTRIA E SERVIZI  (b-n)"]

# Generate forecast
fc <- forecast_series(series, horizon = 24)

# View results
print(fc)
plot(fc)
} # }
```
