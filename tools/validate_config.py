"""Validate private configuration without printing its contents."""
import json
import sys
from pathlib import Path
from jsonschema import Draft202012Validator

root=Path(__file__).resolve().parents[1]
path=Path(sys.argv[1]) if len(sys.argv)>1 else root/'examples/klikavec-home.json'
cfg=json.loads(path.read_text(encoding='utf-8'))
Draft202012Validator(json.loads((root/'klikavec.schema.json').read_text())).validate(cfg)
ids=set()
def walk(items):
    for item in items:
        if item['type']=='group': walk(item['items'])
        if 'entity' in item: ids.add(item['entity'])
        if 'humidity' in item: ids.add(item['humidity'])
walk(cfg['items'])
assert len(ids)<=60, 'Maximum 60 unique entities'
assert any(s.get('visible',True) for s in cfg['items']), 'At least one visible section required'
for section in cfg['items']:
    assert len(json.dumps(section,ensure_ascii=False).encode())<6000, 'Section exceeds storage safety budget'
def size_budget(item):
    total=120+len(item['name'])*3
    if 'entity' in item: total+=len(item['entity'])+150
    if 'humidity' in item: total+=len(item['humidity'])
    if item['type']=='group': total+=sum(size_budget(i) for i in item['items'])
    return total
assert all(size_budget(s)<=6000 for s in cfg['items']), 'Section exceeds watch cache budget'
assert len({s['name'] for s in cfg['items']})==len(cfg['items']), 'Section names must be unique'
assert sum(s.get('home',False) for s in cfg['items'])<=1, 'Only one home dashboard is supported'
print(f'OK: {len(cfg["items"])} sections, {len(ids)} unique entities, schema + device limits valid')
