# Caveats

## Missing Country Data

- **Netherlands / Países Bajos**: Eurostat `nama_10_fte` does not publish the Netherlands. Keep the panel marked as missing unless a CBS fallback is intentionally added with an explicit comparability caveat.
- **Greece / Grecia**: Greece currently lacks the required Eurostat HPI series under the selected `prc_hpi_a` filters.

## Salary Units

- Salary values should use `unit=NAC`, not `unit=EUR`, to avoid exchange-rate noise for non-euro countries.
- Using `EUR` materially distorts countries outside the euro area, especially cases such as Hungary and Romania.
- Romania's large negative adjusted change is formula-consistent, not a rendering error. The 2024 HPI is `155.89`, while the salary index is `335.01`, producing an adjusted index of `46.53` and a change of `-53.5%`. This should be explained carefully because it can look suspicious at first glance.

## Source Mixing

- If non-Eurostat data is mixed into the analysis, document the source, methodology, and comparability risk directly in the output notes.
- National statistical office fallbacks may be valid, but they stop the chart from being a strictly harmonised Eurostat-only comparison.

## Latest Year

- As checked on 2026-05-11, the full adjusted metric cannot be updated past 2024 because Eurostat `nama_10_fte` with `unit=NAC` has no 2025 or 2026 values for the selected geographies.
- Eurostat `prc_hpi_a` has 2025 annual HPI values, but HPI alone is not enough for this metric. Updating only the numerator would create a fake affordability series.
- Do not publish a 2025 or 2026 adjusted ranking unless both source tables are available for the target year, or unless a separate nowcast/fallback method is explicitly introduced and labelled.
