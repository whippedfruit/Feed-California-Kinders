"""Independently check all October mobility-unit source counts and observed attendance."""
from pathlib import Path
import pandas as pd,numpy as np,json
import os
ROOT=Path(__file__).resolve().parents[1]
CDE=Path(os.environ.get('FCK_CDE_DIR', ROOT/'data/raw'));out=ROOT/'analysis/2026-10-25/tables'
prior=ROOT/'analysis/2026-10-25'
u=pd.read_csv(prior/'reference/mobility_test_units.csv',dtype={'cds':str})
e=pd.read_csv(CDE/'cdenroll2526.txt',sep='\t',dtype=str,encoding='latin1');e=e[(e.AggregateLevel=='S') & (e.ReportingCategory=='TA')].copy();e['cds']=e.CountyCode.str.zfill(2)+e.DistrictCode.str.zfill(5)+e.SchoolCode.str.zfill(7);e=e.set_index('cds')
a=pd.read_csv(CDE/'absenteeismreason26.txt',sep='\t',dtype=str,encoding='latin1');a=a[(a['Aggregate Level']=='S') & a['Reporting Category'].isin(['GRTKKN','TA'])].copy();a['cds']=a['County Code'].str.zfill(2)+a['District Code'].str.zfill(5)+a['School Code'].str.zfill(7);a=a.set_index(['cds','Reporting Category'])
v=pd.read_excel(ROOT/'Ventura Unified/extracted data/Ventura 8:13:2025 - 6:4:2026 ADA clear_copy.xlsx',sheet_name=None,header=None)
oj=pd.read_excel(ROOT/'Ojai Unified/raw data/Ojai Attendance 25-26 copy.xlsX',sheet_name='Attndance Data',header=1);oj=oj[oj.Track.notna()].copy();oj['track']=oj.Track.str.extract(r'T (\w+) ')[0];oj['grade']=oj.Grade.astype(str).str.zfill(2)
tracks={'MO':'6055198','MM':'6055206','TT':'6055248','SUM':'0139626','NJHS':'6060339','NHS':'5634076','LHS':'5631817'};oj['cds']='5672520'+oj.track.map(tracks)
assert (oj['Days Taught']==172).all()
rows=[]
for r in u.itertuples():
 if r.district=='Ventura':
  keys=[k for k in v if k==r.school or k==r.school[:31]]
  assert len(keys)==1,(r.school,keys)
  z=v[keys[0]].copy();z['grade']=z[4].astype(str).str.replace(r'\.0$','',regex=True)
  grades=['TK','K'] if r.group=='TK+K' else ['TK','K']+list(map(str,range(1,9)))
  z=z[z.grade.isin(grades)]
  ada=pd.to_numeric(z[8]).sum();ade=pd.to_numeric(z[6]).sum()
  cols=[{'TK':'GR_TK','K':'GR_KN'}.get(g,f'GR_{int(g):02}' if g.isdigit() else '') for g in z.grade]
 else:
  z=oj[oj.cds==r.cds];z=z[z.grade.isin(['TK','00'])] if r.group=='TK+K' else z
  ada=z['Actual Present'].sum()/172;ade=z['Days Enrolled'].sum()/172
  cols=[{'TK':'GR_TK','00':'GR_KN'}.get(g,f'GR_{g}') for g in z.grade.unique()]
 census=sum(float(e.loc[r.cds,c]) for c in cols)
 ar=a.loc[(r.cds,r.cat)];cum=float(ar['Eligible Cumulative Enrollment']);ab=float(ar['Total Days Absent'])
 for field,fresh,old in [('obs_ada',ada,r.obs_ada),('obs_ade',ade,r.obs_ade),('census',census,r.census),('cum',cum,r.cum),('abs_days',ab,r.abs_days)]:
  rows.append(dict(cds=r.cds,school=r.school,group=r.group,field=field,reconstructed=fresh,reference=old,difference=fresh-old,pass_check=bool(np.isclose(fresh,old,rtol=1e-10,atol=1e-10))))
pd.DataFrame(rows).to_csv(out/'independent_benchmark_checks.csv',index=False)
fail=[r for r in rows if not r['pass_check']]
print(json.dumps(dict(units=len(u),checks=len(rows),failed=len(fail)),indent=2));print(fail)
assert not fail
