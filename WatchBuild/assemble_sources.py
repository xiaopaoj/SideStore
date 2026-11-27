"""Publish the pinned, patched source snapshot into this user's build repository."""
import json
import os
from pathlib import Path
import shutil
import subprocess

root = Path(__file__).resolve().parent.parent
source = root/'build/SideStore'
overlays = root/'build/Fairway'
skip = {'.git', '__pycache__', '.build', '.swiftpm', 'target'}
paths = []
for directory, dirs, files in os.walk(source):
    dirs[:] = [name for name in dirs if name not in skip]
    for name in files:
        path = Path(directory)/name
        relative = path.relative_to(source)
        if name in {'.git', '.gitmodules', 'CodeSigning.xcconfig'}:
            continue
        if relative.as_posix() in {'.gitignore', 'README.md'}:
            continue
        if relative.parts[:2] == ('.github', 'workflows'):
            relative = Path('.github/upstream-workflows').joinpath(*relative.parts[2:])
        destination = root/relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        paths.append(relative.as_posix())

for origin, destination in [
    (source/'README.md', root/'README.upstream.md'),
    (overlays/'LICENSE', root/'LICENSE-WATCH-OVERLAYS'),
]:
    shutil.copy2(origin, destination)
    paths.append(destination.relative_to(root).as_posix())
for origin, destination in [
    (overlays/'tools/watch-support/Recovery', root/'WatchBuild/Recovery'),
    (overlays/'tools/watch-support/fixtures', root/'WatchBuild/fixtures'),
]:
    shutil.copytree(origin, destination, dirs_exist_ok=True)
    paths.extend(p.relative_to(root).as_posix() for p in destination.rglob('*') if p.is_file())

pins = {
    'fairway_base': '5fbb18175e69255c117b16ed0bca7bc59e209d89',
    'previous_sidestore_base': 'd97ec133719d79916675bdaf722b82a8d091d545',
    'sidestore': '4f3d18d98c5fbee72c80f787ceb2e8e09ded60a6',
    'sidesign': '752d1ef602aa792a432ffa1e71646dc1ecf7363c',
    'minimuxer': '12be70dc2627307a16bfd2dc7a009080d5bec909',
    'idevice': '3e55c8486b2057e40c1f74aaaa1155c82341cf76',
    'codesignkit': 'd0c67710fda9a2646b9e829cb2cf443892728371',
}
(root/'WatchBuild/source-pins.json').write_text(json.dumps(pins, indent=2)+'\n')
(root/'.gitignore').write_text('build/\nartifacts/\nNativeIDevice.xcframework/\nSideStore.xcarchive/\nPayload/\nSideStore.ipa\n**/.build/\n**/.swiftpm/\n**/__pycache__/\n**/target/\nCodeSigning.xcconfig\n*.p12\n*.mobileprovision\n')
(root/'README.md').write_text('''# SideStore with Watch and OS Recovery

Independent, AI-assisted experimental build of SideStore develop with Watch installation,
refresh and OS recovery changes from Fairway. This is not an official SideStore release.

The Build Watch-enabled SideStore IPA action publishes the pinned adapted source here,
runs the existing recovery, native Watch and signing tests, and builds an unsigned IPA.
Download the successful run artifact for the IPA, corresponding source, BUILD.json and checksums.
Install using your own Apple account; no account credentials are used in CI.

Modified dependencies are vendored here. Original upstream workflows are retained under
`.github/upstream-workflows` as inactive reference. Source revisions are in
`WatchBuild/source-pins.json`. See NOTICE-WATCH.md and README.upstream.md for attribution,
licenses and verification limits. Successful CI does not prove device migration, data
preservation or reliable automatic Watch renewal.
''')
paths.extend(['WatchBuild/source-pins.json', '.gitignore', 'README.md'])
manifest = root/'build/publish-paths.bin'
manifest.write_bytes(b'\0'.join(p.encode() for p in sorted(set(paths)))+b'\0')
subprocess.run(['git', 'add', '--force', '--pathspec-from-file='+str(manifest), '--pathspec-file-nul'], cwd=root, check=True)
subprocess.run(['git', 'config', 'user.name', 'github-actions[bot]'], cwd=root, check=True)
subprocess.run(['git', 'config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com'], cwd=root, check=True)
if subprocess.run(['git', 'diff', '--cached', '--quiet'], cwd=root).returncode:
    subprocess.run(['git', 'commit', '-qm', 'Publish AI-assisted Watch adaptation of pinned SideStore develop'], cwd=root, check=True)
    subprocess.run(['git', 'push', 'origin', 'HEAD:main'], cwd=root, check=True)

