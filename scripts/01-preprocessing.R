library(tidyverse)
library(readxl)
library(sf)
library(rmapshaper)
source('./scripts/borderman.R')

#Laden der Finanzgebarung nach Ansatz
ansatz <- read_excel("input/bessereheader/gemeindennachansatz.xlsx") %>%
  mutate(gkz = as.numeric(gkz),
         fj = as.numeric(fj))
#ansatz_bordermanned <- ansatz %>% group_by(fj,hh,haushalt,ans3,bez) %>% do(borderman(.[,c('gkz','soll')]))

#saveRDS(ansatz_bordermanned, "output/ansatz_bordermanned.rds")
ansatz_bordermanned<- readRDS("output/ansatz_bordermanned.RDS")


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
         FJ = as.numeric(FJ))

# data_bordermanned <- data %>%
#   group_by(FJ,HH, ans2, post3) %>%
#   do((borderman(.[,c('gkz','SOLL')])))

#saveRDS(data_bordermanned, "output/data_bordermanned.rds")
data_bordermanned<- readRDS("output/data_bordermanned.RDS")


# Der Borderman macht ein Gather und Spread auf Werte mit 0, deshalb sind im File dann zu viele Werte bei Ansätzen, die es eigenltich nicht gibt --> entfernen
data <- data_bordermanned %>%
filter(SOLL !=0)%>%
  filter(SOLL >0)%>% # Überträge aus dem Vorjahr weg
  mutate(fj = as.numeric(FJ), 
         gkz_neu = as.numeric(gkz_neu), 
         hh = HH, 
         soll = SOLL)%>%
  ungroup() %>%
  select(fj, hh, ans2, post3, gkz_neu, soll)

# gsr15 <- read_excel("input/bessereheader/2015gsr.xls", sheet="gsrliste") %>% rename(gkz = gkz_neu) %>% select(gkz, gemtypneu, gsrbetr, gsrbeschreibung) %>% mutate(test =1) %>% filter(gemtypneu!="X")
# gsr15 %>% group_by(gkz, gemtypneu, gsrbetr, gsrbeschreibung) %>% do(borderman(.[,c('gkz','test')])) %>% select(-test)
# saveRDS(gsr15, "output/gsr15.rds")
gsr15<- readRDS("output/gsr15.RDS")

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
   select(-c(haushalt, bez))

ansatz2017 <- read_excel("input/bessereheader/Ansatz2017.xlsx", trim_ws = TRUE) %>%
   mutate(gkz = as.numeric(gem),
          fj = as.numeric(FJ))%>%
   rename(hh = HH,
          soll = SOLL) %>%
   select(-c(FJ, gem))

ansaetze_data <- bind_rows(ansatz2017, ansatz)

 ansaetze_data_bordermanned <- ansaetze_data %>% 
    group_by(fj,hh,ans3) %>%
    do(borderman(.[,c('gkz','soll')])) 
 
 ansaetze_data <- ansaetze_data_bordermanned %>%
   filter(soll!=0) # Entfernen neu hinzugefügter Nullmeldungen für nicht existente Kostenstellen

# Gefunden im Analyse-Schritt: gkz 62248, 62227, 62336 --> dürften nicht da sein --> lt Gabriel zu vernachlässigen


 
# Laden der Bevölkerungsdaten

mylabels <- c("Bis 500","501- 1.000","1.001- 1.500","1.501- 2.000","2.001- 2.500","2.501- 3.000" ,  
              "3.001- 5.000","5.001- 10.000","10.001- 20.000","20.001- 30.000","30.001- 50.000","50.001-100.000","100.001-200.000",
               "200.001-500.000","Über 1 000.000", "über 1 000.000")
my_breaks <- c(0, 500, 1000, 1500,2000,2500,3000,5000,10000,20000,30000,50000,100000,200000,500000,1000000,5000000)

gemeinden_vz <- read_excel("input/bessereheader/beventwicklung1910_2018.xlsx", sheet="bev_volkszaehlung")%>%
  gather(jahr, wert, `1910`:`2011`) %>%
  filter(jahr!="2011")%>%
  spread(jahr, wert)
gemeinden_reg <- read_excel("input/bessereheader/beventwicklung1910_2018.xlsx", sheet="bev_register") %>%
  rename("gem" = "gemeind")%>% 
  left_join(gemeinden_vz, by=c("gkz", "gkz")) %>%
  select(-`gem.y`) %>%
  gather(jahr, ew, `2002`:`2001`) %>%
  arrange(jahr) %>%
  rename("name" = "gem.x")%>%
  mutate(jahr=as.numeric(jahr)) %>%
  filter(jahr>=2010 & jahr<=2017) %>%
  mutate(gemgrklas = cut(ew, breaks=my_breaks, labels=mylabels))

#needs(rmapshaper)
# Laden der Geodaten
gde_18 <- read_sf("input/geo/gemeinden m bezirke 2018.geojson") %>%
  mutate(GKZ=as.character(GKZ)) %>%
  as('Spatial') %>%
  ms_simplify(keep=0.5, keep_shapes = T) %>%
  st_as_sf()

gde_18$BL = substring(gde_18$GKZ,0,1)
gde_18$BEZ = substring(gde_18$GKZ,0,3)
bundeslaendergrenzen <- gde_18 %>% group_by(BL) %>% summarise()
bezirksgrenzen <- gde_18 %>% group_by(BEZ) %>% summarise()


gde_18_2 <- read_sf("input/geo/grenzen_katastral_oesterreich_bev_2018.geojson") %>%
  mutate(GKZ=as.character(GKZ)) %>%
  as('Spatial') %>%
  #ms_simplify(keep=0.5, keep_shapes = T) %>%
  st_as_sf()
gde_18_2$BL = substring(gde_18_2$GKZ,0,1)
gde_18_2$BEZ = substring(gde_18_2$GKZ,0,3)

gde_18_2 <- gde_18_2 %>% group_by(GKZ) %>% summarise() 
gde_18_2$BEZ = substring(gde_18_2$GKZ,0,3)
bezirksgrenzen_2 <- gde_18_2 %>% group_by(BEZ) %>% summarise()

#Exportieren der Karte von 2018
map_2018 <- ggplot() +
  geom_sf(data = gde_18_2 %>%filter(gkz), color="black", size=0.1) +
  coord_sf()+
  #scale_fill_gradient2(low = "#84a07c", midpoint = 0, mid = "#f0edf1", high = "#ba2b58")+
  #labs(title = "Veränderung der Pro-Kopf-Kosten", caption = "Quelle: Statistik Austria, BEV.") +
  theme_map() +
  theme(panel.grid.major = element_line(colour = "white"))

plot(map_2014)
ggsave("output/ignore/map_2014.pdf", device="pdf")


# Laden der Urban-Rural-Typologie
urbanrural <- read_excel("input/bessereheader/urbanrural.xlsx", sheet="data") %>%
  mutate(gkz = as.numeric(gkz)
  ) %>%
  select(-name)

bezirke <-  read_excel("input/bessereheader/polbezirke2018.xls") %>%
  mutate(blkz = as.numeric(blkz),
         bezcode = as.numeric(bezcode),
         polbezcode = as.numeric(polbezcode))

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
   left_join(gemeinden_reg, by=c("gkz_neu"="gkz", "fj"="jahr")) %>% # für die Pro-Kopf-berechnung
   left_join(ansatz_bez, by=c("ans2"="ansatz")) %>% # Namen der Ansätze
   left_join(posten_bez, by=c("post3"="posten")) %>%  # Namen der Posten
   left_join(urbanrural, by = c("gkz_neu"="gkz")) %>% # Typologie hinzufügen
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
   left_join(gemeinden_reg, by=c("gkz_neu"="gkz", "fj"="jahr")) %>% # für die Pro-Kopf-berechnung
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




