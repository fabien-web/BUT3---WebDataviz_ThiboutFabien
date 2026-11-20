library(data.table)
library(sf)

setwd("C:/Users/fabien/Documents/IUT/BUT 3 SD/Dataviz/Séance5")

# 1 - Importation des données

donnees <- fread("dpt2022.csv", sep = ";",
                 encoding = "UTF-8",
                 colClasses = c(dpt = "character",
                                annais = "character"))


# 2 - Nettoyage des données

# Suppression des années et départements inconnus
donnees <- donnees[annais != "XXXX" & dpt != "XX"]

setnames(donnees, c("annais", "preusuel"), c("annee", "prenom"))

donnees[, annee := as.integer(annee)]


# 3 - Agrégation des données départementales

# Les prénoms rares sont inclus dans les totaux,mais exclus des classements des prénoms
totaux <- donnees[, .(total = sum(nombre)),
                  by = .(annee, sexe, dpt)]

prenoms <- donnees[!prenom %in% c("_PRENOMS_RARES", "_PRENOMS_RARES_"),
                   .(nombre = sum(nombre)),
                   by = .(annee, sexe, dpt, prenom)]


# 4 - Agrégation des données nationales

France <- prenoms[, .(nombre = sum(nombre)),
                  by = .(annee, sexe, prenom)]

France_totaux <- totaux[, .(total = sum(total)),
                        by = .(annee, sexe)]


# Indexation des tables pour accélérer les filtres de Shiny
setkey(prenoms, annee, sexe, dpt)
setkey(totaux, annee, sexe, dpt)

setkey(France, annee, sexe)
setkey(France_totaux, annee, sexe)


# 5 - Récupération des contours géographiques

url <- "https://raw.githubusercontent.com/gregoiredavid/france-geojson/master/departements-avec-outre-mer.geojson"

geo <- st_read(url, quiet = TRUE)

geo <- geo[, c("code", "nom")]
geo <- st_make_valid(geo)
geo <- st_transform(geo, 4326)


# Fusion des deux départements corses, identifiés par le code 20 dans les données de l'INSEE
corse <- geo[geo$code %in% c("2A", "2B"), ]

corse <- st_union(st_transform(corse, 2154))
corse <- st_transform(corse, 4326)

corse <- st_sf(code = "20",
               nom = "Corse",
               geometry = corse)

geo <- geo[!geo$code %in% c("2A", "2B"), ]
geo <- rbind(geo, corse)


# 6 - Exportation des données pour Shiny

resultat <- list(
  prenoms = prenoms,
  totaux = totaux,
  France = France,
  France_totaux = France_totaux,
  geo = geo
)

saveRDS(resultat, "donnees_preparees.rds")
