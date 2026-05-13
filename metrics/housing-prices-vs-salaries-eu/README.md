# EU Housing Prices Adjusted By Salaries

Replication of the small-multiple chart concept:

> Change in European Union house prices after adjusting for salary growth, 2015-2024

## Data

Sources:

- Eurostat `prc_hpi_a`: annual house price index, `purchase=TOTAL`, `unit=I15_A_AVG`.
  - Data: <https://ec.europa.eu/eurostat/databrowser/view/prc_hpi_a/default/table>
  - Metadata: <https://ec.europa.eu/eurostat/cache/metadata/en/prc_hpi_inx_esms.htm>
- Eurostat `nama_10_fte`: average full-time adjusted salary per employee, `unit=NAC`.
  - Data: <https://ec.europa.eu/eurostat/databrowser/view/nama_10_fte/default/table>
  - Metadata: <https://ec.europa.eu/eurostat/cache/metadata/en/nama_10_fte_esms.htm>
- Eurostat `prc_hpi_cow`: HPI country weights for the EU contribution screen, `purchase=TOTAL`, `statinfo=COWEU27_2020`, `time=2024`, `unit=PM`.
  - Data: <https://ec.europa.eu/eurostat/databrowser/view/prc_hpi_cow/default/table>
  - Metadata: <https://ec.europa.eu/eurostat/cache/metadata/en/prc_hpi_inx_esms.htm>

The adjusted index is:

```text
house_price_adjusted_by_salary = house_price_index_2015_100 / (salary_year / salary_2015)
change_vs_2015_pct = house_price_adjusted_by_salary - 100
```

Equivalently, the displayed value is `HPI / salary growth index - 1`, expressed as a percentage point change from the 2015 baseline. The neutral point is 0% because the ratio is shown after subtracting the 2015 baseline.

Use national currency (`NAC`) for salaries. Using euros introduces exchange-rate noise for non-euro countries.

## Caveats

- 2015 is close to the post-GFC housing trough for Spain, Portugal, and Ireland. This inflates the apparent gap versus a longer-run base year because part of the move is rebound from a depressed market.
- The salary measure is an average full-time adjusted salary, not a median buyer income.
- This is a price-to-pay proxy, not a mortgage affordability index. It does not include interest rates, taxes, deposits, rents, household structure, or regional dispersion.
- National results hide huge local variation. Spain is the obvious example: Madrid, Barcelona, and the Balearics are not inland Spain.

## Run

```bash
Rscript scripts/fetch_data.R
Rscript scripts/calculate_eu_reversal_contributions.R
Rscript scripts/plot_replication.R
Rscript scripts/build_observable_html.R
Rscript scripts/build_spain_eu_history_html.R
```

Output:

- `data/housing_price_adjusted_by_salary_eu_2015_2024.csv`
- `data/eu_hpi_weighted_reversal_contributions_2022_2024.csv`
- `output/eu_housing_salary_replication.png`
- `output/observable_replication.html`
- `output/spain_eu_history.html`

## EU Reversal Contribution Screen

The small multiples under the Spain/EU comparison use a transparent contribution screen for the 2022-2024 reversal:

```text
hpi_weighted_delta = (adjusted_change_2024 - adjusted_change_2022) * hpi_weight_2024_share
```

Weights come from Eurostat `prc_hpi_cow`, filtered to `purchase=TOTAL`, `statinfo=COWEU27_2020`, and `time=2024`.
Eurostat publishes those weights in per-mille units (`unit=PM`), so the script converts them to shares with `hpi_weight_2024_pm / 1000`.

This is the right weight table for the HPI numerator because Eurostat says EU HPI aggregates are calculated from national HPIs using country weights, and the published 2024 EU27 HPI country weights are the latest weights available for the metric's final year.

This is not a full decomposition of the adjusted EU ratio because the salary denominator comes from `nama_10_fte`, which Eurostat derives from national accounts wages and salaries, employee counts, and Labour Force Survey full-time adjustment ratios. The screen ranks countries by HPI-weighted pressure on the salary-adjusted gap; it does not claim to exactly reconstruct the EU salary denominator country by country.

The generated contribution CSV has these columns:

| Column | Meaning |
| --- | --- |
| `geo` | Eurostat country code |
| `country` | Eurostat country label from the adjusted metric table |
| `change_2022`, `change_2024` | Salary-adjusted house price gap in each year, in percentage points versus 2015 |
| `delta_2022_2024_pct_points` | `change_2024 - change_2022` |
| `hpi_weight_2024_pm` | Eurostat 2024 EU27 HPI country weight, per mille |
| `hpi_weight_2024_share` | `hpi_weight_2024_pm / 1000` |
| `hpi_weighted_delta_pct_points` | `delta_2022_2024_pct_points * hpi_weight_2024_share` |
| `eu_closing_rank` | Rank among countries pulling the HPI-weighted screen down |
| `eu_widening_rank` | Rank among countries pushing the HPI-weighted screen up |
| `contribution_group` | Selected plot group for the top six closers or wideners |
