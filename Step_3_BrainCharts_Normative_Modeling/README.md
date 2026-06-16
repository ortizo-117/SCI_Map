# Step 3: BrainCharts Normative Modeling

This folder replaces the previous brain-age Steps 3-7. It prepares FreeSurfer outputs for the BrainCharts lifespan normative models, splits healthy controls into adaptation and held-out test sets, applies the site-adapted models, and exports regional z-scores for the statistical analysis.

The workflow follows the core prediction/adaptation logic in [`apply_normative_models_ct.ipynb`](https://github.com/ortizo-117/braincharts_normative_modeling_SCI/blob/main/scripts/apply_normative_models_ct.ipynb).

## Inputs

- FreeSurfer `stats` folders after local processing and QC.
- Participant metadata CSV with at least `subject`, `age`, `sex`, `site`, `sitenum`, and `cohort`.
- `keys_lifespan57K_82sites.csv`, which maps FreeSurfer table headers to BrainCharts model headers.
- A local clone of the BrainCharts repository with the `lifespan_57K_82sites` model unpacked.

Use `cohort=0` or another value listed in `--control-values` for healthy controls. Use a different value for SCI participants so they remain in the test set.

## 1. Build the FreeSurfer table

```bash
bash Step_3_BrainCharts_Normative_Modeling/build_freesurfer_sheet.sh \
  --derivs /path/to/freesurfer_outputs \
  --outdir /path/to/outputs \
  --parc aparc.a2009s
```

This writes `_dbg_joined_all.csv` plus individual debug tables for aseg volume, cortical thickness, and cortical surface area.

## 2. Rename/reorder columns and merge metadata

```bash
bash Step_3_BrainCharts_Normative_Modeling/make_brainchart_outputs.sh \
  --joined /path/to/outputs/_dbg_joined_all.csv \
  --dict Step_3_BrainCharts_Normative_Modeling/keys_lifespan57K_82sites.csv \
  --metadata /path/to/metadata.csv \
  --outdir /path/to/outputs
```

The main output is `braincharts_all_subjects.csv`.

## 3. Split controls for site adaptation

```bash
python Step_3_BrainCharts_Normative_Modeling/split_braincharts_adaptation_test.py \
  --input /path/to/outputs/braincharts_all_subjects.csv \
  --adaptation-out /path/to/outputs/braincharts_adaptation_controls.csv \
  --test-out /path/to/outputs/braincharts_test.csv \
  --adapt-fraction 0.5 \
  --seed 117
```

The adaptation file contains only a reproducible 50 percent subset of healthy controls within each site. The test file contains the held-out controls plus all SCI participants.

## 4. Apply the BrainCharts models

```bash
python Step_3_BrainCharts_Normative_Modeling/run_braincharts_normative_models.py \
  --braincharts-root /path/to/braincharts \
  --adaptation-csv /path/to/outputs/braincharts_adaptation_controls.csv \
  --test-csv /path/to/outputs/braincharts_test.csv \
  --output-dir /path/to/outputs/braincharts_normative_outputs \
  --force-adaptation
```

Outputs:

- `braincharts_zscores.csv`: metadata plus regional z-score columns for Step 9.
- `braincharts_test_with_zscores.csv`: the full BrainCharts test sheet plus z-score columns.
- `braincharts_zscore_summary.csv`: quick QC summary by modeled phenotype.

## Parallel Raw FreeSurfer Analysis

The BrainCharts outputs do not replace the raw morphometry analyses. Step 8 still creates raw FreeSurfer tables for cortical thickness, cortical volume, cortical surface area, subcortical volume, ICV, and white matter volume. Step 9 should be run once on the BrainCharts z-scores and again on the raw FreeSurfer outputs.
