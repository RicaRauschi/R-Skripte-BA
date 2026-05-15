# ==========================================
# Hypothese 1: Erfassungsrate nach Kameraplatzierung
# ============================================

# Ziel:
# - Vergleich der Erfassungsraten zwischen zufällig platzierten Kameras und gezielt
# an Wildwechseln platzierten Kameras.
# Berechnet werden:
# - Ereignisse pro Kameratag
# - Individuen pro Kameratag
# - statistischer Vergleich mit Wilcoxon-Rangsummentest
# - Effektgröße Cliff's Delta
# - mittlere Individuenzahl pro Ereignis
# ============================================

# ----- 1) Pakete laden -----
library(readxl)
library(dplyr)
library(ggplot2)
library(effsize)
library(ggtext)

# ----- 2) Dateipfade definieren -----
# Ereignistabelle:
#   Jede Zeile entspricht einem unabhängigen Kamerafallen-Event
events_path  <- "data/Kriterienkatalog.xlsx"

# Laufzeittabelle:
#   Eine Zeile pro Kamera mit Start- und Enddatum
runtime_path <- "data/Kamera_Laufzeit.xlsx"

# ----- 3) Kamera VTK 090 ausschließen -----
# -> VTK 090 wird ausgeschlossen, da diese Kamera nicht in die finale Auswertung eingeht
exclude_cameras <- c("VTK 090")

# ----- 4) Ereignisdaten einlesen und Kameragruppen bilden -----
# Kameras werden anhand ihrer Platzierung in zwei Gruppen eingeteilt:
# - Random: zufällig platzierte Kameras
# - Targeted: gezielt an Wildwechsel platzierte Kameras 
events <- read_excel(events_path) %>%
  mutate(
    Camera_id   = as.character(Camera_id),
    Camera_type = as.character(Camera_type),
    Camera_group = case_when(
      Camera_type == "Random"                ~ "Random",
      Camera_type %in% c("Trail", "Hotspot") ~ "Targeted",
      TRUE                                   ~ NA_character_
    )
  ) %>%
  filter(!Camera_id %in% exclude_cameras) %>%     # <- NEU
  # Nur Kameras mit eindeutiger Gruppenzuordnung berücksichtigen
  filter(!is.na(Camera_group)) %>%
  # Faktor-Reihenfolge  setzen (Random zuerst)
  mutate(Camera_group = factor(Camera_group,
                               levels = c("Random", "Targeted")))

# ----- 5) Laufzeitdaten einlesen und Kameratage berechnen -----
# Die Kameralaufzeit wird inklusive Start- und Enddatum berechnet.
# Diese Kameratage bilden den Aufwand, auf den die Ereigniszahl standardisiert wird.
runtime <- read_excel(runtime_path) %>%
  mutate(
    Camera_id  = as.character(Camera_id),
    start_date = as.Date(start_date),
    end_date   = as.Date(end_date),
    camera_days = as.numeric(difftime(end_date,
                                      start_date,
                                      units = "days")) + 1
  ) %>%
  filter(!Camera_id %in% exclude_cameras) %>%     # <- NEU
  filter(!is.na(camera_days) & camera_days > 0)

# Check
unique(events$Camera_id)
unique(runtime$Camera_id)

# ----- 6) Ereignisrate pro Kamera berechnen -----
# Für jede Kamera wird die Anzahl unabhängiger Ereignisse gezählt und durch die
# aktiven Kameratage geteilt.
cam_summary <- events %>%
  count(Camera_id, Camera_group, name = "n_events") %>%
  left_join(runtime, by = "Camera_id") %>%
  filter(!is.na(camera_days) & camera_days > 0) %>%
  mutate(
    rate_events_per_day = n_events / camera_days
  )

# ----- 7) Deskriptive Statistik der Ereignisrate -----
# Median und IQR werden verwendet, da die Stichprobe klein ist und keine Normal-
# verteilung angenommen wird.
desc <- cam_summary %>%
  group_by(Camera_group) %>%
  summarise(
    n_cameras   = n(),
    median_rate = median(rate_events_per_day),
    IQR_rate    = IQR(rate_events_per_day),
    .groups = "drop"
  )

print(desc)

# Ergänzend werden Mittelwert und Standardabweichung der Ereignisraten berechnet,
# um die Streuung innerhalb der Kameragruppen zusätzlich zu beschreiben.
desc_sd <- cam_summary %>%
  group_by(Camera_group) %>%
  summarise(
    n_cameras = n(),
    mean_rate = mean(rate_events_per_day),
    sd_rate   = sd(rate_events_per_day),
    .groups = "drop"
  )

print(desc_sd)


# ----- 8) Wilcoxon-Rangsummentest für Ereignisrate -----
# Aufgrund der kleinen Stichprobe und nicht normalverteilter Daten wird ein 
# nichtparametrischer Test verwendet.
# Einseitige Hypothese: Gezielt platzierte Kameras haben höhere Erfassungsraten
# als zufällig platzierte Kameras.
# -> Bei Faktor-Reihenfolge Random, Targeted bedeutet: alternative = "less" prüft
# Random < Targeted.
wilcox_events <- wilcox.test(
  rate_events_per_day ~ Camera_group,
  data = cam_summary,
  alternative = "less"
)

print(wilcox_events)

# ----- 9) Effektgröße Cliff's Delta für Ereignisrate -----
# Cliff’s delta beschreibt die Wahrscheinlichkeit, dass ein zufällig gezogener 
# Wert aus der Random-Gruppe größer ist als ein zufällig gezogener Wert aus der 
# Targeted-Gruppe, also die Richtung und Stärke des Unterschieds.
# Wenn Cliff's delta > 0 dann: Targeted > Random
# Wenn Cliff's delta < 0 dann: Targeted < Random
cam_summary <- cam_summary %>%
  mutate(Camera_group_delta = factor(Camera_group,
                                     levels = c("Targeted", "Random")))

cliff_events <- cliff.delta(
  rate_events_per_day ~ Camera_group_delta,
  data = cam_summary
)

print(cliff_events)

# ----- 10) Boxplot der Ereignisrate -----
# Boxplot mit Einzelwerten (jede Kamera = ein Punkt)
# zur Darstellung der Verteilungen und Streuung
plot_events <- cam_summary %>%
  mutate(
    Camera_group_lbl = recode(
      Camera_group,
      "Random" = "Zufällig",
      "Targeted" = "Gezielt (Wildwechsel)"
    )
  )

ggplot(plot_events,
       aes(x = Camera_group_lbl, y = rate_events_per_day)) +
  geom_boxplot(width = 0.55, outlier.shape = NA,
               fill = "grey85", color = "black") +
  geom_jitter(width = 0.08, size = 2, alpha = 0.7, color = "black") +
  labs(
    title = "Ereignisse pro Kameratag:\nErfassungsrate in Abhängigkeit von der Kameraplatzierung",
    x = "Kameraplatzierung",
    y = "Ereignisse pro Kameratag"
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10)
  )

# ========================================
# Individuenrate pro Kameratag
# ========================================

# ----- 11) Individuenrate pro Kamera berechnen -----
# -> Zusätzlich zur Ereignisrate wird die Anzahl erfasster Individuen pro Kameratag
# berechnet. Dadurch wird berücksichtig, dass ein Ereignis mehrere Individuen 
# enthalten kann.
cam_summary_ind <- events %>%
  mutate(n_individuals = as.numeric(n_individuals)) %>%
  group_by(Camera_id, Camera_group) %>%
  summarise(
    n_individuals = sum(n_individuals, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(runtime, by = "Camera_id") %>%
  filter(!is.na(camera_days) & camera_days > 0) %>%
  mutate(rate_individuals_per_day = n_individuals / camera_days)

# ----- 12) Deskriptive Statistik der Individuenrate -----
desc_individuals <- cam_summary_ind %>%
  group_by(Camera_group) %>%
  summarise(
    n_cameras   = n(),
    median_rate = median(rate_individuals_per_day),
    IQR_rate    = IQR(rate_individuals_per_day),
    .groups = "drop"
  )

print(desc_individuals)

# ----- 13) Wilcoxon-Rangsummentest für Individuenrate -----
wilcox_individuals <- wilcox.test(
  rate_individuals_per_day ~ Camera_group,
  data = cam_summary_ind,
  alternative = "less"
)

print(wilcox_individuals)

# ----- 14) Effektgröße Cliff's Delta für Individuenrate -----
cam_summary_ind <- cam_summary_ind %>%
  mutate(Camera_group_delta = factor(Camera_group,
                                     levels = c("Targeted", "Random")))

cliff_individuals <- cliff.delta(
  rate_individuals_per_day ~ Camera_group_delta,
  data = cam_summary_ind
)

print(cliff_individuals)

# ----- 15) Boxplot der Individuenrate -----
plot_individuals <- cam_summary_ind %>%
  mutate(
    Camera_group_lbl = recode(
      Camera_group,
      "Random" = "Zufällig",
      "Targeted" = "Gezielt (Wildwechsel)"
    )
  )

ggplot(plot_individuals,
       aes(x = Camera_group_lbl, y = rate_individuals_per_day)) +
  geom_boxplot(width = 0.55, outlier.shape = NA,
               fill = "grey85", color = "black") +
  geom_jitter(width = 0.08, size = 2, alpha = 0.7, color = "black") +
  labs(
    title = "Individuen pro Kameratag:\nErfassungsrate in Abhängigkeit von der Kameraplatzierung",
    x = "Kameraplatzierung",
    y = "Individuen pro Kameratag"
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 10)
  )

# ========================================
# Mittlere Individuenzahl pro Ereignis
# ========================================

# ----- 16) Gesamtzahl von Ereignissen und Individuen vergleichen -----
events %>%
  summarise(
    total_events = n(),
    total_individuals = sum(n_individuals, na.rm = TRUE)
  )

# ----- 17) Kameraweise Gegenüberstellung von Ereginissen und Individuen -----
events %>%
  group_by(Camera_id) %>%
  summarise(
    events = n(),
    individuals = sum(n_individuals, na.rm = TRUE)
  ) %>%
  arrange(desc(individuals))

# ----- 18) Vergleich von Ereginisrate und Individuenrate -----
cam_summary %>%
  select(Camera_id, rate_events_per_day) %>%
  left_join(
    cam_summary_ind %>% 
      select(Camera_id, rate_individuals_per_day),
    by = "Camera_id"
  )

# ----- 19) Datensatz auf Untersuchungsarten filtern -----
events_filt <- events %>%
  filter(species %in% c("Cervus elaphus",
                        "Capreolus capreolus",
                        "Sus scrofa")) %>%
  mutate(
    n_individuals = as.numeric(n_individuals),
    group2 = recode(
      Camera_group,
      "Random" = "Zufällig",
      "Targeted" = "Gezielt (Wildwechsel)"
    )
  )

# ----- 20) Quotient aus Individuen und Ereignissen berechnen -----
# -> Der Quotient beschreibt, wie viele Individuen durchschnittlich pro unabhängigem
# Ereignis erfasst wurden.
plot_counts_ratio <- events_filt %>%
  group_by(group2, species) %>%
  summarise(
    events = n(),
    individuals = sum(n_individuals, na.rm = TRUE),
    individuals_per_event = individuals / events,
    .groups = "drop"
  ) %>%
  mutate(
    species = factor(
      species,
      levels = c("Cervus elaphus",
                 "Capreolus capreolus",
                 "Sus scrofa"),
      labels = c(
        "Rothirsch<br><i>Cervus elaphus</i>",
        "Reh<br><i>Capreolus capreolus</i>",
        "Wildschwein<br><i>Sus scrofa</i>"
      )
    ),
    group2 = factor(group2,
                    levels = c("Zufällig", "Gezielt (Wildwechsel)"))
  )
ggplot(plot_counts_ratio,
       aes(x = individuals_per_event, y = species, fill = group2)) +
  geom_col(width = 0.7, position = position_dodge(width = 0.75)) +
  geom_text(
    aes(label = round(individuals_per_event, 2)),
    position = position_dodge(width = 0.75),
    hjust = -0.15,
    size = 3.5
  ) +
  scale_fill_manual(
    values = c(
      "Zufällig" = "#3B73B9",
      "Gezielt (Wildwechsel)" = "#E68613"
    )
  ) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Mittlere Individuenzahl pro Ereignis",
    subtitle = "Quotient aus Individuen und unabhängigen Ereignissen",
    x = "Individuen pro Ereignis",
    y = NULL,
    fill = NULL
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    axis.text.y = ggtext::element_markdown(size = 11),
    legend.position = "top"
  )

# ----- 21) Quotient pro Kamera berechnen -----
# -> Statt nur aggregiert über alle Kameras wird der Quotient hier kameraweise
# berechnet. Dadurch kann die Streuung zwischen den Kamerastandorten dargestellt 
# werden.

ratio_cam <- events_filt %>%
  mutate(
    n_individuals = as.numeric(n_individuals),
    # Gruppenlabel korrigieren (kein "Trail", sondern "Wildwechsel")
    group2 = recode(
      group2,
      "Gezielt (Trails/Hotspots)" = "Gezielt (Wildwechsel)"
    )
  ) %>%
  group_by(Camera_id, group2, species) %>%
  summarise(
    events = n(),
    individuals = sum(n_individuals, na.rm = TRUE),
    individuals_per_event = individuals / events,
    .groups = "drop"
  ) %>%
  mutate(
    group2 = factor(group2, levels = c("Zufällig", "Gezielt (Wildwechsel)")),
    species_lab = factor(
      species,
      levels = c("Cervus elaphus", "Capreolus capreolus", "Sus scrofa"),
      labels = c(
        "Rothirsch<br><i>Cervus elaphus</i>",
        "Reh<br><i>Capreolus capreolus</i>",
        "Wildschwein<br><i>Sus scrofa</i>"
      )
    )
  )

# ----- 22) Boxplot: Individuen pro Ereginis -----
ggplot(ratio_cam, aes(x = group2, y = individuals_per_event, fill = group2)) +
  geom_boxplot(width = 0.6, outlier.shape = NA) +
  geom_jitter(width = 0.1, size = 2, alpha = 0.7, color = "black") +
  facet_wrap(~ species_lab, nrow = 1) +
  scale_fill_manual(values = c(
    "Zufällig" = "#3B73B9",
    "Gezielt (Wildwechsel)" = "#E68613"
  )) +
  labs(
    title = "Individuenzahl pro Ereignis (kamerabasiert)",
    subtitle = "Quotient aus Individuen und unabhängigen Ereignissen",
    x = NULL,
    y = "Individuen pro Ereignis"
  ) +
  scale_y_continuous(limits = c(0, 3.2), breaks = seq(0, 3, 0.5)) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 12),
    legend.position = "none",
    strip.text = ggtext::element_markdown(size = 11),
    axis.text.x = element_text(size = 10)
  )

# ----- 23) Medieanwerte des Quotienten berechnen -----
ratio_cam %>%
  group_by(group2, species) %>%
  summarise(
    median_ratio = median(individuals_per_event),
    .groups = "drop"
  )

# Ergänzende Kontrolle
# ----- 24) Ereignisrate und Individuenrate zusammenführen -----
check <- cam_summary %>%
  select(Camera_id, Camera_group, rate_events_per_day) %>%
  inner_join(
    cam_summary_ind %>% select(Camera_id, rate_individuals_per_day),
    by = "Camera_id"
  )

# ----- 24) Rangfolge der beiden Raten vergleichen -----
all(rank(check$rate_events_per_day) == rank(check$rate_individuals_per_day))

# ----- 25) Rangkorrelation zwischen Ereignis- und Individuenrate -----
cor(check$rate_events_per_day, check$rate_individuals_per_day, method = "spearman")



# ================================
# Maximale realisierte Reichweite pro Kamera
# ================================
# -> Aus mehreren gemessenen Entfernungen wird pro Kamera die größe realisierte 
# Detektionsdistanz übernommen.

# ----- 25) Datei einlesen -----
reach_path <- "data/MaxReichweite.xlsx"

# ----- 26) Ereignisrate erneut berechnen -----
cam_summary <- events %>%
  count(Camera_id, Camera_group, name = "n_events") %>%
  left_join(runtime, by = "Camera_id") %>%
  filter(!is.na(camera_days) & camera_days > 0) %>%
  mutate(rate_events_per_day = n_events / camera_days)

# ----- 27) Maximal realisierte Reichweite berechnen -----
reach_df <- read_excel(reach_path) %>%
  mutate(
    Kamera_ID  = as.character(Kamera_ID),
    cam_id_norm = str_squish(str_to_upper(Kamera_ID)),
    max_reichweite = pmax(Entfernung_1, Entfernung_2, Entfernung_3, na.rm = TRUE)
  ) %>%
  select(cam_id_norm, Standort_Typ, max_reichweite)

# ----- 28) Reichweitendaten mit Erfassungsraten verknüpfen -----
cam_summary2 <- cam_summary %>%
  mutate(cam_id_norm = str_squish(str_to_upper(Camera_id))) %>%
  select(cam_id_norm, Camera_group, rate_events_per_day)

df_reach_events <- reach_df %>%
  inner_join(cam_summary2, by = "cam_id_norm")

# ----- 29) Kontrollausgabe -----
print(nrow(df_reach_events))
print(table(df_reach_events$Camera_group))

# ----- 30) Streudiagramm: Detektionsdistanz und Erfassungsrate -----
p <- ggplot(df_reach_events,
            aes(x = max_reichweite,
                y = rate_events_per_day,
                shape = Camera_group,
                color = Camera_group)) +
  
  geom_point(size = 3) +
    scale_shape_manual(
    values = c("Random" = 16, "Targeted" = 15),
    guide = "none"
  ) +
  scale_color_manual(
    values = c("Random" = "#2C7FB8",      
               "Targeted" = "#E68613"),   
    labels = c("Random" = "Zufällig",
               "Targeted" = "Wildwechsel"),
    name = "Kameratyp"
  ) +
  scale_x_continuous(breaks = seq(5, 25, by = 5)) +
  
  labs(
    title = "Zusammenhang zwischen der maximal realisierten\nDetektionsdistanz und den Erfassungsraten",
    x = "Maximal realisierte Detektionsdistanz (m)",
    y = "Ereignisse pro Kameratag"
  ) +
  
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, lineheight = 1.1),
    aspect.ratio = 0.8
  )

p

# ----- 31) Spearman-Korrelation zwischen Detektionsdistanz und Erfassungsrate -----
cor.test(
  df_reach_events$max_reichweite,
  df_reach_events$rate_events_per_day,
  method = "spearman"
)

# ----- 32) Gruppenweise Spearman-Korrelation -----
# -> Die Korrelation wird zusätzlich getrennt nach Kameragruppe berechnet.
# Aufgrund der sehr kleinen Gruppengröße ist dies nur explorativ interpretierbar.
df_reach_events %>%
  group_by(Camera_group) %>%
  summarise(
    cor = cor(max_reichweite,
              rate_events_per_day,
              method = "spearman")
  )