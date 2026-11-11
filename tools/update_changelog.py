#!/usr/bin/env python3
"""Add a pull request's changelog entries to the checked-out repository."""

import os
from pathlib import Path
import re
import subprocess
import sys


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def description_entries(body):
    match = re.search(r"(?im)^##\s+Changelog\s*$", body)
    if not match:
        return []
    section = body[match.end():]
    next_heading = re.search(r"(?m)^#{1,2}\s+", section)
    if next_heading:
        section = section[:next_heading.start()]
    lines = section.strip().splitlines()
    if not lines:
        return []
    if any(not re.match(r"^\s*[-*]\s+\S", line) for line in lines if line.strip()):
        raise ValueError("The PR's Changelog section must contain bullet points only.")
    return [re.sub(r"^\s*[-*]\s+", "", line.strip()) for line in lines if line.strip()]


def commit_entries(history_ref):
    last_update = git("log", "-1", "--format=%H", history_ref, "--", "CHANGELOG.md")
    revision = f"{last_update}..{history_ref}" if last_update else history_ref
    subjects = git("log", "--no-merges", "--reverse", "--format=%s", revision)
    return subjects.splitlines() if subjects else []


def update_changelog(content, number, url, entries):
    marker = f"<!-- changelog-pr:{number} -->"
    if marker in content:
        return content
    if not entries:
        raise ValueError("No changelog entries or commits since the last changelog update.")
    if not re.match(r"^# Changelog\s*\n", content):
        raise ValueError("CHANGELOG.md must start with '# Changelog'.")
    if any("<!-- changelog-pr:" in entry for entry in entries):
        raise ValueError("Changelog entries must not contain changelog markers.")
    block = marker + "\n" + "\n".join(f"* {entry} ([#{number}]({url}))" for entry in entries) + "\n\n"
    unreleased = re.search(r"(?m)^## Unreleased\s*$", content)
    if unreleased:
        insertion = unreleased.end()
        return content[:insertion] + "\n\n" + block + content[insertion:].lstrip("\n")
    title = re.match(r"^# Changelog[^\n]*\n", content)
    return content[:title.end()] + "\n## Unreleased\n\n" + block + content[title.end():].lstrip("\n")


def main():
    number = os.environ["PR_NUMBER"]
    if not number.isdecimal():
        raise ValueError("PR_NUMBER must be numeric.")
    path = Path("CHANGELOG.md")
    if path.is_symlink():
        raise ValueError("CHANGELOG.md must not be a symbolic link.")
    content = path.read_text(encoding="utf-8")
    if f"<!-- changelog-pr:{number} -->" in content:
        return
    entries = description_entries(os.environ.get("PR_BODY", ""))
    if not entries:
        entries = commit_entries(os.environ["HISTORY_REF"])
    updated = update_changelog(content, number, os.environ["PR_URL"], entries)
    path.write_text(updated, encoding="utf-8")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Changelog update failed: {error}", file=sys.stderr)
        sys.exit(1)
