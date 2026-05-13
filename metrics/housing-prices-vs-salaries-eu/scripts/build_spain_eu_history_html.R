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
contribution_path <- file.path(root, "data", "eu_hpi_weighted_reversal_contributions_2022_2024.csv")
out_path <- file.path(root, "output", "spain_eu_history.html")
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

data <- read_csv(data_path, show_col_types = FALSE)
contributions <- read_csv(contribution_path, show_col_types = FALSE)
selected_geos <- unique(c(
  "ES",
  "EU27_2020",
  contributions$geo[!is.na(contributions$contribution_group)]
))

history <- data[data$geo %in% selected_geos, ]
history_json <- toJSON(history, dataframe = "rows", auto_unbox = TRUE, na = "null", digits = 8)
contribution_json <- toJSON(contributions, dataframe = "rows", auto_unbox = TRUE, na = "null", digits = 8)

html <- paste0(
'<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>House prices adjusted for salary growth: Spain, EU, and weighted movers</title>
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
      --grey: #6f7d88;
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

    .metric-subtitle,
    .group-note,
    .method-note {
      color: var(--muted);
      font-size: 11.5px;
      line-height: 1.5;
    }

    .metric-subtitle {
      margin: 0 0 18px;
      font-weight: 600;
    }

    .group {
      margin: 0 0 28px;
    }

    .group:last-of-type {
      margin-bottom: 0;
    }

    .group-heading {
      margin: 0 0 4px;
      color: var(--ink);
      font-size: 13px;
      line-height: 1.2;
      letter-spacing: 0;
      font-weight: 800;
    }

    .group-note {
      margin: 0 0 12px;
    }

    .history-grid {
      display: grid;
      gap: 24px;
      width: 100%;
    }

    .history-grid.two {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .history-grid.three {
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 22px;
    }

    .history-panel {
      min-width: 0;
    }

    .panel-heading {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      gap: 10px;
      margin-bottom: 6px;
    }

    h3 {
      margin: 0;
      color: var(--ink);
      font-size: 12.5px;
      line-height: 1.2;
      letter-spacing: 0;
      font-weight: 800;
    }

    .final-value {
      flex: 0 0 auto;
      font-size: 11.5px;
      line-height: 1.2;
      font-weight: 800;
    }

    .weighted-note {
      min-height: 16px;
      margin: 0 0 4px;
      color: var(--muted);
      font-size: 10.5px;
      line-height: 1.35;
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

    .method-note {
      margin: 16px 0 0;
    }

    @media (max-width: 520px) {
      .history-grid.two,
      .history-grid.three {
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
    <p class="metric-subtitle">House prices vs. salaries, % above 2015 ratio</p>
    <div id="history-root"></div>
    <p class="method-note"><strong>Contribution screen:</strong> country change from 2022 to 2024 multiplied by its 2024 EU27 HPI country weight from Eurostat <code>prc_hpi_cow</code>, converting per-mille weights to shares. This ranks countries by HPI-weighted pressure on the salary-adjusted gap; it is not a full decomposition of the EU salary denominator.</p>
  </main>

  <script id="history-data" type="application/json">', history_json, '</script>
  <script id="contribution-data" type="application/json">', contribution_json, '</script>
  <script type="module">
    import * as Plot from "https://esm.sh/@observablehq/plot@0.6.17?bundle";

    const data = JSON.parse(document.getElementById("history-data").textContent)
      .map(d => ({
        geo: d.geo,
        country: d.geo === "EU27_2020" ? "European Union" : d.country,
        year: +d.year,
        change: +d.change_vs_2015_pct
      }))
      .filter(d => Number.isFinite(d.change));

    const contributions = JSON.parse(document.getElementById("contribution-data").textContent);

    const colors = {
      blue: "#234766",
      red: "hsl(351deg 66% 48%)",
      grey: "#6f7d88"
    };

    const fmtPct = value => `${value >= 0 ? "+" : "-"}${Math.abs(value).toFixed(1)}%`;
    const fmtSigned = value => `${value >= 0 ? "+" : ""}${value.toFixed(2)}pp`;

    function selectedContribution(geo) {
      return contributions.find(d => d.geo === geo);
    }

    function contributionEntries(group, rankField, colorForGeo) {
      return contributions
        .filter(d => d.contribution_group === group)
        .sort((a, b) => a[rankField] - b[rankField])
        .map(d => ({
          geo: d.geo,
          title: d.country,
          color: colorForGeo(d.geo),
          contribution: d
        }));
    }

    const groups = [
      {
        heading: "Spain vs. the EU",
        note: "Spain keeps rising after 2022. The EU aggregate gives back much of the gap.",
        columns: "two",
        entries: [
          { geo: "ES", title: "Spain", color: colors.red },
          { geo: "EU27_2020", title: "European Union", color: colors.blue }
        ]
      },
      {
        heading: "Where the EU gap closed",
        note: "Top 3 by 2024 EU27 HPI weight x 2022-2024 change in the salary-adjusted gap.",
        columns: "three",
        entries: contributionEntries("largest_hpi_weighted_closers", "eu_closing_rank", () => colors.blue)
      },
      {
        heading: "Where it kept widening",
        note: "Top 3 by the same HPI-weighted screen.",
        columns: "three",
        entries: contributionEntries("largest_hpi_weighted_wideners", "eu_widening_rank", geo => geo === "ES" ? colors.red : colors.grey)
      }
    ];

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

    function createPanels() {
      const root = document.getElementById("history-root");
      root.replaceChildren();

      groups.forEach((group, groupIndex) => {
        const section = document.createElement("section");
        section.className = "group";

        const heading = document.createElement("h2");
        heading.className = "group-heading";
        heading.textContent = group.heading;
        section.appendChild(heading);

        const note = document.createElement("p");
        note.className = "group-note";
        note.textContent = group.note;
        section.appendChild(note);

        const grid = document.createElement("div");
        grid.className = `history-grid ${group.columns}`;

        group.entries.forEach((entry, entryIndex) => {
          const article = document.createElement("article");
          article.className = "history-panel";

          const panelHeading = document.createElement("div");
          panelHeading.className = "panel-heading";

          const title = document.createElement("h3");
          title.textContent = entry.title;
          panelHeading.appendChild(title);

          const finalValue = document.createElement("div");
          finalValue.className = "final-value";
          finalValue.dataset.final = entry.geo;
          panelHeading.appendChild(finalValue);

          const weightedNote = document.createElement("p");
          weightedNote.className = "weighted-note";
          const contribution = entry.contribution ?? selectedContribution(entry.geo);
          if (contribution && groupIndex > 0) {
            weightedNote.textContent = `weighted 2022-24 move ${fmtSigned(+contribution.hpi_weighted_delta_pct_points)}`;
          }

          const chart = document.createElement("div");
          chart.className = "chart";
          chart.dataset.chart = `${groupIndex}-${entryIndex}-${entry.geo}`;

          article.appendChild(panelHeading);
          article.appendChild(weightedNote);
          article.appendChild(chart);
          grid.appendChild(article);

          entry.element = chart;
          entry.finalElement = finalValue;
        });

        section.appendChild(grid);
        root.appendChild(section);
      });
    }

    function renderSeries(entry, group) {
      const theme = getTheme();
      const rows = data
        .filter(d => d.geo === entry.geo)
        .sort((a, b) => a.year - b.year);
      const width = Math.max(160, entry.element.clientWidth || 320);
      const compact = width < 260;
      const groupRows = group.entries.flatMap(item => data.filter(d => d.geo === item.geo));
      const yMax = Math.ceil(Math.max(30, ...groupRows.map(d => d.change)) / 5) * 5;
      const final = rows[rows.length - 1];

      entry.finalElement.textContent = fmtPct(final.change);
      entry.finalElement.style.color = entry.color;

      entry.element.replaceChildren();
      const plot = Plot.plot({
        width,
        height: compact ? 168 : 204,
        marginTop: 8,
        marginRight: 16,
        marginBottom: 28,
        marginLeft: 38,
        style: {
          background: "transparent",
          overflow: "visible",
          fontFamily: "Styrene B, ui-sans-serif, system-ui, sans-serif",
          fontSize: compact ? "9.5px" : "10.5px",
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
          domain: [Math.min(0, Math.floor(Math.min(...groupRows.map(d => d.change)) / 10) * 10), yMax],
          ticks: [0, 10, 20, 30, 40, 50].filter(d => d <= yMax),
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
            fill: entry.color,
            fillOpacity: 0.12,
            curve: "catmull-rom"
          }),
          Plot.lineY(rows, {
            x: "year",
            y: "change",
            stroke: entry.color,
            strokeWidth: 2.4,
            curve: "catmull-rom"
          }),
          Plot.dot(rows.filter(d => d.year === 2024), {
            x: "year",
            y: "change",
            r: 3.6,
            fill: entry.color,
            stroke: "transparent"
          })
        ]
      });

      entry.element.appendChild(plot);
      clearPlotBackground(plot);
    }

    function render() {
      groups.forEach(group => {
        group.entries.forEach(entry => renderSeries(entry, group));
      });
    }

    createPanels();
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
