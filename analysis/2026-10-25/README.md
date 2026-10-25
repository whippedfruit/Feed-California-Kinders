# Attendance denominator reproduction — October 25, 2026

The verified run reproduces the Irvine/Lodi district comparisons and the October stability audit. Start with [results and limitations](RESULTS.md); the [school-level data dictionary](DATA_DICTIONARY.md) explains the annual denominator handoff.

The annual Census and cumulative-enrollment constructions are sensitivity proxies. The available public data do not identify school × TK/K annual expected attendance days. Irvine provides five observed days; Lodi's eligibility counts are enrollment-related quantities rather than attended student-days. Lodi Preschool is not relabeled as TK.

## Included evidence

- [Irvine attendance extract](../../Irvine/extracted%20data/irvine_k_pk_attendance_2025_11_03_07.csv): 30 K and 28 PK/TK school rows, totaling 14,104 observed student-days for November 3–7, 2025.
- [Lodi Kindergarten extract](../../Lodi/extracted%20data/lodi_kindergarten_enrollment_measures_2025_26.csv): 31 schools; Highest Eligible and Last Day each total 3,481 and agree at every school.
- [64-school annual handoff](tables/irvine_lodi_tk_k_attendance_denominators_2024_25.csv): 63 usable denominators; the suppressed Valley Robotics Academy estimates remain missing. Import CDS identifiers as text.
- [Annual district summary](tables/irvine_lodi_denominator_summary_2024_25.csv), [Irvine same-year summary](tables/irvine_census_vs_observed_attendance_summary_2025_26.csv), and [Lodi same-year summary](tables/lodi_k_census_vs_district_enrollment_summary_2025_26.csv).
- [October mobility results](tables/mobility_test_results.csv), [77-row stability reconciliation](tables/prior_stability_input_comparison.csv), and [230 independent benchmark checks](tables/independent_benchmark_checks.csv). Frozen October references are in `reference/`; newly computed results are in `tables/`.
- [Source versions and hashes](provenance/sources.json), [Irvine source lines](provenance/irvine_row_provenance.csv), [Lodi source cells/pages](provenance/lodi_row_provenance.csv), [discrepancies](provenance/discrepancies.csv), and [execution status](provenance/execution_status.json).
- [Original runner log](logs/RUN_ALL.log) and [original regression log](logs/test_pipeline.log).

The K PDF prints `11.5` twice in its date header. The extracted fourth column is labeled November 6 by the report's five-column weekly sequence. This assumption does not affect five-day totals; day-specific attribution needs district confirmation.

## Reconstruct the district CSVs

From the FCK repository root, using Python 3.12 or compatible Python:

```bash
python3 -m pip install pdfplumber==0.11.9 openpyxl==3.1.5
python3 scripts/reconstruct_irvine_lodi.py
```

This reads the existing PDFs/workbooks and recreates both district CSVs and their row provenance. It checks all Lodi values against the original PDF and the named rows in the cleaned eligibility workbook.

## Run the annual R pipeline

Use the companion [analysis repository at commit f11fb1b](https://github.com/taielucile/ca-school-lunch-attendance/tree/f11fb1b2bef5831753f338b4870bce4fb03048a3). Place the four CDE files specified by its `data/README.md` in `data/raw/` and copy the two district CSVs there with their current filenames. CDE download URLs and SHA-256 hashes are in `provenance/sources.json`.

```r
install.packages(c("dplyr", "readr", "stringr"))
```

From the companion repository root:

```bash
Rscript RUN_ALL.R
Rscript tests/test_pipeline.R
```

Both original commands passed on October 25. Their 16 output CSVs were identical between builds. The original scripts were not modified. CBEDS processing may take several minutes per build.

## Recheck the October audit

Set `FCK_CDE_DIR` to a directory containing `cdenroll2526.txt`, `absenteeismreason26.txt`, and `sr2425-v3.txt` with the hashes recorded in `provenance/sources.json`.

```bash
python3 -m pip install pandas==2.2.3 numpy==2.3.5 scipy==1.18.1 openpyxl==3.1.5
export FCK_CDE_DIR=/absolute/path/to/cde-files
python3 scripts/verify_october_benchmarks.py
python3 scripts/october_stability_audit.py
```

The first command independently checks the saved 46 school/group benchmark units against the existing Ventura/Ojai workbooks and same-year CDE counts. The second verifies stability inputs against the full CDE release and runs the preserved original mobility analysis section. It compares all eight result rows at `1e-10` tolerance and checks the flag table exactly. The original flag target is positive overestimation above 5%, as clarified in the discrepancy register.

Large CDE files, installed packages, and unrelated prior audit materials are not duplicated here. The existing district source files remain at their original paths.
