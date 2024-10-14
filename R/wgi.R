


#' load_wgi_indicator
#'
#' @import dplyr
#' @import tidyr
#' @import stringr
#' @import openxlsx
#'
#' @param indicatorname a indicator need to extract : VAB, PSV,GEN, RGQ, ROL, COF.
#' @return data.frame
#' @export
#' @examples
#' load_wgi_indicator("VAB")


load_wgi_indicator<-function(indicatorname){

  list_indicator<-c(VAB="VoiceandAccountability",
                    PSV="Political StabilityNoViolence",
                    GEN="GovernmentEffectiveness",
                    RGQ="RegulatoryQuality",
                    ROL="RuleofLaw",
                    COF="ControlofCorruption")

  urlfilename<-"https://www.worldbank.org/content/dam/sites/govindicators/doc/wgidataset.xlsx"
  temp_df<-read.xlsx(urlfilename,sheet=list_indicator[indicatorname], startRow=14, na.strings="#N/A")

  col_names<-str_replace_all(str_replace_all(paste(names(unlist(temp_df[1,])),unlist(temp_df[1,]), sep="_"), "X\\d{1}\\_",""), "\\/","\\_")
  temp_df<-temp_df[-1,]
  colnames(temp_df)<-col_names

  temp_df<-temp_df|>gather(key="Year_Name", value="Value", all_of(col_names[-c(1,2)]))|>
    separate(Year_Name, into=c("Year", "Variable"), sep="\\_")|>
    mutate(Value=as.numeric(Value), Year=as.integer(Year))|>
    mutate(Indicator=indicatorname)|>
    relocate(Indicator)

  return(temp_df)

}

#' read_wgi
#'
#' @import dplyr
#' @import tidyr
#' @import stringr
#' @import openxlsx
#' @param startyear start year
#' @param endyear end year
#' @param country vector of the countries , default is all the countries present in WGI.
#' @param variable Indicator name, default setting is all indicators
#' @param rm.na if it is FALSE preserve missing values, default is TRUE
#'
#' @return data.frame
#' @export
#'
#' @examples
#' wgi_df<-read_wgi(startyear=2021, endyear=2022)
read_wgi <- function(startyear=NULL, endyear=NULL, country=NULL, variable=NULL, rm.na=TRUE) {



  list_indicator<-c(VAB="VoiceandAccountability",
                    PSV="Political StabilityNoViolence",
                    GEN="GovernmentEffectiveness",
                    RGQ="RegulatoryQuality",
                    ROL="RuleofLaw",
                    COF="ControlofCorruption")


  wgi_df<-lapply(names(list_indicator), function(indicatorname){
    load_wgi_indicator(indicatorname)
  })|>
    bind_rows()

  yearlist<-unlist(unique(wgi_df$Year))
  if(is.null(startyear)){
    startyear<-min(yearlist)
  }
  if(is.null(endyear)){
    endyear<-max(yearlist)
  }

  if(is.null(country)){
    wgi_df<-wgi_df|>
      filter(Year>=startyear & Year<=endyear)
  }else{
    wgi_df<- wgi_df|>
      filter(Year>=startyear & Year<=endyear, country_Territory%in%country)

  }

  if(!is.null(variable)){
    wgi_df<-wgi_df|>filter(Variable%in%variable)
  }
  if(rm.na){
    wgi_df<-wgi_df|>filter(!is.na(Value))
  }
  return(wgi_df)
}
