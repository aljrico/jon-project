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
- Under this screen, the largest HPI-weighted 2022-2024 closing countries are Germany, France, and Austria.
- The largest HPI-weighted widening countries are Spain, Portugal, and Cyprus.
- Germany dominates the closing side: its adjusted gap fell from `+37.4%` in 2022 to `+10.0%` in 2024, and its 2024 EU27 HPI weight is `211.92` per mille.
- The exact Germany calculation is `(9.973044 - 37.434825) * (211.92 / 1000) = -5.81970063` percentage points.
- The exact Spain calculation is `(29.222366 - 25.245293) * (98.21 / 1000) = +0.39058834` percentage points.

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
