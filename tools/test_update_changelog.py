import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import update_changelog


class ChangelogTests(unittest.TestCase):
    def test_description_entries_and_invalid_section(self):
        body = "## Changelog\n\n* Added a feature\n- Fixed a bug\n\n## Testing\n* Done"
        self.assertEqual(
            update_changelog.description_entries(body),
            ["Added a feature", "Fixed a bug"],
        )
        self.assertEqual(update_changelog.description_entries("## Changelog\n\n## Testing"), [])
        with self.assertRaises(ValueError):
            update_changelog.description_entries("## Changelog\nNot a bullet")

    def test_insert_and_repeat_without_changing_release_history(self):
        original = "# Changelog\n\n## 1.0\n\n* Previous release\n"
        result = update_changelog.update_changelog(original, "42", "https://example.com/42", ["Added feature"])
        self.assertEqual(
            result,
            "# Changelog\n\n## Unreleased\n\n<!-- changelog-pr:42 -->\n"
            "* Added feature ([#42](https://example.com/42))\n\n"
            "## 1.0\n\n* Previous release\n",
        )
        self.assertEqual(update_changelog.update_changelog(result, "42", "url", []), result)
        next_result = update_changelog.update_changelog(result, "43", "url", ["Fixed bug"])
        self.assertLess(next_result.index("changelog-pr:43"), next_result.index("changelog-pr:42"))

    def test_commit_fallback_starts_after_last_changelog_change(self):
        script = Path(update_changelog.__file__).resolve()
        with tempfile.TemporaryDirectory() as directory:
            previous = os.getcwd()
            try:
                os.chdir(directory)
                subprocess.run(["git", "init", "-q"], check=True)
                subprocess.run(["git", "config", "user.name", "Test"], check=True)
                subprocess.run(["git", "config", "user.email", "test@example.com"], check=True)
                subprocess.run(["git", "config", "commit.gpgsign", "false"], check=True)
                Path("CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")
                subprocess.run(["git", "add", "."], check=True)
                subprocess.run(["git", "commit", "-qm", "Previous release"], check=True)
                subprocess.run(["git", "commit", "--allow-empty", "-qm", "Add feature"], check=True)
                subprocess.run(["git", "commit", "--allow-empty", "-qm", "Fix bug"], check=True)
                self.assertEqual(update_changelog.commit_entries("HEAD"), ["Add feature", "Fix bug"])
                env = os.environ.copy()
                env.update(PR_NUMBER="42", PR_URL="https://example.com/42", PR_BODY="", HISTORY_REF="HEAD")
                subprocess.run([sys.executable, str(script)], env=env, check=True)
                result = Path("CHANGELOG.md").read_text(encoding="utf-8")
                self.assertIn("* Add feature ([#42](https://example.com/42))", result)
                self.assertIn("* Fix bug ([#42](https://example.com/42))", result)
                subprocess.run([sys.executable, str(script)], env=env, check=True)
                self.assertEqual(Path("CHANGELOG.md").read_text(encoding="utf-8"), result)
                Path("CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")
                subprocess.run(["git", "branch", "pr-head"], check=True)
                subprocess.run(["git", "checkout", "-q", "--detach", "HEAD~2"], check=True)
                env["HISTORY_REF"] = "pr-head"
                subprocess.run([sys.executable, str(script)], env=env, check=True)
                self.assertEqual(Path("CHANGELOG.md").read_text(encoding="utf-8"), result)
            finally:
                os.chdir(previous)

    def test_missing_entries_fail(self):
        with self.assertRaises(ValueError):
            update_changelog.update_changelog("# Changelog\n", "42", "url", [])


if __name__ == "__main__":
    unittest.main()
