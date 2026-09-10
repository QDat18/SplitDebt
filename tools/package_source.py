"""Create a full source archive while excluding only known generated/private paths."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import argparse, re
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('output',type=Path);args=parser.parse_args()
output=args.output.resolve();output.parent.mkdir(parents=True,exist_ok=True)
exclude_parts={'.git','.idea','.dart_tool','.gradle','build','__pycache__'}
exclude_prefixes=[('api','data'),('api','target'),('api','target_test-classes'),('frontend','build')]
private_names={'.env','config.json','local.properties','key.properties'}
selected=[]
for path in sorted(root.rglob('*')):
 if not path.is_file() or path.resolve()==output:continue
 relative=path.relative_to(root);parts=relative.parts
 if exclude_parts.intersection(parts):continue
 if any(parts[:len(prefix)]==prefix for prefix in exclude_prefixes):continue
 if path.name in private_names or path.suffix in {'.iml','.class','.jks','.keystore','.pyc'}:continue
 selected.append(path)
# Check local Flutter imports before packaging.
for path in (root/'frontend/lib').rglob('*.dart'):
 for target in re.findall(r"(?:import|export)\s+['\"]([^'\"]+)['\"]",path.read_text()):
  if not target.startswith(('package:','dart:')):assert (path.parent/target).resolve().is_file(),(path,target)
with ZipFile(output,'w',ZIP_DEFLATED) as archive:
 for path in selected:archive.write(path,Path('SplitDebt')/path.relative_to(root))
with ZipFile(output) as archive:
 assert archive.testzip() is None
 entries=set(archive.namelist())
 for source_root in [root/'frontend/lib',root/'api/src']:
  for path in source_root.rglob('*'):
   if path.is_file():assert str(Path('SplitDebt')/path.relative_to(root)) in entries,path
 for required in ['frontend/lib/data/api.dart','frontend/assets/brand/splitdebt-mark.png','docs/SETUP.md']:
  assert 'SplitDebt/'+required in entries
print(f'PASS: complete source ZIP, {len(selected)} files, {output.stat().st_size} bytes: {output}')
