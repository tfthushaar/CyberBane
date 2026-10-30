# -*- coding: utf-8 -*-
"""Audit the engine surface Cyberbane touches.

Three questions, in the order they can actually be answered:
  1. Which engine hooks do we install, and does each one do anything?
  2. Which engine calls have their result assigned to a local that is then never read?
  3. Which engine calls do we make at all (the list to check against vanilla source)?
"""
import io, os, re, collections

ROOT = 'src/r6/scripts/Cyberbane'
src = {}
for root, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith('.reds'):
            p = os.path.join(root, f).replace(os.sep, '/')
            src[p] = io.open(p, encoding='utf-8', errors='replace').read()

# ---- 1. Hooks -------------------------------------------------------------
print('=' * 74)
print('HOOKS INSTALLED INTO THE GAME')
print('=' * 74)
hooks = []
for p, t in src.items():
    for m in re.finditer(r'@(wrapMethod|replaceMethod|addMethod|addField)\((\w+)\)\s*\n\s*([^\n{]+)', t):
        kind, cls, sig = m.group(1), m.group(2), m.group(3).strip()
        name = re.search(r'func (\w+)|let (\w+)', sig)
        name = (name.group(1) or name.group(2)) if name else '?'
        body_start = t.find('{', m.end())
        depth, i = 0, body_start
        while i < len(t):
            if t[i] == '{':
                depth += 1
            elif t[i] == '}':
                depth -= 1
                if depth == 0:
                    break
            i += 1
        body = t[body_start:i]
        lines = [l.strip() for l in body.split('\n')
                 if l.strip() and not l.strip().startswith('//')]
        hooks.append((kind, cls, name, len(lines), p.split('/')[-1]))

by_kind = collections.Counter(h[0] for h in hooks)
print('  %s\n' % dict(by_kind))
for kind, cls, name, n, f in sorted(hooks):
    if kind == 'addField':
        continue
    flag = '   <-- body is %d lines, check it does something' % n if n <= 3 else ''
    print('  %-14s %-28s %-26s %3dL  %s%s' % (kind, cls, name, n, f, flag))

# ---- 2. Results assigned and never read -----------------------------------
print()
print('=' * 74)
print('ENGINE RESULTS ASSIGNED TO A LOCAL THAT IS NEVER READ')
print('=' * 74)
dead = 0
for p, t in src.items():
    # function bodies, so a local's scope is bounded
    for fm in re.finditer(r'\n(?:\s*(?:public |private |protected )?(?:static )?(?:final )?func [^\n]*\{)', t):
        start = fm.end()
        depth, i = 1, start
        while i < len(t) and depth:
            if t[i] == '{':
                depth += 1
            elif t[i] == '}':
                depth -= 1
            i += 1
        body = t[start:i]
        for lm in re.finditer(r'let (\w+)(?:\s*:[^=\n]+)?\s*=\s*([^;\n]+);', body):
            var, rhs = lm.group(1), lm.group(2)
            if not re.search(r'\w\.\w+\(|^\w+\(', rhs.strip()):
                continue
            rest = body[lm.end():]
            if not re.search(r'\b' + var + r'\b', rest):
                dead += 1
                line_no = t.count('\n', 0, start + lm.start()) + 1
                print('  %s:%d  let %s = %s' % (p.split('/')[-1], line_no, var, rhs.strip()[:60]))
if dead == 0:
    print('  none')

# ---- 3. The engine surface we depend on -----------------------------------
print()
print('=' * 74)
print('ENGINE CALLS MADE (static/namespaced), BY FREQUENCY')
print('=' * 74)
calls = collections.Counter()
for p, t in src.items():
    for m in re.finditer(r'\b([A-Z]\w+)\.(\w+)\(', t):
        cls, meth = m.group(1), m.group(2)
        if cls.startswith('CB') or cls.startswith('Cyberbane'):
            continue
        calls[cls + '.' + meth] += 1
for name, n in sorted(calls.items()):
    print('  %-56s %d' % (name, n))
print('\n  %d distinct engine entry points' % len(calls))
