# -*- coding: utf-8 -*-
"""Audit every Mod Settings option: does changing it actually reach gameplay?

A setting is declared in Settings/CyberbaneSettings.reds and consumed as `rt.GetSettings().name`
or `s.name`. Only reads count; assignments do not, which is what keeps the preset block from
making every slider look alive. Reads inside the settings file do count, because `enabled`,
`logLevel` and `preset` take effect precisely there - `Apply()` hands them to the runtime.

Run from the repo root:  python -I tools/audit_settings.py
"""
import io, os, re, sys

ROOT = 'src/r6/scripts/Cyberbane'
src = {}
for root, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith('.reds'):
            p = os.path.join(root, f).replace(os.sep, '/')
            src[p] = io.open(p, encoding='utf-8', errors='replace').read()

SETTINGS = [p for p in src if p.endswith('Settings/CyberbaneSettings.reds')][0]

# Declared options, in order, with the category they sit under.
options, category = [], '?'
for line in src[SETTINGS].split('\n'):
    m = re.search(r'ModSettings.category", "Cyberbane-Settings-Category-(\w+)"', line)
    if m:
        category = m.group(1)
    m = re.match(r'\s*public let (\w+)\s*:\s*(\w+)', line)
    if m:
        options.append((category, m.group(1), m.group(2)))

print('%-12s %-26s %-8s %s' % ('CATEGORY', 'SETTING', 'TYPE', 'READ AT'))
print('-' * 78)
dead = []
for cat, name, typ in options:
    sites = []
    for p, t in src.items():
        for m in re.finditer(r'\.' + name + r'\b', t):
            tail = t[m.end():m.end() + 4]
            if re.match(r'\s*(=[^=]|\+=|-=)', tail):
                continue   # a write, not a use
            sites.append('%s:%d' % (p.split('/')[-1], t.count('\n', 0, m.start()) + 1))
    sites = sorted(set(sites))
    if not sites:
        dead.append((cat, name))
        print('%-12s %-26s %-8s  *** NOTHING READS THIS ***' % (cat, name, typ))
    else:
        shown = ', '.join(sites[:3]) + ('  (+%d more)' % (len(sites) - 3) if len(sites) > 3 else '')
        print('%-12s %-26s %-8s %s' % (cat, name, typ, shown))

print()
print('%d options, %d with no effect' % (len(options), len(dead)))
if dead:
    print('dead: ' + ', '.join(n for _, n in dead))
sys.exit(1 if dead else 0)
