# =================================
# Tab. 2: Standortbezogene Umwelt- und Platzierungsparameter der Kamerastandorte
# =====================================

# Ziel:
# - Berechnung standortbezogener Kovariaten für die Kamerastandorte
# --> dazu wurden Kamerakoordinaten mit OpenStreetMap-Daten und einem digitalen
#     Geländemodell verknüpft. Berechnet wurden:
#     - Distanz zum nächsten Weg
#     - Distanz zum nächsten Gewässer
#     - Höhenlage
#     - Hangneigung
#     - Exposition
#     - Kronendichte
#     - Vegetationsdichte

# Diese Werte dienen der deskriptiven Charakterisierung der Kamerastandorte und 
# werden in der Arbeit in der Standorttabelle (Tab. 2) verwendet.
# ========================================


# ----- 1) Pakete laden -----
library(readxl)
library(dplyr)
library(sf)
library(osmdata)
library(stringr)
library(terra)

# ----- 2) Daten einlesen -----
cov <- read_excel("C:/Users/Ricar/OneDrive/Desktop/Uni/Bachelorarbeit/Rica Bachelorarbeit Stick/Kamera_Laufzeit.xlsx")

# ----- 3) Kamera-IDs bereinigen -----
# -> Leerzeichen in den Kamera-IDs werden vereinheitlicht
# -> VTK 090 wird ausgeschlossen, da diese Kamera nicht in die finale Auswertung eingeht
cov <- cov %>%
  mutate(Camera_id_clean = str_squish(Camera_id)) %>%
  filter(Camera_id_clean != "VTK 090")

# ----- 4) Kontrollausgabe der Koordinaten -----
cov %>% select(Camera_id, Latitude, Longitude)
nrow(cov)

# ----- 5) Kameratyp festlegen -----
# -> die gezielt and Wildwechseln platzierten Kameras werden als "Trail" klassifiziert.
# -> Alle übrigen als "Random".
trail_ids <- c(
  "VTK 005 S",
  "VTK 016 Pfad",
  "VTK 036 Pfad",
  "VTK 050 Pfad",
  "VTK 088 Pfad",
  "VTK 095 Pfad"
)

cov <- cov %>%
  mutate(
    camera_type = ifelse(Camera_id_clean %in% trail_ids, "Trail", "Random")
  )

table(cov$camera_type)

# ----- 6) Kamerastandorte als Punktdaten erstellen -----
# -> Aus Longitude und Latitude werden räumliche Punkte erzeugt.
# -> EPSG: 4326 entspricht WGS84.
pts <- st_as_sf(
  cov,
  coords = c("Longitude", "Latitude"),
  crs = 4326,
  remove = FALSE
)

# ----- 7) Punkte in metrisches Koordinatensystem transformieren -----
# -> Für Distanzberechnungen wird UTM Zone 32N verwendet.
pts_utm <- st_transform(pts, 32632)

# ----- 8) Suchbereich für OpenStreetMap-Daten erstellen -----
# -> Um alle Kamerapunkte wird ein 1000-m Puffer gelegt. Innerhalb dieses Bereichs
# werden Wege und Gewässer abgefragt.
set_overpass_url("https://overpass-api.de/api/interpreter")

aoi_utm <- st_buffer(st_union(pts_utm), 1000)
aoi_wgs <- st_transform(aoi_utm, 4326)
bb <- st_bbox(aoi_wgs)

# ----- 9) Wege aus OpenStreetMap abrufen -----
# -> Abgerufen werden Wegtypen, die als nächstgelegene Wege im Untersuchungsgebiet
# relevant sein können.
highways <- opq(bbox = bb, timeout = 180) |>
  add_osm_feature(
    key = "highway",
    value = c("track", "path", "footway", "service", "unclassified", "residential")
  ) |>
  osmdata_sf()

# ----- 10) Distanz zum nächstgelegenen Weg berechnen -----
# -> Für jede Kamera wird der nächstgelegene OSM-Weg gesucht.
roads_m <- st_transform(highways$osm_lines, st_crs(pts_utm))
idx <- st_nearest_feature(pts_utm, roads_m)

cov$dist_road_m <- as.numeric(st_distance(
  pts_utm,
  roads_m[idx, ],
  by_element = TRUE
))

# ----- 11) Gewässer aus OpenStreetMap abrufen -----
# -> Abgerufen werden lineare Gewässer wie Bäche, Flüsse und Gräben.
water <- opq(bbox = bb, timeout = 180) |>
  add_osm_feature(
    key = "waterway",
    value = c("stream", "river", "ditch", "drain")
  ) |>
  osmdata_sf()

# ----- 12) Distanz zum nächstgelegenen Gewässer berechnen -----
# -> Für jede Kamera wird das nächstgelegene OSM-Gewässer gesucht.
streams_m <- st_transform(water$osm_lines, st_crs(pts_utm))
idx_w <- st_nearest_feature(pts_utm, streams_m)

cov$dist_stream_m <- as.numeric(st_distance(
  pts_utm,
  streams_m[idx_w, ],
  by_element = TRUE
))

# ----- 13) Digitales Geländemodell einlesen -----
# -> Das DGM dient zur Ableitung von Höhenlage, Hangneigung und Exposition.
dem <- rast("C:/Users/Ricar/OneDrive/Desktop/Uni/Bachelorarbeit/QGIS R/Neu Koordinatensystem/VerschmolzenDGM1.tif")

# ----- 14) Kamerapunkte an Koordinatensystem des DGM anpassen -----
# -> Nur bei gleichem Koordinatensystem können Rasterwerte korrekt an den Kamera-
# standorten extrahiert werden.
pts_dem <- st_transform(pts, crs(dem)) |> vect()

# ----- 15) Höhenlage aus dem DGM extrahieren -----
cov$elevation_m <- terra::extract(dem, pts_dem)[,2]

# ----- 16) Hangneigung und Exposition berechnen -----
# -> slope: Hangneigung in Grad
# -> aspect: Exposition des stärksten Gefälles in Grad
slope  <- terrain(dem, v = "slope", unit = "degrees")
aspect <- terrain(dem, v = "aspect", unit = "degrees")

# ----- 17) Hangneigung und Exposition extrahieren -----
cov$slope_deg  <- terra::extract(slope, pts_dem)[,2]
cov$aspect_deg <- terra::extract(aspect, pts_dem)[,2]

# ----- 18) Ergebnistabelle erstellen -----
# -> Die für Tab. 2 relevanten Standortparameter werden ausgewählt, gerundet und 
# nach Kamera-ID sortiert.
results_table <- cov %>%
  select(
    Camera_id,
    camera_type,
    Latitude,
    Longitude,
    dist_road_m,
    dist_stream_m,
    elevation_m,
    slope_deg,
    aspect_deg,
    canopy_cover,
    veg_density
  ) %>%
  mutate(
    dist_road_m   = round(dist_road_m, 1),
    dist_stream_m = round(dist_stream_m, 1),
    elevation_m   = round(elevation_m, 0),
    slope_deg     = round(slope_deg, 1),
    aspect_deg    = round(aspect_deg, 1),
    canopy_cover  = round(canopy_cover, 3),
    veg_density   = round(veg_density, 3)
  ) %>%
  arrange(Camera_id)

# ----- 19) Ergebnistabelle anzeigen -----
View(results_table)