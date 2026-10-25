"""Recheck October stability inputs from CDE and rerun the saved mobility arithmetic.
Attendance outcomes use October 25 reference inputs; verify_october_benchmarks.py independently checks all 46 units against district workbooks and same-year CDE.
"""
from pathlib import Path
import json
import pandas as pd,numpy as np
from scipy.stats import spearmanr
import os
ROOT=Path(__file__).resolve().parents[1]
CDE=Path(os.environ.get('FCK_CDE_DIR', ROOT/'data/raw'))
prior=ROOT/'analysis/2026-10-25'
out=ROOT/'analysis/2026-10-25/tables';out.mkdir(exist_ok=True)
s=pd.read_csv(CDE/'sr2425-v3.txt',sep='\t',dtype=str,encoding='latin1').apply(lambda x:x.str.strip())
s=s[(s['Aggregate Level']=='S') & ~s['School Code'].str.zfill(7).isin(['0000000','0000001'])].copy()
s['cds']=s['County Code'].str.zfill(2)+s['District Code'].str.zfill(5)+s['School Code'].str.zfill(7)
assert not s.duplicated(['cds','Reporting Category']).any()
lookup=s.set_index(['cds','Reporting Category'])
def rate(c,k):
 key=(c,k) if (c,k) in lookup.index else (c,'TA')
 return pd.to_numeric(lookup.loc[key,'Stability Rate (percent)'],errors='coerce') if key in lookup.index else np.nan
frozen=pd.read_csv(prior/'reference/stability_2024-25_ventura_ojai.csv',dtype={'cds':str})
frozen['fresh_rate']=[rate(c,k) for c,k in zip(frozen.cds,frozen.category)]
frozen['difference']=frozen.fresh_rate-frozen.stability_rate
frozen.to_csv(out/'prior_stability_input_comparison.csv',index=False)
assert np.allclose(frozen.fresh_rate,frozen.stability_rate,equal_nan=True)
U=pd.read_csv(prior/'reference/mobility_test_units.csv',dtype={'cds':str})
U['m2_stability_2425']=[rate(c,k) for c,k in zip(U.cds,U.cat)]
U['m3_dass']=[lookup.loc[(c,k) if (c,k) in lookup.index else (c,'TA'),'DASS']=='Yes' for c,k in zip(U.cds,U.cat)]
# Reconstruct derived outcomes from saved source counts, rather than trust saved ratios.
U['p1']=U.census-U.abs_days/180
U['ade_gap']=U.census/U.obs_ade-1
U['p1_err']=U.p1/U.obs_ada-1
# Same-year m1: total Census for schoolwide units, TK+K Census for TK+K units.
e=pd.read_csv(CDE/'cdenroll2526.txt',sep='\t',dtype=str,encoding='latin1')
e=e[(e.AggregateLevel=='S') & (e.ReportingCategory=='TA')].copy()
e['cds']=e.CountyCode.str.zfill(2)+e.DistrictCode.str.zfill(5)+e.SchoolCode.str.zfill(7)
tot=pd.to_numeric(e.set_index('cds').TOTAL_ENR)
U['m1_census_over_cum']=np.where(U.cat=='TA',U.cds.map(tot)/U.cum,U.census/U.cum)
# Execute the original preserved October script's analysis section unchanged.
code=(ROOT/'scripts/october_reference_mobility.py').read_text()
suffix=code[code.index('U.to_csv(OUT /'):]
ns=dict(U=U,OUT=out,pd=pd,np=np,spearmanr=spearmanr)
exec(compile(suffix,'original_23_mobility_test_analysis','exec'),ns)
a=pd.read_csv(out/'mobility_test_results.csv');b=pd.read_csv(prior/'reference/mobility_test_results.csv')
assert list(a.columns)==list(b.columns) and a.shape==b.shape
for col in a:
 if pd.api.types.is_numeric_dtype(a[col]):assert np.allclose(a[col],b[col],rtol=1e-10,atol=1e-10,equal_nan=True),col
 else:assert a[col].equals(b[col]),col
assert (out/'mobility_flag_crosstab.csv').read_text()==(prior/'reference/mobility_flag_crosstab.csv').read_text()
status=dict(stability_reference_rows=len(frozen),stability_mismatches=int((frozen.difference.fillna(0)!=0).sum()),mobility_units=len(U),result_rows=len(a),comparison='PASS at 1e-10 tolerance',scope='Fresh CDE stability verification and original mobility arithmetic; verify_october_benchmarks.py independently validates all 46 unit outcomes and source counts')
(out/'status.json').write_text(json.dumps(status,indent=2));print(json.dumps(status,indent=2))
