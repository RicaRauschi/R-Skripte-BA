# Wildlife Trails and Camera Trap Placement in Ungulates
### Bachelor Thesis - UNESCO Biosphere Reserve Thuringian Forest

R scripts and spatial analyses used for a bachelor thesis on wildlife trail ecology, camera trap placement and ungulate movement behaviour.

---

## Project Overview
This repository contains the R scripts used for the statistical analyses, GIS-based evaluations and figure creation for my bachelor thesis. The study investigaed spatial movement structures ("Wildlife trails") of ungulates and the influence of camera trap placement on detection rates and recorded behavioural patterns within the core zone *Vessertal-Nahetal-Stelzenwiesengrund* in the UNESCO Biosphere Reserve Thuringian Forest (Germany).

The bachelor thesis itself was written in German.

---

## Contents
- [Study Species](#study-species)
- [Research Focus](#research-focus)
- [Repository Structure](#repository-structure)
- [Workflow](#Workflow)
- [Main Methods](#main-methods)
- [Software and Packages](#software-and-packaged)
- [Data Notes](#data-notes)
- [Reproducibility](#reproducibility)
- [Author](#author)

---

## Study species
| Common name | Scientific name |
|---|---|
| Red deer | *Cervus elaphus* |
| Roe deer | *Capreolus capreolus* |
| Wild boar | *Sus scrofa* |

---

## Research Focus
The analyses focused on:
- spatial occurrence of wildlife trails
- orientation of wildlife trails relative to terrain structure
- comparison of random vs. targeted camera trap placement
- detection rated and behavioural patterns
- GIS-based environmental covariates
- movement-related behaviour of ungulates

---

## Repository Structure
```text
├── 01_detection_ratess.R
├── 02_behaviour_analysis.R
├── 03_trail_orientation_analysis.R
├── 04_camera_site_covariates.R
├── 05_spatial_visualization.R
└── README.md
```

## Workflow
```text
Camera Trap Data
      ↓
Data Cleaning and Standardisation
      ↓
Event Classification
      ↓
Statistical Analyses
      ↓
GIS-based Spatial Analyses
      ↓
Visualization and Figure Creation
```

---

## Main Methods

### Statistical analyses
- Monte Carlo permutation tests
- Spearman correlations
- Non-parametric statistics
- Descriptive analyses

### Spatial analyses
- GIS-based covariate extraction
- DEM-derived terrain analyses
- Wildlife trail orientation analyses
- OpenStreetMap-based distance calculations

### Visualization
- ggplot2
- scatterpie
- sf
- ggspatial

---

## Software and Packages

<details>
<summary>Show packages used in R</summary>

