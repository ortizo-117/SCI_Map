#!/usr/bin/env python3
"""Split BrainCharts-ready data into adaptation and test sheets.

The adaptation sheet must contain only healthy controls from each site. The test
sheet contains all SCI participants plus the held-out controls. By default this
uses a 50/50 split of controls within each site.
"""

from __future__ import annotations

import argparse
import csv
import random
from collections import defaultdict
from pathlib import Path


DEFAULT_CONTROL_VALUES = ("0", "control", "controls", "healthy", "hc", "sci_h")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create BrainCharts adaptation and test CSVs from one merged input table."
    )
    parser.add_argument("--input", required=True, help="BrainCharts-ready CSV with metadata and FreeSurfer features.")
    parser.add_argument("--adaptation-out", required=True, help="Output CSV for adaptation controls.")
    parser.add_argument("--test-out", required=True, help="Output CSV for held-out controls and SCI participants.")
    parser.add_argument("--report-out", help="Optional split report CSV.")
    parser.add_argument("--site-col", default="site", help="Site/scanner column. Default: site.")
    parser.add_argument("--cohort-col", default="cohort", help="Cohort/group column. Default: cohort.")
    parser.add_argument("--subject-col", default="subject", help="Subject ID column. Default: subject.")
    parser.add_argument("--adapt-fraction", type=float, default=0.5, help="Fraction of controls per site used for adaptation.")
    parser.add_argument("--seed", type=int, default=117, help="Random seed for reproducible splitting.")
    parser.add_argument(
        "--control-values",
        default=",".join(DEFAULT_CONTROL_VALUES),
        help="Comma-separated values in cohort-col that mean healthy control.",
    )
    return parser.parse_args()


def normalized(value: str) -> str:
    return value.strip().lower()


def read_rows(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        if reader.fieldnames is None:
            raise ValueError(f"{path} has no header")
        return list(reader.fieldnames), rows


def write_rows(path: Path, header: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=header, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    args = parse_args()
    if not 0 < args.adapt_fraction < 1:
        raise SystemExit("--adapt-fraction must be between 0 and 1")

    input_path = Path(args.input)
    header, rows = read_rows(input_path)

    required = [args.site_col, args.cohort_col, args.subject_col, "age", "sex", "sitenum"]
    missing = [col for col in required if col not in header]
    if missing:
        raise SystemExit(f"Missing required column(s) in {input_path}: {', '.join(missing)}")

    control_values = {normalized(v) for v in args.control_values.split(",") if v.strip()}
    controls_by_site: dict[str, list[dict[str, str]]] = defaultdict(list)
    noncontrols: list[dict[str, str]] = []

    for row in rows:
        if normalized(row.get(args.cohort_col, "")) in control_values:
            controls_by_site[row[args.site_col]].append(row)
        else:
            noncontrols.append(row)

    rng = random.Random(args.seed)
    adaptation: list[dict[str, str]] = []
    test: list[dict[str, str]] = []
    report_rows: list[dict[str, str]] = []

    for site in sorted(controls_by_site):
        controls = controls_by_site[site][:]
        controls.sort(key=lambda row: row[args.subject_col])
        rng.shuffle(controls)

        n_controls = len(controls)
        if n_controls == 1:
            n_adapt = 1
        else:
            n_adapt = round(n_controls * args.adapt_fraction)
            n_adapt = max(1, min(n_controls - 1, n_adapt))

        site_adapt = controls[:n_adapt]
        site_test_controls = controls[n_adapt:]
        adaptation.extend(site_adapt)
        test.extend(site_test_controls)

        report_rows.append(
            {
                "site": site,
                "controls_total": str(n_controls),
                "controls_adaptation": str(len(site_adapt)),
                "controls_test": str(len(site_test_controls)),
            }
        )

    test.extend(noncontrols)

    adaptation.sort(key=lambda row: (row[args.site_col], row[args.subject_col]))
    test.sort(key=lambda row: (row[args.site_col], row[args.cohort_col], row[args.subject_col]))

    write_rows(Path(args.adaptation_out), header, adaptation)
    write_rows(Path(args.test_out), header, test)

    report_out = Path(args.report_out) if args.report_out else Path(args.adaptation_out).with_name("braincharts_split_report.csv")
    write_rows(report_out, ["site", "controls_total", "controls_adaptation", "controls_test"], report_rows)

    print(f"Wrote adaptation rows: {len(adaptation)} -> {args.adaptation_out}")
    print(f"Wrote test rows:       {len(test)} -> {args.test_out}")
    print(f"Wrote split report:    {report_out}")


if __name__ == "__main__":
    main()
