# List Available Demographic Dataset Categories

Returns a sorted character vector of the thematic categories present in
the demo.istat.it dataset registry. These categories can be passed to
[`list_demo_datasets`](https://gmontaletti.github.io/istatlab/reference/list_demo_datasets.md)
for filtering.

## Usage

``` r
get_demo_categories()
```

## Value

A character vector of unique category names, sorted alphabetically.

## Examples

``` r
# See all available categories
cats <- get_demo_categories()
print(cats)
#> [1] "dinamica"      "indicatori"    "matrimoni"     "mortalita"    
#> [5] "natalita"      "popolazione"   "previsioni"    "unioni_civili"
```
