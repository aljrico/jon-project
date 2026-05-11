# JON — Journal of Numbers

Open, reproducible public-interest metrics, starting with Spain.

JON is the source of truth for the data work: sources, scripts, caveats, derived datasets, and publishable chart artifacts. The Astro website is the publishing layer.

Inspired by the work of jongzlz.

## Structure

```text
metrics/
  <metric-id>/
    metric.yml
    README.md
    scripts/
    data/
    knowledge/
    output/
```

Each metric should be independently rebuildable and publishable.

## First Metric

- `housing-prices-vs-salaries-eu`: house prices adjusted by salary growth across EU countries, 2015-2024.

## Run A Metric

```bash
cd metrics/housing-prices-vs-salaries-eu
Rscript scripts/fetch_data.R
Rscript scripts/plot_replication.R
Rscript scripts/build_observable_html.R
```

## Publish To Astro

```bash
Rscript scripts/publish_to_astro.R
```

By default this copies publishable artifacts into:

```text
../astro-personal-website/public/metrics/<metric-id>/
```

Override the target site with:

```bash
ASTRO_SITE=/path/to/astro-site Rscript scripts/publish_to_astro.R
```
