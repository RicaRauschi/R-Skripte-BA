# ==========================================
# Hypothese 2: Wildwechsel verlaufen hangparallel
# ============================================

# Ziel: Prüfen, ob kartierte Wildwechsel bevorzugt entlang der Höhenlinien verlaufen.
# Dazu wird:
# - die beobachtete Winkelabweichung zwischen Wildwechselrichtung und hangparalleler
# Richtung beschrieben,
# - die Verfügbarkeit der Hangrichtungen im Untersuchungsgebiet aus dem digitalen
# Geländemodell berechnet,
# - ein Monte-Carlo-Permutationstest durchgeführt.

# ----- 1) Pakete laden -----
library(readxl)
library(ggplot2)
library(terra)
library(sf)
library(dplyr)

# ----- 2) Datei einlesen -----
df <- readxl::read_excel("data/Winkel_fuer_Hangparallel.xlsx")

# ----- 3) Histogramm der beobachteten Winkelabweichung -----
# -> Kleine Winkelwerte bedeuten, dass ein Wildwechsel nahezu hangparallel verläuft.
# Eine Häufung nahe 0° spricht daher für eine Orientierung entlang der Höhenlinien.
p_hist <- ggplot(df, aes(x = Winkel_klein)) +
  geom_histogram(
    binwidth  = 5,
    color     = "black",
    fill      = "grey80",
    linewidth = 0.3
  ) +
  labs(
    title    = "Orientierung der Wildwechsel relativ zum Hangverlauf",
    subtitle = "Winkelabweichung zwischen Wildwechselrichtung und hangparalleler Richtung",
    x        = "Winkelabweichung vom hangparallelen Verlauf (°)",
    y        = "Anzahl der Wildwechsel"
  ) +
  theme_classic(base_size = 14) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, hjust = 0),
    plot.subtitle = element_text(size = 12, hjust = 0, margin = margin(b = 10)),
    axis.title    = element_text(size = 11),
    axis.text     = element_text(size = 11),
    aspect.ratio  = 0.4
  )

p_hist

# ==========================================================
# Verfügbarkeit der Hangrichtungen im Untersuchungsgebiet
# ==========================================================

# ----- 4) Digitales Geländemodell und Untersuchungsgebiet einlesen -----
# -> Das DGM dient zur Ableitung von Hangneigung und Exposition.
# -> Das Untersuchungsgebiet wird verwendet, um die Rasterdaten auf die Kernzone 
# zuzuschneiden.
dem <- rast("data/DGM.tif")          
ug  <- st_read("data/Untersuchungsgebiet.gpkg")   
ug_v <- vect(ug)     

# ----- 5) DGM auf Untersuchungsgebiet zuschneiden -----
dem_ug <- crop(dem, ug_v) |> mask(ug_v)

# ----- 6) Hangneigung und Exposition berechnen -----
# -> slope: Hangneigung in Grad
# -> aspect: Exposition, also Richtung des stärksten Gefälles in Grad
slope  <- terrain(dem_ug, v = "slope",  unit = "degrees")
aspect <- terrain(dem_ug, v = "aspect", unit = "degrees")  

# ----- 7) Flache Bereiche ausschließen -----
# -> In nahezu flachem Gelände ist eine Hangrichtung kaum sinnvoll interpretierbar.
# Deshalb werden nur Rasterzellen mit einer Hangneigung von mindestens 5° berücksichtig.
slope_min <- 5  
aspect_steep <- mask(aspect, slope >= slope_min)

# ----- 8) Exposition in acht Richtungsklassen einteilen -----
aspect_to_8 <- function(a) {
  out <- rep(NA_integer_, length(a))
  out[a >= 0     & a < 22.5]   <- 1  # N
  out[a >= 22.5  & a < 67.5]   <- 2  # NE
  out[a >= 67.5  & a < 112.5]  <- 3  # E
  out[a >= 112.5 & a < 157.5]  <- 4  # SE
  out[a >= 157.5 & a < 202.5]  <- 5  # S
  out[a >= 202.5 & a < 247.5]  <- 6  # SW
  out[a >= 247.5 & a < 292.5]  <- 7  # W
  out[a >= 292.5 & a < 337.5]  <- 8  # NW
  out[a >= 337.5 & a < 360]    <- 1  # N
  out
}

aspect8 <- app(aspect_steep, aspect_to_8)

# ----- 9) Flächenanteile der Expositionsklassen berechnen -----
# -> Für jede Richtungsklasse wird berechnet, welchen Anteil sie an der Gesamtfläche
# der berücksichtigten Rasterzellen einnimmt.
freq_tab <- as.data.frame(freq(aspect8, digits = 0))

cell_area <- prod(res(dem_ug))  

freq_tab <- freq_tab %>%
  mutate(
    area_m2 = count * cell_area,
    percent = 100 * area_m2 / sum(area_m2),
    class_label = factor(
      value,
      levels = 1:8,
      labels = c("N","NE","E","SE","S","SW","W","NW")
    )
  ) %>%
  arrange(class_label)


# ============================================================
# Monte-Carlo-Permutationstest
# ============================================================

# ----- 10) Hangparallele Richtung aus der Exposition ableiten -----
# -> Da Wildwechsel als Linien ohne eindeutige Pfeilrichtung betrachtet werden,
# wird auf 0-180° reduziert.
contour_dir <- (aspect_steep + 90) %% 180

# ----- 11) Funktion zur Berechnung der Winkelabweichung -----
# -> Berechnet den kleinsten Winkel zwischen zwei axialen Richtungen.
# -> Das Ergebnis liegt zwischen 0° und 90°.
ang_diff_0_90 <- function(a, b) {
  d <- abs(a - b) %% 180
  pmin(d, 180 - d)
}

# ----- 12) Nullmodell simulieren -----
# -> Im Nullmodell werden zufällige Linienrichtungen mit zufällig gezogenen
# hangparallelen Richtungen aus dem Untersuchungsgebiet verglichen.
set.seed(1)

n_sim <- 100000  

cont_vals <- values(contour_dir, na.rm = TRUE)

cont_sample <- sample(cont_vals, size = n_sim, replace = TRUE)

rand_dir <- runif(n_sim, min = 0, max = 180)

exp_winkel <- ang_diff_0_90(rand_dir, cont_sample)

# ----- 13) Teststatistik definieren -----
# -> Als nahezu hangparallel gelten Wildwechsel mit einer Winkelabweichung von 
# höchstens 20°.
thresh <- 20

t_obs <- mean(df$Winkel_klein <= thresh, na.rm = TRUE)

t_exp <- mean(exp_winkel <= thresh)

t_obs
t_exp

# ----- 14) Permutationstest durchführen -----
# -> Es wird geprüft, wie häufig ein mindestens so hoher Anteil nahezu hangparalleler
# Wildwechsel unter dem Nullmodell auftritt.
set.seed(2)
B <- 9999

t_null <- replicate(
  B,
  mean(sample(exp_winkel, size = nrow(df), replace = TRUE) <= thresh)
)

p_val <- (sum(t_null >= t_obs) + 1) / (B + 1)
p_val

# ============================================================
# Polar-Balkendiagramm der Hangexposition
# ============================================================
# Diese Abb. zeigt die flächenmäßige Verfügbarkeit der Hangrichtungen im Untersuchungsgebiet.

# ----- 15) Daten für Polar-Balkendiagramm vorbereiten -----
freq_tab2 <- freq_tab %>%
  mutate(
    class_label = factor(class_label, levels = c("N","NE","E","SE","S","SW","W","NW")),
    label = paste0(round(percent, 1), " %"),
    small = percent < 6
  )

# ----- 16) Polar-Balkendiagramm erstellen -----
ggplot(freq_tab2, aes(x = class_label, y = percent)) +
    geom_col(width = 1, fill = "grey85", color = "black", linewidth = 0.4) +
    geom_text(
    data = subset(freq_tab2, !small),
    aes(label = label),
    position = position_stack(vjust = 0.55),
    size = 4,
    color = "black"
  ) +
  geom_label(
    data = subset(freq_tab2, small),
    aes(label = label, y = percent + 1.6),
    size = 4,
    linewidth = 0,      
    fill = "white",
    alpha = 0.9,
    label.padding = unit(0.12, "lines")
  ) +
  coord_polar(start = -pi/8, direction = -1, clip = "off") +
  scale_y_continuous(
    limits = c(0, max(freq_tab2$percent) * 1.03),
    breaks = seq(0, ceiling(max(freq_tab2$percent) / 5) * 5, by = 5),
    expand = c(0, 0)
  ) +
   labs(
    title = "Verfügbarkeit der Hangrichtungen\nim Untersuchungsgebiet",
    subtitle = "Aspect-Verteilung (nur Zellen mit Hangneigung ≥ 5°)",
    x = NULL, y = NULL
  ) +
    theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0, lineheight = 1.1),
    plot.subtitle = element_text(size = 11, hjust = 0),
    
    axis.text.x = element_text(size = 11, color = "black"),
    axis.text.y = element_blank(),
    axis.title = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_line(color = "grey85", linewidth = 0.4),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background  = element_rect(fill = "white", color = NA),
    plot.margin = margin(10, 15, 10, 15)
  )