# ==========================================
# Fehlauslösungen nach Kameragruppe
# ============================================

# Ziel: Berechnung des Anteils an Fehlauslösungen pro Kameragruppe.
# Dafür werden:
# - Tierauslösungen aus der Agouti-Artenübersicht summiert,
# - Fehlauslösungen aus der Laufzeittabelle übernommen,
# - beide Werte pro Kamera zusammengeführt,
# - Fehlauslösungen relativ zur Gesamtzahl der Auslösungen berechnet.
# ============================================

# ----- 1) Pakete laden -----
library(readxl)
library(dplyr)

# ----- 2) Dateipfade definieren -----
file_animals  <- "C:/Users/Ricar/OneDrive/Desktop/Uni/Bachelorarbeit/Rica Bachelorarbeit Stick/Agouti/Arten_pro_Kamera_lang.xlsx"
file_runtime <- "C:/Users/Ricar/OneDrive/Desktop/Uni/Bachelorarbeit/R Skripte Anhang/Kamera_Laufzeit.xlsx"

# ----- 3) Daten einlesen -----
# -> animals: enthält die Anzahl der Tierauslösungen pro Art und Kamera.
# -> runtime: enthält Kameragruppe und Anzahl der Fehlauslösungen pro Kamera.
animals <- read_excel(file_animals)
runtime <- read_excel(file_runtime)

# ----- 4) Funktion zur Standardisierung der Kamera-IDs -----
# -> Kamera-IDs liegen in den Tabellen teilweise unterschiedlich vor. Diese Funktion
# bringt alle IDs in ein einheitliches Format.
standardize_camera_id <- function(x) {
  x <- as.character(x)
  
  x <- str_remove(x, "^2025_")        
  x <- str_remove(x, "_C2$")          
  x <- str_replace(x, "PFAD", " Pfad")
  
  x <- str_replace(x, "^VTK(\\d{3})S$", "VTK \\1 S")
  x <- str_replace(x, "^VTK(\\d{3})$", "VTK \\1")
  x <- str_replace(x, "^VTK(\\d{3})\\s+Pfad$", "VTK \\1 Pfad")
  
  str_squish(x)
}

# ----- 5) Kamera-IDs standardisieren und Kamera VTK 090 ausschließen -----
animals <- animals %>%
  mutate(camera_id_std = standardize_camera_id(locationName)) %>%
  filter(camera_id_std != "VTK 090")

runtime <- runtime %>%
  mutate(camera_id_std = standardize_camera_id(Camera_id)) %>%
  filter(camera_id_std != "VTK 090")

# ----- 6) Teirauslösungen pro Kamera berechnen -----
# -> Menschen werden ausgeschlossen
animals_cam <- animals %>%
  filter(scientificName != "Homo sapiens") %>%   
  group_by(camera_id_std) %>%
  summarise(animal_triggers = sum(Anzahl, na.rm = TRUE), .groups = "drop")

# ----- 7) Fehlauslösungen und Kameragruppe aus Laufzeittabelle übernehmen -----
runtime_cam <- runtime %>%
  transmute(
    camera_id_std,
    camera_group,
    false_triggers = `Anzahl Fehlausloesungen`
  )

# ----- 8) Tier- und Fehlauslösungen zusammenführen -----
# -> Gesamt = Tierauslösungen + Fehlauslösungen
cam_all <- runtime_cam %>%
  left_join(animals_cam, by = "camera_id_std") %>%
  mutate(animal_triggers = if_else(is.na(animal_triggers), 0, animal_triggers)) %>%
  mutate(
    total_triggers = false_triggers + animal_triggers,
    false_trigger_percent = 100 * false_triggers / total_triggers
  )

# ----- 9) Kontrolle der Tabellenverknüpfung -----
missing_in_runtime <- setdiff(animals_cam$camera_id_std, runtime_cam$camera_id_std)
missing_in_animals <- setdiff(runtime_cam$camera_id_std, animals_cam$camera_id_std)

if (length(missing_in_runtime) > 0) {
  message("WARNUNG: Diese Kameras sind in den Tierdaten, aber NICHT in Kamera_Laufzeit:")
  print(missing_in_runtime)
}

if (length(missing_in_animals) > 0) {
  message("HINWEIS: Diese Kameras sind in Kamera_Laufzeit, aber ohne Tierdaten (animal_triggers=0):")
  print(missing_in_animals)
}

# ----- 10) Fehlauslösungen nach Kameragruppe zusammenfassen -----
summary_by_group <- cam_all %>%
  group_by(camera_group) %>%
  summarise(
    false_triggers = sum(false_triggers, na.rm = TRUE),
    animal_triggers = sum(animal_triggers, na.rm = TRUE),
    total_triggers = sum(total_triggers, na.rm = TRUE),
    false_trigger_percent = 100 * false_triggers / total_triggers,
    .groups = "drop"
  )

# ----- 11) Ergebnisse ausgeben -----
message("\n--- Pro Kamera ---")
print(cam_all %>% arrange(camera_group, camera_id_std))

message("\n--- Zusammenfassung nach Kameragruppe ---")
print(summary_by_group)

### ERGEBNIS
# Zufällig: Fehlauslösungen = 101; Tierauslösungen = 129; Gesamt = 230; Anteil Fehlauslösungen = 101 / 230 * 100 = 43,9 %
# Gezielt:  Fehlauslösungen = 67; Tierauslösungen = 166; Gesamt = 233; Anteil Fehlauslösungen = 67 / 233 * 100 = 28,8 % 
