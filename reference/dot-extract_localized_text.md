# Extract Localized Text from SDMX Multilingual Object

SDMX responses encode names and descriptions in multiple languages. This
helper extracts the Italian text when available, falling back to English
and then to the first available language.

## Usage

``` r
.extract_localized_text(text_obj)
```

## Arguments

- text_obj:

  An SDMX text object, which may be a character string, a named list
  (e.g., `list(it = "...", en = "...")`), or a list of
  `list(lang = "it", value = "...")` entries.

## Value

A single character string with the extracted text, or `NA_character_` if
no text is found.
