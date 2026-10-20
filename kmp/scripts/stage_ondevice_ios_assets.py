#!/usr/bin/env python3
"""Stage the pinned asset pack into a derived app bundle; no downloads or inference."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, required=True)
    parser.add_argument('--config', type=Path, default=ROOT / 'config/ondevice-ios-candidate-v1.json')
    parser.add_argument('--build-mode', choices=('Debug', 'Release', 'DebugLocal', 'ReleaseLocal'), default='DebugLocal')
    args = parser.parse_args()
    configuration = json.loads(args.config.read_text())
    destination = args.destination.resolve()
    if destination.name != 'LocalScannerAssets' or not any(p.suffix == '.app' for p in destination.parents):
        parser.error('Destination must be LocalScannerAssets inside a derived .app')
    destination.parent.mkdir(parents=True, exist_ok=True)
    plan = dict(assets_manifest_sha256=configuration['assets_sha256'],
                archive_bytes=(configuration.get('download') or {}).get('archive_bytes', 0),
                manifest_path=(configuration.get('download') or {}).get('manifest_path','/api/local-scanner/manifest.json'))
    (destination.parent / 'LocalScannerDownload.json').write_text(json.dumps(plan, sort_keys=True) + '\n')
    if args.build_mode in ('Debug', 'Release'):
        if destination.exists():
            previous = destination / 'assets.json'
            if not previous.is_file() or json.loads(previous.read_text()).get('kind') != 'wine-ondevice-ios-candidate-assets-v1':
                raise ValueError('Refusing to remove unknown derived resource directory')
            shutil.rmtree(destination)
        print('Server build: models omitted; runtime download metadata only')
        return
    source = (ROOT / configuration['assets']).resolve()
    manifest = source / 'assets.json'
    if not source.is_relative_to(ROOT / 'external') or sha(manifest) != configuration['assets_sha256']:
        raise ValueError('Pinned native asset pack changed')
    doc = json.loads(manifest.read_text())
    for name, expected in doc['files'].items():
        path = source / name
        if not path.resolve().is_relative_to(source) or sha(path) != expected['sha256']:
            raise ValueError('Pinned native asset changed: ' + name)
    if destination.exists():
        previous = destination / 'assets.json'
        if previous.is_file() and sha(previous) == configuration['assets_sha256']:
            # Check derived bytes too; an interrupted prior build is not accepted.
            if all((destination / name).is_file() and sha(destination / name) == expected['sha256'] for name, expected in doc['files'].items()):
                print('Local scanner assets already match: ' + configuration['assets_sha256'])
                return
        if not previous.is_file() or json.loads(previous.read_text()).get('kind') != 'wine-ondevice-ios-candidate-assets-v1':
            raise ValueError('Refusing to replace an unknown app resource folder')
        shutil.rmtree(destination)
    shutil.copytree(source, destination, copy_function=os.link)
    print('Staged local scanner assets: ' + configuration['assets_sha256'])


if __name__ == '__main__':
    main()
