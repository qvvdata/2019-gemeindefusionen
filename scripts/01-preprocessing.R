# Laden der Finanzgebarung nach Ansatz
ansatz <- read_excel("input/bessereheader/gemeindennachansatz.xlsx", fileEncoding="UTF-8") %>%
  mutate(gkz = as.numeric(gkz), 
         fj = as.numeric(fj))

# Laden der Finanzgebarung nach Posten
posten <- read_excel("input/bessereheader/gemeindennachposten.xlsx") %>%
  mutate(gkz = as.numeric(gkz), 
         fj = as.numeric(fj))

# Laden der Bevölkerungsdaten
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
  rename("name" = "gem.x")

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

# Laden der Urban-Rural-Typologie
urbanrural <- read_excel("input/originalfiles/urbanrural.xlsx", sheet="data") %>%
  mutate(gkz = as.numeric(gkz)
  ) %>%
  select(-name)

bezirke <-  read_excel("input/bessere_header/polbezirke2018.xls") %>%
  mutate(blkz = as.numeric(blkz),
         bezcode = as.numeric(bezcode),
         polbezcode = as.numeric(polbezcode))

gsr <- read_excel("input/bessereheader/2015gsr.xls", sheet="gsrliste")

#GRUPPEN EINRICHTEN




#Personal: 
# "Geldbezüge von Beamten der Verwaltung"                           
# "Geldbezüge der Beamten in handwerklicher Verwendung"             
# "Geldbezüge der Vertragsbediensteten der Verwaltung"              
# "Geldbezüge der Vertragsbediensteten in handwerklicher Verwendung"
# "Geldbezüge der ganzjährig beschäftigten Angestellten"     
#"sonstige Aufwandsentschädigungen"                                
#"Mehrleistungsvergütungen"     

#Energie: 
# "Strom"                                                           
# "Gas"                                                             
# "Wasser"                                                          
# "Wärme"  

#Amtsausstattung: Ein neues Gemeindeamt und das verschönert nach dem Zusammenzuzuziehen? 
# Durchschnittliche Steierungsrate der Energie / Personalkosten in allen sieben Bundesländern?
#Gewählte Gemeindeorgane: Aufwandsentschädigung je nach Größe der Gemeinde
#Fuhrpark: eiegener Bagger doer das Teilen von Rasenmähern?


# Steigerung der Aufwendungen pro Kopf und insgesamt?

