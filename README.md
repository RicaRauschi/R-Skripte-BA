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
├── 1_Analyse_der_Kovariaten.R
├── 2_Kameralaufzeit_Berechnung.R
├── 3_Prozent_Fehlauslösungen.R
├── 4_Räumliche_Darstellung_der_Kamerastandorte_und_Artzusammensetzung.R
├── 5_Hypothese1_Erfassungsrate_nach_Kameraplatzierung.R
├── 6_Hypothese2_Hangparallel.R
├── 7_Hypothese3_Verhalten.R
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
Mehrere der verwendeten R-Pakete (`sf`, `terra`, `osmdata`, `jqr`, `nloptr`, …) sind dynamisch mit nativen Bibliotheken verknüpft. Diese werden sowohl bei der Installation aus dem Quellcode als auch zur **Laufzeit** beim Laden der Pakete benötigt.

**macOS** (mit [Homebrew](https://brew.sh)):
```bash
brew install gdal geos proj udunits sqlite tbb jq cmake
```

**Debian / Ubuntu:**
```bash
sudo apt install \
  libgdal-dev libgeos-dev libproj-dev libudunits2-dev libsqlite3-dev libtbb-dev \
  libjq-dev cmake
```

**Windows:** keine zusätzlichen Systempakete erforderlich – `renv::restore()` verwendet die von CRAN bereitgestellten Binärpakete.

> Hinweis: Werden die R-Pakete aus dem Quellcode installiert (siehe Hinweis zu Homebrew-R in [Reproduzierbarkeit](#reproduzierbarkeit)), sind zusätzlich Build-Werkzeuge erforderlich – auf macOS die Xcode Command Line Tools (`xcode-select --install`) und `pkg-config`, auf Debian/Ubuntu `build-essential` und `pkg-config`.

---

## Reproduzierbarkeit
Die R-Paketumgebung wird mit [renv](https://rstudio.github.io/renv/) verwaltet; alle Versionen sind in `renv.lock` gepinnt.

Empfohlener Ablauf für eine frische Installation:

1. **Systemabhängigkeiten installieren** (siehe [Systemvoraussetzungen](#systemvoraussetzungen)).
2. **R installieren** (Version ≥ 4.6 empfohlen, vergleiche `renv.lock`). Bevorzugt das offizielle Installationspaket von [cran.r-project.org](https://cran.r-project.org/) verwenden – damit stehen vorgefertigte Binärpakete zur Verfügung und die Installation dauert nur wenige Minuten.
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

> Hinweis (macOS, Homebrew-R): Wer R über Homebrew installiert hat, verwendet aus Sicherheitsgründen ausschließlich Quellpakete (`pkgType = "source"`); die Installation kompiliert dann mehrere geospatiale Pakete lokal und dauert beim ersten Mal ca. 5 Minuten. Anschließende Restore-Aufrufe greifen auf den globalen renv-Cache zu und sind innerhalb von Sekunden abgeschlossen.

---

## Autorin
Rica Rauschenberg
Universität Potsdam
2026

