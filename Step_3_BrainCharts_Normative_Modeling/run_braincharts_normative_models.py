#!/usr/bin/env python3
"""Apply BrainCharts normative models and collect z-score outputs.

This is a command-line version of the core workflow in
apply_normative_models_ct.ipynb from braincharts_normative_modeling_SCI. It
uses the pre-estimated BrainCharts lifespan model, optionally adapts site
effects with a healthy-control adaptation sheet, and writes z-scores for every
test participant and modeled phenotype.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run BrainCharts normative predictions for SCI_MAP.")
    parser.add_argument("--braincharts-root", required=True, help="Local clone of the braincharts repository.")
    parser.add_argument("--test-csv", required=True, help="BrainCharts test CSV from split_braincharts_adaptation_test.py.")
    parser.add_argument("--adaptation-csv", help="Healthy-control adaptation CSV.")
    parser.add_argument("--output-dir", required=True, help="Directory for z-score outputs and model work files.")
    parser.add_argument("--model-name", default="lifespan_57K_82sites", help="BrainCharts model folder name.")
    parser.add_argument("--site-id-file", default="site_ids_ct_82sites.txt", help="Training site ID file in braincharts/docs.")
    parser.add_argument(
        "--phenotype-files",
        nargs="+",
        default=["phenotypes_ct_lh.txt", "phenotypes_ct_rh.txt", "phenotypes_sc.txt"],
        help="Phenotype lists in braincharts/docs.",
    )
    parser.add_argument("--subject-col", default="subject", help="Subject ID column in test/adaptation CSVs.")
    parser.add_argument("--site-col", default="site", help="Site column. Default: site.")
    parser.add_argument("--sitenum-col", default="sitenum", help="Numeric site column used by PCNtoolkit adaptation.")
    parser.add_argument("--age-col", default="age", help="Age covariate column. Default: age.")
    parser.add_argument("--sex-col", default="sex", help="Sex covariate column. Default: sex.")
    parser.add_argument("--xmin", type=float, default=-5, help="Lower age limit for B-spline basis.")
    parser.add_argument("--xmax", type=float, default=110, help="Upper age limit for B-spline basis.")
    parser.add_argument("--force-adaptation", action="store_true", help="Use adaptation data even if test sites are present in the training model.")
    parser.add_argument("--allow-missing-adaptation-sites", action="store_true", help="Warn instead of failing when a test site is missing from adaptation data.")
    parser.add_argument("--z-suffix", default="_zscore", help="Suffix appended to phenotype names in z-score columns.")
    return parser.parse_args()


def read_lines(path: Path) -> list[str]:
    with path.open(encoding="utf-8") as handle:
        return [line.strip() for line in handle if line.strip()]


def require_columns(frame, columns: list[str], label: str) -> None:
    missing = [col for col in columns if col not in frame.columns]
    if missing:
        raise SystemExit(f"{label} is missing required column(s): {', '.join(missing)}")


def main() -> None:
    args = parse_args()

    braincharts_root = Path(args.braincharts_root).resolve()
    docs_dir = braincharts_root / "docs"
    model_dir = braincharts_root / "models" / args.model_name
    output_dir = Path(args.output_dir).resolve()
    work_root = output_dir / "model_work"

    if not docs_dir.is_dir():
        raise SystemExit(f"BrainCharts docs directory not found: {docs_dir}")
    if not model_dir.is_dir():
        raise SystemExit(f"BrainCharts model directory not found: {model_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)
    work_root.mkdir(parents=True, exist_ok=True)
    sys.path.insert(0, str(braincharts_root))

    try:
        import numpy as np
        import pandas as pd
        from pcntoolkit.normative import predict
        from pcntoolkit.util.utils import create_design_matrix
    except ImportError as exc:
        raise SystemExit(
            "Missing Python dependency. Install the BrainCharts/PCNtoolkit environment "
            "first, for example: pip install pcntoolkit==0.35"
        ) from exc

    site_ids_tr = read_lines(docs_dir / args.site_id_file)

    idp_ids: list[str] = []
    for filename in args.phenotype_files:
        idp_ids.extend(read_lines(docs_dir / filename))
    idp_ids = list(dict.fromkeys(idp_ids))

    df_te = pd.read_csv(args.test_csv)
    df_te[args.site_col] = df_te[args.site_col].astype(str)
    cols_cov = [args.age_col, args.sex_col]
    required_test = [args.subject_col, args.site_col, args.sitenum_col] + cols_cov + idp_ids
    require_columns(df_te, required_test, "Test CSV")

    for col in cols_cov + [args.sitenum_col]:
        df_te[col] = pd.to_numeric(df_te[col], errors="raise")

    site_ids_te = sorted(set(df_te[args.site_col].to_list()))
    needs_adaptation = args.force_adaptation or not all(site in site_ids_tr for site in site_ids_te)

    df_ad = None
    if needs_adaptation:
        if not args.adaptation_csv:
            raise SystemExit("Adaptation is required for at least one test site; provide --adaptation-csv.")
        df_ad = pd.read_csv(args.adaptation_csv)
        df_ad[args.site_col] = df_ad[args.site_col].astype(str)
        required_ad = [args.subject_col, args.site_col, args.sitenum_col] + cols_cov + idp_ids
        require_columns(df_ad, required_ad, "Adaptation CSV")
        for col in cols_cov + [args.sitenum_col]:
            df_ad[col] = pd.to_numeric(df_ad[col], errors="raise")

        missing_ad_sites = sorted(set(site_ids_te) - set(df_ad[args.site_col].to_list()))
        if missing_ad_sites and not args.allow_missing_adaptation_sites:
            raise SystemExit(
                "Adaptation CSV does not include these test site(s): "
                + ", ".join(missing_ad_sites)
                + ". Use the split script on the full site dataset or pass --allow-missing-adaptation-sites."
            )
        if missing_ad_sites:
            print("WARNING: Missing adaptation site(s): " + ", ".join(missing_ad_sites), file=sys.stderr)

    z_scores = {}
    summary_rows = []

    for idp_num, idp in enumerate(idp_ids, start=1):
        print(f"Running IDP {idp_num}/{len(idp_ids)}: {idp}")
        source_idp_dir = model_dir / idp
        source_model_path = source_idp_dir / "Models"
        if not source_model_path.is_dir():
            raise SystemExit(f"Model files not found for {idp}: {source_model_path}")

        idp_work_dir = work_root / idp
        idp_work_dir.mkdir(parents=True, exist_ok=True)

        y_te = pd.to_numeric(df_te[idp], errors="raise").to_numpy()
        resp_file_te = idp_work_dir / "resp_te.txt"
        np.savetxt(resp_file_te, y_te)

        cov_file_te = idp_work_dir / "cov_bspline_te.txt"
        x_te = create_design_matrix(
            df_te[cols_cov],
            site_ids=df_te[args.site_col],
            all_sites=site_ids_tr,
            basis="bspline",
            xmin=args.xmin,
            xmax=args.xmax,
        )
        np.savetxt(cov_file_te, x_te)

        old_cwd = Path.cwd()
        os.chdir(idp_work_dir)
        try:
            if needs_adaptation:
                assert df_ad is not None
                y_ad = pd.to_numeric(df_ad[idp], errors="raise").to_numpy()
                resp_file_ad = idp_work_dir / "resp_ad.txt"
                np.savetxt(resp_file_ad, y_ad)

                cov_file_ad = idp_work_dir / "cov_bspline_ad.txt"
                x_ad = create_design_matrix(
                    df_ad[cols_cov],
                    site_ids=df_ad[args.site_col],
                    all_sites=site_ids_tr,
                    basis="bspline",
                    xmin=args.xmin,
                    xmax=args.xmax,
                )
                np.savetxt(cov_file_ad, x_ad)

                sitenum_file_ad = idp_work_dir / "sitenum_ad.txt"
                sitenum_file_te = idp_work_dir / "sitenum_te.txt"
                np.savetxt(sitenum_file_ad, df_ad[args.sitenum_col].to_numpy(dtype=int))
                np.savetxt(sitenum_file_te, df_te[args.sitenum_col].to_numpy(dtype=int))

                _, _, z_values = predict(
                    str(cov_file_te),
                    alg="blr",
                    respfile=str(resp_file_te),
                    model_path=str(source_model_path),
                    inputsuffix="estimate",
                    adaptrespfile=str(resp_file_ad),
                    adaptcovfile=str(cov_file_ad),
                    adaptvargroupfile=str(sitenum_file_ad),
                    testvargroupfile=str(sitenum_file_te),
                )
            else:
                _, _, z_values = predict(
                    str(cov_file_te),
                    alg="blr",
                    respfile=str(resp_file_te),
                    inputsuffix="estimate",
                    model_path=str(source_model_path),
                )
        finally:
            os.chdir(old_cwd)

        z_array = np.asarray(z_values).reshape(-1)
        if z_array.shape[0] != df_te.shape[0]:
            z_predict = idp_work_dir / "Z_predict.txt"
            z_array = np.loadtxt(z_predict).reshape(-1)
        if z_array.shape[0] != df_te.shape[0]:
            raise SystemExit(f"Z-score length mismatch for {idp}: expected {df_te.shape[0]}, got {z_array.shape[0]}")

        z_scores[f"{idp}{args.z_suffix}"] = z_array
        summary_rows.append(
            {
                "phenotype": idp,
                "n": int(z_array.shape[0]),
                "mean_z": float(np.nanmean(z_array)),
                "sd_z": float(np.nanstd(z_array, ddof=1)),
                "min_z": float(np.nanmin(z_array)),
                "max_z": float(np.nanmax(z_array)),
                "n_abs_z_gt_7": int(np.sum(np.abs(z_array) > 7)),
            }
        )

    z_df = pd.DataFrame(z_scores)
    idp_set = set(idp_ids)
    metadata_cols = [col for col in df_te.columns if col not in idp_set]
    z_only = pd.concat([df_te[metadata_cols].reset_index(drop=True), z_df], axis=1)
    full_with_z = pd.concat([df_te.reset_index(drop=True), z_df], axis=1)
    summary = pd.DataFrame(summary_rows)

    z_only_path = output_dir / "braincharts_zscores.csv"
    full_path = output_dir / "braincharts_test_with_zscores.csv"
    summary_path = output_dir / "braincharts_zscore_summary.csv"

    z_only.to_csv(z_only_path, index=False)
    full_with_z.to_csv(full_path, index=False)
    summary.to_csv(summary_path, index=False)

    print("Wrote:")
    print(f"  {z_only_path}")
    print(f"  {full_path}")
    print(f"  {summary_path}")


if __name__ == "__main__":
    main()
