# EU Housing Prices Adjusted By Salaries

Replication of the small-multiple chart concept:

> Change in European Union house prices after adjusting for salary growth, 2015-2024

## Data

Sources:

- Eurostat `prc_hpi_a`: annual house price index, `purchase=TOTAL`, `unit=I15_A_AVG`
- Eurostat `nama_10_fte`: average full-time adjusted salary per employee, `unit=NAC`

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
Rscript scripts/plot_replication.R
Rscript scripts/build_observable_html.R
Rscript scripts/build_spain_eu_history_html.R
```

Output:

- `data/housing_price_adjusted_by_salary_eu_2015_2024.csv`
- `output/eu_housing_salary_replication.png`
- `output/observable_replication.html`
- `output/spain_eu_history.html`
