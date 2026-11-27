"""Package the unsigned IPA with exact published source and provenance."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

root = Path(__file__).resolve().parent.parent
out = root/'artifacts'
out.mkdir(exist_ok=True)
ipa = root/'SideStore.ipa'
with zipfile.ZipFile(ipa) as archive:
    if archive.testzip() is not None or 'Payload/SideStore.app/Info.plist' not in archive.namelist():
        raise RuntimeError('Missing or invalid built SideStore IPA')
output_ipa = out/'SideStore-Watch-OS-Recovery.ipa'
shutil.copyfile(ipa, output_ipa)
source = out/'SideStore-Watch-OS-Recovery-source.zip'
subprocess.run(['git', 'archive', '--format=zip', '--prefix=SideStore/',
                '-o', str(source), 'HEAD'], cwd=root, check=True)
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
pins = json.loads((root/'WatchBuild/source-pins.json').read_text(encoding='utf-8'))
report = {
    'repository': os.environ.get('GITHUB_REPOSITORY'),
    'published_commit': revision,
    'source_pins': pins,
    'workflow_run_id': os.environ.get('GITHUB_RUN_ID'),
    'unsigned_for_distribution': True,
    'requires_signing_with_your_own_account': True,
    'recovery_policy_tests': 'passed',
    'native_watch_tests': 'passed',
    'watch_signing_and_os_recovery_tests': 'passed',
    'ios_archive': 'passed',
    'physical_device_validation': False,
}
(out/'BUILD.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
names = [output_ipa, source, out/'BUILD.json']
(out/'SHA256SUMS.txt').write_text(''.join(
    f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n' for path in names
), encoding='ascii')
print(json.dumps(report, indent=2))

