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

Use national currency (`NAC`) for salaries. Using euros introduces exchange-rate noise for non-euro countries.

## Run

```bash
Rscript scripts/fetch_data.R
Rscript scripts/plot_replication.R
Rscript scripts/build_observable_html.R
```

Output:

- `data/housing_price_adjusted_by_salary_eu_2015_2024.csv`
- `output/eu_housing_salary_replication.png`
- `output/observable_replication.html`
