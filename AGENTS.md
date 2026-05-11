# Project Standards

This is JON — Journal of Numbers: an open-source public-interest metrics project, starting with Spain. The job is to find important signals that are easy to miss, document them obsessively, and publish them without hiding the machinery.

## Core Principles

- Every metric must be reproducible end-to-end.
- Every published number must trace back to a source, query, formula, script, and output artifact.
- Every caveat that matters must be written down as soon as it is found.
- The data pipeline is the source of truth. The website is only a publishing surface.
- Prefer boring, inspectable artifacts over clever invisible magic.

## Reproducibility

- Each metric lives in `metrics/<metric-id>/`.
- Each metric must have a `README.md`, `metric.yml`, `scripts/`, `data/`, `output/`, and `knowledge/`.
- Raw downloads should be cached or archived when practical, with retrieval timestamps and source query URLs.
- Derived datasets must document source tables, filters, transformations, units, formulas, and missingness.
- Generated outputs must be rebuildable and should not be hand-edited.
- Scripts must fail loudly when required inputs, columns, years, geographies, or units are missing.

## Sources And Citations

- Cite sources to an agonising degree. Dataset IDs alone are not enough.
- Record source URLs, API query parameters, access dates, update timestamps, units, dimensions, and relevant metadata pages.
- Prefer primary sources: Eurostat, INE, Banco de España, ministries, national statistical offices, and official APIs.
- If a metric uses fallback or mixed sources, document the comparability risk in `knowledge/caveats.md` and the output notes.

## R First

- Use pure R wherever reasonable.
- Prefer S4 classes for formal data shapes, validation, and pipeline contracts.
- Prefer `data.table` for data manipulation.
- Keep dependencies lean and justified.
- Avoid moving core analysis into JavaScript, Python, notebooks, or the Astro site.
- R owns retrieval, validation, shaping, and artifact generation.

## HTML And Charts

- Interactive charts should be renderable as standalone pure HTML using Observable Plot.
- Standalone chart HTML must work outside the website for inspection.
- Astro integration should consume built artifacts from `output/`, not recompute metric logic.
- Static PNG/SVG charts are useful for previews, social cards, and regression checks.

## Project Knowledge

- Each metric keeps cumulative notes under `knowledge/`.
- Use `knowledge/caveats.md` for limitations, missing data, source mixing, and interpretation warnings.
- Use `knowledge/findings.md` for researched facts, source behavior, formula confirmations, and implementation discoveries.
- Do not delete old findings just because the project moved on. Amend them with newer context.

## Visual QA

- Visually inspect charts before considering them done.
- Check labels, hover states, missing-data states, axes, responsive behavior, and source notes.
- Save visual QA screenshots when useful.
- If a chart replicates a reference, explicitly document known differences.

## Publishing

- Publishable artifacts should be copied into the Astro site under `public/metrics/<metric-id>/`.
- Posts in the Astro site should tell the story and embed the artifact.
- Do not put source data fetching or metric calculations inside Astro components.
- If an Astro post depends on a metric artifact, the post should link back to the metric repo path and cite the metric manifest.
