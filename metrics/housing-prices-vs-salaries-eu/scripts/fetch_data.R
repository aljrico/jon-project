library(jsonlite)
library(readr)

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
root <- if (length(file_arg)) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
  normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  normalizePath(getwd(), mustWork = TRUE)
}

out_path <- file.path(root, "data", "housing_price_adjusted_by_salary_eu_2015_2024.csv")
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

geos <- c(
  "EU27_2020", "BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES",
  "FR", "HR", "IT", "CY", "LV", "LT", "LU", "HU", "MT", "NL", "AT",
  "PL", "PT", "RO", "SI", "SK", "FI", "SE"
)
years <- 2015:2024

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

geo_q <- query_pairs(geos, "geo")
time_q <- query_pairs(years, "time")

hpi <- fetch_eurostat(
  "prc_hpi_a",
  c("purchase=TOTAL", "unit=I15_A_AVG", geo_q, time_q)
) |>
  jsonstat_records()

salary <- fetch_eurostat(
  "nama_10_fte",
  c("unit=NAC", geo_q, time_q)
) |>
  jsonstat_records()

hpi_key <- setNames(hpi$value, paste(hpi$geo, hpi$time, sep = "_"))
salary_key <- setNames(salary$value, paste(salary$geo, salary$time, sep = "_"))
country_labels <- unique(rbind(
  hpi[, c("geo", "geo_label")],
  salary[, c("geo", "geo_label")]
))
country_labels <- setNames(country_labels$geo_label, country_labels$geo)

get_value <- function(x, key) {
  value <- unname(x[key])
  if (!length(value) || is.na(value)) NA_real_ else value
}

rows <- do.call(rbind, lapply(geos, function(geo) {
  salary_2015 <- get_value(salary_key, paste(geo, 2015, sep = "_"))
  do.call(rbind, lapply(years, function(year) {
    h <- get_value(hpi_key, paste(geo, year, sep = "_"))
    s <- get_value(salary_key, paste(geo, year, sep = "_"))
    salary_index <- adjusted <- change <- NA_real_
    if (!is.na(h) && !is.na(s) && !is.na(salary_2015)) {
      salary_index <- s / salary_2015 * 100
      adjusted <- h / (s / salary_2015)
      change <- adjusted - 100
    }
    data.frame(
      geo = geo,
      country = unname(country_labels[geo]),
      year = year,
      house_price_index_2015_100 = h,
      salary_national_currency = s,
      salary_index_2015_100 = round(salary_index, 6),
      house_price_adjusted_by_salary_index_2015_100 = round(adjusted, 6),
      change_vs_2015_pct = round(change, 6)
    )
  }))
}))

write_csv(rows, out_path)
message("Wrote ", out_path)
