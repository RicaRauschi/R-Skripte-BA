# Wildwechsel und Kameraplatzierung bei Paarhufern
### Bachelorarbeit - UNESCO-Biosphärenreservat Thüringer Wald

R-Skripte und räumliche Analysen zur Untersuchung von Wildwechseln, Kameraplatzierungen und Bewegungsverhalten von Paarhufern.

---

## Projektübersicht
Diese Repository enthält die R-Skripte, die für die statistischen Analysen, GIS-basierten Auswertungen und die Erstellung der Abbildungen meiner Bachelorarbeit verwendet wurden. Die Studie untersuchte räumliche Bewegungsstrukturen ("Wildwechsel") von Paarhufern sowie den Einfluss der Kameraplatzierung auf Erfassungsraten und aufgezeichnete Verhaltensmuster innerhalb der Kernzone *Vessertal-Nahetal-Stelzenwiesengrund* im UNESCO-Biosphärenreservat Thüringer Wald (Deutschland).

---

## Inhalt
- [Untersuchungsarten](#untersuchungsarten)
- [Forschungsschwerpunkte](#forschungsschwerpunkte)
- [Repository-Struktur](#repository-struktur)
- [Arbeitsablauf](#arbeitsablauf)
- [Methoden](#methoden)
- [Verwendete Software und Pakete](#verwendete-software-und-pakete)
- [Hinweise zu den Daten](#hinweise-zu-den-daten)
- [Reproduzierbarkeit](#reproduzierbarkeit)
- [Autorin(#autorin)

---

## Untersuchungsarten
| Deutscher Name | Wissenschaftlicher Name |
|---|---|
| Rothirsch | *Cervus elaphus* |
| Reh| *Capreolus capreolus* |
| Wildschwein | *Sus scrofa* |

---

## Forschungsschwerpunkte
Die Analysen konzentrierten sich auf:
- das räumliche Auftreten von Wildwechseln
- die Orientierung von Wildwechseln relativ zur Geländeform
- den Vergleich zufälliger und gezielter Kameraplatzierung
- Erfassungsraten und Verhaltensmuster
- GIS-basierte Umwelt- und Standortparameter
- bewegungsbezogenes Verhalten von Paarhufern
---

## Repository-Struktur
```text
├── 1 Analyse_der_Kovariaten.R
├── 2 Kameralaufzeit_Berechnung.R
├── 3 Prozent_Fehlauslösungen.R
├── 4 Räumliche Darstellung der Kamerastandorte und Artzusammensetzung.R
├── 5 Hypothese1_Erfassungsrate_nach_Kameraplatzierung.R
├── 6 Hypothese2_Hangparallel.R
├── 7 Hypothese3_Verhalten.R
└── README.md
```

## Arbeitsablauf
```text
Kamerafallen-Daten
      ↓
Datenbereinigung und Standardisierung
      ↓
Klassifikation unabhängiger Ereignisse
      ↓
Statistische Analyse
      ↓
GIS-basierte räumliche Analyses
      ↓
Visualisierung und Abbildungserstellung
```

---

## Methoden

### Statistische Analyses
- Wilcoxon-Rangsummen-Tests
- Chi-Quadrat-Tests
- Monte-Carlo-Permutationstests
- Effektstärkenschätzung
- Deskriptive Statistik

### Räumliche Analysen
- GIS-basierte Kovariatenextraktion
- Geländeanalysesn auf Basis digitaler Geländemodelle (DGM)
- Analyses der Wildwechselorientierung
- Distanzberechnungen auf Basis von OpenStreetMap-Daten

### Visualisierung
- ggplot2
- scatterpie
- sf
- ggspatial

---

## Verwendete Software und Pakete

<details>
<summary>Verwendete R-Pakete anzeigen</summary>

### Kernpakete
```r
library(dplyr)
library(ggplot2)
library(sf)
library(terra)
library(tidyr)
```

### Räumliche Analysen
```r
library(osmdata)
library(ggspatial)
library(scatterpie)
library(ggforce)
```

### Kamerafallenanalysen
```r
library(camtrapDensity)
```

</details>

---

## Hinweise zu den Daten
Dieses Repository enthält ausschließlich Analyseskripte. Rohdaten der Feldarbeit, Kamerafallenaufnahmen und GIS-Basisdaten sind nicht öffentlich enthalten. Einige Analysen erfordern lokale Raster- und Vektordatensätze, die nicht Bestandteil des Repositorys sind.

---

## Reproduzierbarkeit
Die Skripte wurden speziell für die im Rahmen der Bachelorarbeit durchgeführten Analysen entwickelt. Vor der Ausführung müssen lokale Datepfade gegebenenfalls angepasst werden.

---

## Autorin
Rica Rauschenberg
Universität Potsdam
2026

