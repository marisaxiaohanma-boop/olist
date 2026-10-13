#!/usr/bin/env python3
"""Mechanical checks for findings.md files (see docs/findings_standard.md).

Checks what can be verified automatically:
  1. English only (no CJK characters)
  2. Required sections are present (cleaning findings)
  3. Every relative link points to a file that exists
  4. Traceability: every file in the step's sql/ and results/ folders is linked
  5. Status tables explain their icons, and every non-pass row has a treatment
  6. The check-by-check table has 'Passes if / What we found / What it means / Treatment',
     and every non-pass row explains what the result means

Judgment criteria (business relevance, scope, stakeholder value, insight) are
reviewed by a person; see section 3 of docs/findings_standard.md.

Usage: python3 scripts/check_findings.py [path/to/findings.md ...]
       (no args = every findings.md in the repo)
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CJK = re.compile(r"[㐀-鿿＀-￯　-〿]")
LINK = re.compile(r"\]\(([^)#\s]+)(?:#[^)]*)?\)")
CLEANING_SECTIONS = ["Summary", "Business model fit", "Critical missing data", "Integrity",
                     "Check-by-check results", "Hand-off to", "Files"]
STATUS_ICONS = ("✅", "⚠️", "❌")


def check(path: Path) -> list[str]:
    errors = []
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    # 1. English only
    for i, line in enumerate(lines, 1):
        if CJK.search(line):
            errors.append(f"line {i}: non-English text: {line.strip()[:60]}")

    # 2. Required sections (cleaning steps only)
    if "cleaning" in path.parts:
        headings = [re.sub(r"^[\d.]+\s*", "", l.lstrip("#").strip()) for l in lines if l.startswith("#")]
        for section in CLEANING_SECTIONS:
            if not any(h.startswith(section) for h in headings):
                errors.append(f"missing section: '{section}'")

    # 3. Links resolve
    linked = set()
    for target in LINK.findall(text):
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        resolved = (path.parent / target).resolve()
        linked.add(resolved)
        if not resolved.exists():
            errors.append(f"broken link: {target}")

    # 4. Traceability: every query and result in this step is linked
    for folder in ("sql", "results"):
        for f in sorted((path.parent / folder).glob("*")):
            if f.name.startswith("."):
                continue
            if f.resolve() not in linked:
                errors.append(f"{folder}/{f.name} is not linked from findings (untraceable)")

    # 5. Status tables: icons explained, non-pass rows have a treatment
    uses_icons = any(icon in text for icon in STATUS_ICONS)
    if uses_icons and not re.search(r"✅[^|\n]*·[^|\n]*⚠️[^|\n]*·[^|\n]*❌", text):
        errors.append("status icons are used but no legend explains ✅ / ⚠️ / ❌")
    header = None
    for i, line in enumerate(lines, 1):
        if not line.startswith("|"):
            header = None
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header is None:
            header = [c.lower() for c in cells]
            continue
        if set(line) <= set("|-: "):
            continue
        if "treatment" in header and len(cells) == len(header):
            status = " ".join(cells)
            treatment = cells[header.index("treatment")]
            if ("⚠️" in status or "❌" in status) and treatment in ("", "—", "-"):
                errors.append(f"line {i}: non-pass row has no treatment: {cells[0]}")
    # 6. Check-by-check table is self-explanatory
    if "cleaning" in path.parts:
        body = text.split("Check-by-check results", 1)[-1].split("\n## ", 1)[0]
        table = [l for l in body.splitlines() if l.startswith("|")]
        if table:
            cols = [c.strip().lower() for c in table[0].strip().strip("|").split("|")]
            for required in ("passes if", "what we found", "what it means", "treatment"):
                if not any(c.startswith(required) for c in cols):
                    errors.append(f"check-by-check table is missing column '{required}'")
            if "what it means" in cols:
                k = cols.index("what it means")
                for row in table[2:]:
                    cells = [c.strip() for c in row.strip().strip("|").split("|")]
                    if len(cells) == len(cols) and ("⚠️" in row or "❌" in row) and len(cells[k].split()) < 12:
                        errors.append(f"check '{cells[0]}' is not a pass but 'What it means' is too short to explain why")
    return errors


def main(argv: list[str]) -> int:
    paths = [Path(p).resolve() for p in argv] or sorted(ROOT.rglob("findings.md"))
    failed = 0
    for p in paths:
        errs = check(p)
        rel = p.relative_to(ROOT) if p.is_relative_to(ROOT) else p
        if errs:
            failed += 1
            print(f"FAIL {rel}")
            for e in errs:
                print(f"  - {e}")
        else:
            print(f"PASS {rel}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
