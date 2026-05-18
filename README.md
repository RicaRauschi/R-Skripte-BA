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
- [Systemvoraussetzungen](#systemvoraussetzungen)
- [Reproduzierbarkeit](#reproduzierbarkeit)
- [Autorin](#autorin)

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
├── data/                  # Eingabedaten (Tabellen, CamtrapDP, GIS-Layer)
├── renv.lock              # Gepinnte R-Paketversionen
├── renv/                  # renv-Projektbibliothek (von renv verwaltet)
├── .Rprofile              # aktiviert renv beim R-Start
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
GIS-basierte räumliche Analysen
      ↓
Visualisierung und Abbildungserstellung
```

---

## Methoden

### Statistische Analysen
- Wilcoxon-Rangsummentests
- Chi-Quadrat-Tests
- Monte-Carlo-Permutationstests
- Effektstärkenschätzung mit Cliff’s Delta
- Spearman-Rangkorrelationen
- Deskriptive Statistik

### Räumliche Analysen
- GIS-basierte Kovariatenextraktion
- Geländeanalysen auf Basis digitaler Geländemodelle (DGM)
- Analyse der Wildwechselorientierung
- Distanzberechnungen auf Basis von OpenStreetMap-Daten

### Visualisierung
- Erstellung statistischer Diagramme
- GIS-basierte Kartendarstellung
- Räumliche Visualisierung von Kamerastandorten
- Darstellung artspezifischer Nachweishäufigkeiten mittels Pie-Charts

---

## Verwendete Software und Pakete
Die Analysen wurden in **R** durchgeführt. Eingesetzt wurden:

- **Datenverarbeitung:** tidyverse-Pakete (`readxl`, `readr`, `dplyr`, `tidyr`, `stringr`)
- **Statistik:** `effsize`, `scales`
- **Räumliche Analysen und GIS:** `sf`, `terra`, `osmdata`
- **Visualisierung:** `ggplot2`, `ggspatial`, `scatterpie`, `ggforce`, `ggtext`, `cowplot`
- **Kamerafallenanalysen:** `camtrapDensity` (mit `camtraptor`)

Die exakten Paketversionen sind in [`renv.lock`](renv.lock) festgehalten und können mit `renv::restore()` reproduziert werden (siehe [Reproduzierbarkeit](#reproduzierbarkeit)).

---

## Hinweise zu den Daten
Das Repository enthält Analyseskripte sowie ausgewählte Datensätze, die für die Reproduzierbarkeit der Analysen erforderlich sind. Dazu gehören unter anderem Tabellen im `.xlsx`-Format, CamtrapDP-Dateien sowie GIS-basierte Raster- und Vektordaten.

Originale Kamerafallenaufnahmen, vollständige Rohdaten der Feldarbeit und sensible Standortinformationen sind nicht öffentlich enthalten.

---

## Systemvoraussetzungen
Die räumlichen R-Pakete (`sf`, `terra`, `osmdata`) binden native Bibliotheken ein, die vor der Paketinstallation auf System­ebene vorhanden sein müssen.

**macOS** (mit [Homebrew](https://brew.sh)):
```bash
xcode-select --install
brew install pkg-config gdal geos proj udunits sqlite tbb
```

**Debian / Ubuntu:**
```bash
sudo apt install build-essential pkg-config \
  libgdal-dev libgeos-dev libproj-dev libudunits2-dev libsqlite3-dev libtbb-dev
```

**Windows:** keine zusätzlichen Systempakete erforderlich – CRAN liefert vorkompilierte Binärpakete für `sf`, `terra` etc., die `renv::restore()` automatisch verwendet.

---

## Reproduzierbarkeit
Die R-Paketumgebung wird mit [renv](https://rstudio.github.io/renv/) verwaltet; alle Versionen sind in `renv.lock` gepinnt.

Empfohlener Ablauf für eine frische Installation:

1. **Systemabhängigkeiten installieren** (siehe [Systemvoraussetzungen](#systemvoraussetzungen)).
2. **R installieren** (Version ≥ 4.6 empfohlen, vergleiche `renv.lock`).
3. **renv installieren**, falls noch nicht vorhanden:
   ```r
   install.packages("renv")
   ```
4. **Projektbibliothek wiederherstellen** – im Projektverzeichnis R starten und ausführen:
   ```r
   renv::restore()
   ```
5. **Skripte ausführen.**

Lokale Dateipfade innerhalb der Skripte müssen gegebenenfalls an die eigene Umgebung angepasst werden.

---

## Autorin
Rica Rauschenberg
Universität Potsdam
2026

