# Caveats

## Missing Country Data

- **Netherlands**: Eurostat `nama_10_fte` does not publish the Netherlands. Eurostat news pages may point to a CBS fallback through the metadata, but that uses a different methodology. Keep the panel marked as missing unless that fallback is intentionally added with an explicit comparability caveat.
- **Greece**: Greece currently lacks the required Eurostat HPI series under the selected `prc_hpi_a` filters.

## Base Year

- 2015 is close to the post-GFC housing trough for Spain, Portugal, and Ireland. That makes the 2015-2024 rebound look larger than it would from a longer-run base year.
- The chart remains useful as a common Eurostat baseline, but the prose should acknowledge that part of the observed rise is mean reversion from a depressed housing market.

## Salary Units

- Salary values should use `unit=NAC`, not `unit=EUR`, to avoid exchange-rate noise for non-euro countries.
- Using `EUR` materially distorts countries outside the euro area, especially cases such as Hungary and Romania.
- Romania's large negative adjusted change is formula-consistent, not a rendering error. The 2024 HPI is `155.89`, while the salary index is `335.01`, producing an adjusted index of `46.53` and a change of `-53.5%`. This should be explained as a high-inflation catch-up economy where nominal wages rose much faster than house prices, not as a simple affordability miracle.

## Affordability Limits

- The salary measure is an average full-time adjusted salary, not a median buyer income.
- Mortgage affordability also depends on rates, deposits, taxes, credit standards, and household structure.
- National HPI data hides regional dispersion. In Spain especially, Madrid, Barcelona, and the Balearics are not well represented by a single national number.
- Nominal salary growth does not mean real purchasing power improved. Consumer inflation can erase wage gains while housing still pulls away.

## EU Contribution Screen

- The 2022-2024 contribution screen uses 2024 EU27 HPI country weights from `prc_hpi_cow`. That matches the HPI numerator's aggregation method, not the salary denominator.
- Do not call the weighted screen an exact decomposition of the EU adjusted ratio. It ranks countries by HPI-weighted pressure on the salary-adjusted gap.
- Exact country decomposition of the denominator would require reconstructing Eurostat's `nama_10_fte` aggregate from wages and salaries, employee counts, and full-time adjustment ratios, including cross-currency aggregation choices.

## Source Mixing

- If non-Eurostat data is mixed into the analysis, document the source, methodology, and comparability risk directly in the output notes.
- National statistical office fallbacks may be valid, but they stop the chart from being a strictly harmonised Eurostat-only comparison.

## Latest Year

- As checked on 2026-05-11, the full adjusted metric cannot be updated past 2024 because Eurostat `nama_10_fte` with `unit=NAC` has no 2025 or 2026 values for the selected geographies.
- Eurostat `prc_hpi_a` has 2025 annual HPI values, but HPI alone is not enough for this metric. Updating only the numerator would create a fake affordability series.
- Do not publish a 2025 or 2026 adjusted ranking unless both source tables are available for the target year, or unless a separate nowcast/fallback method is explicitly introduced and labelled.
