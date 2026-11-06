# TP Data Visualisation — Accidents routiers en Île-de-France (2025)

Analyse des règles GoldenViz 7 à 16, puis étude du fichier officiel des accidents corporels, dans un **notebook Jupyter exécuté, avec ses sorties enregistrées**.

- **[Notebook exécuté — graphiques visibles](TP_Accidents_Routiers.ipynb)** : rendu principal. Les cellules Python et Markdown sont alternées ; les résultats et figures sont intégrés au fichier.
- **[Compte rendu Markdown](TP_Accidents_Routiers.md)** : même démarche, avec codes, tableaux calculés et interprétations. Certaines plateformes, dont GitHub, bloquent les images `data:` intégrées directement au Markdown ; pour voir les figures sur GitHub, ouvrir le notebook.
- `caract-2025.csv` : données source.
- `contours_departements_idf.geojson` : géométries vectorielles des huit départements, issues des contours IGN/INSEE, simplifiées et conservées localement pour une exécution reproductible.

## Exécution avec VS Code

Installer les extensions **Python** et **Jupyter**, puis les bibliothèques :

```bash
python -m pip install pandas numpy geopandas shapely matplotlib ipykernel
```

Ouvrir `TP_Accidents_Routiers.ipynb`, choisir le noyau Python et cliquer sur **Run All**. Enregistrer ensuite avec `Ctrl + S`. Les calculs ont déjà été exécutés pour les données 2025 : tu peux lire les résultats sans relancer le notebook.

Pour exporter de nouveau en Markdown dans VS Code : menu `…` du notebook, puis **Export → Markdown**, ou `jupyter nbconvert --to markdown TP_Accidents_Routiers.ipynb`. **Important :** cette conversion standard externalise souvent les figures en images ; elle ne donne pas un Markdown autonome avec carte rendue sur GitHub. La version `.md` du ZIP est déjà construite sans images séparées.

## Sources

- [Base BAAC 2025 — data.gouv.fr](https://www.data.gouv.fr/datasets/bases-de-donnees-annuelles-des-accidents-corporels-de-la-circulation-routiere-annees-de-2005-a-2025)
- [GoldenViz — règles de lisibilité](https://goldenviz.org/fr/readability.html)
- [Contours IGN/INSEE (GeoJSON simplifié)](https://github.com/gregoiredavid/france-geojson)
