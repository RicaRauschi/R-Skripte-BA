# ==========================================
# Räumliche Darstellung der Kamerastandorte und Artzusammensetzung
# ============================================

# Ziel: Erstellung einer Übersichtskarte der Kamerastandorte innerhalb der Kernzone.
# Dargestellt werden:
# - Kamerastandorte
# - Kameratypen (Zufällig vs. Gezielt (Wildwechsel))
# - relative Häufigkeiten der drei Untersuchungsarten als Pie-Charts
# ============================================

# ----- 1) Pakete laden -----
library(camtrapDensity)  
library(dplyr)
library(tidyr)
library(stringr)
library(sf)
library(ggplot2)
library(ggspatial)
library(scatterpie)
library(ggforce)

# ----- 2) Pfade definieren und Daten einlesen -----
# CamtrapDP-Datensatz
dp_path <- "data/biosphere-reserve-thuringian-forest-20260128120013/datapackage.json"

# Polygon der Kernzone 
kernzone_path <- "data/UmrandungNeu.gpkg"

# CamtrapDP einlesen
pkg <- camtrapDensity::read_camtrapDP(dp_path)

# Kernzone einlesen
kernzone <- st_read(kernzone_path, quiet = TRUE)

# ----- 3) Kamera VTK 090 ausschließen -----
drop_location <- "2025_VTK090_C2"

dep <- pkg$data$deployments
drop_ids <- dep$deploymentID[dep$locationName == drop_location]

if (length(drop_ids) > 0) {
  for (nm in names(pkg$data)) {
    x <- pkg$data[[nm]]
    if (is.data.frame(x) && "deploymentID" %in% names(x)) {
      pkg$data[[nm]] <- x[!(x$deploymentID %in% drop_ids), ]
    }
  }
}

# ----- 4) Zielarten definieren -----
target_species <- c("Cervus elaphus", "Capreolus capreolus", "Sus scrofa")

# ----- 5) Deployments und Beobachtungen vorbereiten -----
# Deployments: Koordinaten + Standortname
dep <- pkg$data$deployments %>%
  select(deploymentID, locationName, latitude, longitude)

# Beobachtungen: Nachweise
obs <- pkg$data$observations

# ----- 6) Individuenzahlen pro Art und Standort berechnen -----
# Je Deployment werden die Nachweise der Zielarten summiert.
count_col <- intersect(c("count", "individualCount", "numberOfIndividuals"), names(obs))
count_col <- if (length(count_col) > 0) count_col[1] else NA_character_

summ <- obs %>%
  filter(scientificName %in% target_species) %>%
  group_by(deploymentID, scientificName) %>%
  summarise(
    n = if (!is.na(count_col)) sum(.data[[count_col]], na.rm = TRUE) else n(),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from  = scientificName,
    values_from = n,
    values_fill = 0
  )

# ----- 7) Koordinaten und Artensummen zusammenführen -----
plot_df <- dep %>%
  left_join(summ, by = "deploymentID") %>%
  mutate(
    `Cervus elaphus`      = coalesce(`Cervus elaphus`, 0),
    `Capreolus capreolus` = coalesce(`Capreolus capreolus`, 0),
    `Sus scrofa`          = coalesce(`Sus scrofa`, 0),
    total = `Cervus elaphus` + `Capreolus capreolus` + `Sus scrofa`
  ) %>%
  filter(!is.na(latitude), !is.na(longitude))

# ----- 8) Kamerastandorte zu Basisstandorten zusammenfassen -----
# Je Standort werden zufällige Kameras und Wildwechselkameras getrennt aggregiert.
plot_df2 <- plot_df %>%
  mutate(
    base_site = case_when(
      str_detect(locationName, "^2025_VTK005") ~ "2025_VTK005",
      str_detect(locationName, "^2025_VTK016") ~ "2025_VTK016",
      str_detect(locationName, "^2025_VTK036") ~ "2025_VTK036",
      str_detect(locationName, "^2025_VTK050") ~ "2025_VTK050",
      str_detect(locationName, "^2025_VTK088") ~ "2025_VTK088",
      str_detect(locationName, "^2025_VTK095") ~ "2025_VTK095",
      TRUE ~ NA_character_
    ),
    cam_type = case_when(
      str_detect(locationName, "PFAD") ~ "Wildwechsel / Hotspot",
      str_detect(locationName, "VTK\\d{3}S") ~ "Wildwechsel / Hotspot",
      TRUE ~ "Zufällig"
    )
  ) %>%
  filter(!is.na(base_site)) %>%
  group_by(base_site, cam_type) %>%
  summarise(
    longitude = first(longitude),
    latitude  = first(latitude),
    `Cervus elaphus`      = sum(`Cervus elaphus`, na.rm = TRUE),
    `Capreolus capreolus` = sum(`Capreolus capreolus`, na.rm = TRUE),
    `Sus scrofa`          = sum(`Sus scrofa`, na.rm = TRUE),
    .groups = "drop"
  )

# Sicherstellen: max. 2 Zeilen pro base_site (Zufällig + Wildwechsel/Hotspot)
# (Falls ein Standort aus irgendeinem Grund nur 1 Typ hat, bleibt er mit 1 Zeile.)
plot_df2 <- plot_df2 %>%
  arrange(base_site, cam_type) %>%
  group_by(base_site) %>%
  slice_head(n = 2) %>%
  ungroup()

# ----- 9) Koordinaten transformieren -----
# Die Punkte werden in das Koordinatensystem der Kernzone transformiert.

r_min <- 50
r_max <- 130
offset_scale <- 2.2   

cam_cols <- c(
  "Wildwechsel / Hotspot" = "lightblue2",
  "Zufällig"              = "orange"
)

# Transform: WGS84 -> CRS der Kernzone
cams_sf <- st_as_sf(plot_df2, coords = c("longitude", "latitude"), crs = 4326) %>%
  st_transform(st_crs(kernzone))

xy <- st_coordinates(cams_sf)

plot_df2 <- plot_df2 %>%
  mutate(
    x = xy[, 1],
    y = xy[, 2]
  )

# ----- 10) Pie-Chart-Größe berechnen -----
plot_df2 <- plot_df2 %>%
  mutate(total = `Cervus elaphus` + `Capreolus capreolus` + `Sus scrofa`)

max_total <- max(plot_df2$total, na.rm = TRUE)

plot_df2 <- plot_df2 %>%
  mutate(
    r = ifelse(
      is.finite(max_total) && max_total > 0,
      r_min + (r_max - r_min) * sqrt(total / max_total),
      r_min
    )
  )

# ----- 11) Pie-Charts seitlich versetzen -----
plot_df2 <- plot_df2 %>%
  arrange(base_site, cam_type) %>%
  group_by(base_site) %>%
  mutate(
    idx = row_number(),                 
    dir = if_else(idx == 1, -1, 1),     
    theta = if_else(idx == 1, -0.35, 0.35),
    
    x_pie = x + dir * offset_scale * r * cos(theta),
    y_pie = y + dir * offset_scale * r * sin(theta)
  ) %>%
  ungroup()

# ----- 12) Plot -----
crs_utm  <- st_crs(kernzone)
bbox_utm <- st_bbox(kernzone)

p <- ggplot() +
  # Basemap (OSM)
  annotation_map_tile(type = "osm", zoom = 14) +
  
  # Kernzone-Polygon
  geom_sf(data = kernzone, fill = NA, color = "black", linewidth = 1) +
  
  # Linie vom Standortpunkt zum versetzten Pie (Farbe = cam_type)
  geom_segment(
    data = plot_df2,
    aes(x = x, y = y, xend = x_pie, yend = y_pie, color = cam_type),
    linewidth = 0.6,
    lineend = "round"
  ) +
  
  # Punkt am echten Standort (Farbe = cam_type)
  geom_point(
    data = plot_df2,
    aes(x = x, y = y, color = cam_type),
    size = 2.2
  ) +
  
  # Pie-Charts 
  geom_scatterpie(
    data = plot_df2,
    aes(x = x_pie, y = y_pie, r = r),
    cols = c("Cervus elaphus", "Capreolus capreolus", "Sus scrofa"),
    color = NA,
    alpha = 1
  ) +
  
  # Nur Außenumrandung des Kreises (Farbe = cam_type)
  ggforce::geom_circle(
    data = plot_df2,
    aes(x0 = x_pie, y0 = y_pie, r = r, color = cam_type),
    inherit.aes = FALSE,
    fill = NA,
    linewidth = 0.7
  ) +
  
  # Legenden: Kameratyp
  scale_color_manual(
    values = cam_cols,
    labels = c(
      "Wildwechsel / Hotspot" = "Wildwechsel",
      "Zufällig"              = "Zufällig"
    ),
    name = "Kameratyp"
  ) +
  # Legende: Untersuchungsarten 
  scale_fill_manual(
    values = c(
      "Cervus elaphus"      = "#1f77b4",
      "Capreolus capreolus" = "#ff7f0e",
      "Sus scrofa"          = "#2ca02c"
    ),
    labels = c(
      "Cervus elaphus"      = "Rothirsch",
      "Capreolus capreolus" = "Reh",
      "Sus scrofa"          = "Wildschwein"
    ),
    name = "Untersuchungsarten"
  ) +
  
  # Schwarze Umrandung in der Fill-Legende entfernen
  guides(
    fill  = guide_legend(override.aes = list(colour = NA)),
    color = guide_legend(override.aes = list(fill = NA))
  ) +
  
  # Maßstab & Nordpfeil
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(
    location = "tr",
    which_north = "true",
    pad_x = unit(-0.3, "cm"),
    pad_y = unit(0.1, "cm"),
    style = north_arrow_fancy_orienteering
  ) +
  
  # Ausschnitt auf Kernzone begrenzen
  coord_sf(
    crs = crs_utm,
    xlim = c(bbox_utm["xmin"], bbox_utm["xmax"]),
    ylim = c(bbox_utm["ymin"], bbox_utm["ymax"]),
    expand = FALSE
  ) +
  
  # Layout
  theme(
    panel.grid = element_blank(),
    axis.title = element_blank(),
    axis.text.y = element_text(angle = 90, vjust = 0.5, hjust = 0.5, margin = margin(r = 2)),
    axis.text.x = element_text(margin = margin(t = 4)),
    legend.key  = element_rect(color = NA)  
  )

p