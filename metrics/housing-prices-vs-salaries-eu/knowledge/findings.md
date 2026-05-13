# Findings

## Formula

- The replicated metric is:

```text
adjusted_index = house_price_index_2015_100 / (salary_year / salary_2015)
change_pct = adjusted_index - 100
```

- In prose, the displayed value is `HPI / salary growth index - 1`, expressed as a percentage point change from the 2015 baseline. This is why the chart's neutral point is 0%, even though the underlying ratio's neutral point is 1.0.
- Spain validates the formula against the reference chart: HPI 2024 is `160.25`, salary rises from `27,175` to `33,700`, and `160.25 / (33700 / 27175) = 129.2`, i.e. `+29.2%`.

## Eurostat Sources

- House prices use Eurostat `prc_hpi_a`, filtered to `purchase=TOTAL`, `unit=I15_A_AVG`.
  - Data: <https://ec.europa.eu/eurostat/databrowser/view/prc_hpi_a/default/table>
  - Metadata: <https://ec.europa.eu/eurostat/cache/metadata/en/prc_hpi_inx_esms.htm>
- Salaries use Eurostat `nama_10_fte`, filtered to `unit=NAC`.
  - Data: <https://ec.europa.eu/eurostat/databrowser/view/nama_10_fte/default/table>
  - Metadata: <https://ec.europa.eu/eurostat/cache/metadata/en/nama_10_fte_esms.htm>
- EU reversal contribution screening uses Eurostat `prc_hpi_cow`, filtered to `purchase=TOTAL`, `statinfo=COWEU27_2020`, `time=2024`, and `unit=PM`.
  - Data: <https://ec.europa.eu/eurostat/databrowser/view/prc_hpi_cow/default/table>
  - Metadata: <https://ec.europa.eu/eurostat/cache/metadata/en/prc_hpi_inx_esms.htm>
- Portugal housing-market context uses Banco de Portugal and OECD synthesis:
  - Banco de Portugal Financial Stability Report, November 2024: <https://www.bportugal.pt/en/publicacao/financial-stability-report-november-2024>
  - Banco de Portugal Financial Stability Report, May 2024: <https://www.bportugal.pt/en/publicacao/financial-stability-report-may-2024>
  - OECD Economic Surveys: Portugal 2026, housing affordability chapter: <https://www.oecd.org/en/publications/oecd-economic-surveys-portugal-2026_025b3445-en/full-report/tackling-portugal-s-housing-affordability-challenge-promoting-sustainable-and-inclusive-housing_c920df36.html>
- EU housing reversal context uses European Commission housing notes:
  - Spring 2025 forecast special topic: <https://economy-finance.ec.europa.eu/economic-forecast-and-surveys/economic-forecasts/spring-2025-economic-forecast-moderate-growth-amid-global-economic-uncertainty/signals-turnaround-housing-market_en>
  - Autumn 2023 special topic PDF: <https://ec.europa.eu/economy_finance/forecasts/2023/autumn/cooling_housing_market_amid_mortgage_rate_increases_en.pdf>
- `nama_10_fte` metadata says the indicator is available for all EU Member States except the Netherlands.
- `nama_10_fte` metadata says Statistics Netherlands uses a different methodology based on exhaustive register information.
- Eurostat news summaries can mention the Netherlands by pointing users to the metadata-linked CBS fallback. That does not mean the Netherlands exists in the harmonised `nama_10_fte` dataset under `unit=NAC`.
- Availability check on 2026-05-11: `prc_hpi_a` has annual 2025 values for the selected geographies, but `nama_10_fte` stops at 2024. There are no 2026 values in either source under the selected filters. The latest valid end year for the combined adjusted metric remains 2024.

## EU Reversal Contribution Screen

- The 2022-2024 EU reversal screen is:

```text
hpi_weighted_delta = (adjusted_change_2024 - adjusted_change_2022) * (hpi_weight_2024_pm / 1000)
```

- The method uses `prc_hpi_cow` because Eurostat says EU HPI aggregates are calculated from national HPIs using country weights, and `prc_hpi_cow` publishes those weights in per-mille units.
- This is a numerator-weighted contribution screen, not a full decomposition of the EU adjusted ratio. The salary denominator comes from `nama_10_fte`, which Eurostat derives from national accounts wages and salaries, employee counts, and Labour Force Survey full-time adjustment ratios.
- Under this screen, the largest six HPI-weighted 2022-2024 closing countries are Germany, France, Austria, Romania, Sweden, and Czechia.
- The largest six HPI-weighted widening countries are Spain, Portugal, Cyprus, Croatia, Malta, and Lithuania.
- The small multiples display each six-country group ordered by 2024 EU27 HPI weight, not by contribution rank.
- Germany dominates the closing side: its adjusted gap fell from `+37.4%` in 2022 to `+10.0%` in 2024, and its 2024 EU27 HPI weight is `211.92` per mille.
- The exact Germany calculation is `(9.973044 - 37.434825) * (211.92 / 1000) = -5.81970063` percentage points.
- The exact Spain calculation is `(29.222366 - 25.245293) * (98.21 / 1000) = +0.39058834` percentage points.
- Spain accounts for about 92% of positive HPI-weighted pressure in the 2022-2024 screen. The other positive countries in the reproducible output add only about `+0.03` percentage points combined.
- Spain matters because its salary-adjusted gap widened and its 2024 EU27 HPI weight is large. Smaller countries such as Cyprus and Malta also worsened, but their HPI weights are too small to move the screen.
- Portugal is the level outlier: by 2021 its HPI had risen to `168.84` while the salary index was `120.06`, producing a salary-adjusted gap of `+40.63%`.
- Portugal barely worsened after 2022 in this metric because HPI rose `18.0%` from 2022 to 2024 while the salary index rose `17.4%`. Spain worsened because HPI rose `12.9%` while the salary index rose `9.4%`.
- Banco de Portugal attributes Portugal's housing pressure to a weak supply response after the financial crisis, demand from residents and non-residents, tourism, Golden Visa effects, non-habitual resident tax benefits, and limited market stock. The November 2024 Financial Stability Report says Portugal built less than half as many dwellings from 2015-2023 as in the preceding eight years and licensed only `17` dwellings per thousand inhabitants from 2013-2022, versus `60` in France and `34` in Germany.
- The EU reversal around 2021-2022 is consistent with the European Commission's housing-market analysis: nominal euro-area house prices peaked in mid-2022, mortgage-rate increases reduced borrowing capacity, credit flows contracted, and the drop was led by large markets such as Germany and the Netherlands while several smaller markets also cooled.

## Observable HTML

- Standalone Observable Plot HTML works best with a bundled ESM import:

```js
import * as Plot from "https://esm.sh/@observablehq/plot@0.6.17?bundle";
```

- The earlier jsDelivr `+esm` import caused dependency paths to resolve against the local server, producing local `/npm/...` 404s.
- Final-value badges should be positioned after the panels are in the DOM; otherwise measurements are zero and badges land in the wrong place.
- When embedding the standalone chart in an Astro prose post, the iframe should stay in the prose column and resize to the chart document height. A fixed iframe height creates either inner scrollbars or ugly blank space.
- The Observable HTML title should be allowed to wrap; a forced one-line title clips inside medium-width iframes.
- The website version works better as a ranked horizontal bar chart than as the original small-multiple replica. It fits the prose layout, reduces visual clutter, and makes Spain's rank immediately obvious.
- Chart HTML should use the website font stack (`Styrene B` for chart text and `Tiempos Text` for the title) and transparent backgrounds so the embed inherits the site feel.
- The ranked bar chart should retain the EU aggregate from the original reference. A striped "European Union" row works better than a dotted reference line here because it keeps the aggregate visible in the same reading pattern as the countries while still visually marking it as not a country.
