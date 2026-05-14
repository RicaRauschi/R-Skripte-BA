# ============================================================
# Kameralaufzeit und Kameratage
# ============================================================
# Ziel:
# Berechnung der aktiven Kameratage pro Kamera sowie der
# durchschnittlichen Kameratage pro Kamerapaar.
#
# Die Werte dienen der Beschreibung des Erhebungsaufwands
# im Ergebnisteil.
# ============================================================

# ----- 1) Pakete laden -----
library(readxl)   
library(dplyr)    
library(stringr)  
library(readr)    

# ----- 2) Laufzeitdaten einlesen -----
df <- read_excel(
  "C:/Users/Ricar/OneDrive/Desktop/Uni/Bachelorarbeit/Rica Bachelorarbeit Stick/Kamera_Laufzeit.xlsx",
  col_types = "text"
)

# ----- 3) Kamera VTK 090 ausschließen -----
df <- df %>%
  filter(!str_detect(Camera_id, "\\b090\\b"))

# ----- 4) Datumswerte umwandeln und Kameratage berechnen -----
# -> Excel-Datumszahlen werden in R-Datumswerte umgerechnet.
# -> Die Kameratage werden inklusive Start- und Enddatum berechnet.
df <- df %>%
  mutate(
    start_num = parse_number(start_date),
    end_num   = parse_number(end_date),
    start_date = as.Date(start_num, origin = "1899-12-30"),
    end_date   = as.Date(end_num, origin = "1899-12-30"),
    camera_days = as.numeric(end_date - start_date) + 1
  )

# ----- 5) Kamerapaare identifizieren -----
df <- df %>%
  mutate(
    pair_id = str_extract(Camera_id, "\\d{3}")
  )

# ----- 6) Kameratage pro Kamerapaar berechnen -----
# -> Für jedes Kamerapaar wird die mittlere Laufzeit berechnet.
pair_days <- df %>%
  group_by(pair_id) %>%
  summarise(
    n_cameras = n(),
    mean_camera_days = mean(camera_days),
    sd_camera_days   = sd(camera_days),
    .groups = "drop"
  )

pair_days

# ----- 7) Kontrolle der einzelnen Kameralaufzeiten -----
# -> Diese Tabelle dient der Prüfung der berechneten Kameratage.

df %>%
  select(Camera_id, start_date, end_date, camera_days, pair_id) %>%
  print(n = 20)

# ----- 8) Durchschnittlicher Erhebungsaufwand über alle Kamerapaare -----
overall_mean_pairs <- mean(pair_days$mean_camera_days)
overall_mean_pairs

# ----- 9) Streuung der mittleren Kameratage zwischen Kamerapaaren -----
sd_pairs <- sd(pair_days$mean_camera_days)
sd_pairs