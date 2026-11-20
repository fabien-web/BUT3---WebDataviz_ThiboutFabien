# Prénoms de France — 1900–2022

Tableau de bord interactif réalisé avec R Shiny dans le cadre du TP de visualisation des données. Il répond à la question suivante : **comment la popularité des prénoms a-t-elle évolué au fil des générations et selon les départements ?**

**Application en ligne :** à renseigner après le déploiement sur shinyapps.io.

## 1. Lancer l'application

Prérequis : R 4.1 ou supérieur, RStudio (facultatif), connexion Internet pour le premier téléchargement des limites géographiques et l'affichage du fond cartographique.

Dans la console R, depuis le dossier du projet :

```r
install.packages(c("shiny", "bslib", "data.table", "ggplot2", "plotly",
                   "leaflet", "sf", "DT", "viridisLite", "htmltools"))
shiny::runApp()
```

Au premier démarrage, `app.R` exécute automatiquement `preparation.R`, qui extrait temporairement le CSV, prépare les tables et télécharge les contours géographiques. Il crée `donnees_preparees.rds`, puis l'application exploite ce cache aux lancements suivants. Il est aussi possible de réaliser la préparation séparément :

```r
source("preparation.R")
shiny::runApp()
```

Pour refaire la préparation, supprimer le RDS, ou relancer `source("preparation.R")`. Ne pas renommer le ZIP d'origine. La préparation peut nécessiter un peu plus de mémoire et de temps lors du premier lancement. Sous Linux, `sf` nécessite les bibliothèques système GDAL, GEOS et PROJ si le package doit être compilé.

## 2. Structure du projet

```text
Prenoms_France/
├── dpt2022_csv.zip       # Données INSEE d'origine
├── preparation.R        # Toutes les transformations et la préparation géographique
├── app.R                # Interface et calculs réactifs
├── .gitignore
└── README.md
```

`donnees_preparees.rds` est produit localement et ignoré par Git. Il contient les prénoms nommés par année, sexe et département, les dénominateurs correspondants, les agrégats nationaux et les contours. Aucune donnée transformée ne doit être ajoutée au dépôt.

## 3. Données et méthode

- [INSEE, fichier des prénoms, millésime 2022 (publication du 4 juillet 2023)](https://www.insee.fr/fr/statistiques/7633685), fichier départemental fourni pour le TP.
- [Contours géographiques IGN, via france-geojson](https://github.com/gregoiredavid/france-geojson), fichier `departements-avec-outre-mer.geojson`, téléchargé au premier lancement.
- [GoldenViz — Intégrité des visualisations](https://goldenviz.org/fr/integrity.html).

Le fichier CSV contient 3 835 767 lignes. Après retrait des 39 333 lignes dont l'année et le département sont inconnus (`XXXX`, `XX`), il reste 3 796 434 lignes, 100 codes territoriaux (la Corse est regroupée), 123 années et 79 045 578 attributions publiées. On compte 16 226 prénoms distincts identifiables, tous sexes confondus, hors catégorie des prénoms rares.

Les transformations conservent les codes géographiques sous forme de texte. `_PRENOMS_RARES` est exclu des classements et conservé dans le dénominateur. Les effectifs sont ceux publiés dans le fichier départemental 2022, sans réutiliser les règles d'arrondi des éditions récentes.

Le taux utilisé est :

**Popularité = 10 000 × somme des effectifs publiés du prénom / somme de tous les effectifs publiés sur le périmètre sélectionné.**

Un taux de période est un ratio de sommes, pas une moyenne des taux annuels ou départementaux. Les deux sexes sont additionnés si les deux cases sont cochées, y compris pour les prénoms mixtes. Les absences de données ne sont pas transformées en zéros ; les classements, les agrégations et les comparaisons portent sur les valeurs disponibles. Les taux ne doivent pas être interprétés comme des proportions exactes de toutes les naissances françaises.

Les limites territoriales sont actuelles. Le code 20 correspond aux deux départements corses réunis. Les sept codes franciliens concernés par la réforme de 1968 (75, 78, 91 à 95) sont grisés sur la carte si le début de période précède 1968 ; ils ne sont pas exclus des agrégats nationaux. Les codes historiques peuvent cependant être sélectionnés dans les séries temporelles avec un avertissement. La couverture du fichier est moins exhaustive avant 1946 ; Le fichier contient des observations pour Mayotte à partir de 2012 ; la documentation indique une couverture à partir de 2013. Les observations de 2012 sont conservées, sans supposer une couverture complète.

## 4. Fonctionnalités

Les filtres de période et de sexe sont persistants dans le bandeau latéral et s'appliquent aux trois onglets. Les deux cases de sexe peuvent être cochées séparément ou ensemble. Des boutons permettent de sélectionner les grandes périodes générationnelles ; un curseur permet de choisir les années avec précision.

### Carte de France

- Carte interactive du prénom le plus attribué par territoire (Leaflet), ou carte du taux d'un prénom choisi.
- Accès à la métropole et à chacun des cinq DROM via le sélecteur de zone.
- Survol : effectif, taux et gagnants ex æquo ; la couleur représente le premier prénom par ordre alphabétique si plusieurs sont à égalité. Les couleurs proches ne signalent pas une proximité statistique entre prénoms.
- Clic sur un territoire : Top 10 local, retour à la France et interprétation dynamique.
- Les zones sans donnée publiée ou non comparables restent grises.

### Évolution temporelle

Comparaison interactive de six prénoms au maximum, en France ou sur plusieurs départements. Le choix entre effectifs et taux concerne les courbes et les pics. La heatmap affiche les taux par décennie sur la période sélectionnée. Les lacunes annuelles interrompent les lignes. Les pics sont recherchés uniquement parmi les années observées.

### Classements et générations

Top 10, 20 ou 50 des prénoms, indicateur de concentration du Top 10, comparaison entre deux sous-périodes disjointes et chronologiques à l'intérieur de la période globale, et tableau des différences de taux. Seuls les prénoms observés dans les deux sous-périodes sont comparés pour ne pas confondre non-diffusion et absence réelle.

## 5. Résultats et interprétation

Ces résultats descriptifs ont été calculés à partir du CSV départemental fourni, avec les mêmes filtres et agrégations que l'application ; ils ne correspondent pas au fichier national indépendant. Les effectifs de chaque colonne concernent le sexe indiqué.

| Période | 1er masculin | Effectif | 1er féminin | Effectif |
|---|---|---:|---|---:|
| 1900–1949 | Jean | 1 414 724 | Marie | 1 655 501 |
| 1950–1999 | Philippe | 480 706 | Marie | 522 671 |
| 2000–2022 | Lucas | 138 100 | Emma | 125 792 |
| 2022 | Gabriel | 4 885 | Jade | 3 418 |

Le premier résultat est un renouvellement des prénoms dominants : Jean et Marie structurent le début du XXe siècle, alors que Lucas et Emma arrivent en tête sur la période 2000–2022. En 2022, Gabriel et Jade passent en tête dans notre agrégation. Les périodes sont de longueurs différentes : les volumes bruts ne peuvent donc pas servir à comparer directement les niveaux de popularité.

La part des dix premiers prénoms, sexes réunis, diminue : **25,41 %** en 1900–1949, **10,65 %** en 1950–1999 et **7,79 %** en 2000–2022. Cette diminution témoigne d'une moindre concentration sur les prénoms dominants parmi les effectifs publiés. Elle est compatible avec une diversification des choix, sans démontrer à elle seule une hausse exhaustive de la diversité (couverture historique, confidentialité et durées de période différentes).

En 2022, sur le versant territorial, Gabriel est au premier rang masculin dans 34 codes territoriaux (égalités comprises), tandis qu'Ambre occupe le premier rang féminin dans 26 codes. Jade arrive pourtant en tête du total féminin agrégé. Remporter le plus grand nombre de territoires et cumuler le plus grand nombre d'attributions ne sont donc pas la même chose : les tailles de population diffèrent d'un département à l'autre.

## 6. Règles d'intégrité graphique

| Règle GoldenViz | Problème évité | Application |
|---|---|---|
| 17 — Échelle appropriée | Exagération des écarts | Les barres de classement démarrent à zéro. |
| 18 — Type de graphique | Encodage inadapté | Courbes pour le temps, barres pour les catégories, carte pour la dimension territoriale. |
| 19 — Palette continue | Fausses ruptures d'intensité | Palette séquentielle plasma (option C de viridis), valeurs absentes en gris. |
| 20 — Doubles axes | Comparaison trompeuse d'unités | Un seul axe d'ordonnées, choix explicite effectif/taux. |
| 22 — Rapport hauteur/largeur | Pentes artificiellement amplifiées ou aplaties | Courbes de hauteur 440 px, largeur responsive ; hauteur des classements ajustée au nombre de prénoms. |
| 24 — Couleurs catégorielles | Changement de sens d'une couleur | Couleur déterministe par prénom pour les cartes, courbes et classements ; palette distincte pour les hausses et baisses. |
| 25 — Référence zéro | Mauvaise lecture des variations signées | Ligne zéro visible sur le graphique des écarts. |

Les règles 21 (aires) et 23 (histogrammes) ne s'appliquent pas aux graphiques réalisés. Nous avons préféré des visualisations utiles à la problématique plutôt que d'ajouter des graphiques uniquement pour satisfaire des règles supplémentaires.

## 7. Publication sur shinyapps.io

1. Créer un compte sur [shinyapps.io](https://www.shinyapps.io/) et récupérer la commande de connexion depuis le tableau de bord (Account / Tokens).
2. Dans RStudio, depuis le dossier du projet :

```r
install.packages("rsconnect")
# Exécuter ici la commande rsconnect::setAccountInfo fournie par shinyapps.io.
rsconnect::deployApp(
  appDir = ".",
  appName = "prenoms-france",
  appFiles = c("app.R", "preparation.R", "dpt2022_csv.zip", "README.md")
)
```

L'application déployée prépare son cache au démarrage si celui-ci n'existe pas. L'instance doit disposer d'assez de RAM, d'un temps de démarrage suffisant et d'un accès au fichier GeoJSON distant. Si la préparation dépasse les limites de l'offre choisie, envisager de déployer le RDS directement sur shinyapps.io (sans jamais le committer sur GitHub), et ajouter temporairement `donnees_preparees.rds` à `appFiles`.

Copier ensuite l'URL réelle fournie par shinyapps.io au début de ce README, puis publier ces cinq fichiers sur GitHub. Ne pas committer les jetons de connexion ou le cache. Les données du TP sont publiques (INSEE) ; le ZIP source fait environ 14 Mo, ce qui permet son dépôt sur GitHub.

## 8. État de validation

Le fichier CSV a été inspecté et les résultats ci-dessus recalculés indépendamment. Le code a fait l'objet d'une vérification statique ; l'exécution R/Shiny et le téléchargement des contours n'ont pas pu être testés dans l'environnement de création. Le lancement local dans RStudio doit donc servir de test final avant publication.
