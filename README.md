# Feed California Kinders

District source records and analyses for the California school meal and attendance project.

## Verified attendance denominator work

The [October 25, 2026 reproducibility update](analysis/2026-10-25/README.md) includes validated Irvine/Lodi extracts, school-level denominator sensitivity tables, source provenance, run logs, and the reproduced October stability audit. See [results and limitations](analysis/2026-10-25/RESULTS.md) before interpreting the estimates.

The annual Census and cumulative-enrollment constructions are alternative proxies, not observed annual student-days attended. Suppressed values remain missing. Irvine's observed attendance covers five days, while Lodi's eligibility quantities do not identify annual attendance exposure.

The executable annual R pipeline is maintained in [ca-school-lunch-attendance](https://github.com/taielucile/ca-school-lunch-attendance).

## District and statewide files

- [Irvine](Irvine/): original attendance and meal PDFs, plus validated K/PK attendance extraction.
- [Lodi](Lodi/): source reports, workbooks, and validated Kindergarten enrollment/eligibility extraction.
- [Ventura Unified](Ventura%20Unified/)
- [Ojai Unified](Ojai%20Unified/)
- [Davis Joint Unified](Davis%20Joint%20Unified/)
- [Chino](Chino/)
- [Statewide](Statewide/)

[Project proposal abstract](proposal_abstract.md)
