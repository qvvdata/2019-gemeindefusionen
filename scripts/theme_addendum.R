needs(showtext)
##################
# Notwendig für Schriftarten in Plots
##################
#library(showtext)
font_add("Sailec Medium", "Type Dynamic - Sailec Medium.otf")
font_add("Sailec Regular", "Type Dynamic - Sailec.otf")
font_add("Martha", "Martha-Regular.otf")
#Automatische Ersetzung
showtext.auto()
#-------------------------------


theme_addendum <- function(base_family = "Sailec Regular", base_size = 14, ticks = FALSE) {
  ## TODO: start with theme_minimal
  ret <- theme_bw(base_size = base_size) +
    theme(legend.background = element_blank(),
          legend.key = element_blank(),
          # legend.text = element_text(size= 11, face = "plain", family = "Sailec Regular"),
          panel.background = element_blank(),
          panel.border = element_blank(),
          strip.background = element_blank(),
          plot.background = element_blank(),
          plot.title = element_text(size= 21, face = "plain", family = "Sailec Medium"),
          plot.subtitle = element_text(size = 14, colour = "black", family = "Sailec Regular"),
          plot.caption = element_text(family = "Martha", size = 11, vjust = 0.5),
          #axis.line = element_blank(),
          #panel.grid.minor = element_blank(),
          #panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour = "lightgrey",size=0.1),
          #axis.text.y = element_text(hjust=0),
          # axis.title.x=element_blank(),
          # axis.title.y=element_blank(),
          panel.spacing.y = unit(2, "lines"),
          panel.grid.major = element_line(colour = "#e5e5e5",size=0.1),
          legend.position = c("top"),
          legend.title = element_blank(),
          legend.direction = "horizontal"
    )
  if (!ticks) {
    ret <- ret + theme(axis.ticks = element_blank())
  }
  ret
}
