
<!-- README.md is generated from README.Rmd. Please edit that file -->

# foodaccess

<!-- badges: start -->
<!-- badges: end -->

This data-only package that provides a copy of the USDA’s Food Access
Research Atlas dataset. This dataset works in tandem with the package
fooddeserts, but it can also be used on its own to provide data about
the availability of groceries throughout the United States at a census
tract level.

The dataset covers census tracts from all 50 states plus the District of
Columbia. It contains 72531 observations with 147 features representing
demographic information about populations living in each census tract.

## Installation

You can install the development version of foodaccess like so:

``` r
devtools::install_github("Phioria/foodaccess")
```

## Example

``` r
library(foodaccess)
#str(foodaccess)
```
