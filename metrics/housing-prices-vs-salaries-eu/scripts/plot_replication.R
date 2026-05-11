library(dplyr)
library(ggplot2)
library(grid)
library(gridExtra)
library(readr)

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
root <- if (length(file_arg)) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
  normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  normalizePath(getwd(), mustWork = TRUE)
}

data_path <- file.path(root, "data", "housing_price_adjusted_by_salary_eu_2015_2024.csv")
out_path <- file.path(root, "output", "eu_housing_salary_replication.png")

dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
unlink(file.path(root, "Rplots.pdf"))

label_es <- c(
  EU27_2020 = "UNIÓN EUROPEA",
  BE = "BÉLGICA",
  BG = "BULGARIA",
  CZ = "R. CHECA",
  DK = "DINAMARCA",
  DE = "ALEMANIA",
  EE = "ESTONIA",
  IE = "IRLANDA",
  ES = "ESPANA",
  FR = "FRANCIA",
  HR = "CROACIA",
  IT = "ITALIA",
  CY = "CHIPRE",
  LV = "LETONIA",
  LT = "LITUANIA",
  LU = "LUXEMBURGO",
  HU = "HUNGRÍA",
  MT = "MALTA",
  NL = "PAÍSES BAJOS",
  AT = "AUSTRIA",
  PL = "POLONIA",
  PT = "PORTUGAL",
  RO = "RUMANÍA",
  SI = "ESLOVENIA",
  SK = "ESLOVAQUIA",
  FI = "FINLANDIA",
  SE = "SUECIA"
)

plot_order <- c(
  "EU27_2020", "BE", "BG", "CZ", "DK",
  "DE", "EE", "IE", "ES",
  "FR", "HR", "IT", "CY", "LV", "LT",
  "LU", "HU", "MT", "NL", "AT", "PL",
  "PT", "RO", "SI", "SK", "FI", "SE"
)

df <- read_csv(data_path, show_col_types = FALSE) |>
  mutate(
    label = unname(label_es[geo]),
    label = if_else(is.na(label), geo, label)
  )

make_panel <- function(geo_code, large = FALSE) {
  panel <- df |> filter(geo == geo_code)
  color <- if (geo_code == "ES") "#d45a4f" else "#6f8fab"
  fill <- if (geo_code == "ES") "#f1d2cd" else "#eaf1f7"
  final <- panel |> filter(year == 2024) |> pull(change_vs_2015_pct)
  label <- unique(panel$label)[1]
  has_data <- any(!is.na(panel$house_price_adjusted_by_salary_index_2015_100))
  label_text <- if (length(final) && !is.na(final)) {
    paste0(ifelse(final >= 0, "+", ""), gsub("\\.", ",", sprintf("%.1f%%", final)))
  } else {
    ""
  }

  base_size <- if (large) 10.5 else 7
  badge_size <- if (large) 3.5 else 2.25
  title_size <- if (large) 10.5 else 7.2
  line_width <- if (large) 1.1 else 0.65

  p <- ggplot(panel, aes(year, house_price_adjusted_by_salary_index_2015_100)) +
    coord_cartesian(xlim = c(2015, 2024), ylim = c(48, 152), clip = "off") +
    scale_x_continuous(
      breaks = c(2015, 2024),
      minor_breaks = 2016:2023,
      labels = c("2015", "2024")
    ) +
    scale_y_continuous(breaks = c(50, 100, 150)) +
    theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", color = "#333333", hjust = 0.5, size = title_size),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_line(color = "#edf1f4", linewidth = 0.25),
      panel.grid.major.y = element_line(color = "#edf1f4", linewidth = 0.35),
      panel.grid.minor.y = element_blank(),
      axis.title = element_blank(),
      axis.text = element_text(color = "#8f99a3"),
      axis.text.y = element_text(size = if (large) 7.5 else 5.2),
      axis.text.x = element_text(size = if (large) 7.5 else 5.2),
      axis.ticks = element_blank(),
      plot.margin = margin(3, 5, 10, 5),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    ) +
    labs(title = label)

  if (has_data) {
    p <- p +
      geom_ribbon(aes(ymin = 50, ymax = house_price_adjusted_by_salary_index_2015_100),
                  fill = fill, alpha = 0.95) +
      geom_line(color = color, linewidth = line_width) +
      geom_point(
        data = panel |> filter(year == max(year[!is.na(house_price_adjusted_by_salary_index_2015_100)])),
        shape = 21, color = color, fill = "white", stroke = if (large) 1.2 else 0.8,
        size = if (large) 4.3 else 2.5
      )
  }

  if (nzchar(label_text)) {
    p <- p +
      annotate(
        "label", x = 2023.35, y = if (large) 70 else 66,
        label = label_text, fill = "#1f4b73", color = "white",
        linewidth = 0, size = badge_size, fontface = "bold",
        label.padding = unit(if (large) 0.18 else 0.12, "lines")
      )
  }

  p
}

plots <- setNames(lapply(plot_order, make_panel), plot_order)
plots[["EU27_2020"]] <- make_panel("EU27_2020", large = TRUE)

grobs <- list(
  plots[["EU27_2020"]], plots[["BE"]], plots[["BG"]], plots[["CZ"]], plots[["DK"]],
  plots[["DE"]], plots[["EE"]], plots[["IE"]], plots[["ES"]],
  plots[["FR"]], plots[["HR"]], plots[["IT"]], plots[["CY"]], plots[["LV"]], plots[["LT"]],
  plots[["LU"]], plots[["HU"]], plots[["MT"]], plots[["NL"]], plots[["AT"]], plots[["PL"]],
  plots[["PT"]], plots[["RO"]], plots[["SI"]], plots[["SK"]], plots[["FI"]], plots[["SE"]]
)

layout <- rbind(
  c(1, 1, 2, 3, 4, 5),
  c(1, 1, 6, 7, 8, 9),
  c(10, 11, 12, 13, 14, 15),
  c(16, 17, 18, 19, 20, 21),
  c(22, 23, 24, 25, 26, 27)
)

title <- textGrob(
  expression(bold("Incremento del ")*bolditalic("precio de la vivienda")*bold(" en la Unión Europea ajustado al crecimiento de los salarios ")*bold("2015-2024")),
  x = 0.02, hjust = 0, gp = gpar(fontsize = 12.5, col = "#26323d")
)

footer <- textGrob(
  "Fuentes: Eurostat [prc_hpi_a] y [nama_10_fte] datos más recientes disponibles (2024)\nNota: Elaboración propia a partir del House Price Index deflactado con el crecimiento de los salarios, con 2015 definido como el año base (índice = 100)",
  x = 0.02, hjust = 0, gp = gpar(fontsize = 8.5, col = "#5e6872")
)

canvas <- arrangeGrob(
  title,
  arrangeGrob(grobs = grobs, layout_matrix = layout, padding = unit(0.25, "line")),
  footer,
  ncol = 1,
  heights = c(0.75, 8.6, 0.65)
)

while (as.integer(dev.cur()) > 1) dev.off()
ragg::agg_png(out_path, width = 2400, height = 1600, res = 220, background = "white")
grid.draw(canvas)
dev.off()
while (as.integer(dev.cur()) > 1) dev.off()
unlink(file.path(root, "Rplots.pdf"))

message("Wrote ", out_path)
