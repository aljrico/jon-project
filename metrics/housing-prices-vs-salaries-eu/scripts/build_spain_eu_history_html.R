library(jsonlite)
library(readr)

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
root <- if (length(file_arg)) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
  normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
} else {
  normalizePath(getwd(), mustWork = TRUE)
}

data_path <- file.path(root, "data", "housing_price_adjusted_by_salary_eu_2015_2024.csv")
out_path <- file.path(root, "output", "spain_eu_history.html")
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

data <- read_csv(data_path, show_col_types = FALSE)
history <- data[data$geo %in% c("ES", "EU27_2020"), ]
history_json <- toJSON(history, dataframe = "rows", auto_unbox = TRUE, na = "null", digits = 8)

html <- paste0(
'<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Spain and EU house prices adjusted for salary growth</title>
  <style>
    @font-face {
      font-family: "Styrene B";
      font-style: normal;
      font-weight: 400;
      font-display: swap;
      src: url("/fonts/StyreneB-Regular.woff2") format("woff2");
    }

    @font-face {
      font-family: "Styrene B";
      font-style: normal;
      font-weight: 600 800;
      font-display: swap;
      src: url("/fonts/StyreneB-Bold.woff2") format("woff2");
    }

    :root {
      --ink: #26323d;
      --muted: #7d8a96;
      --grid: #e9eef2;
      --blue: #234766;
      --red: hsl(351deg 66% 48%);
      --zero: #9aa7b3;
      --chart-bg: transparent;
      color-scheme: light dark;
    }

    * { box-sizing: border-box; }

    html,
    body {
      margin: 0;
      overflow: hidden;
      background: var(--chart-bg);
    }

    body {
      font-family: "Styrene B", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      color: var(--ink);
    }

    main {
      width: 100%;
      margin: 0 auto;
    }

    .history-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 28px;
      width: 100%;
    }

    .history-panel {
      min-width: 0;
    }

    .panel-heading {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 8px;
    }

    h2 {
      margin: 0;
      color: var(--ink);
      font-size: 13px;
      line-height: 1.2;
      letter-spacing: 0;
      font-weight: 800;
    }

    .final-value {
      flex: 0 0 auto;
      font-size: 12px;
      line-height: 1.2;
      font-weight: 800;
    }

    .chart {
      width: 100%;
    }

    .chart svg {
      display: block;
      width: 100%;
      height: auto;
      overflow: visible;
      background: transparent;
    }

    @media (max-width: 620px) {
      .history-grid {
        grid-template-columns: 1fr;
        gap: 24px;
      }
    }

    @media (prefers-color-scheme: dark) {
      :root {
        --ink: #e8edf2;
        --muted: #b7c0c9;
        --grid: rgba(232, 237, 242, 0.14);
        --zero: rgba(232, 237, 242, 0.42);
        --chart-bg: #1b1f22;
      }
    }
  </style>
</head>
<body>
  <main>
    <section class="history-grid" aria-label="Salary-adjusted house price history for Spain and the European Union">
      <article class="history-panel" data-series="ES">
        <div class="panel-heading">
          <h2>Spain</h2>
          <div class="final-value" data-final="ES"></div>
        </div>
        <div class="chart" id="chart-es"></div>
      </article>
      <article class="history-panel" data-series="EU27_2020">
        <div class="panel-heading">
          <h2>European Union</h2>
          <div class="final-value" data-final="EU27_2020"></div>
        </div>
        <div class="chart" id="chart-eu"></div>
      </article>
    </section>
  </main>

  <script id="history-data" type="application/json">', history_json, '</script>
  <script type="module">
    import * as Plot from "https://esm.sh/@observablehq/plot@0.6.17?bundle";

    const data = JSON.parse(document.getElementById("history-data").textContent)
      .map(d => ({
        geo: d.geo,
        year: +d.year,
        change: +d.change_vs_2015_pct
      }))
      .filter(d => Number.isFinite(d.change));

    const series = {
      ES: {
        title: "Spain",
        color: "hsl(351deg 66% 48%)",
        element: document.getElementById("chart-es")
      },
      EU27_2020: {
        title: "European Union",
        color: "#234766",
        element: document.getElementById("chart-eu")
      }
    };

    const fmtPct = value => `${value >= 0 ? "+" : "-"}${Math.abs(value).toFixed(1)}%`;

    function getTheme() {
      const styles = getComputedStyle(document.documentElement);
      return {
        ink: styles.getPropertyValue("--ink").trim() || "#26323d",
        muted: styles.getPropertyValue("--muted").trim() || "#7d8a96",
        grid: styles.getPropertyValue("--grid").trim() || "#e9eef2",
        zero: styles.getPropertyValue("--zero").trim() || "#9aa7b3"
      };
    }

    function clearPlotBackground(svg) {
      svg.style.background = "transparent";
      Array.from(svg.querySelectorAll("rect"))
        .filter(rect => {
          if (rect.closest("defs")) return false;
          const height = +rect.getAttribute("height");
          const width = +rect.getAttribute("width");
          return height >= 40 && width >= 40;
        })
        .forEach(rect => {
          rect.setAttribute("fill", "transparent");
          rect.setAttribute("stroke", "none");
        });
    }

    function renderSeries(geo, config) {
      const theme = getTheme();
      const rows = data
        .filter(d => d.geo === geo)
        .sort((a, b) => a.year - b.year);
      const width = Math.max(260, config.element.clientWidth || 360);
      const compact = width < 330;
      const yMax = Math.ceil(Math.max(30, ...rows.map(d => d.change)) / 5) * 5;
      const final = rows[rows.length - 1];

      document.querySelector(`[data-final="${geo}"]`).textContent = fmtPct(final.change);
      document.querySelector(`[data-final="${geo}"]`).style.color = config.color;

      config.element.replaceChildren();
      const plot = Plot.plot({
        width,
        height: compact ? 190 : 220,
        marginTop: 8,
        marginRight: 18,
        marginBottom: 28,
        marginLeft: 38,
        style: {
          background: "transparent",
          overflow: "visible",
          fontFamily: "Styrene B, ui-sans-serif, system-ui, sans-serif",
          fontSize: compact ? "10px" : "11px",
          color: theme.muted
        },
        x: {
          domain: [2015, 2024],
          ticks: [2015, 2018, 2021, 2024],
          tickFormat: d => String(d),
          label: null,
          grid: false
        },
        y: {
          domain: [0, yMax],
          ticks: [0, 10, 20, 30],
          tickFormat: d => `${d}%`,
          label: null,
          grid: true
        },
        marks: [
          Plot.ruleY([0], {stroke: theme.zero, strokeWidth: 1}),
          Plot.areaY(rows, {
            x: "year",
            y1: 0,
            y2: "change",
            fill: config.color,
            fillOpacity: 0.12,
            curve: "catmull-rom"
          }),
          Plot.lineY(rows, {
            x: "year",
            y: "change",
            stroke: config.color,
            strokeWidth: 2.5,
            curve: "catmull-rom"
          }),
          Plot.dot(rows.filter(d => d.year === 2024), {
            x: "year",
            y: "change",
            r: 3.8,
            fill: config.color,
            stroke: "transparent"
          })
        ]
      });

      config.element.appendChild(plot);
      clearPlotBackground(plot);
    }

    function render() {
      Object.entries(series).forEach(([geo, config]) => renderSeries(geo, config));
    }

    render();
    let resizeTimer;
    window.addEventListener("resize", () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(render, 80);
    });
  </script>
</body>
</html>
'
)

writeLines(html, out_path, useBytes = TRUE)
message("Wrote ", out_path)
