"""Marks the first two reading levels completed in the app's saved progress, so the later reading levels open.
Keeps every other field. Used only by the simulator audit."""
import json, sys

path = sys.argv[1]
with open(path) as f:
    record = json.load(f)
levels = record.setdefault('levels', {})
for level in ('reading-fr-r1', 'reading-fr-r2'):
    entry = levels.setdefault(level, {})
    entry['completions'] = max(1, entry.get('completions', 0))
    entry.setdefault('visits', 1)
record.setdefault('stars', {})['total'] = record.get('stars', {}).get('total', 0) + 6
with open(path, 'w') as f:
    json.dump(record, f, sort_keys=True)
print('seeded', sorted(levels))
