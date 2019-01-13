suppressPackageStartupMessages(library("dplyr"))
library(tidyr)

# 1. der name von remove_teilungen ist jetzt borderman_remove_teilungen
# 2. borderman() macht jetzt automatisch remove_teilungen mit
# 3. wenn du nur GKZ austauschen willst, kannst du einfach borderman_propagate_fusions machen – das entfernt allerdings auch keine teilungen!


borderman_fusionen_cache <- NULL

borderman_propagate_fusions <- function(df) {
  library("googlesheets")
  if(is.null(borderman_fusionen_cache)) {
    data <- gs_key('13vfbtcOrA95sw4McFjT1znVgzgdrMQjYtmOZ9w5oVIQ')
    borderman_fusionen_cache <<- gs_read_listfeed(data, ws = 'gemeindefusionen', col_names = TRUE)
  }
  fusionen <- borderman_fusionen_cache
  
  
  neuer_df <- df;
  j = 0;
  changes = 0;
  while(j==0 || changes != 0) {
    print(paste('propagate fusions', j))
    j=j+1;
    
    neuer_df <- neuer_df %>%
      left_join(fusionen, by=c(gkz='gkz_alt')) %>%
      mutate(gkz=case_when(is.na(gkz_neu) ~ as.numeric(gkz), TRUE ~ as.numeric(gkz_neu)))
    
    changes = nrow(neuer_df %>% filter(!is.na(gkz_neu)));
    neuer_df <- neuer_df %>%
      select(-gkz_neu,-name_neu,-jahr)
    
    if(j>10) {
      print('more than 10 iterations. assuming a fusion loop & quitting!')
      return(NULL);
    }
  }
  neuer_df
}

# propagate_fusions <- function(df, fusionen) {
#   # Takes two dataframes
#   # One containing the columns gkz (Gemeindekennziffer) and name (Gemeindename), and any number of columns containing number values
#   # The other containing columns gkz_alt,gkz_neu,name_alt,name_neu describing fusions of areas (like communes)
#   #
#   # Call example: propagate_fusions(bev,fusionen)
#   
#   neuer_df <- merge(x = df, y = fusionen, by.x = "gkz", by.y = "gkz_alt", all = TRUE)
#   j = 0;
#   changes = 0;
#   while(j==0 || changes != 0) {
#     j=j+1;
#     changes = 0;
#     for(i in 1:nrow(fusionen)) {
#       if(any(neuer_df$gkz_neu %in% fusionen[i,]$gkz_alt)) {
#         changes=changes+1;
#         neuer_df[neuer_df$gkz_neu %in% fusionen[i,]$gkz_alt, c("gkz_neu","name_neu")] = fusionen[i,c("gkz_neu","name_neu")]
#       }
#     }
#     print(changes)
#     if(j>10) {
#       print('more than 10 iterations. assuming a fusion loop & quitting!')
#       return(NULL);
#     }
#   }
#   neuer_df[is.na(neuer_df$gkz_neu) & neuer_df$gkz %in% fusionen$gkz_neu,]$name_neu = neuer_df[is.na(neuer_df$gkz_neu) & neuer_df$gkz %in% fusionen$gkz_neu,]$name
#   neuer_df[is.na(neuer_df$gkz_neu) & neuer_df$gkz %in% fusionen$gkz_neu,]$gkz_neu = neuer_df[is.na(neuer_df$gkz_neu) & neuer_df$gkz %in% fusionen$gkz_neu,]$gkz
#   neuer_df$gkz_neu[is.na(neuer_df$gkz_neu)] <- as.character(neuer_df$gkz[is.na(neuer_df$gkz_neu)])
#   
#   neuer_df$jahr <- NULL
#   data_colnames <- colnames(neuer_df)[!(colnames(neuer_df) %in% c('gkz_neu', 'gkz', 'name', 'name_neu'))]
#   
#   umgeformte_df <- neuer_df %>% gather(jahr, value, one_of(data_colnames))
#   #umgeformte_df$jahr <- as.numeric(umgeformte_df$jahr)
#   
#   #Raushauen von #NA-Spalten via Index, weil logische Spalten sonst nicht zum Loswerden
#   #umgeformte_df <- umgeformte_df[,-c(3:5)]
#   
#   if(nrow(umgeformte_df[is.na(umgeformte_df$value),])>0) {
#     umgeformte_df[is.na(umgeformte_df$value),]$value <- 0
#   }
#   #umgeformte_df %>% dplyr::group_by(gkz_neu, jahr)  %>% dplyr::summarise(ew = sum(ew))
#   
#   
#   tmp <- umgeformte_df %>% group_by(gkz_neu, jahr) %>% summarise(value = sum(value))
#   wide_tmp <- tmp %>% spread(jahr, value)
#   wide_tmp
# }


borderman_teilungen_cache <- NULL
borderman_remove_teilungen <- function(df) {
  library("googlesheets")
  if(is.null(borderman_teilungen_cache)) {
    data <- gs_key('13vfbtcOrA95sw4McFjT1znVgzgdrMQjYtmOZ9w5oVIQ')
    borderman_teilungen_cache <<- gs_read_listfeed(data, ws = 'teilung', col_names = TRUE)
  }
  teilungen <- borderman_teilungen_cache
  gkz_to_remove = unique(c(teilungen$gkz_neu,teilungen$gkz_alt))
  
  for(gkzcol in colnames(df)[grepl("gkz",colnames(df))]) {
    df <- df %>% filter(!(!!sym(gkzcol) %in% gkz_to_remove))
  }
  df
}


borderman <- function(df) {
  # Applies Austria's community mergers to a dataframe containing count values
  # Parameter df is a Dataframe containing the columns gkz (Gemeindekennziffer) and name (Gemeindename), and any number of columns containing number values
  #
  # Call example: borderman(bev) or borderman(arbeitslose)
  
  borderman_remove_teilungen(
    borderman_propagate_fusions(
      borderman_remove_teilungen(df))
  ) %>%
    group_by(gkz) %>%
    summarise_if(is.numeric, sum) %>%
    rename(gkz_neu=gkz)
}

borderman_test <- function() {
  data <- data.frame(
    gkz=c(41124,41519,41520,62248,62277,60802),
    name=c('schwertberg','a','b','c','d','e'),
    value=c(1,2,3,13,15,0.5))
  
  stopifnot(borderman_remove_teilungen(data) %>% filter(gkz==62248) %>% nrow()==0)
  stopifnot(borderman_remove_teilungen(data) %>% filter(gkz==62277) %>% nrow()==0)
  bmd <- borderman(data)
  stopifnot(bmd %>% filter(gkz_neu==41522) %>% summarise(value=sum(value)) %>% select(value) == 5)
  stopifnot(bmd %>% filter(gkz_neu==41124) %>% summarise(value=sum(value)) %>% select(value) == 1)
  stopifnot(bmd %>% filter(gkz_neu==62248) %>% nrow()==0)
  stopifnot(bmd %>% filter(gkz_neu==62277) %>% nrow()==0)
  
  print('borderman test successful')
}
#borderman_test()