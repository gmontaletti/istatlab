# Build Demo URL for ISTAT Demographic Data

Constructs the download URL for a given demographic dataset by looking
up its code in the demo registry and dispatching to the appropriate
pattern builder. The URL patterns correspond to different file-naming
conventions used on demo.istat.it:

- **Pattern A**: Year-indexed CSV ZIP
  (`{base_url}/{base_path}/{file_code}{year}.csv.zip`)

- **Pattern A1**: Year+locale CSV ZIP
  (`{base_url}/{base_path}/{file_code}_{year}_it.csv.zip`)

- **Pattern B**: Territory-indexed ZIP
  (`{base_url}/{base_path}/{file_code}_{year}_it_{territory}.zip`)

- **Pattern C**: Level+type+year ZIP
  (`{base_url}/{base_path}/dati{level}{type}{year}.zip`)

- **Pattern D**: Datatype-geolevel
  (`{base_url}/{base_path}/{data_type}-{geo_level}{ext}`)

- **Pattern E**: Subtype+year ZIP
  (`{base_url}/{base_path}/{file_code}_{subtype}_{year}.zip`)

- **Pattern F**: Static file
  (`{base_url}/{base_path}/{static_filename}`)

- **Pattern G**: Year-indexed plain CSV
  (`{base_url}/{base_path}/{file_code}{year}.csv`)

## Usage

``` r
build_demo_url(
  code,
  year = NULL,
  territory = NULL,
  level = NULL,
  type = NULL,
  data_type = NULL,
  geo_level = NULL,
  subtype = NULL
)
```

## Arguments

- code:

  Character string identifying the dataset in the demo registry (e.g.,
  `"D7B"`, `"POS"`, `"TVM"`, `"PPR"`).

- year:

  Integer year for the data file. Required for patterns A, A1, B, C, E,
  and G.

- territory:

  Character string specifying geographic territory (Pattern B only).
  Valid values are defined per dataset in the demo registry.

- level:

  Character string specifying geographic aggregation level (Pattern C
  only). Valid values are defined per dataset in the demo registry.

- type:

  Character string specifying data completeness type (Pattern C only).
  Valid values are defined per dataset in the demo registry.

- data_type:

  Character string specifying forecast data category (Pattern D only).
  Valid values are defined per dataset in the demo registry.

- geo_level:

  Character string specifying geographic resolution (Pattern D only).
  Valid values are defined per dataset in the demo registry. May be
  `NULL` for datasets without geographic levels.

- subtype:

  Character string specifying the data subtype (Pattern E only, e.g.,
  `"nascita"`, `"cittadinanza"`). Valid values are defined per dataset
  in the demo registry.

## Value

Character string containing the full download URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Pattern A (year-indexed)
build_demo_url("D7B", year = 2024)

# Pattern A1 (year+locale)
build_demo_url("AIR", year = 2023)

# Pattern B (territory-indexed)
build_demo_url("POS", year = 2025, territory = "Comuni")

# Pattern C (level+type+year)
build_demo_url("TVM", year = 2024, level = "regionali", type = "completi")

# Pattern D (datatype-geolevel)
build_demo_url("PPR", data_type = "Previsioni-Popolazione_per_eta",
               geo_level = "Regioni")

# Pattern D without geo_level
build_demo_url("PRF", data_type = "Famiglie_per_tipologia_familiare")

# Pattern E (subtype-indexed)
build_demo_url("RCS", year = 2025, subtype = "cittadinanza")

# Pattern F (static file)
build_demo_url("TVA")

# Pattern G (year-indexed CSV)
build_demo_url("ISM", year = 2020)
} # }
```
