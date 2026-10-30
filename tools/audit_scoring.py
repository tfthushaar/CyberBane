"""Audit every scoring field: which are written, which are read, which are neither.

Counts `.field` occurrences across the whole mod. A write is `.field =`, `.field +=`
or `.field -=`; everything else is a read. Declaration lines are skipped by matching
only dotted accesses, so `public persistent let kills: Int32;` never counts.
"""
import io, os, re

ROOT = 'src/r6/scripts/Cyberbane'
src = {}
for root, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith('.reds'):
            p = os.path.join(root, f).replace(os.sep, '/')
            src[p] = io.open(p, encoding='utf-8', errors='replace').read()

STATE = [p for p in src if p.endswith('Core/State.reds')][0]
REP = [p for p in src if p.endswith('Model/Reputation.reds')][0]


def collect(path):
    out, cls = [], None
    for line in src[path].split('\n'):
        m = re.match(r'\s*public class (\w+)', line)
        if m:
            cls = m.group(1)
        m = re.match(r'\s*public (?:persistent )?let (\w+)\s*:', line)
        if m:
            out.append((cls, m.group(1)))
    return out


def tally(field):
    w, r, wsites, rsites = 0, 0, [], []
    for p, t in src.items():
        for m in re.finditer(r'\.' + field + r'\b', t):
            tail = t[m.end():m.end() + 4]
            where = '%s:%d' % (p.split('/')[-1], t.count('\n', 0, m.start()) + 1)
            if re.match(r'\s*(=[^=]|\+=|-=)', tail):
                w += 1
                wsites.append(where)
            else:
                r += 1
                rsites.append(where)
    return w, r, wsites, rsites


def report(title, fields):
    print('=' * 72)
    print(title)
    print('=' * 72)
    bad = 0
    for cls, f in fields:
        w, r, ws, rs = tally(f)
        if w and r:
            continue
        bad += 1
        kind = 'NEVER WRITTEN -> always default' if w == 0 else 'NEVER READ -> influences nothing'
        print('  %-18s %-22s wr=%-3d rd=%-3d  %s' % (cls, f, w, r, kind))
        sites = sorted(set(rs if w == 0 else ws))[:5]
        if sites:
            print('%sat: %s' % (' ' * 22, ', '.join(sites)))
    print('  -> %d of %d flagged\n' % (bad, len(fields)))


report('PERSISTENT STATE FIELDS', collect(STATE))
report('CBKillInfo FLAGS (the inputs every kill is scored from)', collect(REP))
