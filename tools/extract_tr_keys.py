"""One-off: list translation keys used in lib/ vs JSON files."""
import json
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), "..")
LIB = os.path.join(ROOT, "lib")
AR = os.path.join(ROOT, "assets", "translations", "ar.json")
EN = os.path.join(ROOT, "assets", "translations", "en.json")

patterns = [
    re.compile(r"\.tr\(\s*['\"]([^'\"]+)['\"]"),
    re.compile(r"\btr\(\s*['\"]([^'\"]+)['\"]"),
    re.compile(r"easy_localization\.tr\(\s*['\"]([^'\"]+)['\"]"),
    re.compile(r"['\"]([a-zA-Z][a-zA-Z0-9_]*)['\"]\.tr\("),
]

keys: set[str] = set()
for dirpath, _, files in os.walk(LIB):
    for f in files:
        if not f.endswith(".dart"):
            continue
        path = os.path.join(dirpath, f)
        with open(path, encoding="utf-8") as fp:
            text = fp.read()
        for pat in patterns:
            keys.update(pat.findall(text))

with open(EN, encoding="utf-8") as fp:
    en_keys = set(json.load(fp).keys())
with open(AR, encoding="utf-8") as fp:
    ar_keys = set(json.load(fp).keys())

used_missing_en = sorted(keys - en_keys)
used_missing_ar = sorted(keys - ar_keys)
in_ar_not_en = sorted(ar_keys - en_keys)
in_en_not_ar = sorted(en_keys - ar_keys)

print("=== Used in Dart, missing in en.json ===")
for k in used_missing_en:
    print(k)
print(f"count: {len(used_missing_en)}")
print()
print("=== Used in Dart, missing in ar.json ===")
for k in used_missing_ar:
    print(k)
print(f"count: {len(used_missing_ar)}")
print()
print(f"keys in en not ar: {len(in_en_not_ar)}")
print(f"keys in ar not en: {len(in_ar_not_en)}")
