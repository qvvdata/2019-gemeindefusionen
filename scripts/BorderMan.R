suppressPackageStartupMessages(library("dplyr"))
library(tidyr)


borderman_fusionen_cache <- NULL
propagate_fusions <- function(df, fusionen) {
  # Takes two dataframes
  # One containing the columns gkz (Gemeindekennziffer) and name (Gemeindename), and any number of columns containing number values
  # The other containing columns gkz_alt,gkz_neu,name_alt,name_neu describing fusions of areas (like communes)
  #
  # Call example: propagate_fusions(bev,fusionen)

  neuer_df <- merge(x = df, y = fusionen, by.x = "gkz", by.y = "gkz_alt", all = TRUE)
  j = 0;
  changes = 0;
  while(j==0 || changes != 0) {
    j=j+1;
    changes = 0;
    for(i in 1:nrow(fusionen)) {
      if(any(neuer_df$gkz_neu %in% fusionen[i,]$gkz_alt)) {
        changes=changes+1;
        neuer_df[neuer_df$gkz_neu %in% fusionen[i,]$gkz_alt, c("gkz_neu","name_neu")] = fusionen[i,c("gkz_neu","name_neu")]
      }
    }
    print(changes)
    if(j>10) {
      print('more than 10 iterations. assuming a fusion loop & quitting!')
      return(NULL);
    }
  }
  neuer_df[is.na(neuer_df$gkz_neu) & neuer_df$gkz %in% fusionen$gkz_neu,]$name_neu = neuer_df[is.na(neuer_df$gkz_neu) & neuer_df$gkz %in% fusionen$gkz_neu,]$name
  neuer_df[is.na(neuer_df$gkz_neu) & neuer_df$gkz %in% fusionen$gkz_neu,]$gkz_neu = neuer_df[is.na(neuer_df$gkz_neu) & neuer_df$gkz %in% fusionen$gkz_neu,]$gkz
  neuer_df$gkz_neu[is.na(neuer_df$gkz_neu)] <- as.character(neuer_df$gkz[is.na(neuer_df$gkz_neu)])

  neuer_df$jahr <- NULL
  data_colnames <- colnames(neuer_df)[!(colnames(neuer_df) %in% c('gkz_neu', 'gkz', 'name', 'name_neu'))]

  umgeformte_df <- neuer_df %>% gather(jahr, value, one_of(data_colnames))
  #umgeformte_df$jahr <- as.numeric(umgeformte_df$jahr)

  #Raushauen von #NA-Spalten via Index, weil logische Spalten sonst nicht zum Loswerden
  #umgeformte_df <- umgeformte_df[,-c(3:5)]

  if(nrow(umgeformte_df[is.na(umgeformte_df$value),])>0) {
    umgeformte_df[is.na(umgeformte_df$value),]$value <- 0
  }
  #umgeformte_df %>% dplyr::group_by(gkz_neu, jahr)  %>% dplyr::summarise(ew = sum(ew))


  tmp <- umgeformte_df %>% group_by(gkz_neu, jahr) %>% summarise(value = sum(value))
  wide_tmp <- tmp %>% spread(jahr, value)
  wide_tmp
}

borderman <- function(df) {
  # Applies Austria's community mergers to a dataframe containing count values
  # Parameter df is a Dataframe containing the columns gkz (Gemeindekennziffer) and name (Gemeindename), and any number of columns containing number values
  #
  # Call example: borderman(bev) or borderman(arbeitslose)

  library("googlesheets")
  if(is.null(borderman_fusionen_cache)) {
    data <- gs_key('13vfbtcOrA95sw4McFjT1znVgzgdrMQjYtmOZ9w5oVIQ')
    borderman_fusionen_cache <<- gs_read_listfeed(data, ws = 'gemeindefusionen', col_names = TRUE)
  }

  propagate_fusions(df, borderman_fusionen_cache)
}

remove_teilungen <- function(df) {
  library("googlesheets")
  data <- gs_key('13vfbtcOrA95sw4McFjT1znVgzgdrMQjYtmOZ9w5oVIQ')
  teilungen <- gs_read_listfeed(data, ws = 'teilung', col_names = TRUE)
  teilungen$check <- "true"
  teilungen <- subset(teilungen, select = c("gkz_alt", "check"))

  df_tmp <- merge(df, teilungen, by.x = "gkz_neu", by.y = "gkz_alt", all=T)

  df_tmp <- df_tmp[is.na(df_tmp$check),]
  df_tmp$check <- NULL
  df_tmp
}
