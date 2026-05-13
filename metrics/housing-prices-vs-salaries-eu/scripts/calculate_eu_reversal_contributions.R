library(dplyr)
library(jsonlite)
library(readr)
library(tidyr)

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
root <- if (length(file_arg)) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
  normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  normalizePath(getwd(), mustWork = TRUE)
}

data_path <- file.path(root, "data", "housing_price_adjusted_by_salary_eu_2015_2024.csv")
out_path <- file.path(root, "data", "eu_hpi_weighted_reversal_contributions_2022_2024.csv")
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

# Eurostat HPI country weights are published in per-mille units. For the
# 2024 EU27 aggregate, `prc_hpi_cow` with `statinfo=COWEU27_2020` gives the
# country weights used for the HPI numerator.
# Dataset: https://ec.europa.eu/eurostat/databrowser/view/prc_hpi_cow/default/table
# Metadata: https://ec.europa.eu/eurostat/cache/metadata/en/prc_hpi_inx_esms.htm
country_geos <- c(
  "BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR",
  "IT", "CY", "LV", "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT",
  "RO", "SI", "SK", "FI", "SE"
)

fetch_eurostat <- function(dataset, params) {
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
    dataset, "?",
    paste(params, collapse = "&")
  )
  fromJSON(url, simplifyVector = FALSE)
}

jsonstat_records <- function(js) {
  ids <- unlist(js$id)
  sizes <- unlist(js$size)
  dims <- js$dimension
  values <- js$value
  if (is.null(values)) return(data.frame())

  cats <- lapply(ids, function(id) {
    idx <- unlist(dims[[id]]$category$index)
    names(sort(idx))
  })

  labels <- lapply(ids, function(id) {
    x <- dims[[id]]$category$label
    if (is.null(x)) character() else unlist(x)
  })

  grid <- expand.grid(lapply(sizes, seq_len), KEEP.OUT.ATTRS = FALSE)
  names(grid) <- ids
  grid[] <- Map(function(col, codes) codes[col], grid, cats)

  positions <- expand.grid(lapply(sizes, function(size) 0:(size - 1)), KEEP.OUT.ATTRS = FALSE)
  position <- Reduce(function(acc, i) acc * sizes[[i]] + positions[[i]], seq_along(sizes), init = 0)

  value_names <- as.integer(names(values))
  keep <- match(position, value_names)
  records <- grid[!is.na(keep), , drop = FALSE]
  records$value <- as.numeric(unlist(values[keep[!is.na(keep)]]))

  for (id in ids) {
    lab <- labels[[which(ids == id)]]
    if (length(lab)) {
      records[[paste0(id, "_label")]] <- unname(lab[records[[id]]])
    }
  }

  records
}

query_pairs <- function(values, key) {
  paste(paste0(key, "=", values), collapse = "&")
}

weights <- fetch_eurostat(
  "prc_hpi_cow",
  c(
    "purchase=TOTAL",
    "statinfo=COWEU27_2020",
    "time=2024",
    query_pairs(country_geos, "geo")
  )
) |>
  jsonstat_records() |>
  filter(unit == "PM") |>
  transmute(
    geo,
    hpi_weight_2024_pm = value,
    hpi_weight_2024_share = value / 1000
  )

metric <- read_csv(data_path, show_col_types = FALSE)

contributions <- metric |>
  filter(
    year %in% c(2022, 2024),
    geo %in% country_geos,
    !is.na(change_vs_2015_pct)
  ) |>
  select(geo, country, year, change_vs_2015_pct) |>
  pivot_wider(
    names_from = year,
    values_from = change_vs_2015_pct,
    names_prefix = "change_"
  ) |>
  inner_join(weights, by = "geo") |>
  mutate(
    # This is a numerator-side contribution screen, not an exact decomposition
    # of the full salary-adjusted EU ratio. The salary denominator comes from
    # `nama_10_fte`, which is not published with these HPI country weights.
    delta_2022_2024_pct_points = change_2024 - change_2022,
    hpi_weighted_delta_pct_points = delta_2022_2024_pct_points * hpi_weight_2024_share
  ) |>
  arrange(hpi_weighted_delta_pct_points) |>
  mutate(
    eu_closing_rank = if_else(
      hpi_weighted_delta_pct_points < 0,
      rank(hpi_weighted_delta_pct_points, ties.method = "first"),
      NA_integer_
    ),
    eu_widening_rank = if_else(
      hpi_weighted_delta_pct_points > 0,
      rank(-hpi_weighted_delta_pct_points, ties.method = "first"),
      NA_integer_
    ),
    contribution_group = case_when(
      !is.na(eu_closing_rank) & eu_closing_rank <= 3 ~ "largest_hpi_weighted_closers",
      !is.na(eu_widening_rank) & eu_widening_rank <= 3 ~ "largest_hpi_weighted_wideners",
      TRUE ~ NA_character_
    )
  ) |>
  select(
    geo,
    country,
    change_2022,
    change_2024,
    delta_2022_2024_pct_points,
    hpi_weight_2024_pm,
    hpi_weight_2024_share,
    hpi_weighted_delta_pct_points,
    eu_closing_rank,
    eu_widening_rank,
    contribution_group
  )

write_csv(contributions, out_path)
message("Wrote ", out_path)
