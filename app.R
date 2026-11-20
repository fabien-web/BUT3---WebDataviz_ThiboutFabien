library(shiny)
library(bslib)
library(data.table)
library(ggplot2)
library(plotly)
library(leaflet)
library(sf)
library(DT)
library(viridisLite)


# 1 - Importation des données

donnees <- readRDS("donnees_preparees.rds")

prenoms <- donnees$prenoms
totaux <- donnees$totaux
France <- donnees$France
France_totaux <- donnees$France_totaux
geo <- donnees$geo

annees <- range(totaux$annee)

liste_prenoms <- sort(unique(prenoms$prenom))
liste_dpt <- setNames(geo$code, paste(geo$code, "-", geo$nom))


# 2 - Paramètres graphiques

theme_graphique <- theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "bottom",
    axis.title = element_text(colour = "#334155"),
    plot.background = element_rect(fill = "white", colour = NA)
  )


# Attribution d'une couleur fixe à chaque prénom

palette <- hcl.colors(60, palette = "Dynamic")

indices <- vapply(liste_prenoms, function(nom) {
  lettres <- utf8ToInt(enc2utf8(nom))
  sum(lettres * seq_along(lettres)) %% length(palette) + 1
}, numeric(1))

couleurs <- setNames(palette[indices], liste_prenoms)


# Formatage des effectifs et des axes

format_nombre <- function(x, decimales = 0) {
  formatC(x, format = "f", digits = decimales,
          big.mark = " ", decimal.mark = ",")
}

format_axe <- function(x) {
  ifelse(
    abs(x) >= 1000000,
    paste0(x / 1000000, "M"),
    ifelse(abs(x) >= 1000, paste0(x / 1000, "k"), x)
  )
}


# Présentation commune des blocs et des indicateurs

bloc <- function(titre, ...) {
  div(class = "bloc", h3(titre), ...)
}

indicateur <- function(titre, id) {
  div(class = "indicateur",
      h5(titre),
      textOutput(id))
}

graphique_barres <- function(data, unite) {
  
  ggplot(data, aes(x = reorder(prenom, valeur),
                   y = valeur,
                   fill = prenom)) +
    geom_col(width = 0.7) +
    coord_flip() +
    scale_fill_manual(
      values = couleurs[unique(data$prenom)],
      guide = "none"
    ) +
    scale_y_continuous(
      limits = c(0, NA),
      expand = expansion(mult = c(0, 0.08)),
      labels = format_axe
    ) +
    labs(x = NULL, y = unite) +
    theme_graphique
}


# 3 - Interface utilisateur

ui <- fluidPage(
  
  theme = bs_theme(
    version = 5,
    bg = "#F3F6FA",
    fg = "#172E46",
    primary = "#176B85"
  ),
  
  tags$head(
    tags$style(HTML("

      .container-fluid {
        max-width: 1800px;
        padding: 20px;
      }

      .header {
        background: #122D46;
        color: white;
        padding: 25px;
        border-radius: 12px;
        margin-bottom: 20px;
      }

      .header h1 {
        font-size: 30px;
        font-weight: bold;
        color: white;
      }

      .header p {
        color: #DCEAF4;
        margin-bottom: 5px;
      }

      .sidebar {
        background: #193953;
        color: white;
        padding: 20px;
        border-radius: 12px;
      }

      .sidebar h3 {
        color: white;
        font-size: 24px;
        font-weight: bold;
      }

      .sidebar h4 {
        color: white;
        font-size: 19px;
        font-weight: 600;
      }

      .sidebar label,
      .sidebar .shiny-text-output {
        color: white !important;
      }

      .sidebar hr {
        border-color: #A5BBCD;
        opacity: 0.5;
        margin: 25px 0;
      }

      .sidebar .btn {
        background: #31536D;
        color: white !important;
        border: 1px solid #68869D;
        font-size: 13px;
        font-weight: 600;
        min-height: 44px;
        white-space: normal;
      }

      .sidebar .btn:hover,
      .sidebar .btn:focus,
      .sidebar .btn:active {
        background: #267C96;
        color: white !important;
        border-color: #66C9E5;
      }

      .periode {
        background: white;
        color: #193953 !important;
        border-radius: 8px;
        text-align: center;
        padding: 14px;
        margin-bottom: 15px;
        font-size: 28px;
        font-weight: bold;
      }

      .sidebar .periode .shiny-text-output {
        color: #193953 !important;
      }

      .sidebar .shiny-options-group {
        background: #274B65;
        padding: 16px;
        border-radius: 8px;
        font-size: 18px;
        font-weight: bold;
      }

      .sidebar .form-check-input {
        width: 19px;
        height: 19px;
        cursor: pointer;
      }

      .sidebar .irs-grid-text {
        color: #DCEAF4 !important;
        font-size: 10px;
      }

      .sidebar .irs-grid-pol {
        background: #A5BBCD;
      }

      .sidebar .irs-line {
        background: #58758A;
      }

      .sidebar .irs-bar {
        background: #66C9E5;
      }

      .sidebar .irs-handle {
        background: white;
        border: 2px solid #66C9E5;
      }

      .sidebar .irs-from,
      .sidebar .irs-to,
      .sidebar .irs-single {
        background: #267C96;
        color: white;
      }

      .sidebar .irs-min,
      .sidebar .irs-max {
        background: #31536D;
        color: white;
      }

      .bloc {
        background: white;
        border: 1px solid #E0E7EE;
        border-radius: 12px;
        padding: 20px;
        margin-bottom: 20px;
      }

      .bloc h3 {
        font-size: 19px;
        font-weight: bold;
        margin-bottom: 20px;
      }

      .indicateur {
        background: white;
        border: 1px solid #E0E7EE;
        border-radius: 12px;
        padding: 20px;
        margin-bottom: 20px;
        min-height: 115px;
      }

      .indicateur h5 {
        font-size: 13px;
        color: #64748B;
        text-transform: uppercase;
      }

      .indicateur .shiny-text-output {
        font-size: 27px;
        font-weight: bold;
        color: #172E46;
        overflow-wrap: anywhere;
      }

      .analyse {
        background: #EDF5F8;
        border-left: 4px solid #176B85;
        padding: 15px;
        margin-top: 15px;
        border-radius: 5px;
        line-height: 1.6;
      }

      .instruction {
        background: #F1F5F9;
        border-radius: 6px;
        padding: 12px;
        margin-bottom: 18px;
        font-size: 13px;
        color: #334155;
        line-height: 1.5;
      }

      .note {
        font-size: 12px;
        color: #64748B;
        margin-top: 10px;
        line-height: 1.5;
      }

      .sidebar .note {
        color: #DCEAF4;
      }

      .tab-content {
        padding-top: 20px;
      }

      .nav-link {
        font-weight: 600;
      }

      .legende {
        max-height: 150px;
        overflow-y: auto;
        display: flex;
        flex-wrap: wrap;
        gap: 10px 15px;
        padding-top: 15px;
        font-size: 12px;
      }

      .legende-couleur {
        display: inline-block;
        width: 13px;
        height: 13px;
        margin-right: 5px;
        border-radius: 2px;
        border: 1px solid #BFCBD5;
      }

      .leaflet-container {
        background: #EDF2F6;
        border-radius: 8px;
      }

      @media (max-width: 768px) {
        .sidebar {
          margin-bottom: 20px;
        }

        .container-fluid {
          padding: 10px;
        }
      }

    "))
  ),
  
  div(
    class = "header",
    h1("Prénoms de France"),
    p("Explorer l'évolution des prénoms et leurs différences territoriales"),
    tags$small("Source : INSEE | 1900 - 2022")
  ),
  
  fluidRow(
    
    # Bandeau latéral : filtres communs aux trois onglets
    
    column(
      width = 3,
      
      div(
        class = "sidebar",
        
        h3("Filtres d'analyse"),
        hr(),
        
        h4("Période sélectionnée"),
        
        div(
          class = "periode",
          textOutput("periode_label")
        ),
        
        sliderInput(
          "periode", NULL,
          min = annees[1],
          max = annees[2],
          value = c(2000, 2022),
          step = 1,
          sep = "",
          width = "100%"
        ),
        
        fluidRow(
          column(6, actionButton("p1", "1900 - 1949",
                                 width = "100%")),
          column(6, actionButton("p2", "1950 - 1999",
                                 width = "100%"))
        ),
        
        br(),
        
        fluidRow(
          column(6, actionButton("p3", "2000 - 2022",
                                 width = "100%")),
          column(6, actionButton("p4", "Toute la période",
                                 width = "100%"))
        ),
        
        hr(),
        
        h4("Sexe à la naissance"),
        
        checkboxGroupInput(
          "sexe", NULL,
          choices = c("Masculin" = 1, "Féminin" = 2),
          selected = c(1, 2)
        ),
        
        textOutput("sexe_label"),
        
        hr(),
        
        actionButton(
          "reset", "Réinitialiser les filtres",
          width = "100%"
        ),
        
        div(
          class = "note",
          "Ces filtres s'appliquent à l'ensemble de l'application.
          Lorsque les deux sexes sont sélectionnés, leurs effectifs
          sont additionnés."
        ),
        
        hr(),
        
        div(
          class = "note",
          "Source : fichier départemental des prénoms de l'INSEE.
          Les années antérieures à 1946 présentent des limites
          d'exhaustivité. Les effectifs utilisés correspondent
          uniquement aux données publiées."
        )
      )
    ),
    
    
    # Contenu principal de l'application
    
    column(
      width = 9,
      
      tabsetPanel(
        
        # Onglet 1 - Cartographie
        
        tabPanel(
          "Carte de France",
          
          fluidRow(
            column(4, indicateur("Attributions publiées", "k_total")),
            column(4, indicateur("Prénom dominant", "k_nom")),
            column(4, indicateur("Territoires renseignés", "k_dept"))
          ),
          
          fluidRow(
            
            column(
              8,
              
              bloc(
                "Répartition géographique des prénoms",
                
                radioButtons(
                  "mode_carte", "Mode de représentation",
                  choices = c(
                    "Prénom dominant" = "dominant",
                    "Popularité d'un prénom" = "popularite"
                  ),
                  inline = TRUE
                ),
                
                conditionalPanel(
                  condition = "input.mode_carte == 'popularite'",
                  
                  selectizeInput(
                    "prenom_carte", "Choisir un prénom",
                    choices = NULL
                  )
                ),
                
                selectInput(
                  "zone", "Zone géographique",
                  choices = c(
                    "France métropolitaine" = "metro",
                    "Guadeloupe" = "971",
                    "Martinique" = "972",
                    "Guyane" = "973",
                    "La Réunion" = "974",
                    "Mayotte" = "976"
                  )
                ),
                
                leafletOutput("carte", height = "550px"),
                
                uiOutput("legende"),
                
                div(class = "note",
                    textOutput("avertissement_carte")),
                
                div(
                  class = "note",
                  "Survolez un département pour consulter ses données.
                  Cliquez dessus pour afficher son classement.
                  En cas d'égalité, les prénoms concernés sont
                  indiqués au survol."
                )
              )
            ),
            
            column(
              4,
              
              bloc(
                "Classement local",
                
                div(
                  class = "instruction",
                  icon("hand-pointer"),
                  strong(" Sélectionnez un département sur la carte."),
                  br(),
                  "Le classement affiche alors les 10 prénoms les
                  plus attribués dans ce département. Par défaut,
                  il concerne la France entière."
                ),
                
                h5(textOutput("titre_local")),
                
                actionButton(
                  "reset_dept", "Revenir à la France",
                  width = "100%"
                ),
                
                plotlyOutput("top_local", height = "420px"),
                
                div(class = "analyse",
                    textOutput("analyse_carte"))
              )
            )
          )
        ),
        
        
        # Onglet 2 - Évolution temporelle
        
        tabPanel(
          "Évolution temporelle",
          
          bloc(
            "Paramètres de comparaison",
            
            fluidRow(
              
              column(
                7,
                
                selectizeInput(
                  "noms_temps", "Prénoms à comparer (6 maximum)",
                  choices = NULL,
                  multiple = TRUE,
                  options = list(maxItems = 6)
                )
              ),
              
              column(
                5,
                
                selectizeInput(
                  "dpt_temps", "Départements (vide = France)",
                  choices = liste_dpt,
                  multiple = TRUE
                )
              )
            ),
            
            radioButtons(
              "unite", "Indicateur",
              choices = c(
                "Pour 10 000 attributions" = "taux",
                "Effectif brut" = "nombre"
              ),
              inline = TRUE
            ),
            
            div(class = "note",
                textOutput("note_temps"))
          ),
          
          bloc(
            "Évolution annuelle des prénoms",
            
            plotlyOutput("courbes", height = "450px"),
            
            div(
              class = "note",
              "Une interruption dans une courbe indique une valeur
              non publiée et non une absence certaine d'attributions."
            )
          ),
          
          bloc(
            "Popularité par décennie",
            
            plotlyOutput("chaleur", height = "350px"),
            
            div(
              class = "note",
              "Les couleurs représentent le nombre d'attributions
              pour 10 000 attributions publiées.
              Les décennies sont limitées à la période sélectionnée.
              Les cellules grises correspondent aux valeurs non publiées."
            )
          ),
          
          bloc(
            "Pics de popularité",
            
            DTOutput("pics"),
            
            div(class = "analyse",
                textOutput("analyse_temps"))
          )
        ),
        
        
        # Onglet 3 - Classements et générations
        
        tabPanel(
          "Classements et générations",
          
          bloc(
            "Prénoms les plus attribués",
            
            fluidRow(
              
              column(
                6,
                
                selectInput(
                  "top_n", "Nombre de prénoms",
                  choices = c(10, 20, 50),
                  selected = 10
                )
              ),
              
              column(
                6,
                
                radioButtons(
                  "unite_top", "Indicateur",
                  choices = c(
                    "Effectif brut" = "nombre",
                    "Pour 10 000" = "taux"
                  ),
                  inline = TRUE
                )
              )
            ),
            
            uiOutput("top_ui"),
            
            div(class = "analyse",
                textOutput("analyse_top"))
          ),
          
          bloc(
            "Comparaison de deux générations",
            
            uiOutput("periodes_comparaison"),
            
            plotlyOutput("variations", height = "500px"),
            
            div(
              class = "note",
              "Les variations correspondent à la différence
              de popularité entre la génération B et la génération A.
              Seuls les prénoms publiés dans les deux périodes
              sont comparés."
            )
          ),
          
          bloc(
            "Résultats détaillés",
            
            DTOutput("table_variations"),
            
            div(class = "analyse",
                textOutput("analyse_variations"))
          )
        )
      )
    )
  ),
  
  div(
    class = "note",
    "Source : INSEE - Fichier des prénoms DPT2022.",
    br(),
    "Règles d'intégrité graphique appliquées :
    17, 18, 19, 20, 22, 24 et 25."
  )
)


# 4 - Serveur Shiny

server <- function(input, output, session) {
  
  
  # 4.1 - Gestion des filtres globaux
  
  periode <- reactive({
    req(input$periode)
    input$periode
  })
  
  sexes <- reactive({
    
    validate(
      need(length(input$sexe) > 0,
           "Sélectionnez au moins un sexe.")
    )
    
    as.integer(input$sexe)
  })
  
  output$periode_label <- renderText({
    
    paste(input$periode[1], "-", input$periode[2])
  })
  
  output$sexe_label <- renderText({
    
    if (length(input$sexe) == 2) {
      "Les deux sexes sélectionnés"
    } else if (length(input$sexe) == 0) {
      "Sélectionnez au moins un sexe"
    } else if (input$sexe == "1") {
      "Masculin uniquement"
    } else {
      "Féminin uniquement"
    }
  })
  
  observeEvent(input$p1, {
    updateSliderInput(session, "periode",
                      value = c(1900, 1949))
  })
  
  observeEvent(input$p2, {
    updateSliderInput(session, "periode",
                      value = c(1950, 1999))
  })
  
  observeEvent(input$p3, {
    updateSliderInput(session, "periode",
                      value = c(2000, 2022))
  })
  
  observeEvent(input$p4, {
    updateSliderInput(session, "periode",
                      value = annees)
  })
  
  observeEvent(input$reset, {
    
    updateSliderInput(session, "periode",
                      value = annees)
    
    updateCheckboxGroupInput(session, "sexe",
                             selected = c(1, 2))
  })
  
  
  # Chargement des prénoms côté serveur pour limiter
  # le volume de données envoyé au navigateur
  
  noms_defaut <- intersect(
    c("MARIE", "JEAN", "EMMA", "LUCAS"),
    liste_prenoms
  )
  
  nom_carte_defaut <- intersect("LOUIS", liste_prenoms)
  
  if (length(noms_defaut) == 0) {
    noms_defaut <- head(liste_prenoms, 4)
  }
  
  if (length(nom_carte_defaut) == 0) {
    nom_carte_defaut <- liste_prenoms[1]
  }
  
  updateSelectizeInput(
    session, "prenom_carte",
    choices = liste_prenoms,
    selected = nom_carte_defaut,
    server = TRUE
  )
  
  updateSelectizeInput(
    session, "noms_temps",
    choices = liste_prenoms,
    selected = noms_defaut,
    server = TRUE
  )
  
  
  # 4.2 - Filtrage et agrégation des données
  
  national <- reactive({
    
    debut <- periode()[1]
    fin <- periode()[2]
    selection <- sexes()
    
    France[
      annee >= debut &
        annee <= fin &
        sexe %in% selection
    ]
  })
  
  total_national <- reactive({
    
    debut <- periode()[1]
    fin <- periode()[2]
    selection <- sexes()
    
    France_totaux[
      annee >= debut &
        annee <= fin &
        sexe %in% selection,
      sum(total)
    ]
  })
  
  departements <- reactive({
    
    debut <- periode()[1]
    fin <- periode()[2]
    selection <- sexes()
    
    prenoms[
      annee >= debut &
        annee <= fin &
        sexe %in% selection,
      .(nombre = sum(nombre)),
      by = .(dpt, prenom)
    ]
  })
  
  total_departements <- reactive({
    
    debut <- periode()[1]
    fin <- periode()[2]
    selection <- sexes()
    
    totaux[
      annee >= debut &
        annee <= fin &
        sexe %in% selection,
      .(total = sum(total)),
      by = dpt
    ]
  })
  
  
  # Calcul des taux pour comparer les générations
  # indépendamment du volume des attributions
  
  classement <- reactive({
    
    data <- national()[, .(nombre = sum(nombre)),
                       by = prenom]
    
    total <- total_national()
    
    validate(need(total > 0, "Aucune attribution publiée."))
    
    data[, taux := 10000 * nombre / total]
    
    data[order(-nombre, prenom)]
  })
  
  
  # 4.3 - Indicateurs principaux
  
  output$k_total <- renderText({
    
    format_nombre(total_national())
  })
  
  output$k_nom <- renderText({
    
    data <- classement()
    
    validate(need(nrow(data) > 0, "Aucun prénom"))
    
    paste(data[nombre == max(nombre), prenom],
          collapse = " / ")
  })
  
  output$k_dept <- renderText({
    
    nrow(total_departements())
  })
  
  
  # 4.4 - Cartographie des prénoms
  
  donnees_carte <- reactive({
    
    data <- departements()
    
    # Sélection du prénom dominant dans chaque département
    
    if (input$mode_carte == "dominant") {
      
      data <- data[, .SD[nombre == max(nombre)], by = dpt]
      
      data <- data[
        order(prenom),
        .(
          prenom = prenom[1],
          gagnants = paste(prenom, collapse = " / "),
          nombre = nombre[1]
        ),
        by = dpt
      ]
      
    } else {
      
      req(input$prenom_carte)
      
      nom <- input$prenom_carte
      
      data <- data[prenom == nom]
      
      data[, gagnants := prenom]
    }
    
    data <- merge(
      data, total_departements(),
      by = "dpt", all.x = TRUE
    )
    
    data[, taux := 10000 * nombre / total]
    
    data[!is.finite(taux), taux := NA_real_]
    
    # Association des statistiques aux contours géographiques
    
    carte <- geo
    
    indices <- match(carte$code, data$dpt)
    
    carte$prenom <- data$prenom[indices]
    carte$gagnants <- data$gagnants[indices]
    carte$nombre <- data$nombre[indices]
    carte$taux <- data$taux[indices]
    
    # Le découpage francilien a changé en 1968
    
    carte$historique <- periode()[1] < 1968 &
      carte$code %in% c("75", "78", "91", "92", "93", "94", "95")
    
    carte$prenom[carte$historique] <- NA
    carte$gagnants[carte$historique] <- NA
    carte$nombre[carte$historique] <- NA
    carte$taux[carte$historique] <- NA
    
    carte
  })
  
  zone_carte <- reactive({
    
    carte <- donnees_carte()
    
    if (input$zone == "metro") {
      
      carte[nchar(carte$code) == 2, ]
      
    } else {
      
      carte[carte$code == input$zone, ]
    }
  })
  
  
  # Palette continue pour la popularité relative d'un prénom
  
  palette_carte <- reactive({
    
    maximum <- max(c(1, donnees_carte()$taux),
                   na.rm = TRUE)
    
    colorNumeric(
      palette = viridis(100),
      domain = c(0, maximum),
      na.color = "#CBD5E1"
    )
  })
  
  output$carte <- renderLeaflet({
    
    carte <- zone_carte()
    
    validate(
      need(nrow(carte) > 0,
           "Aucun contour disponible pour ce territoire.")
    )
    
    if (input$mode_carte == "dominant") {
      
      carte$couleur <- unname(couleurs[carte$prenom])
      
      carte$couleur[is.na(carte$couleur)] <- "#CBD5E1"
      
    } else {
      
      pal <- palette_carte()
      
      carte$couleur <- pal(carte$taux)
    }
    
    carte$info <- ifelse(
      carte$historique,
      paste(carte$nom, "- Contours non comparables avant 1968"),
      ifelse(
        is.na(carte$nombre),
        paste(carte$nom, "- Aucune valeur publiée"),
        paste0(
          carte$code, " - ", carte$nom,
          " | ", carte$gagnants,
          " | ", format_nombre(carte$nombre), " attributions",
          " | ", format_nombre(carte$taux, 2), " pour 10 000"
        )
      )
    )
    
    limites <- st_bbox(carte)
    
    # Affichage des contours sans fond cartographique externe
    
    map <- leaflet(
      carte,
      options = leafletOptions(
        minZoom = 2,
        maxZoom = 12
      )
    ) |>
      addPolygons(
        layerId = ~code,
        fillColor = ~couleur,
        fillOpacity = 0.9,
        color = "white",
        weight = 1.5,
        opacity = 1,
        label = ~info,
        highlightOptions = highlightOptions(
          weight = 3,
          color = "#193953",
          fillOpacity = 1,
          bringToFront = TRUE
        )
      ) |>
      fitBounds(
        lng1 = unname(limites["xmin"]),
        lat1 = unname(limites["ymin"]),
        lng2 = unname(limites["xmax"]),
        lat2 = unname(limites["ymax"])
      )
    
    if (input$mode_carte == "popularite") {
      
      maximum <- max(c(1, donnees_carte()$taux),
                     na.rm = TRUE)
      
      map <- map |>
        addLegend(
          position = "bottomright",
          pal = palette_carte(),
          values = c(0, maximum, NA_real_),
          title = "Pour 10 000 attributions",
          na.label = "Non renseigné",
          opacity = 0.9
        )
    }
    
    map
  })
  
  output$legende <- renderUI({
    
    if (input$mode_carte != "dominant") {
      return(NULL)
    }
    
    noms <- sort(unique(na.omit(zone_carte()$prenom)))
    
    elements <- lapply(noms, function(nom) {
      
      tags$span(
        tags$span(
          class = "legende-couleur",
          style = paste0("background:", couleurs[nom])
        ),
        nom
      )
    })
    
    div(
      class = "legende",
      elements,
      
      tags$span(
        tags$span(
          class = "legende-couleur",
          style = "background:#CBD5E1"
        ),
        "Non renseigné ou non comparable"
      )
    )
  })
  
  output$avertissement_carte <- renderText({
    
    if (periode()[1] < 1968) {
      
      paste(
        "Les contours utilisés sont actuels.",
        "Sept départements franciliens sont grisés en raison",
        "du changement de découpage en 1968.",
        "La Corse est représentée comme un territoire unique.",
        "En cas d'égalité, la couleur correspond au premier",
        "prénom par ordre alphabétique."
      )
      
    } else {
      
      paste(
        "La Corse est représentée comme un territoire unique.",
        "Les premières données de Mayotte datent de 2012.",
        "En cas d'égalité, la couleur correspond au premier",
        "prénom par ordre alphabétique."
      )
    }
  })
  
  
  # 4.5 - Classement du département sélectionné sur la carte
  
  dpt_choisi <- reactiveVal(NULL)
  
  observeEvent(input$carte_shape_click, {
    
    dpt_choisi(input$carte_shape_click$id)
  })
  
  observeEvent(input$reset_dept, {
    dpt_choisi(NULL)
  })
  
  observeEvent(input$zone, {
    dpt_choisi(NULL)
  })
  
  observeEvent(input$reset, {
    dpt_choisi(NULL)
  })
  
  classement_local <- reactive({
    
    id <- dpt_choisi()
    
    if (is.null(id)) {
      
      classement()
      
    } else {
      
      validate(
        need(
          !(periode()[1] < 1968 &&
              id %in% c("75", "78", "91", "92", "93", "94", "95")),
          "Territoire non comparable avant 1968."
        )
      )
      
      data <- departements()[dpt == id]
      
      data[order(-nombre, prenom)]
    }
  })
  
  output$titre_local <- renderText({
    
    if (is.null(dpt_choisi())) {
      
      "France - Top 10"
      
    } else {
      
      paste(
        geo$nom[geo$code == dpt_choisi()],
        "- Top 10"
      )
    }
  })
  
  output$top_local <- renderPlotly({
    
    data <- copy(head(classement_local(), 10))
    
    validate(
      need(nrow(data) > 0,
           "Aucune donnée sur ce territoire.")
    )
    
    data[, valeur := nombre]
    
    graphique <- graphique_barres(
      data, "Attributions publiées"
    )
    
    ggplotly(graphique) |>
      config(displaylogo = FALSE)
  })
  
  output$analyse_carte <- renderText({
    
    data <- classement_local()
    
    validate(
      need(nrow(data) > 0, "Aucune donnée disponible.")
    )
    
    gagnants <- paste(
      data[nombre == max(nombre), prenom],
      collapse = " / "
    )
    
    paste0(
      "Prénom(s) en tête sur la période sélectionnée : ",
      gagnants, ", avec ",
      format_nombre(data$nombre[1]),
      " attributions publiées."
    )
  })
  
  
  # 4.6 - Évolution temporelle des prénoms
  
  series <- reactive({
    
    validate(
      need(length(input$noms_temps) > 0,
           "Sélectionnez au moins un prénom.")
    )
    
    debut <- periode()[1]
    fin <- periode()[2]
    selection <- sexes()
    noms <- input$noms_temps
    territoires <- input$dpt_temps
    
    # Utilisation des données nationales déjà agrégées
    # lorsqu'aucun département n'est sélectionné
    
    if (length(territoires) == 0) {
      
      data <- France[
        annee >= debut &
          annee <= fin &
          sexe %in% selection &
          prenom %in% noms
      ]
      
      total <- France_totaux[
        annee >= debut &
          annee <= fin &
          sexe %in% selection
      ]
      
    } else {
      
      data <- prenoms[
        annee >= debut &
          annee <= fin &
          sexe %in% selection &
          dpt %in% territoires &
          prenom %in% noms
      ]
      
      total <- totaux[
        annee >= debut &
          annee <= fin &
          sexe %in% selection &
          dpt %in% territoires
      ]
    }
    
    data <- data[
      , .(nombre = sum(nombre)),
      by = .(annee, prenom)
    ]
    
    total <- total[
      , .(total = sum(total)),
      by = annee
    ]
    
    # Conservation des années sans effectif publié
    # pour ne pas les assimiler à des valeurs nulles
    
    grille <- CJ(
      annee = seq(debut, fin),
      prenom = noms
    )
    
    data <- merge(
      grille, data,
      by = c("annee", "prenom"),
      all.x = TRUE
    )
    
    data <- merge(
      data, total,
      by = "annee",
      all.x = TRUE
    )
    
    data[, taux := 10000 * nombre / total]
    
    data[!is.finite(taux), taux := NA_real_]
    
    data[order(prenom, annee)]
  })
  
  output$note_temps <- renderText({
    
    if (length(input$dpt_temps) > 0 &&
        periode()[1] < 1968) {
      
      paste(
        "Attention : les séries utilisent les codes départementaux",
        "historiques de l'INSEE, dont les limites géographiques",
        "peuvent avoir évolué."
      )
      
    } else {
      
      "Les taux sont calculés sur les attributions publiées."
    }
  })
  
  
  # Construction des séries temporelles avec Plotly
  
  output$courbes <- renderPlotly({
    
    data <- copy(series())
    
    req(input$unite)
    
    data$valeur <- data[[input$unite]]
    
    validate(
      need(any(is.finite(data$valeur)),
           "Aucune donnée publiée sur cette période.")
    )
    
    unite <- if (input$unite == "taux") {
      "Attributions pour 10 000"
    } else {
      "Nombre d'attributions"
    }
    
    decimales <- if (input$unite == "taux") 2 else 0
    
    graphique <- plot_ly()
    
    for (nom in unique(data$prenom)) {
      
      serie <- data[prenom == nom]
      
      if (!any(is.finite(serie$valeur))) {
        next
      }
      
      texte <- paste0(
        nom,
        "<br>Année : ", serie$annee,
        "<br>", unite, " : ",
        format_nombre(serie$valeur, decimales)
      )
      
      graphique <- add_trace(
        graphique,
        x = serie$annee,
        y = serie$valeur,
        type = "scatter",
        mode = "lines+markers",
        name = nom,
        line = list(
          color = unname(couleurs[nom]),
          width = 2.5
        ),
        marker = list(
          color = unname(couleurs[nom]),
          size = 4
        ),
        text = texte,
        hoverinfo = "text",
        connectgaps = FALSE
      )
    }
    
    graphique |>
      layout(
        xaxis = list(
          title = "Année de naissance",
          tickformat = "d",
          showgrid = FALSE
        ),
        yaxis = list(
          title = unite,
          tickformat = "~s",
          rangemode = "tozero",
          gridcolor = "#E5E7EB"
        ),
        legend = list(
          orientation = "h",
          x = 0,
          y = -0.2
        ),
        margin = list(l = 75, r = 25, b = 100, t = 20),
        plot_bgcolor = "#FFFFFF",
        paper_bgcolor = "#FFFFFF",
        hovermode = "x unified"
      ) |>
      config(displaylogo = FALSE)
  })
  
  
  # 4.7 - Popularité par décennie
  
  output$chaleur <- renderPlotly({
    
    data <- copy(series())
    
    data[, decennie := floor(annee / 10) * 10]
    
    # Conversion en numérique pour garantir un type identique
    # entre les groupes contenant ou non des valeurs manquantes
    
    data[, nombre := as.numeric(nombre)]
    data[, total := as.numeric(total)]
    
    # Calcul du taux à partir des sommes d'effectifs
    
    data <- data[
      , .(
        nombre = if (all(is.na(nombre))) {
          NA_real_
        } else {
          sum(nombre, na.rm = TRUE)
        },
        total = sum(total, na.rm = TRUE)
      ),
      by = .(prenom, decennie)
    ]
    
    data[, taux := 10000 * nombre / total]
    
    data[!is.finite(taux), taux := NA_real_]
    
    matrice <- dcast(
      data,
      prenom ~ decennie,
      value.var = "taux"
    )
    
    valeurs <- as.matrix(matrice[, -1, with = FALSE])
    
    validate(
      need(any(is.finite(valeurs)),
           "Aucune donnée publiée pour les prénoms et la période sélectionnés.")
    )
    
    decennies <- as.numeric(names(matrice)[-1])
    
    etiquettes <- paste(
      pmax(decennies, periode()[1]),
      pmin(decennies + 9, periode()[2]),
      sep = "-"
    )
    
    plot_ly(
      x = etiquettes,
      y = matrice$prenom,
      z = valeurs,
      type = "heatmap",
      colorscale = "Viridis",
      zmin = 0,
      xgap = 2,
      ygap = 2,
      hoverongaps = FALSE,
      colorbar = list(
        title = "Pour 10 000"
      ),
      hovertemplate = paste0(
        "Prénom : %{y}<br>",
        "Période : %{x}<br>",
        "Popularité : %{z:.2f} pour 10 000",
        "<extra></extra>"
      )
    ) |>
      layout(
        xaxis = list(
          title = "Décennie",
          type = "category",
          tickangle = -45,
          showgrid = FALSE
        ),
        yaxis = list(
          title = "",
          showgrid = FALSE
        ),
        margin = list(l = 90, r = 40, b = 90, t = 10),
        plot_bgcolor = "#CBD5E1",
        paper_bgcolor = "#FFFFFF"
      ) |>
      config(displaylogo = FALSE)
  })
  
  
  # 4.8 - Identification des pics de popularité
  
  pics <- reactive({
    
    data <- copy(series())
    
    req(input$unite)
    
    data$valeur <- data[[input$unite]]
    
    data <- data[is.finite(valeur)]
    
    data <- data[
      , .(
        pic = paste(
          annee[valeur == max(valeur)],
          collapse = ", "
        ),
        valeur = max(valeur),
        total = sum(nombre)
      ),
      by = prenom
    ]
    
    data[order(-valeur)]
  })
  
  output$pics <- renderDT({
    
    titre_valeur <- if (input$unite == "taux") {
      "Pic pour 10 000"
    } else {
      "Effectif au pic"
    }
    
    datatable(
      pics(),
      rownames = FALSE,
      colnames = c(
        "Prénom",
        "Année(s) du pic",
        titre_valeur,
        "Attributions publiées"
      ),
      options = list(
        dom = "t",
        pageLength = 6
      )
    ) |>
      formatRound(
        "valeur",
        digits = if (input$unite == "taux") 2 else 0
      ) |>
      formatRound("total", digits = 0)
  })
  
  output$analyse_temps <- renderText({
    
    data <- pics()
    
    validate(
      need(nrow(data) > 0,
           "Aucune série disponible sur cette période.")
    )
    
    unite <- if (input$unite == "taux") {
      "attributions pour 10 000"
    } else {
      "attributions"
    }
    
    paste0(
      data$prenom[1],
      " présente le pic le plus élevé parmi les prénoms ",
      "sélectionnés, en ", data$pic[1], ", avec ",
      format_nombre(data$valeur[1],
                    if (input$unite == "taux") 2 else 0),
      " ", unite, ". ",
      "Les taux relatifs permettent de comparer les générations ",
      "en tenant compte du volume des attributions publiées."
    )
  })
  
  
  # 4.9 - Classement national
  
  output$top_ui <- renderUI({
    
    hauteur <- max(
      350,
      as.integer(input$top_n) * 25 + 80
    )
    
    plotlyOutput(
      "top_global",
      height = paste0(hauteur, "px")
    )
  })
  
  output$top_global <- renderPlotly({
    
    data <- copy(
      head(classement(), as.integer(input$top_n))
    )
    
    validate(
      need(nrow(data) > 0,
           "Aucun prénom publié.")
    )
    
    data$valeur <- data[[input$unite_top]]
    
    unite <- if (input$unite_top == "taux") {
      "Attributions pour 10 000"
    } else {
      "Attributions publiées"
    }
    
    graphique <- graphique_barres(data, unite)
    
    ggplotly(graphique) |>
      config(displaylogo = FALSE)
  })
  
  output$analyse_top <- renderText({
    
    data <- classement()
    
    validate(
      need(nrow(data) > 0, "Aucun résultat.")
    )
    
    concentration <- 100 * sum(head(data$nombre, 10)) /
      total_national()
    
    paste0(
      "Les dix prénoms les plus attribués représentent ",
      format_nombre(concentration, 2),
      " % des attributions publiées sur la période. ",
      "Une diminution de cette proportion entre deux périodes ",
      "traduit une moindre concentration autour des prénoms ",
      "dominants, sans mesurer à elle seule toute la diversité."
    )
  })
  
  
  # 4.10 - Comparaison de deux générations
  
  output$periodes_comparaison <- renderUI({
    
    debut <- periode()[1]
    fin <- periode()[2]
    
    if (debut == fin) {
      return(p("Sélectionnez au moins deux années."))
    }
    
    milieu <- floor((debut + fin) / 2)
    
    fluidRow(
      
      column(
        6,
        
        sliderInput(
          "periode_a", "Génération A",
          min = debut,
          max = fin,
          value = c(debut, milieu),
          sep = "",
          width = "100%"
        )
      ),
      
      column(
        6,
        
        sliderInput(
          "periode_b", "Génération B",
          min = debut,
          max = fin,
          value = c(milieu + 1, fin),
          sep = "",
          width = "100%"
        )
      )
    )
  })
  
  variations <- reactive({
    
    validate(
      need(diff(periode()) > 0,
           "Sélectionnez au moins deux années.")
    )
    
    req(input$periode_a, input$periode_b)
    
    a <- input$periode_a
    b <- input$periode_b
    
    debut <- periode()[1]
    fin <- periode()[2]
    selection <- sexes()
    
    validate(
      need(
        all(c(a, b) >= debut & c(a, b) <= fin) &&
          a[2] < b[1],
        "Les deux périodes ne doivent pas se chevaucher
        et la génération A doit précéder la génération B."
      )
    )
    
    # Agrégation des effectifs de chaque génération
    
    data_a <- national()[
      annee >= a[1] &
        annee <= a[2],
      .(nombre = sum(nombre)),
      by = prenom
    ]
    
    data_b <- national()[
      annee >= b[1] &
        annee <= b[2],
      .(nombre = sum(nombre)),
      by = prenom
    ]
    
    total_a <- France_totaux[
      annee >= a[1] &
        annee <= a[2] &
        sexe %in% selection,
      sum(total)
    ]
    
    total_b <- France_totaux[
      annee >= b[1] &
        annee <= b[2] &
        sexe %in% selection,
      sum(total)
    ]
    
    data_a[, taux_a := 10000 * nombre / total_a]
    
    data_b[, taux_b := 10000 * nombre / total_b]
    
    # Comparaison des prénoms publiés dans les deux périodes
    
    data <- merge(
      data_a[, .(prenom, taux_a)],
      data_b[, .(prenom, taux_b)],
      by = "prenom"
    )
    
    data[, ecart := taux_b - taux_a]
    
    data <- data[is.finite(ecart)]
    
    data[order(-ecart, prenom)]
  })
  
  
  # 4.11 - Gains et pertes de popularité
  
  output$variations <- renderPlotly({
    
    data <- variations()
    
    validate(
      need(nrow(data) > 0,
           "Aucun prénom commun aux deux périodes.")
    )
    
    hausses <- head(data[ecart > 0], 8)
    
    baisses <- head(data[ecart < 0][order(ecart)], 8)
    
    data <- rbind(hausses, baisses)
    
    validate(
      need(nrow(data) > 0,
           "Aucune variation.")
    )
    
    data[, tendance := ifelse(ecart > 0, "Hausse", "Baisse")]
    
    graphique <- ggplot(
      data,
      aes(
        x = reorder(prenom, ecart),
        y = ecart,
        fill = tendance
      )
    ) +
      geom_col(width = 0.7) +
      geom_hline(
        yintercept = 0,
        colour = "#172E46",
        linewidth = 0.8
      ) +
      coord_flip() +
      scale_fill_manual(
        values = c(
          "Hausse" = "#18877E",
          "Baisse" = "#BA6748"
        )
      ) +
      scale_y_continuous(
        labels = format_axe
      ) +
      labs(
        x = NULL,
        y = "Écart de popularité B - A (pour 10 000)",
        fill = NULL
      ) +
      theme_graphique
    
    ggplotly(graphique) |>
      config(displaylogo = FALSE)
  })
  
  output$table_variations <- renderDT({
    
    datatable(
      variations(),
      rownames = FALSE,
      colnames = c(
        "Prénom",
        "Popularité A",
        "Popularité B",
        "Écart B - A"
      ),
      options = list(
        pageLength = 10,
        order = list(list(3, "desc"))
      )
    ) |>
      formatRound(
        c("taux_a", "taux_b", "ecart"),
        digits = 2
      )
  })
  
  output$analyse_variations <- renderText({
    
    data <- variations()
    
    validate(
      need(nrow(data) > 0,
           "Aucun prénom commun.")
    )
    
    hausses <- data[ecart > 0]
    
    baisses <- data[ecart < 0][order(ecart)]
    
    texte_hausse <- if (nrow(hausses) > 0) {
      
      paste0(
        "La plus forte hausse concerne ",
        hausses$prenom[1],
        " (+", format_nombre(hausses$ecart[1], 2), ")."
      )
      
    } else {
      
      "Aucune hausse observée."
    }
    
    texte_baisse <- if (nrow(baisses) > 0) {
      
      paste0(
        "La plus forte baisse concerne ",
        baisses$prenom[1],
        " (", format_nombre(baisses$ecart[1], 2), ")."
      )
      
    } else {
      
      "Aucune baisse observée."
    }
    
    paste(
      texte_hausse,
      texte_baisse,
      "Ces écarts sont exprimés pour 10 000 attributions",
      "et concernent les prénoms publiés dans les deux générations."
    )
  })
}


# 5 - Lancement de l'application

shinyApp(ui = ui, server = server)