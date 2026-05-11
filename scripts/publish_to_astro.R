# Copies built metric artifacts into the Astro website public directory.
# This script does not rebuild metrics; run each metric pipeline first.

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
repo_root <- if (length(file_arg)) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
  normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  normalizePath(getwd(), mustWork = TRUE)
}

astro_site <- Sys.getenv("ASTRO_SITE", unset = file.path(dirname(repo_root), "astro-personal-website"))
astro_site <- normalizePath(astro_site, mustWork = TRUE)

metrics <- list(
  list(
    id = "housing-prices-vs-salaries-eu",
    files = c(
      "output/observable_replication.html",
      "output/eu_housing_salary_replication.png",
      "data/housing_price_adjusted_by_salary_eu_2015_2024.csv",
      "metric.yml",
      "knowledge/caveats.md",
      "knowledge/findings.md"
    )
  )
)

for (metric in metrics) {
  metric_dir <- file.path(repo_root, "metrics", metric$id)
  target_dir <- file.path(astro_site, "public", "metrics", metric$id)
  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

  for (relative_path in metric$files) {
    source <- file.path(metric_dir, relative_path)
    if (!file.exists(source)) {
      stop("Missing publish artifact: ", source, call. = FALSE)
    }
    file.copy(source, file.path(target_dir, basename(relative_path)), overwrite = TRUE)
  }

  message("Published ", metric$id, " to ", target_dir)
}
