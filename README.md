WGIpkg
================
Richard Amegble
2024-10-14

## Introduction

This package allows to extract [Worldwide Governance Indicators
(WGI)](https://www.worldbank.org/en/publication/worldwide-governance-indicators).
Two mains functions are built to perform this extraction.

## Extraction

The extraction can be done for whole set of countries, or for specific
list of countries or single country.

``` r
#devtools::install_github("Dzigbodi/WGIpkg")
```

Indicator

``` r
library(WGIpkg)
# Download Voice and Accountability represented by VAB
VAB_df<-load_wgi_indicator("VAB")

print(head(VAB_df))
```

    ##   Indicator Country_Territory Code Year Variable      Value
    ## 1       VAB             Aruba  ABW 1996 Estimate         NA
    ## 2       VAB           Andorra  ADO 1996 Estimate  1.5632167
    ## 3       VAB       Afghanistan  AFG 1996 Estimate -1.9085401
    ## 4       VAB            Angola  AGO 1996 Estimate -1.5781635
    ## 5       VAB          Anguilla  AIA 1996 Estimate         NA
    ## 6       VAB           Albania  ALB 1996 Estimate -0.6482978

Download the whole data set with six indicators

``` r
df<-read_wgi(startyear = 2020, endyear = 2022)

print(head(df))
```

    ##   Indicator    Country_Territory Code Year Variable       Value
    ## 1       VAB                Aruba  ABW 2020 Estimate  1.28214300
    ## 2       VAB              Andorra  ADO 2020 Estimate  1.08625340
    ## 3       VAB          Afghanistan  AFG 2020 Estimate -1.07768857
    ## 4       VAB               Angola  AGO 2020 Estimate -0.81600285
    ## 5       VAB              Albania  ALB 2020 Estimate  0.08640257
    ## 6       VAB United Arab Emirates  ARE 2020 Estimate -1.17824411
