"""Cyberbane localization check (2.7.1). Run by build.ps1 and validate.ps1; exits 1 on any fault.

  python -I tools/check_loc.py                      check
  python -I tools/check_loc.py --changed-since REF  also list keys added or changed since a git ref (for translators)

Checks, over src/r6/scripts/Cyberbane:
  - every key the code asks for (CBT(n"..."), CBTf(n"...", ...), Mod Settings names, descriptions, categories and dropdown
    values) is defined in Localization/en-us/English.reds;
  - no key is defined twice;
  - every CBTf call passes as many slot values as its English uses ({0} {1} ...), and a CBT call's English uses none;
  - every Define method of the English class is called from DefineTexts, and every call has a method.
"""
import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(os.path.dirname(HERE), 'src', 'r6', 'scripts', 'Cyberbane')
ENG = os.path.join(ROOT, 'Localization', 'en-us', 'English.reds')

TEXT_RE = re.compile(r'this\.Text\("([^"]+)",\s*"((?:\\.|[^"\\])*)"(?:\s*,\s*"((?:\\.|[^"\\])*)")?\)')


def strip_comments(src):
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == '"':
            j = i + 1
            while j < n and src[j] != '"':
                j += 2 if src[j] == '\\' else 1
            out.append(src[i:j + 1])
            i = j + 1
            continue
        if src.startswith('//', i):
            j = src.find('\n', i)
            i = n if j < 0 else j
            continue
        if src.startswith('/*', i):
            j = src.find('*/', i + 2)
            i = n if j < 0 else j + 2
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def english(path):
    src = strip_comments(open(path, encoding='utf-8').read())
    defs, dups = {}, []
    for m in TEXT_RE.finditer(src):
        k = m.group(1)
        if k in defs:
            dups.append(k)
        defs[k] = m.group(2) + ('\x00' + m.group(3) if m.group(3) is not None else '')
    methods = set(re.findall(r'protected func (Define[A-Za-z0-9_]*)\(\)', src))
    body = re.search(r'protected func DefineTexts\(\) -> Void \{(.*?)\n  \}', src, re.S)
    called = set(re.findall(r'this\.(Define[A-Za-z0-9_]*)\(\);', body.group(1))) if body else set()
    return defs, dups, methods, called


def slots_in(text):
    found = set(int(x) for x in re.findall(r'\{(\d+)\}', text))
    return (max(found) + 1) if found else 0


def call_args(src, start):
    """src[start] is '(' of CBTf; returns the number of items in its second argument's array literal, or -1."""
    depth, i, n = 0, start, len(src)
    arr_depth, items, in_arr, seen_item = None, 0, False, False
    while i < n:
        c = src[i]
        if c == '"':
            j = i + 1
            while j < n and src[j] != '"':
                if src[j] == '\\' and j + 1 < n and src[j + 1] == '(':
                    # interpolation: skip to its close
                    d, j = 1, j + 2
                    while j < n and d > 0:
                        if src[j] == '(':
                            d += 1
                        elif src[j] == ')':
                            d -= 1
                        elif src[j] == '"':
                            j += 1
                            while j < n and src[j] != '"':
                                j += 2 if src[j] == '\\' else 1
                        j += 1
                    continue
                j += 2 if src[j] == '\\' else 1
            if in_arr and depth == arr_depth:
                seen_item = True
            i = j + 1
            continue
        if c in '([':
            if c == '[' and not in_arr and depth == 1:
                in_arr, arr_depth = True, depth + 1
            elif in_arr and depth == arr_depth:
                seen_item = True   # an item that starts with a bracket: (a ? b : c), [..]
            depth += 1
        elif c in ')]':
            depth -= 1
            if in_arr and c == ']' and depth == arr_depth - 1:
                return items + (1 if seen_item else 0)
            if depth == 0:
                return -1
        elif c == ',' and in_arr and depth == arr_depth:
            items += 1
            seen_item = False
        elif not c.isspace() and in_arr and depth == arr_depth:
            seen_item = True
        i += 1
    return -1


def main():
    faults = []
    defs, dups, methods, called = english(ENG)
    for k in dups:
        faults.append('defined twice: %s' % k)
    for m in sorted(methods - called - {'DefineTexts'}):
        faults.append('English method never called from DefineTexts: %s' % m)
    for m in sorted(called - methods):
        faults.append('DefineTexts calls a method that does not exist: %s' % m)
    used = 0
    for d, _, fs in os.walk(ROOT):
        for f in fs:
            if not f.endswith('.reds'):
                continue
            path = os.path.join(d, f)
            rel = os.path.relpath(path, ROOT)
            src = strip_comments(open(path, encoding='utf-8').read())
            for m in re.finditer(r'\bCBT\(n"([^"]+)"\)', src):
                used += 1
                k = m.group(1)
                if k not in defs:
                    faults.append('%s: CBT key not defined: %s' % (rel, k))
                elif slots_in(defs[k]) > 0:
                    faults.append('%s: CBT used for a line with slots (use CBTf): %s' % (rel, k))
            for m in re.finditer(r'\bCBTf\(n"([^"]+)",', src):
                used += 1
                k = m.group(1)
                if k not in defs:
                    faults.append('%s: CBTf key not defined: %s' % (rel, k))
                    continue
                n = call_args(src, m.start() + 4)
                want = slots_in(defs[k])
                if n != want:
                    faults.append('%s: CBTf %s passes %d slot(s), its English uses %d' % (rel, k, n, want))
            for m in re.finditer(r'@runtimeProperty\("ModSettings\.(?:displayName|description|category|displayValues\.[A-Za-z0-9_]+)",\s*"([^"]+)"\)', src):
                k = m.group(1)
                used += 1
                if k.startswith('Cyberbane-') and k not in defs:
                    faults.append('%s: Mod Settings key not defined: %s' % (rel, k))
    print('Localization: %d keys defined, %d uses checked.' % (len(defs), used))
    if '--changed-since' in sys.argv:
        ref = sys.argv[sys.argv.index('--changed-since') + 1]
        try:
            old = subprocess.run(['git', 'show', '%s:src/r6/scripts/Cyberbane/Localization/en-us/English.reds' % ref],
                                 cwd=os.path.dirname(HERE), capture_output=True, text=True, encoding='utf-8').stdout
            olddefs = {m.group(1): m.group(2) for m in TEXT_RE.finditer(strip_comments(old))}
        except Exception:
            olddefs = {}
        for k in defs:
            if k not in olddefs:
                print('  new      %s' % k)
            elif olddefs[k] != defs[k].split('\x00')[0]:
                print('  changed  %s' % k)
    if faults:
        for f in faults:
            print('FAULT ' + f)
        print('%d localization fault(s).' % len(faults))
        sys.exit(1)
    print('OK: localization keys and slots line up.')


main()
