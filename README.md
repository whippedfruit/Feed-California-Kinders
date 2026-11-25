# Feed California Kinders

How does the timing of the school day shape access to breakfast and lunch for transitional kindergarten (TK) and kindergarten students in California? This repository brings together district meal and attendance records, statewide data, and project analyses. See the [project proposal](proposal_abstract.md) for the research questions and data limitations.

## Analyses and results

| Analysis | What you'll find |
| --- | --- |
| [Lodi K–5 meal comparisons](https://github.com/taielucile/ca-school-lunch-attendance/blob/main/studies/lodi_2025_26/K5_MEAL_COMPARISONS.md) · November 25, 2026 | Preliminary breakfast and lunch comparisons across 31 schools, using modeled attendance. Includes figures, code, and proposed district follow-up. |
| [Ventura analysis scripts](Ventura%20Unified/) and [figures](Ventura%20Unified/visualizations/) | School and grade comparisons using district meal and attendance records. |
| [Irvine and Lodi attendance reproduction](analysis/2026-10-25/README.md) · October 25, 2026 | District data extracts, a comparison of attendance proxies, and verification logs. See [results and limitations](analysis/2026-10-25/RESULTS.md). |

## Source files by district

| District | Records in this repository |
| --- | --- |
| [Chino](Chino/) | Attendance summary and meals by school and grade |
| [Davis Joint Unified](Davis%20Joint%20Unified/) | Attendance and meal workbooks |
| [Irvine](Irvine/) | Daily attendance and meal PDFs, plus the extracted K and PK/TK attendance table |
| [Lodi](Lodi/) | Meal and eligibility workbooks, plus the kindergarten eligibility extract |
| [Oak Park Unified](Oak%20Park%20Unified/) | District workbook and grade-level meal report |
| [Ojai Unified](Ojai%20Unified/) | Attendance and meal workbooks, plus cleaned tables |
| [San Ramon Valley](San%20Ramon%20Valley/) | Meal report and attendance source reference |
| [Ventura Unified](Ventura%20Unified/) | Attendance and meal PDFs, plus extracted workbooks |

The [statewide files](Statewide/) include a CDE school-site file, meal claims, and a district schedule workbook.

## Reproduce the analyses

Use the [companion R repository](https://github.com/taielucile/ca-school-lunch-attendance) for the attendance pipeline. The [October reproduction guide](analysis/2026-10-25/README.md) explains how to rebuild its district extracts. The [Lodi handoff](https://github.com/taielucile/ca-school-lunch-attendance/blob/main/studies/lodi_2025_26/K5_MEAL_COMPARISONS.md#reproduce) gives the separate K–5 command.

The annual Census and cumulative-enrollment methods estimate attended student-days. Suppressed inputs remain missing. Irvine's district records cover five observed school days, and Lodi's eligibility counts do not establish annual attendance. See the [attendance methods note](https://github.com/taielucile/ca-school-lunch-attendance/blob/main/docs/denominator_method_note.md) for details.
