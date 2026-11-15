"""Print UDID|device name|runtime for the newest iPhone Pro on the newest available iOS runtime."""
import json, re, subprocess, sys

j = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', '-j']))
PHONE = re.compile(r'iPhone \d+ Pro')
rts = [r for r in j['runtimes'] if r.get('platform') == 'iOS' and r.get('isAvailable')
       and any(PHONE.fullmatch(t['name']) for t in r.get('supportedDeviceTypes', []))]
if not rts:
    sys.exit('no available iOS runtime with an iPhone Pro')
rt = max(rts, key=lambda r: [int(x) for x in r['version'].split('.')])
dev = max((t for t in rt['supportedDeviceTypes'] if PHONE.fullmatch(t['name'])),
          key=lambda t: [int(n) for n in re.findall(r'\d+', t['name'])])
devs = j['devices'].get(rt['identifier'], [])
udid = next((d['udid'] for d in devs if d['deviceTypeIdentifier'] == dev['identifier'] and d.get('isAvailable')), None)
if not udid:
    udid = subprocess.check_output(['xcrun', 'simctl', 'create', dev['name'], dev['identifier'], rt['identifier']]).decode().strip()
print('|'.join([udid, dev['name'], rt['name'] + ' ' + rt.get('buildversion', '')]))
