# Verified results — October 25, 2026

The original `RUN_ALL.R` and unmodified `tests/test_pipeline.R` both exited successfully (code 0). All pipeline regression and integrity tests passed. The 16 output CSVs are byte-for-byte identical across the two full builds. There are no warnings or errors in the runner log. Original source scripts and repository tests were not edited. This report describes the verified run before the repository documentation update.

## Reconstructed district inputs

| Check | Reproduced value |
|---|---:|
| Irvine K school rows | 30 |
| Irvine PK/TK school rows | 28 |
| Irvine K five-day student-days | 8,703 |
| Irvine PK/TK five-day student-days | 5,401 |
| Irvine combined five-day student-days | 14,104 |
| Lodi Kindergarten school rows | 31 |
| Lodi Highest Eligible total | 3,481 |
| Lodi Last Day total | 3,481 |

Irvine row values are extracted from the original PDFs; row provenance preserves the source lines. Lodi values are extracted from the wide original workbook, checked against every value on PDF pages 16–17, and independently checked against the 31 named school rows of the cleaned eligibility workbook. Highest Eligible and Last Day are identical for all schools.

## Annual denominator sensitivity, 2024–25

| District | Schools / usable | Census proxy, 180 days | Cumulative proxy, 180 days | Difference |
|---|---:|---:|---:|---:|
| Irvine | 30 / 30 | 537,808 | 581,908 | +8.1999524% |
| Lodi | 34 / 33 | 430,504 | 464,884 | +7.9859885% |

The 64-school handoff contains 63 usable public denominators. Valley Robotics Academy remains suppressed and its estimates remain missing. The statewide panel contains 10,591 Census school-total rows, including 6,295 with positive TK/K enrollment; 291 positive-TK/K rows have suppressed absenteeism inputs. Non-charter differences reproduce at 8.7574195% for Irvine and 8.5211807% for Lodi.

## Same-year district comparisons, 2025–26

Irvine's 30 attendance-report schools have 3,043 same-year Census TK/K students. Mean daily observed attendance is 2,820.8, or 0.92697995399277 of Census enrollment. The full Irvine Census extract has 47 school rows and 3,318 TK/K students; the 3,043 figure is the report-covered subset. The two missing PK/TK rows have zero TK Census enrollment and are reconciled only on that basis.

Lodi's 31 matched schools have 1,763 same-year Census K students, compared with 3,481 in each report-side measure. The report-to-Census ratio is 1.9744753261486103. This difference does not identify annual attendance exposure.

## October stability/mobility audit

The October reference was recovered from the local October 25 audit archive. All 77 saved stability-input rows match fresh CDE `sr2425-v3.txt`, with zero differences. The original analysis section of `23_mobility_test.py` was executed against source-reconciled unit data; all eight saved result rows reproduce within absolute/relative tolerance `1e-10`, and the flag cross-tab matches exactly.

A separate independent check reconstructs the source counts and observed ADA/ADE for all 46 school/group units from the Ventura and Ojai workbooks plus 2025–26 CDE enrollment and absenteeism files. All 230 field comparisons pass. Ojai ADA/ADE uses the 172 days taught recorded in its workbook; Ventura uses the workbook's daily averages. Student rows are aggregated in memory; no student-level records are written to check outputs.

| Sample | Units | Baseline MAE | MAE after stability correction |
|---|---:|---:|---:|
| TK/K excluding Summit | 20 | 1.1891 | 1.2501 |
| TK/K all units | 21 | 1.1538 | 1.2696 |
| Schoolwide excluding Summit | 24 | 4.1224 | 4.6996 |
| Schoolwide all units | 25 | 4.6963 | 5.2782 |

MAE is measured in average daily students. The leave-one-out stability correction increases MAE in each tested sample. Stability is from the preceding school year, and these small samples do not establish a generally valid correction. The saved flag implementation identifies positive overestimation above 5%, rather than absolute error above 5% as one original comment suggests.

## Discrepancies and limits

See [the discrepancy register](provenance/discrepancies.csv) for the complete issue register. The Irvine K report prints `11.5` above both the Wednesday and Thursday columns. The reporting period is November 3–7, 2025 (Monday–Friday), which confirms that the fourth column is Thursday, November 6. The repeated header is a source-label typo; the extracted values follow the weekday sequence, and five-day totals are unaffected.

The R repository's package-free comment is inaccurate for module 09, which requires dplyr, readr, and stringr. Dependencies were installed locally and versions logged. Three CDE stability rows reuse pseudo-school identifier `0000001`; pseudo-schools are excluded before real-school matching.

No numerical disagreement was found with the frozen district totals or the October stability references. The public-data annual constructions remain sensitivity proxies. Irvine covers five days; Lodi's eligibility measures are not attended student-days; Lodi Preschool is not relabeled as TK. These checks do not identify annual duration-weighted TK/K expected attendance days or select an annual denominator as ground truth.
