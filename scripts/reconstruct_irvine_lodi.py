from pathlib import Path
import csv,re,json
import pdfplumber,openpyxl
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'analysis/2026-10-25/provenance'
OUT.mkdir(parents=True,exist_ok=True)
def write(path, rows):
 with path.open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
rows=[]; audit=[]
for label,grade,count,total in [('K','K',30,8703),('PK','PK_TK',28,5401)]:
 p=ROOT/f'Irvine/RR {label} Attendance 11.3.25 to 11.7.25.pdf'
 with pdfplumber.open(p) as pdf:
  for line in pdf.pages[0].extract_text().splitlines():
   m=re.fullmatch(r'(.+?)\s+((?:\d+\.00\s+){4}\d+\.00)',line)
   if not m:continue
   vals=[int(float(x)) for x in m[2].split()]
   row=dict(school=m[1],grade=grade,**{f'attendance_11_0{d}':v for d,v in zip(range(3,8),vals)})
   rows.append(row)
   audit.append(dict(**row,source=str(p.relative_to(ROOT)),page=1,source_line=line))
 selected=[r for r in rows if r['grade']==grade]
 assert len(selected)==count and sum(sum(r[f'attendance_11_0{d}'] for d in range(3,8)) for r in selected)==total
assert len({(r['school'],r['grade']) for r in rows})==58
write(ROOT/'Irvine/extracted data/irvine_k_pk_attendance_2025_11_03_07.csv',rows);write(OUT/'irvine_row_provenance.csv',audit)
p=ROOT/'Lodi/extracted data/UCI Project - Student Research.xlsx'
s=openpyxl.load_workbook(p,data_only=True).worksheets[0]
# Kindergarten-filtered left block rows 360:420, right block 433:493.
assert s.cell(429,8).value=='(Kindergarten)'
names=[' '.join(str(s.cell(r,1).value).split()) for r in range(360,421,2)]
nums=[(int(s.cell(r,19).value),int(s.cell(r,26).value)) for r in range(433,494,2)]
assert len(names)==len(nums)==31 and sum(x[0] for x in nums)==3481 and all(x==y for x,y in nums)
# Independently verify the cleaned workbook with names and values on the same row.
c=openpyxl.load_workbook(ROOT/'Lodi/cleaned data/Lodi FreeReduced eligibility_copy.xlsx',data_only=True)['Kindergarten']
for i,(name,(hi,last)) in enumerate(zip(names,nums),4):
 assert ' '.join(str(c.cell(i,1).value).split())==name
 assert (c.cell(i,14).value,c.cell(i,15).value)==(hi,last)
# Verify every value against PDF right-hand pages, not just aggregate totals.
with pdfplumber.open(ROOT/'Lodi/raw data/UCI Project - Student Research.pdf') as pdf:
 assert '(Kindergarten)' in pdf.pages[14].extract_text()
 pdfnums=[]
 for page in pdf.pages[15:17]:
  pdfnums += [tuple(map(int,m.groups())) for m in re.finditer(r'(?m)^(\d+) (\d+)$',page.extract_text())]
 assert pdfnums[:31]==nums and pdfnums[31]==(3481,3481),pdfnums
lodi=[dict(school=n,kindergarten_highest_eligible=v[0],kindergarten_last_day=v[1]) for n,v in zip(names,nums)]
write(ROOT/'Lodi/extracted data/lodi_kindergarten_enrollment_measures_2025_26.csv',lodi)
write(OUT/'lodi_row_provenance.csv',[dict(**r,school_cell=f'A{360+2*i}',highest_eligible_cell=f'S{433+2*i}',last_day_cell=f'Z{433+2*i}',pdf_school_page=13 if i<18 else 14,pdf_value_page=16 if i<18 else 17,cleaned_workbook_row=i+4) for i,r in enumerate(lodi)])
print(json.dumps(dict(irvine_rows=58,k_student_days=8703,pk_student_days=5401,lodi_rows=31,lodi_highest_eligible=3481,lodi_last_day=3481,pdf_and_cleaned_workbook_crosschecks='PASS',irvine_k_fourth_date_label='11.5 printed twice; fourth column confirmed as Nov 6 by Monday-Friday sequence'),indent=2))
