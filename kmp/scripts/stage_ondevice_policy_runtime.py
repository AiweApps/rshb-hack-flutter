#!/usr/bin/env python3
"""Stage signed, pinned app-side Python/policy support into a derived KMM app."""
import argparse,hashlib,json,os,plistlib
from pathlib import Path
import shutil,subprocess

ROOT=Path(__file__).resolve().parents[1]

def sha(p):
    digest=hashlib.sha256()
    # Xcode's script PATH can select the system Python3.9 even when the shell
    # uses3.12. Keep staging independent of hashlib.file_digest (added in3.11).
    with Path(p).open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):digest.update(chunk)
    return digest.hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--destination',type=Path,required=True)
    args=parser.parse_args();app=args.destination.resolve()
    if app.suffix!='.app':parser.error('A derived app bundle is required')
    config=json.loads((ROOT/'config/ondevice-ios-candidate-v1.json').read_text())
    sdk=os.environ.get('PLATFORM_NAME')
    if sdk not in ('iphonesimulator','iphoneos'):raise ValueError('An explicit supported iOS SDK is required')
    policy=ROOT/config['policy']['path'];manifest=policy/'policy-manifest.json'
    if sha(manifest)!=config['policy']['sha256']:raise ValueError('Pinned policy manifest changed')
    doc=json.loads(manifest.read_text())
    if doc['native_assets_sha256']!=config['assets_sha256'] or not doc['control_snapshot']['outer_graph']:raise ValueError('Full policy/native assets binding differs')
    runtime=ROOT/config['python_runtime'][sdk];receipt=json.loads((runtime/'receipt.json').read_text());source=runtime/'Runtime.app'
    identity=os.environ.get('EXPANDED_CODE_SIGN_IDENTITY') or '-'
    fingerprint=hashlib.sha256(json.dumps(dict(policy=config['policy'],runtime=sha(runtime/'receipt.json'),sdk=sdk,identity=identity,installer=sha(__file__)),sort_keys=True).encode()).hexdigest()
    marker=app/'LocalPolicySupport.json';previous=json.loads(marker.read_text()) if marker.exists() else None
    if previous and previous.get('kind')!='wine-main-app-policy-support-v1':raise ValueError('Unknown app support marker')
    if previous and previous.get('ready') and previous.get('fingerprint')==fingerprint:
        if all((app/p).is_file() and sha(app/p)==v for p,v in previous['files'].items()):
            print('Main-app policy/Python resources already verified');return
    policy_names={str(p.relative_to(policy)) for p in policy.rglob('*') if p.is_file()}
    if policy_names!=set(doc['files'])|{'policy-manifest.json'}:raise ValueError('Unmanifested policy files')
    for name,pin in doc['files'].items():
        p=(policy/name).resolve(strict=True)
        if not p.is_relative_to(policy.resolve()) or sha(p)!=pin:raise ValueError('Policy source changed: '+name)
    for name,pin in receipt['files'].items():
        p=(source/name).resolve(strict=True)
        if not p.is_relative_to(source.resolve()) or sha(p)!=pin['sha256']:raise ValueError('SDK runtime changed: '+name)
    owned=['python','app_packages','LocalScannerPolicy']+['Frameworks/'+p.name for p in (source/'Frameworks').iterdir()]
    if not previous and any((app/p).exists() for p in owned):raise ValueError('Refusing to replace unknown app runtime folders')
    app.mkdir(parents=True,exist_ok=True)
    marker.write_text(json.dumps(dict(kind='wine-main-app-policy-support-v1',ready=False,fingerprint=fingerprint,owned=owned)))
    for name in owned:
        target=app/name
        if target.exists():shutil.rmtree(target)
        origin=policy if name=='LocalScannerPolicy' else source/name
        target.parent.mkdir(parents=True,exist_ok=True)
        # Signing must not mutate the verified source framework through a hardlink.
        shutil.copytree(origin,target,symlinks=True)
    for name in owned:
        if name.startswith('Frameworks/'):
            # BeeWare's extension template labels the generated .framework as
            # APPL. App Store validation requires FMWK. Normalize only the
            # derived copy, keeping the pinned SDK sources byte-identical.
            info=app/name/'Info.plist'
            metadata=plistlib.loads(info.read_bytes())
            metadata['CFBundlePackageType']='FMWK'
            metadata['CFBundleSupportedPlatforms']=['iPhoneSimulator' if sdk=='iphonesimulator' else 'iPhoneOS']
            info.write_bytes(plistlib.dumps(metadata))
            subprocess.run(['codesign','--force','--sign',identity,'--timestamp=none',str(app/name)],check=True,capture_output=True)
    files={str(p.relative_to(app)):sha(p) for name in owned for p in (app/name).rglob('*') if p.is_file()}
    marker.write_text(json.dumps(dict(kind='wine-main-app-policy-support-v1',ready=True,fingerprint=fingerprint,owned=owned,files=files,
        policy_sha256=config['policy']['sha256'],native_assets_sha256=config['assets_sha256'],sdk=sdk),sort_keys=True))
    print('Staged main-app full policy and Python for '+sdk)

if __name__=='__main__':main()
