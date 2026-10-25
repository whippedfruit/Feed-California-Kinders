# Irvine/Lodi school-level denominator handoff: data dictionary

File: `tables/irvine_lodi_tk_k_attendance_denominators_2024_25.csv`

Purpose: school-level 2024–25 TK/K attendance-denominator file for comparison with Irvine Unified and Lodi Unified district data.

**Important:** `cds_code_14char` is an identifier, not a number. CDE defines CDS as a 14-character school identifier. When opening/importing the CSV in spreadsheet software, import this field as **text** to prevent scientific-notation display or other numeric auto-formatting.

| Column | Meaning |
|---|---|
| cds_code_14char | Official 14-digit California County-District-School identifier, stored as character data. |
| district | Focus district: Irvine Unified or Lodi Unified. |
| school | CDE school name. |
| charter | Census enrollment file charter indicator. |
| census_day_tk_enrollment | TK enrollment on Census Day. |
| census_day_k_enrollment | K enrollment on Census Day. |
| census_day_tk_k_enrollment | Combined TK + K Census Day enrollment. |
| eligible_cumulative_tk_k_enrollment | Public Absenteeism by Reason eligible cumulative enrollment for the combined TK/K reporting band. |
| observed_tk_k_absence_days | Publicly reported total absence days for the combined TK/K reporting band. |
| estimated_tk_k_attended_student_days_census_180 | Sensitivity estimate: 180 × Census Day TK/K enrollment − observed TK/K absence days. This is not observed student-days attended. |
| estimated_tk_k_attended_student_days_cumulative_180 | Sensitivity estimate: 180 × eligible cumulative TK/K enrollment − observed TK/K absence days. This is not observed student-days attended. |
| cumulative_minus_census_estimated_student_days | Cumulative-based estimate minus Census-based estimate. |
| cumulative_vs_census_estimate_pct | Percent by which the cumulative-based estimate differs from the Census-based estimate. |
| cbeds_k_program | CBEDS kindergarten program classification. |
| cbeds_tk_program | CBEDS transitional-kindergarten program classification. |
| absenteeism_suppressed | TRUE when the public TK/K absenteeism cell is suppressed. Suppressed values are not treated as zero. |
| usable_public_denominator | TRUE when the public values required for the two denominator estimates are available. |
| notes | School-specific interpretation note where needed. |

The midpoint construction remains available in the internal sensitivity outputs but is intentionally omitted from this collaborator-facing handoff because it is not a substantively identified estimator.
