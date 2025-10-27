WGIpkg
================
Richard Amegble
2025-10-26

## Introduction

This package allows to extract [Worldwide Governance Indicators
(WGI)](https://www.worldbank.org/en/publication/worldwide-governance-indicators).
Two mains functions are built to perform this extraction.

Indicator codes:

- `va` = Voice and Accountability
- `pv` = Political Stability/Absence of Violence
- `ge` = Government Effectiveness
- `rq` = Regulatory Quality
- `rl` = Rule of Law
- `cc` = Control of Corruption

## Extraction

The extraction can be done for whole set of countries, or for specific
list of countries or single country.

``` r
#devtools::install_github("Dzigbodi/WGIpkg")
library(WGIpkg)
```

Download the whole data set with six indicators

``` r
df <- read_wgi(startyear = 2020, endyear = 2022)

print(head(df))
```

    ## # A tibble: 6 × 7
    ##   codeindyr code  countryname  year indicator variable      value
    ##   <chr>     <chr> <chr>       <dbl> <chr>     <chr>         <dbl>
    ## 1 AFGcc2020 AFG   Afghanistan  2020 cc        estimate     -1.49 
    ## 2 AFGcc2020 AFG   Afghanistan  2020 cc        nsource       9    
    ## 3 AFGcc2020 AFG   Afghanistan  2020 cc        pctrank       4.76 
    ## 4 AFGcc2020 AFG   Afghanistan  2020 cc        pctranklower  0    
    ## 5 AFGcc2020 AFG   Afghanistan  2020 cc        pctrankupper 10.5  
    ## 6 AFGcc2020 AFG   Afghanistan  2020 cc        stddev        0.157

Download a specific indicator

``` r
df <- read_wgi(startyear = 2020, endyear = 2022,indicator = "va")
print(head(df))
```

    ## # A tibble: 6 × 7
    ##   codeindyr code  countryname  year indicator variable      value
    ##   <chr>     <chr> <chr>       <dbl> <chr>     <chr>         <dbl>
    ## 1 AFGva2020 AFG   Afghanistan  2020 va        estimate     -1.08 
    ## 2 AFGva2020 AFG   Afghanistan  2020 va        nsource       9    
    ## 3 AFGva2020 AFG   Afghanistan  2020 va        pctrank      19.8  
    ## 4 AFGva2020 AFG   Afghanistan  2020 va        pctranklower 13.5  
    ## 5 AFGva2020 AFG   Afghanistan  2020 va        pctrankupper 23.7  
    ## 6 AFGva2020 AFG   Afghanistan  2020 va        stddev        0.132

Download a specific estimate

``` r
df <- read_wgi(startyear = 2020, endyear = 2022,indicator = "va", variable = "estimate")
print(head(df))
```

    ## # A tibble: 6 × 7
    ##   codeindyr code  countryname  year indicator variable      value
    ##   <chr>     <chr> <chr>       <dbl> <chr>     <chr>         <dbl>
    ## 1 AFGva2020 AFG   Afghanistan  2020 va        estimate     -1.08 
    ## 2 AFGva2020 AFG   Afghanistan  2020 va        nsource       9    
    ## 3 AFGva2020 AFG   Afghanistan  2020 va        pctrank      19.8  
    ## 4 AFGva2020 AFG   Afghanistan  2020 va        pctranklower 13.5  
    ## 5 AFGva2020 AFG   Afghanistan  2020 va        pctrankupper 23.7  
    ## 6 AFGva2020 AFG   Afghanistan  2020 va        stddev        0.132
