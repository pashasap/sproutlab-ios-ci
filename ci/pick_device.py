"""Pick the newest iOS runtime holding both an iPhone Pro and an iPad Pro, and a device of the requested kind.
Prints UDID|device name|runtime. Fails clearly when the runtime lacks the device types."""
import json, re, subprocess, sys

kind = sys.argv[1]
j = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', '-j']))
PHONE = re.compile(r'iPhone \d+ Pro')
PAD = re.compile(r'iPad Pro 13-inch \(M\d+\)')


def types(r):
    return r.get('supportedDeviceTypes', [])


rts = [r for r in j['runtimes'] if r.get('platform') == 'iOS' and r.get('isAvailable')]
for r in rts:
    print('runtime', r['name'], r.get('buildversion', ''), file=sys.stderr)
rts = [r for r in rts if any(PHONE.fullmatch(t['name']) for t in types(r)) and any(PAD.fullmatch(t['name']) for t in types(r))]
if not rts:
    sys.exit('no iOS runtime with both an iPhone Pro and an iPad Pro 13-inch')
rt = max(rts, key=lambda r: [int(x) for x in r['version'].split('.')])
pat = PHONE if kind == 'phone' else PAD
cands = [t for t in types(rt) if pat.fullmatch(t['name'])]
dev = max(cands, key=lambda t: [int(n) for n in re.findall(r'\d+', t['name'])])
devs = j['devices'].get(rt['identifier'], [])
udid = next((d['udid'] for d in devs if d['deviceTypeIdentifier'] == dev['identifier'] and d.get('isAvailable')), None)
if not udid:
    udid = subprocess.check_output(['xcrun', 'simctl', 'create', dev['name'], dev['identifier'], rt['identifier']]).decode().strip()
print('|'.join([udid, dev['name'], rt['name'] + ' ' + rt.get('buildversion', '')]))
