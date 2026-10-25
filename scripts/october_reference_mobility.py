"""Do mobility measures identify schools where Census Day enrollment overstates average daily enrollment (ADE), and so where P1 overestimates attendance?
Units (2025-26 observed): Ventura TK+K (17) and schoolwide TK-8 (18); Ojai TK+K (3) and schoolwide (6 regular + Summit, independent-study pattern).
Outcomes: ADE gap = Census / observed ADE - 1;  P1 error = (Census - absences/180) / observed ADA - 1.
Predictors available statewide:
  m1 = Census / eligible cumulative enrollment (CDE absence file, same year, same grade group)
  m2 = stability rate, 2024-25 (CDE stability file; one year earlier than the benchmarks; 2025-26 not posted)  [group: TA or GRTKKN]
  m3 = DASS (alternative school) flag
Tests: Spearman correlation; leave-one-out (LOO) linear correction of P1 using each predictor vs no correction (MAE and median abs % error);
       a simple flag rule (m2 < 85 or DASS) vs schools with |P1 error| > 5%.
Usage: python3 -I 23_mobility_test.py <baseline validation_units_same_year.csv> <ventura_proxy_comparison_by_school_reproduced.csv> <ventura_ada_rows.csv>
        <ventura_school_k_g1_lunch_per_ada.csv> <cdenroll2526.txt> <ojai_school_level_errors_2025-26.csv> <stability_2024-25_ventura_ojai.csv> <out_dir>"""
import sys, numpy as np, pandas as pd
from pathlib import Path
from scipy.stats import spearmanr
VU, VX, VA, VXW, ENR, OJ, ST, OUT = sys.argv[1:9]; OUT = Path(OUT); OUT.mkdir(parents=True, exist_ok=True)
D = 180.0
st = pd.read_csv(ST, dtype={'cds': str})
stab = {(r.cds, r.category): r.stability_rate for r in st.itertuples()}
dass = {r.cds: r.dass == 'Yes' for r in st.itertuples()}
u = pd.read_csv(VU, dtype={'cds': str}); vx = pd.read_csv(VX, dtype={'cds': str})
rows = []
g1 = u[u.group.str.startswith('G1')].merge(vx[['cds', 'obs_ade']], on='cds')
for r in g1.itertuples():
    rows.append(dict(district='Ventura', group='TK+K', school=r.school, cds=r.cds, census=r.census, cum=r.cum, abs_days=r.abs_days, obs_ada=r.observed, obs_ade=r.obs_ade, cat='GRTKKN'))
# schoolwide: ADE from ADA Summary, grades present in the ADA report that are Census grades
ada = pd.read_csv(VA, dtype={'grade': str}); vgr = ['TK', 'K'] + [str(i) for i in range(1, 9)]
xw = pd.read_csv(VXW, dtype={'cds_code': str})[['school', 'cds_code']]
xw = pd.concat([xw, pd.DataFrame([{'school': 'Homestead', 'cds_code': '56726526115687'}])])
s1 = u[u.group.str.startswith('S1')]
for r in s1.itertuples():
    sch = r.school
    ade = ada[(ada.school == sch) & ada.grade.isin(vgr)].ade.sum()
    rows.append(dict(district='Ventura', group='Schoolwide', school=sch, cds=r.cds, census=r.census, cum=r.cum, abs_days=r.abs_days, obs_ada=r.observed, obs_ade=ade, cat='TA'))
oj = pd.read_csv(OJ, dtype={'cds': str})
oj = oj[oj.observed_ada.astype(str) != 'suppressed (<11 records)']
for r in oj.itertuples():
    if r.group not in ('TK+K combined', 'Schoolwide (grades in file)'): continue
    grp = 'TK+K' if r.group.startswith('TK+K') else 'Schoolwide'
    rows.append(dict(district='Ojai' + (' (Summit, independent study)' if r.independent_study_like else ''), group=grp, school=r.school, cds=r.cds,
                     census=float(r.census), cum=float(r.cum), abs_days=float(r.cde_abs_days), obs_ada=float(r.observed_ada), obs_ade=float(r.observed_ade), cat='GRTKKN' if grp == 'TK+K' else 'TA'))
U = pd.DataFrame(rows)
U['p1'] = U.census - U.abs_days / D
U['ade_gap'] = U.census / U.obs_ade - 1
U['p1_err'] = U.p1 / U.obs_ada - 1
e = pd.read_csv(ENR, sep='\t', dtype=str, encoding='latin1'); e = e[(e.AggregateLevel == 'S') & (e.ReportingCategory == 'TA')].copy()
e['cds'] = e.CountyCode.str.zfill(2) + e.DistrictCode.str.zfill(5) + e.SchoolCode.str.zfill(7); tot = e.set_index('cds').TOTAL_ENR.astype(int)
# m1 must use the same population as the cumulative count: TK+K Census for GRTKKN; total Census enrollment for TA (the ADA-report grade restriction applies only to the outcome)
U['m1_census_over_cum'] = np.where(U.cat == 'TA', U.cds.map(tot) / U.cum, U.census / U.cum)
U['m2_stability_2425'] = [stab.get((c, k), stab.get((c, 'TA'), np.nan)) for c, k in zip(U.cds, U.cat)]
U['m3_dass'] = U.cds.map(dass).fillna(False).astype(bool)
U.to_csv(OUT / 'mobility_test_units.csv', index=False)
res = []
for grp in ['TK+K', 'Schoolwide']:
    for incl, lab in [(lambda d: ~d.district.str.contains('Summit'), 'excluding Summit'), (lambda d: d.district.notna(), 'all units')]:
        g = U[(U.group == grp) & incl(U)].reset_index(drop=True)
        base_mae = (g.p1 - g.obs_ada).abs().mean(); base_md = (100 * g.p1_err.abs()).median()
        for m in ['m1_census_over_cum', 'm2_stability_2425']:
            x = g[m].astype(float); ok = x.notna()
            rho_gap, p_gap = spearmanr(x[ok], g.ade_gap[ok]); rho_err, p_err = spearmanr(x[ok], g.p1_err[ok])
            # LOO: predict ade_gap from m with OLS on the other units, then correct P1 by dividing by (1 + predicted gap)
            pred = np.full(len(g), np.nan)
            for i in g.index[ok]:
                tr = ok & (g.index != i)
                b = np.polyfit(x[tr], g.ade_gap[tr], 1); pred[i] = np.polyval(b, x[i])
            adj = g.p1 / (1 + pred)
            mae_adj = (adj - g.obs_ada)[ok].abs().mean(); md_adj = (100 * (adj / g.obs_ada - 1)[ok].abs()).median()
            res.append(dict(group=grp, sample=lab, units=int(ok.sum()), predictor=m, spearman_vs_ade_gap=rho_gap, p_ade_gap=p_gap, spearman_vs_p1_err=rho_err, p_p1_err=p_err,
                            mae_unadjusted=(g.p1 - g.obs_ada)[ok].abs().mean(), mae_loo_adjusted=mae_adj, median_abs_pct_unadjusted=(100 * g.p1_err[ok].abs()).median(), median_abs_pct_loo_adjusted=md_adj))
R = pd.DataFrame(res); R.to_csv(OUT / 'mobility_test_results.csv', index=False)
# flag rule
U['flag_rule'] = (U.m2_stability_2425 < 85) | U.m3_dass
U['large_overestimate'] = U.p1_err > 0.05
fl = pd.crosstab([U.group, U.flag_rule], U.large_overestimate); fl.to_csv(OUT / 'mobility_flag_crosstab.csv')
pd.set_option('display.width', 250)
print(U[['district', 'group', 'school', 'ade_gap', 'p1_err', 'm1_census_over_cum', 'm2_stability_2425', 'm3_dass']].round(3).sort_values(['group', 'p1_err']).to_string())
print(R.round(3).to_string()); print(fl)
