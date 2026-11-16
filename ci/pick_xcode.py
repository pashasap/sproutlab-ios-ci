"""Print the newest release (non-beta) Xcode under /Applications; the argument, if any, is the directory to look in.

A beta can hide behind another name: a runner image may carry `Xcode_27.3.app` as a link to `Xcode_27.3_beta.app`, so the
name, the real path and the bundle's own names are all checked. Aliases of one bundle count once. Only when every Xcode
found is a beta does the newest of them come out. Everything found goes to stderr, one line each, for the run's env.txt."""
import glob
import os
import plistlib
import re
import sys

BETA = re.compile(r"beta|\brc\b|_rc|release.?candidate|preview|seed", re.I)


def names(path):
    """Every name that says what this bundle is: its path, its real path and the names in its Info.plist."""
    out = [path, os.path.realpath(path)]
    try:
        with open(os.path.join(path, "Contents", "Info.plist"), "rb") as f:
            info = plistlib.load(f)
        out += [str(info.get(k, "")) for k in ("CFBundleName", "CFBundleDisplayName", "CFBundleIdentifier")]
    except Exception:
        pass
    return out


def version(path):
    try:
        with open(os.path.join(path, "Contents", "Info.plist"), "rb") as f:
            v = plistlib.load(f).get("CFBundleShortVersionString", "")
        found = [int(n) for n in re.findall(r"\d+", v)]
        if found:
            return found
    except Exception:
        pass
    found = [int(n) for n in re.findall(r"\d+", os.path.basename(os.path.realpath(path)).split("Xcode_")[-1])]
    return found or [0]


def pick(folder="/Applications"):
    bundles = {}
    for p in sorted(glob.glob(os.path.join(folder, "Xcode_*.app"))):
        bundles.setdefault(os.path.realpath(p), []).append(p)
    rows = []
    for real, aliases in bundles.items():
        beta = any(BETA.search(n) for a in aliases for n in names(a))
        rows.append((real, aliases, beta, version(real)))
    for real, aliases, beta, v in rows:
        print(f"xcode {'BETA' if beta else 'release'} {'.'.join(map(str, v))} {real} aliases {' '.join(aliases)}", file=sys.stderr)
    pool = [r for r in rows if not r[2]] or rows
    if not pool:
        sys.exit("no Xcode_*.app under " + folder)
    return max(pool, key=lambda r: r[3])[0]


if __name__ == "__main__":
    print(pick(*sys.argv[1:2]))
