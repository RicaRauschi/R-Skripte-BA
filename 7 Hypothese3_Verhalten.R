# ==========================================
# Hypothese 3: Verhaltensklassen nach Kamerastandort
# ============================================

# Ziel: Darstellung der relativen Anteile von Bewegungs- und Verweilereignissen 
# an zufälligen und gezielt an Wildwechseln platzierten Kameras.
# ============================================

# ----- 1) Pakete laden -----
install.packages("cowplot")
library(cowplot)
library(readxl)
library(dplyr)
library(ggplot2)
library(scales)

# ----- 2) Daten einlesen -----
df <- read_excel("data/Kriterienkatalog.xlsx")

# ----- 3) Kamera VTK 090 ausschließen -----
df <- df %>%
  filter(Camera_id != "VTK 090")

# ----- 4) Kameragruppen und Verhaltensklassen bilden -----
# -> Random = zufällig platzierte Kameras
# -> Targeted = gezielt an Wildwechslen platzierte Kameras
# Die Einzelverhalten werden zu zwei funktionalen Klassen zusammengefasst:
# -> movement = Laufen/Rennen
# -> foraging = Äsen/Stehen
df2 <- df %>%
  mutate(
    Camera_group = case_when(
      Camera_type == "Random" ~ "Random",
      Camera_type %in% c("Hotspot", "Trail") ~ "Targeted",
      TRUE ~ NA_character_
    ),
    Camera_group = factor(Camera_group, levels = c("Random", "Targeted")),
    behaviour_class = case_when(
      Behaviour %in% c("laufen", "rennen") ~ "movement",
      Behaviour %in% c("äsen", "stehen")   ~ "foraging",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(Camera_group), !is.na(behaviour_class))

# ----- 5) Anzahl der Kameras pro Kameragruppe berechnen -----
cam_n <- df %>%
  mutate(
    Camera_group = case_when(
      Camera_type == "Random" ~ "Random",
      Camera_type %in% c("Hotspot", "Trail") ~ "Targeted",
      TRUE ~ NA_character_
    ),
    Camera_group = factor(Camera_group, levels = c("Random", "Targeted"))
  ) %>%
  distinct(Camera_group, Camera_id) %>%
  count(Camera_group, name = "n_cameras")

get_n <- function(type) {
  out <- cam_n$n_cameras[cam_n$Camera_group == type]
  if (length(out) == 0) 0 else out
}

n_rand <- get_n("Random")
n_wild <- get_n("Targeted")

camera_info_txt <- paste0(
  "Kameras:\n",
  "  Zufällig n = ", n_rand, "\n",
  "  Wildwechsel n = ", n_wild
)

# ============================================================
# Plot A: relative Anteile nach Ereignissen
# ============================================================

# ----- 6) Ereignisbasierte Anteile berechnen -----
# -> Grundlage sind unabhängige Kamerafallenereignisse. Jedes Ergebnis zählt einmal.
plot_df <- df2 %>%
  group_by(Camera_group, behaviour_class) %>%
  summarise(n_events = n(), .groups = "drop") %>%
  group_by(Camera_group) %>%
  mutate(
    percent = n_events / sum(n_events),
    label   = scales::percent(percent, accuracy = 0.1)
  ) %>%
  ungroup()

# ----- 7) Ereignisbasierte Abbildung erstellen -----
p_base <- ggplot(plot_df, aes(x = Camera_group, y = percent, fill = behaviour_class)) +
  geom_col(width = 0.7) +
  geom_text(
    aes(label = label),
    position = position_stack(vjust = 0.5),
    color = "white", size = 4
  ) +
  scale_y_continuous(labels = percent, expand = expansion(mult = c(0, 0.02))) +
  scale_x_discrete(labels = c(
    "Random"   = "Zufällig",
    "Targeted" = "Gezielt\n(Wildwechsel)"
  )) +
  scale_fill_manual(
    values = c("movement" = "#0072B2", "foraging" = "#D55E00"),
    labels = c(
      "foraging" = "Verweilend\n (Äsen, Stehen)",
      "movement" = "Bewegung\n  (Laufen, Rennen)"
    )
  ) +
  labs(
    title    = "Verhaltensklassen nach Kamerastandort",
    subtitle = "Relative Anteile der erfassten Ereignisse",
    x = "Kamerastandort",
    y = "Anteil der Ereignisse",
    fill = "Verhaltensklassen:"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    
    axis.line  = element_line(color = "black", linewidth = 0.6),
    axis.ticks = element_line(color = "black"),
    axis.text.x  = element_text(size = 11, lineheight = 1.05),
    axis.title.x = element_text(margin = margin(t = 12)),
    panel.grid.minor = element_blank(),
    legend.position = "right",
    legend.title = element_text(size = 10),
    legend.text  = element_text(size = 10,  hjust = 0.2),
    plot.margin = margin(t = 10, r = 10, b = 15, l = 10)
  ) +
  guides(
    fill = guide_legend(
      keyheight = unit(10, "pt"),
      label.theme = element_text(margin = margin(b = 8))
    )
  )

# ----- 8) Legende und Kamerazahl separat anordnen -----
p_noleg <- p_base + theme(legend.position = "none")
leg <- cowplot::get_legend(p_base + theme(legend.position = "right"))

right_panel <- cowplot::ggdraw() +
  cowplot::draw_grob(
    leg,
    x = 0, y = 1,
    hjust = 0, vjust = 1,
    width = 1, height = 0.82   
  ) +
  cowplot::draw_label(
    camera_info_txt,
    x = 0.10, y = 0.45,           
    hjust = 0, vjust = 1,
    size = 10
  )

p_final <- cowplot::plot_grid(
  p_noleg,
  right_panel,
  ncol = 2,
  rel_widths = c(1, 0.28)
)

p_final

# ============================================================
# Plot B: relative Anteile nach Individuen
# ============================================================

# ----- 9) Individuengewichtete Anteile berechnen -----
# -> Hier wird nicht jedes Ereignis gleich gezählt, sondern mit der Anzahl der 
# erfassten Individuen gewichtet. 
plot_df_inds <- df2 %>%
  mutate(n_individuals = as.numeric(n_individuals)) %>%
  filter(!is.na(n_individuals)) %>%
  group_by(Camera_group, behaviour_class) %>%
  summarise(n_inds = sum(n_individuals, na.rm = TRUE), .groups = "drop") %>%
  group_by(Camera_group) %>%
  mutate(
    percent = n_inds / sum(n_inds),
    label   = scales::percent(percent, accuracy = 0.1)
  ) %>%
  ungroup()

# ----- 10) Individuengewichtete Abbildung erstellen -----
p_base_inds <- ggplot(plot_df_inds, aes(x = Camera_group, y = percent, fill = behaviour_class)) +
  geom_col(width = 0.7) +
  geom_text(
    aes(label = label),
    position = position_stack(vjust = 0.5),
    color = "white", size = 4
  ) +
  scale_y_continuous(labels = percent, expand = expansion(mult = c(0, 0.02))) +
  scale_x_discrete(labels = c(
    "Random"   = "Zufällig",
    "Targeted" = "Gezielt\n(Wildwechsel)"
  )) +
  scale_fill_manual(
    values = c("movement" = "#0072B2", "foraging" = "#D55E00"),
    labels = c(
      "foraging" = "Verweilend\n (Äsen, Stehen)",
      "movement" = "Bewegung\n  (Laufen, Rennen)"
    )
  ) +
  labs(
    title    = "Verhaltensklassen nach Kamerastandort",
    subtitle = "Relative Anteile (gewichtet nach Anzahl Individuen)",
    x = "Kamerastandort",
    y = "Anteil der Individuen",
    fill = "Verhaltensklassen:"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    axis.line  = element_line(color = "black", linewidth = 0.6),
    axis.ticks = element_line(color = "black"),
    axis.text.x  = element_text(size = 11, lineheight = 1.05),
    axis.title.x = element_text(margin = margin(t = 12)),
    panel.grid.minor = element_blank(),
    legend.position = "right",
    legend.title = element_text(size = 10),
    legend.text  = element_text(size = 10, hjust = 0.2),
    plot.margin = margin(t = 10, r = 10, b = 15, l = 10)
  ) +
  guides(
    fill = guide_legend(
      keyheight = unit(10, "pt"),
      label.theme = element_text(margin = margin(b = 8))
    )
  )

p_noleg_inds <- p_base_inds + theme(legend.position = "none")
leg_inds <- cowplot::get_legend(p_base_inds + theme(legend.position = "right"))

right_panel_inds <- cowplot::ggdraw() +
  cowplot::draw_grob(
    leg_inds,
    x = 0, y = 1,
    hjust = 0, vjust = 1,
    width = 1, height = 0.82
  ) +
  cowplot::draw_label(
    camera_info_txt,
    x = 0.10, y = 0.45,
    hjust = 0, vjust = 1,
    size = 10
  )

p_final_inds <- cowplot::plot_grid(
  p_noleg_inds,
  right_panel_inds,
  ncol = 2,
  rel_widths = c(1, 0.28)
)

p_final_inds

# ============================================================
# Ergänzende Diagramme pro Kamera
# ============================================================

# ----- 10) Datensatz für Einzeldiagramme vorbereiten -----
df_cam <- df %>%
  mutate(
    behaviour_class = case_when(
      Behaviour %in% c("laufen", "rennen") ~ "movement",
      Behaviour %in% c("äsen", "stehen") ~ "foraging",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(behaviour_class)) %>%
  filter(species %in% c("Cervus elaphus",
                        "Capreolus capreolus",
                        "Sus scrofa"))

# ----- 11) Funktion für Einzeldiagramm pro Kamera -----
make_cam_plot <- function(cam_id) {
  
  plot_df_cam <- df2 %>%
    filter(Camera_id == cam_id) %>%
    count(species, behaviour_class, name = "n") %>%
    group_by(species) %>%
    mutate(
      percent = n / sum(n),
      n_total = sum(n)
    ) %>%
    ungroup()
  
  ggplot(plot_df_cam, aes(x = species, y = percent, fill = behaviour_class)) +
    
    geom_col(width = 0.45, position = position_stack(reverse = TRUE)) +
    
    geom_text(
      aes(label = scales::percent(percent, accuracy = 0.1)),
      position = position_stack(vjust = 0.5, reverse = TRUE),
      color = "white", size = 3.5
    ) +

    geom_text(
      data = distinct(plot_df_cam, species, n_total),
      aes(x = species, y = 1.05, label = paste0("n = ", n_total)),
      inherit.aes = FALSE,
      size = 3.5
    ) +
    
    scale_fill_manual(
      values = c("movement" = "#0072B2", "foraging" = "#D55E00"),
      breaks = c("movement", "foraging"),
      labels = c(
        "movement" = "Bewegung\n(Laufen, Rennen)",
        "foraging" = "Verweilend\n(Äsen, Stehen)"
      )
    ) +
    
    scale_x_discrete(labels = c(
      "Cervus elaphus"      = "Rothirsch\n(Cervus elaphus)",
      "Capreolus capreolus" = "Reh\n(Capreolus capreolus)",
      "Sus scrofa"          = "Wildschwein\n(Sus scrofa)"
    )) +
    
    scale_y_continuous(
      labels = scales::percent,
      limits = c(0, 1.1),
      expand = expansion(mult = c(0, 0))
    ) +
    
    labs(
      title = paste0("Verhaltensklassen – ", cam_id),
      x = "Art",
      y = "Anteil",
      fill = "Verhaltensklassen:"
    ) +
    
    theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 13),
      panel.grid.minor = element_blank(),
      axis.line = element_line(color = "black"),
      axis.ticks = element_line(color = "black"),
      axis.text.x = element_text(size = 9),
      legend.position = "right"
    )
}

pdf("Behaviour_pro_Kamera.pdf", width = 6, height = 4)

for (cam in sort(unique(df$Camera_id))) {
  print(make_cam_plot(cam))
}

dev.off()

