library(tidyverse)
library(readxl)
library(sf)
library(rmapshaper)
source('./scripts/borderman.R')

#Funktion
`%not in%` <- function (x, table) is.na(match(x, table, nomatch=NA_integer_))

numerize <- function(data,vars){
  data = as.data.frame(data)
  variables <- colnames(data)
  variables <- variables[! variables %in% vars]
  for(i in variables){
    data[,i]<- as.numeric(data[,i])
    data[,i][is.na(data[,i])] <- 0
  }
  return(data)
}

needs(ggthemes)

# Zwei geteilte Gemeinden, die auf drei Gemeinden gemeindet wurden, aus der Analyse ausschließen
teilungen_exkl <- c("62336", "62349")



# Posten Daten reinladen 
fj10 <- read_excel("input/bessereheader/Gemeinden nach Posten_neu_AS2_2010.xlsx")
fj11 <- read_excel("input/bessereheader/Gemeinden nach Posten_neu_AS2_2011.xlsx")
fj12 <- read_excel("input/bessereheader/Gemeinden nach Posten_neu_AS2_2012.xlsx")
fj13 <- read_excel("input/bessereheader/Gemeinden nach Posten_neu_AS2_2013.xlsx")
fj14 <- read_excel("input/bessereheader/Gemeinden nach Posten_neu_AS2_2014.xlsx")
fj15 <- read_excel("input/bessereheader/Gemeinden nach Posten_neu_AS2_2015.xlsx")
fj16 <- read_excel("input/bessereheader/Gemeinden nach Posten_neu_AS2_2016.xlsx")
fj17 <- read_excel("input/bessereheader/Gemeinden nach Posten_neu_AS2all_2017.xlsx")

data <- bind_rows(fj10,fj11,fj12,fj13,fj14,fj15,fj16, fj17) %>%
  mutate(gkz = as.numeric(gem),
         FJ = as.numeric(FJ)) %>%
  filter(gkz %not in% teilungen_exkl)

 # data_bordermanned <- data %>%
 #    group_by(FJ,HH, ans2, post3) %>%
 #     do((borderman(.[,c('gkz','SOLL')])))
 # 
 # saveRDS(data_bordermanned, "output/data_bordermanned.rds")
data_bordermanned <- readRDS("output/data_bordermanned.rds") %>% filter(gkz_neu %not in% teilungen_exkl)


data <- data_bordermanned %>%
  filter(SOLL !=0)%>%
  filter(SOLL >0)%>% # Überträge aus dem Vorjahr weg
  mutate(fj = as.numeric(FJ), 
         gkz_neu = as.numeric(gkz_neu), 
         hh = HH, 
         soll = SOLL)%>%
  ungroup() %>%
  select(fj, hh, ans2, post3, gkz_neu, soll)

# GSR 2015 : Ist die Gemeinde von Zusammenlegungen betroffen?
gsr15 <- read_excel("input/bessereheader/2015gsr.xls", sheet="gsrliste") %>%
  rename(gkz = gkz_neu) %>% select(gkz, gemtypneu, gsrbetr, gsrbeschreibung) %>%
  filter(gemtypneu!="X")

#gsr15 %>% group_by(gkz, gemtypneu, gsrbetr, gsrbeschreibung) #%>% do(borderman(.[,c('gkz','test')])) %>% select(-test)
 
#saveRDS(gsr15, "output/gsr15.rds")
#gsr15<- readRDS("output/gsr15.RDS")
#gsr15 <- readRDS("output/ignore/gsr15.rds")

vfgh <- read_excel("input/bessereheader/2015gsr.xls", sheet="vfgh") %>% rename(gkz = gkz_neu) 

# braucht mehr Leistung
options(java.parameters = "- Xmx1024m")

#mapping laden
ansatz_bez <- read_excel("input/bessereheader/ansaetze.xlsx", sheet ="Ansätze") # %>% mutate(ans2 = as.numeric())
ansatz3_bez <- read_excel("input/bessereheader/mapping.xlsx", sheet ="ansaetze", trim_ws=TRUE) 
posten_bez <- read_excel("input/bessereheader/mapping.xlsx", sheet ="posten", trim_ws=TRUE)
haushalt_bez <- read_excel("input/bessereheader/mapping.xlsx", sheet ="haushalt", trim_ws=TRUE)

# 0. Borderman auf alles
# 1. Merge der Bezeichnungen ✅
# 2. Erstellen der Gruppen ✅
# 3. Merge der Bevölkerungszahlen ✅
# 4. Merge der Bezirke und Urban-Rural-Typologie ✅
# 5. Von der Gemeindestrukturreform betroffen mergen ✅
# 6. Kosten pro Kopf für die Verwaltung im Verlauf berechnen✅
# Werte unter 0 raushauen ✅


#Laden der Finanzgebarung nach Ansatz 
ansatz <- read_excel("input/bessereheader/gemeindennachansatz.xlsx", sheet ="fileref",  trim_ws = TRUE) %>%
   mutate(gkz = as.numeric(gkz),
          fj = as.numeric(fj)) %>%
   filter(gkz %not in% teilungen_exkl)%>%
   select(-c(haushalt, bez))

ansatz2017 <- read_excel("input/bessereheader/Ansatz2017.xlsx", trim_ws = TRUE) %>%
   mutate(gkz = as.numeric(gem),
          fj = as.numeric(FJ))%>%
  filter(gkz %not in% teilungen_exkl)%>%
   rename(hh = HH,
          soll = SOLL) %>%
   select(-c(FJ, gem))

 # ansaetze_data <- bind_rows(ansatz2017, ansatz)
 # 
 #  ansaetze_data_bordermanned <- ansaetze_data %>%
 #     group_by(fj,hh,ans3) %>%
 #     do(borderman(.[,c('gkz','soll')]))
 # 
 #  ansaetze_data <- ansaetze_data_bordermanned %>%
 #  filter(soll!=0) # Entfernen neu hinzugefügter Nullmeldungen für nicht existente Kostenstellen
 # 
 # saveRDS(ansaetze_data, "output/ansaetze_data.rds")
ansaetze_data <- readRDS("output/ansaetze_data.RDS")
 
# Laden der Bevölkerungsdaten und Zuteilung der Gemeindegrößenklassen
mylabels <- c("Bis 500","501- 1.000","1.001- 1.500","1.501- 2.000","2.001- 2.500","2.501- 3.000" ,  
              "3.001- 5.000","5.001- 10.000","10.001- 20.000","20.001- 30.000","30.001- 50.000","50.001-100.000","100.001-200.000",
               "200.001-500.000","Über 1 000.000", "über 1 000.000")
my_breaks <- c(0, 500, 1000, 1500,2000,2500,3000,5000,10000,20000,30000,50000,100000,200000,500000,1000000,5000000)

gemeinden_vz <- read_excel("input/bessereheader/beventwicklung1910_2018.xlsx", sheet="bev_volkszaehlung")%>%
  gather(jahr, wert, `1910`:`2011`) %>%
  filter(jahr!="2011")%>%
  spread(jahr, wert)

gemeinden_reg_all <- read_excel("input/bessereheader/beventwicklung1910_2018.xlsx", sheet="bev_register") %>%
  rename("gem" = "gemeind")%>% 
  left_join(gemeinden_vz, by=c("gkz", "gkz")) %>%
  select(-`gem.y`) %>%
  gather(jahr, ew, `2002`:`2001`) %>%
  arrange(jahr) %>%
  rename("name" = "gem.x")%>%
  mutate(jahr=as.numeric(jahr)) %>%
  filter(jahr>=2010 & jahr<=2017)


gemeinden_reg_wahl <- gemeinden_reg_all %>%
  mutate(gemgrklas = cut(ew, breaks=my_breaks, labels=mylabels))

#  gemeinden_reg <- gemeinden_reg_all %>%
#    group_by(gkz, name,jahr) %>%
#    do(borderman(.[,c('gkz','ew')])) %>%
#    group_by(gkz_neu, jahr) %>%
#    summarise(ew = sum(ew))%>%
#    mutate(gemgrklas = cut(ew, breaks=my_breaks, labels=mylabels))
# #
#  saveRDS(gemeinden_reg, "output/gemeinden_reg.rds")
gemeinden_reg <- readRDS("output/gemeinden_reg.RDS") 

#needs(rmapshaper)
# Laden der Geodaten
gde_18 <- read_sf("input/geo/gemeinden_2018_map_fusionen_inkl_splitter.geojson") %>%
  mutate(GKZ=as.character(GKZ)) %>%
  as('Spatial') %>%
  #ms_simplify(keep=0.5, keep_shapes = T) %>%
  st_as_sf()

gde_18$BL = substring(gde_18$GKZ,0,1)
gde_18$BEZ = substring(gde_18$GKZ,0,3)
bundeslaendergrenzen <- gde_18 %>% group_by(BL) %>% summarise()
bezirksgrenzen <- gde_18 %>% group_by(BEZ) %>% summarise()


gde_18_2 <- read_sf("input/geo/gemeinden_2018_katastral_oktober.geojson") %>%
  mutate(GKZ=as.numeric(GKZ)) %>%
  as('Spatial') %>%
  #ms_simplify(keep=0.5, keep_shapes = T) %>%
  st_as_sf()
gde_18_2$BL = substring(gde_18_2$GKZ,0,1)
gde_18_2$BEZ = substring(gde_18_2$GKZ,0,3)

gde_18_2 <- gde_18_2 %>% group_by(GKZ) %>% summarise() 
gde_18_2$BEZ = substring(gde_18_2$GKZ,0,3)
bezirksgrenzen_2 <- gde_18_2 %>% group_by(BEZ) %>% summarise()

#write_sf(gde_18_2, "output/gde_18_2.geojson", quiet = TRUE)

gde_18_2_splitter <- read_sf("input/geo/gde_18_2_splitter.geojson") %>%
  mutate(GKZ=as.numeric(GKZ)) %>%
  as('Spatial') %>%
  #ms_simplify(keep=0.5, keep_shapes = T) %>%
  st_as_sf()






#Exportieren der Karte von 2018
map_2018 <- ggplot() +
  geom_sf(data = gde_18_2 %>%filter(GKZ <70000 & GKZ >60000), color="black", size=0.1) +
  coord_sf()+
  #scale_fill_gradient2(low = "#84a07c", midpoint = 0, mid = "#f0edf1", high = "#ba2b58")+
  #labs(title = "Veränderung der Pro-Kopf-Kosten", caption = "Quelle: Statistik Austria, BEV.") +
  theme_map() +
  theme(panel.grid.major = element_line(colour = "white"))

plot(map_2018)
ggsave("output/ignore/map_2018.pdf", device="pdf")


# Laden der Urban-Rural-Typologie
urbanrural <- read_excel("input/bessereheader/urbanrural.xlsx", sheet="data") %>%
  mutate(gkz = as.numeric(gkz)
  ) %>%
  select(-name)

bezirke <-  read_excel("input/bessereheader/polbezirke2018.xls") %>%
  mutate(blkz = as.numeric(blkz),
         bezcode = as.numeric(bezcode),
         polbezcode = as.numeric(polbezcode))

#Laden der alten GEmeindedaten für visuellen Vergleich
gde_14 <- read_sf("input/geo/gemeinden_2014_4_wgs.geojson") %>%
  mutate(GKZ=as.numeric(GKZ)) %>%
  as('Spatial') %>%
  #ms_simplify(keep=0.5, keep_shapes = T) %>%
  st_as_sf() %>%
  group_by(GKZ) %>%
  summarise() %>%
  filter(GKZ <70000 & GKZ >60000)

gde_14$BL = substring(gde_14$GKZ,0,1)
gde_14$BEZ = substring(gde_14$GKZ,0,3)
bundeslaendergrenzen14 <- gde_14 %>% group_by(BL) %>% summarise()
bezirksgrenzen <- gde_14 %>% group_by(BEZ) %>% summarise()

#Exportieren der Karte vor 2014
map_2014 <- ggplot() +
  geom_sf(data = gde_14, color="black", size=0.1) +
  coord_sf()+
  #scale_fill_gradient2(low = "#84a07c", midpoint = 0, mid = "#f0edf1", high = "#ba2b58")+
  #labs(title = "Veränderung der Pro-Kopf-Kosten", caption = "Quelle: Statistik Austria, BEV.") +
  theme_map() +
  theme(panel.grid.major = element_line(colour = "white"))

plot(map_2014)
ggsave("output/ignore/map_2014.pdf", device="pdf")

# Zusammenführen der Datensätze
 data_tt <- data %>%
   filter(ans2!="72" & ans2!="19") %>% # Das sind 5 Zeilen, die Buchungsfehler sind
   left_join(gemeinden_reg, by=c("gkz_neu"="gkz_neu", "fj"="jahr")) %>% # für die Pro-Kopf-berechnung
   left_join(ansatz_bez, by=c("ans2"="ansatz")) %>% # Namen der Ansätze
   left_join(posten_bez, by=c("post3"="posten")) %>%  # Namen der Posten
   #left_join(urbanrural, by = c("gkz_neu"="gkz")) %>% # Typologie hinzufügen
   left_join(gsr15, by=c("gkz_neu" = "gkz")) %>% # von Gemeindestrukturreform betroffen?
   rename(posten_bez = `bezeichnung.y`, 
          ansatz_bez = `bezeichnung.x`)

#   needs(openxlsx)
#  write.xlsx(data_tt, "output/ignore/data_tt.xls")
 
 #GRUPPEN EINRICHTEN
 personal <- c("Geldbezüge von Beamten der Verwaltung", "Geldbezüge der Beamten in handwerklicher Verwendung", 
               "Geldbezüge der Vertragsbediensteten der Verwaltung", "Geldbezüge der Vertragsbediensteten in handwerklicher Verwendung", 
               "Geldbezüge der ganzjährig beschäftigten Angestellten", "sonstige Aufwandsentschädigungen", "Mehrleistungsvergütungen", "Sonstige Nebengebühren")
 
 energie <- c("Strom", "Gas", "Wasser", "Wärme")
 
 gemeindereferate <- c("Standesamt", "Bauamt", "Amt für Raumordnung und Raumplanung", "Sozialamt", "Zentralamt")
 
#####################################

 

 posten_data <- data_tt %>%
   mutate(gruppe1 = ifelse(posten_bez %in% personal, "Personal", 
                           ifelse(posten_bez %in% energie, "Energie", "nope")), 
          gruppe = ifelse(gruppe1=="nope", posten_bez, gruppe1), 
          gkz_neu = as.numeric(gkz_neu)) %>%
   select(-gruppe1) %>%
   mutate(bezcode =  as.numeric(substr(gkz_neu, 0,3))) %>%
   left_join(bezirke, by=c("bezcode"="bezcode"))


 # Ansätze-Daten zusammenführen
 ansaetze_data_tt <- ansaetze_data %>%
   #filter(ans2!="72" & ans3!="19") %>% # Das sind 5 Zeilen, die Buchungsfehler sind
   left_join(gemeinden_reg, by=c("gkz_neu"="gkz_neu", "fj"="jahr")) %>% # für die Pro-Kopf-berechnung
   left_join(ansatz3_bez, by=c("ans3"="ansaetze")) %>% # Namen der Ansätze
   left_join(urbanrural, by = c("gkz_neu"="gkz")) %>% # Typologie hinzufügen
   left_join(gsr15, by=c("gkz_neu" = "gkz")) %>% # von Gemeindestrukturreform betroffen?
     mutate(gruppe1 = ifelse(bezeichnung %in% gemeindereferate, "gemeindereferate", "nope"), 
        gruppe = ifelse(gruppe1=="nope", bezeichnung, gruppe1), 
        gkz_neu = as.numeric(gkz_neu)) %>%
   select(-gruppe1)
 
 
ansaetze_data <- ansaetze_data_tt


 
#Bevölkerung und Zahl der Gemeinden 1961 bis 2011 nach der Gemeindegröße und Bundesländern (Gebietsstand: jeweiliger Erhebungsstichtag)
gemstruktur <- read_excel("input/bessereheader/gemeindegroessenklassenbundesländer1961bis2018.xlsx")%>%
gather(type,value, österreich_bev:wien_gemzahl)%>%
separate(type, into=c("bl", "typ"), sep="_")

##################################################
### DATEN FÜR POLITISCHE TEILHABE ################
##################################################

# Laden der Wahldaten 
ltwstmk2005 <- read_csv("input/bessereheader/ltwstmk2005.csv") %>% mutate(gkz = substr(GKZ, 2,6), jahr=2005, wahl= "ltw") %>% numerize(vars = c("Name","wahl")) %>% select(-GKZ)
ltwstmk2010 <- read_csv("input/bessereheader/ltwstmk2010.csv") %>% mutate(gkz = substr(GKZ, 2,6), jahr=2010, wahl= "ltw") %>% numerize(vars = c("Name","wahl")) %>% select(-GKZ)
ltwstmk2015 <- read_csv("input/bessereheader/ltwstmk2015.csv") %>% mutate(gkz = substr(GKZ, 2,6), jahr=2015, wahl= "ltw") %>% numerize(vars = c("Name","wahl")) %>% select(-GKZ)

nrw2008 <- read_csv("input/bessereheader/nrw2008.csv") %>% mutate(gkz = substr(GKZ, 2,6), jahr=2008, wahl= "nrw") %>% numerize(vars = c("Name","wahl")) %>% select(-GKZ)
nrw2013 <- read_csv("input/bessereheader/nrw2013.csv") %>% mutate(gkz = substr(GKZ, 2,6), jahr=2013, wahl= "nrw") %>% numerize(vars = c("Name","wahl")) %>% select(-GKZ)
nrw2017 <- read_csv("input/bessereheader/nrw2017.csv") %>% mutate(gkz = substr(GKZ, 2,6), jahr=2017, wahl= "nrw") %>% numerize(vars = c("Name","wahl")) %>% select(-GKZ)

#Reshape für Merge
ltwstmk2005 <- ltwstmk2005 %>%
  gather(partei, count, Wahlberechtigte:pf)

ltwstmk2010 <- ltwstmk2010 %>%
  gather(partei, count, Wahlberechtigte:puma)

ltwstmk2015 <- ltwstmk2015 %>%
  gather(partei, count, Wahlberechtigte:pirat)

nrw2008 <- nrw2008 %>%
  gather(partei, count, Wahlberechtigte:stark)

nrw2013 <- nrw2013 %>%
  gather(partei, count, Wahlberechtigte:m)

nrw2017 <- nrw2017 %>%
  gather(partei, count, Wahlberechtigte:m)


wahlen <- bind_rows(ltwstmk2005, ltwstmk2010, ltwstmk2015, nrw2008, nrw2013, nrw2017) %>% filter(gkz<70000 & gkz>60000)

# Borderman-Variante zerstört die Teilungen, deshalb unten anders gelöst
#wahlen_bordermanned <- wahlen %>% group_by(Name, gkz, jahr, wahl, partei) %>% do(borderman_propagate_fusions(.[,c('gkz','count')]))


# Teilungen raushauen, nicht mit Borderman, weil dann auch neue entfernt werden

teilungen <- c("61040", 
               "62227",
               "62248",
               "62336",
               "62349")

#wahlen_bordermanned <- wahlen_bordermanned %>% filter(gkz %not in% teilungen) %>% group_by(jahr, wahl, gkz, partei) %>% summarise(count = sum(count))

#wahlen_bordermanned_tw <- wahlen_bordermanned %>% group_by(jahr, wahl, gkz, partei) %>% summarise(count = sum(count)) %>% left_join(select(gemeinden_reg18, gkz, name.x), by=c("gkz"="gkz")) %>%rename(name = name.x)

#saveRDS(wahlen_bordermanned, "output/wahlen_bordermanned.rds")
wahlen_bordermanned<- readRDS("output/wahlen_bordermanned.RDS")


#testen, wie viele gemeinden in der steiermark enthalten sind
# wahltest <- wahlen_bordermanned_tw %>%
#   spread(partei, count) %>%
#   filter(jahr=="2005")
# Alles korrekt

names(posten_data)
# Endgütlige Namenszuweisung
gemeindenamen18 <- read_excel("input/bessereheader/gemeindenamen2018inklteilungsasterix.xlsx")
posten_data <- posten_data %>% left_join(gemeindenamen18, by=c("gkz_neu"="gkz_neu"))
ansaetze_data <- ansaetze_data %>% left_join(gemeindenamen18, by=c("gkz_neu"="gkz_neu")) %>%
  filter(gkz_neu %not in% teilungen_exkl)



