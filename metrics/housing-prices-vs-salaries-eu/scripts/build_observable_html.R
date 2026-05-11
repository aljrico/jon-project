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
out_path <- file.path(root, "output", "observable_replication.html")
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

data <- read_csv(data_path, show_col_types = FALSE)
data_json <- toJSON(data, dataframe = "rows", auto_unbox = TRUE, na = "null", digits = 8)

html <- paste0(
'<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Precio de la vivienda ajustado a salarios | Observable Plot</title>
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

    @font-face {
      font-family: "Tiempos Text";
      font-style: normal;
      font-weight: 700;
      font-display: swap;
      src: url("/fonts/TiemposText-Bold.woff2") format("woff2");
    }

    :root {
      --ink: #26323d;
      --muted: #7d8a96;
      --grid: #e9eef2;
      --bar: #234766;
      --red: hsl(351deg 66% 48%);
      --zero: #9aa7b3;
      --chart-bg: transparent;
      color-scheme: light dark;
    }

    * { box-sizing: border-box; }

    html {
      background: var(--chart-bg);
      overflow: hidden;
    }

    body {
      margin: 0;
      font-family: "Styrene B", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      color: var(--ink);
      background: var(--chart-bg);
      overflow: hidden;
    }

    main {
      width: 100%;
      margin: 0 auto;
    }

    h1 {
      margin: 0 0 8px;
      font-family: "Tiempos Text", Georgia, serif;
      font-size: clamp(22px, 4vw, 28px);
      line-height: 1.08;
      letter-spacing: 0;
      font-weight: 700;
      white-space: normal;
      color: var(--ink);
    }

    .subtitle {
      max-width: 100%;
      margin: 0 0 22px;
      color: var(--muted);
      font-size: 13.5px;
      line-height: 1.5;
    }

    #chart {
      width: 100%;
    }

    #chart svg {
      display: block;
      width: 100%;
      height: auto;
      overflow: visible;
      background: transparent;
    }

    .sources {
      margin-top: 14px;
      color: var(--muted);
      font-size: 11.5px;
      line-height: 1.5;
    }

    .missing-note {
      margin-top: 8px;
      color: var(--muted);
    }

    .tooltip {
      position: fixed;
      pointer-events: none;
      z-index: 20;
      display: none;
      min-width: 210px;
      padding: 9px 10px;
      border-radius: 6px;
      background: rgba(22, 42, 61, 0.96);
      color: white;
      box-shadow: 0 8px 24px rgba(28, 47, 66, 0.18);
      font-size: 12px;
      line-height: 1.35;
    }

    .tooltip strong {
      display: block;
      margin-bottom: 4px;
      font-size: 12px;
    }

    .tooltip .row {
      display: flex;
      justify-content: space-between;
      gap: 14px;
      color: #dce8f2;
    }

    .tooltip b {
      color: white;
      font-weight: 800;
    }

    @media (max-width: 720px) {
      main {
        width: 100%;
      }

      h1 {
        font-size: 24px;
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
    <h1>Vivienda contra salarios</h1>
    <p class="subtitle">Incremento del precio de la vivienda ajustado al crecimiento de los salarios, 2015-2024. Valores positivos indican que la vivienda se encareció más rápido que los salarios.</p>
    <section id="chart" aria-label="Ranking de países por incremento ajustado"></section>
    <section class="sources">
      <div><strong>Fuentes:</strong> Eurostat, índice de precios de la vivienda y remuneración por empleado en cuentas nacionales, datos más recientes disponibles (2024)</div>
      <div><strong>Nota:</strong> Elaboración propia a partir del House Price Index deflactado con el crecimiento de los salarios, con 2015 definido como el año base (índice = 100)</div>
      <div class="missing-note">Sin datos suficientes para Grecia y Países Bajos bajo los filtros armonizados usados aquí.</div>
    </section>
  </main>

  <script id="housing-data" type="application/json">', data_json, '</script>
  <script type="module">
    import * as Plot from "https://esm.sh/@observablehq/plot@0.6.17?bundle";

    const data = JSON.parse(document.getElementById("housing-data").textContent);

    const labels = {
      EU27_2020: "Unión Europea",
      BE: "Bélgica",
      BG: "Bulgaria",
      CZ: "R. Checa",
      DK: "Dinamarca",
      DE: "Alemania",
      EE: "Estonia",
      IE: "Irlanda",
      ES: "España",
      FR: "Francia",
      HR: "Croacia",
      IT: "Italia",
      CY: "Chipre",
      LV: "Letonia",
      LT: "Lituania",
      LU: "Luxemburgo",
      HU: "Hungría",
      MT: "Malta",
      NL: "Países Bajos",
      AT: "Austria",
      PL: "Polonia",
      PT: "Portugal",
      RO: "Rumanía",
      SI: "Eslovenia",
      SK: "Eslovaquia",
      FI: "Finlandia",
      SE: "Suecia"
    };

    const tooltip = document.createElement("div");
    tooltip.className = "tooltip";
    document.body.appendChild(tooltip);

    const fmtPct = value => {
      if (value == null || Number.isNaN(value)) return "";
      const formatted = Math.abs(value).toFixed(1).replace(".", ",");
      return `${value >= 0 ? "+" : "-"}${formatted}%`;
    };

    const fmtIndex = value => value == null || Number.isNaN(value)
      ? "n/a"
      : value.toFixed(1).replace(".", ",");

    const euRow = data
      .filter(d => +d.year === 2024 && d.geo === "EU27_2020" && d.change_vs_2015_pct != null)
      .map(d => ({
        geo: d.geo,
        country: "Unión Europea",
        change: +d.change_vs_2015_pct,
        adjusted: +d.house_price_adjusted_by_salary_index_2015_100,
        hpi: +d.house_price_index_2015_100,
        salaryIndex: +d.salary_index_2015_100
      }))[0];

    const rows = data
      .filter(d => +d.year === 2024 && d.geo !== "EU27_2020" && d.change_vs_2015_pct != null)
      .map(d => ({
        geo: d.geo,
        country: labels[d.geo] ?? d.country ?? d.geo,
        change: +d.change_vs_2015_pct,
        adjusted: +d.house_price_adjusted_by_salary_index_2015_100,
        hpi: +d.house_price_index_2015_100,
        salaryIndex: +d.salary_index_2015_100
      }))
      .sort((a, b) => b.change - a.change);

    const plotRows = (euRow ? rows.concat(euRow) : rows)
      .sort((a, b) => b.change - a.change);

    const chart = document.getElementById("chart");

    function render() {
      chart.replaceChildren();
      const width = Math.max(320, chart.clientWidth || 900);
      const compact = width < 620;
      const theme = getTheme();
      const marginLeft = compact ? 118 : 150;
      const marginRight = compact ? 44 : 72;
      const height = plotRows.length * (compact ? 29 : 33) + 56;
      const changes = plotRows.map(d => d.change);
      const xMin = Math.min(-70, Math.floor(Math.min(...changes) / 10) * 10 - 10);
      const xMax = Math.max(55, Math.ceil(Math.max(...changes) / 10) * 10);

      const plot = Plot.plot({
        width,
        height,
        marginLeft,
        marginRight,
        marginTop: 10,
        marginBottom: 32,
        style: {
          background: "transparent",
          overflow: "visible",
          fontFamily: "Styrene B, ui-sans-serif, system-ui, sans-serif",
          fontSize: compact ? "10px" : "12px",
          color: theme.ink
        },
        x: {
          domain: [xMin, xMax],
          ticks: [-50, -25, 0, 25, 50],
          tickFormat: d => `${d}%`,
          grid: true,
          label: "Incremento ajustado desde 2015",
          labelAnchor: "center",
          labelArrow: "none"
        },
        y: {
          domain: plotRows.map(d => d.country),
          label: null,
          tickSize: 0
        },
        marks: [
          Plot.ruleX([0], {stroke: theme.zero, strokeWidth: 1}),
          Plot.barX(plotRows, {
            y: "country",
            x: "change",
            fill: d => d.geo === "ES" ? "hsl(351deg 66% 48%)" : "#234766",
            fillOpacity: 1,
            rx: 5,
            tip: false
          })
        ]
      });

      chart.appendChild(plot);
      clearPlotBackground(plot);
      const bars = getBarRects(plot);
      bars.forEach((rect, i) => {
        rect.setAttribute("rx", "5");
        rect.setAttribute("ry", "5");
        if (plotRows[i]?.geo === "EU27_2020") {
          rect.setAttribute("fill", "url(#eu-stripes)");
        }
      });
      addEuStripePattern(plot);
      addCountryLabels(plot, plotRows, compact, theme);
      addValueLabels(plot, plotRows, compact);

      installTooltip(plot);
    }

    function getTheme() {
      const styles = getComputedStyle(document.documentElement);
      return {
        ink: styles.getPropertyValue("--ink").trim() || "#26323d",
        muted: styles.getPropertyValue("--muted").trim() || "#7d8a96",
        zero: styles.getPropertyValue("--zero").trim() || "#9aa7b3"
      };
    }

    function clearPlotBackground(svg) {
      svg.style.background = "transparent";
      const svgWidth = svg.viewBox.baseVal.width || +svg.getAttribute("width") || 0;
      Array.from(svg.querySelectorAll("rect"))
        .filter(rect => {
          if (rect.closest("defs")) return false;
          const height = +rect.getAttribute("height");
          const width = +rect.getAttribute("width");
          return height >= 40 || (svgWidth > 0 && width >= svgWidth - 2);
        })
        .forEach(rect => {
          rect.setAttribute("fill", "transparent");
          rect.setAttribute("stroke", "none");
        });
    }

    function getBarRects(svg) {
      return Array.from(svg.querySelectorAll("rect"))
        .filter(rect => {
          if (rect.closest("defs")) return false;
          const height = +rect.getAttribute("height");
          const width = +rect.getAttribute("width");
          return Number.isFinite(height) && Number.isFinite(width) && height > 0 && height < 40 && width > 0;
        });
    }

    function addEuStripePattern(plot) {
      const svg = plot;
      const ns = "http://www.w3.org/2000/svg";
      const defs = document.createElementNS(ns, "defs");
      const pattern = document.createElementNS(ns, "pattern");
      const background = document.createElementNS(ns, "rect");
      const stripe = document.createElementNS(ns, "path");

      pattern.setAttribute("id", "eu-stripes");
      pattern.setAttribute("patternUnits", "userSpaceOnUse");
      pattern.setAttribute("width", "16");
      pattern.setAttribute("height", "16");
      pattern.setAttribute("patternTransform", "rotate(45)");

      background.setAttribute("width", "16");
      background.setAttribute("height", "16");
      background.setAttribute("fill", "#234766");

      stripe.setAttribute("d", "M 0 0 L 0 16");
      stripe.setAttribute("stroke", "#d8e3ec");
      stripe.setAttribute("stroke-width", "6");
      stripe.setAttribute("stroke-opacity", "0.75");

      pattern.appendChild(background);
      pattern.appendChild(stripe);
      defs.appendChild(pattern);
      svg.insertBefore(defs, svg.firstChild);
    }

    function addCountryLabels(plot, rows, compact, theme) {
      const svg = plot;
      const ns = "http://www.w3.org/2000/svg";
      const bars = getBarRects(svg);
      const countryNames = new Set(rows.map(d => d.country));

      svg.querySelectorAll("text").forEach(text => {
        if (countryNames.has(text.textContent.trim())) {
          text.remove();
        }
      });

      bars.forEach((bar, i) => {
        const d = rows[i];
        if (!d) return;

        const y = +bar.getAttribute("y");
        const height = +bar.getAttribute("height");
        const label = document.createElementNS(ns, "text");

        label.textContent = d.country;
        label.setAttribute("x", "0");
        label.setAttribute("y", String(y + height / 2));
        label.setAttribute("text-anchor", "start");
        label.setAttribute("dominant-baseline", "middle");
        label.setAttribute("alignment-baseline", "middle");
        label.setAttribute("fill", theme.ink);
        label.setAttribute("font-weight", d.geo === "ES" || d.geo === "EU27_2020" ? "800" : "400");
        label.setAttribute("font-size", compact ? "10" : "12");
        label.setAttribute("font-family", "Styrene B, ui-sans-serif, system-ui, sans-serif");
        label.style.pointerEvents = "none";
        svg.appendChild(label);
      });
    }

    function addValueLabels(plot, rows, compact) {
      const svg = plot;
      const ns = "http://www.w3.org/2000/svg";
      const bars = getBarRects(svg);

      bars.forEach((bar, i) => {
        const d = rows[i];
        if (!d) return;

        const x = +bar.getAttribute("x");
        const y = +bar.getAttribute("y");
        const width = +bar.getAttribute("width");
        const height = +bar.getAttribute("height");
        const positive = d.change >= 0;
        const label = document.createElementNS(ns, "text");

        label.textContent = fmtPct(d.change);
        label.setAttribute("x", String(positive ? x + width + 8 : x - 8));
        label.setAttribute("y", String(y + height / 2));
        label.setAttribute("text-anchor", positive ? "start" : "end");
        label.setAttribute("dominant-baseline", "middle");
        label.setAttribute("alignment-baseline", "middle");
        label.setAttribute("fill", d.geo === "ES" ? "hsl(351deg 66% 48%)" : "#234766");
        label.setAttribute("font-weight", "700");
        label.setAttribute("font-size", compact ? "10" : "12");
        label.setAttribute("font-family", "Styrene B, ui-sans-serif, system-ui, sans-serif");
        label.style.pointerEvents = "none";
        svg.appendChild(label);
      });
    }

    function installTooltip(plot) {
      const rects = getBarRects(plot);
      rects.forEach((rect, i) => {
        const d = plotRows[i];
        if (!d) return;
        rect.style.cursor = "default";
        rect.addEventListener("mousemove", event => {
          tooltip.innerHTML = `
            <strong>${d.country}</strong>
            <div class="row"><span>Cambio desde 2015</span><b>${fmtPct(d.change)}</b></div>
            <div class="row"><span>Índice ajustado</span><b>${fmtIndex(d.adjusted)}</b></div>
            <div class="row"><span>HPI vivienda</span><b>${fmtIndex(d.hpi)}</b></div>
            <div class="row"><span>Índice salarios</span><b>${fmtIndex(d.salaryIndex)}</b></div>
          `;
          tooltip.style.left = `${event.clientX + 14}px`;
          tooltip.style.top = `${event.clientY + 14}px`;
          tooltip.style.display = "block";
        });
        rect.addEventListener("mouseleave", () => {
          tooltip.style.display = "none";
        });
      });
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
