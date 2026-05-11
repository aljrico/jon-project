# Findings

## Formula

- The replicated metric is:

```text
adjusted_index = house_price_index_2015_100 / (salary_year / salary_2015)
change_pct = adjusted_index - 100
```

- Spain validates the formula against the reference chart: HPI 2024 is `160.25`, salary rises from `27,175` to `33,700`, and `160.25 / (33700 / 27175) = 129.2`, i.e. `+29.2%`.

## Eurostat Sources

- House prices use Eurostat `prc_hpi_a`, filtered to `purchase=TOTAL`, `unit=I15_A_AVG`.
- Salaries use Eurostat `nama_10_fte`, filtered to `unit=NAC`.
- `nama_10_fte` metadata says the indicator is available for all EU Member States except the Netherlands.
- `nama_10_fte` metadata says Statistics Netherlands uses a different methodology based on exhaustive register information.
- Availability check on 2026-05-11: `prc_hpi_a` has annual 2025 values for the selected geographies, but `nama_10_fte` stops at 2024. There are no 2026 values in either source under the selected filters. The latest valid end year for the combined adjusted metric remains 2024.

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
