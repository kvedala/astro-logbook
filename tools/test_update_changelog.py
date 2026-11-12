import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

import update_changelog


class ChangelogTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.previous = os.getcwd()
        os.chdir(self.directory.name)
        self.run_git("init", "-q", "-b", "main")
        self.run_git("config", "user.name", "Test")
        self.run_git("config", "user.email", "test@example.com")
        self.run_git("config", "commit.gpgsign", "false")
        Path("CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")
        self.commit("Initial release")
        self.run_git("tag", "v1.0.0")

    def tearDown(self):
        os.chdir(self.previous)
        self.directory.cleanup()

    def run_git(self, *args):
        return subprocess.check_output(["git", *args], text=True).strip()

    def commit(self, subject, filename=None, description=None):
        if filename:
            Path(filename).write_text(subject, encoding="utf-8")
            self.run_git("add", filename)
        else:
            self.run_git("add", "CHANGELOG.md")
        command = ["commit", "-q", "-m", subject]
        if description:
            command.extend(["-m", description])
        self.run_git(*command)

    def test_release_entries_use_previous_tag_and_include_merges(self):
        self.run_git("checkout", "-qb", "feature")
        self.commit(
            "feat: add catalog target",
            "feature.txt",
            "Add objects visible tonight to the checklist.",
        )
        self.run_git("checkout", "-q", "main")
        self.commit("fix: save checklist target", "fix.txt")
        self.run_git(
            "merge",
            "--no-ff",
            "-m",
            "Merge feature branch\n\nAdd checklist action for visible objects.",
            "feature",
        )
        self.run_git("tag", "v1.1.0")

        version, entries = update_changelog.release_entries("v1.1.0")

        self.assertEqual(version, "1.1.0")
        self.assertCountEqual(
            entries,
            [
                {
                    "subject": "feat: add catalog target",
                    "description": "Add objects visible tonight to the checklist.",
                },
                {"subject": "fix: save checklist target", "description": ""},
                {
                    "subject": "Merge feature branch",
                    "description": "Add checklist action for visible objects.",
                },
            ],
        )

    def test_update_inserts_and_replaces_tag_section(self):
        original = "# Changelog\n\n## 1.0.0\n\n* Previous release\n"
        result = update_changelog.update_changelog(
            original, "1.1.0", ["Added feature", "Fixed bug"]
        )
        self.assertEqual(
            result,
            "# Changelog\n\n## 1.1.0\n\n* Added feature\n* Fixed bug\n\n"
            "## 1.0.0\n\n* Previous release\n",
        )
        updated = update_changelog.update_changelog(
            result, "1.1.0", ["Corrected entry"]
        )
        self.assertEqual(
            updated,
            "# Changelog\n\n## 1.1.0\n\n* Corrected entry\n\n"
            "## 1.0.0\n\n* Previous release\n",
        )
        self.assertEqual(updated.count("## 1.1.0"), 1)
        self.assertIn("* Corrected entry", updated)
        self.assertNotIn("* Added feature", updated)

    @patch("update_changelog.urlopen")
    def test_rewrite_entries_uses_openrouter_free_router(self, urlopen):
        response_body = {
            "output": [
                {
                    "type": "message",
                    "content": [
                        {
                            "type": "output_text",
                            "text": json.dumps(
                                {"entries": ["Added visible targets to the checklist"]}
                            ),
                        }
                    ],
                }
            ]
        }
        urlopen.return_value = io.BytesIO(json.dumps(response_body).encode("utf-8"))

        commits = [
            {
                "subject": "feat: add visible catalog targets",
                "description": "Allow adding selected objects to the checklist.",
            }
        ]
        entries = update_changelog.rewrite_entries(commits, "test-key")

        request = urlopen.call_args.args[0]
        payload = json.loads(request.data)
        self.assertEqual(payload["model"], "openrouter/free")
        self.assertEqual(payload["text"], {"format": {"type": "json_object"}})
        self.assertEqual(
            json.loads(payload["input"]), commits
        )
        self.assertEqual(request.get_header("Authorization"), "Bearer test-key")
        self.assertEqual(entries, ["Added visible targets to the checklist"])

    @patch("update_changelog.urlopen")
    def test_rewrite_entries_reads_responses_api_output_text(self, urlopen):
        response_body = {
            "output": [
                {
                    "type": "message",
                    "output_text": json.dumps({"entries": ["Added a catalog target"]}),
                }
            ]
        }
        urlopen.return_value = io.BytesIO(json.dumps(response_body).encode("utf-8"))

        entries = update_changelog.rewrite_entries(
            [{"subject": "feat: add target", "description": ""}], "test-key"
        )

        self.assertEqual(entries, ["Added a catalog target"])

    @patch("update_changelog.urlopen")
    def test_rewrite_entries_reads_object_style_response_content(self, urlopen):
        response_body = {
            "output": [
                {
                    "type": "message",
                    "content": {
                        "output_text": json.dumps(
                            {"entries": ["Added a catalog target"]}
                        )
                    },
                }
            ]
        }
        urlopen.return_value = io.BytesIO(json.dumps(response_body).encode("utf-8"))

        entries = update_changelog.rewrite_entries(
            [{"subject": "feat: add target", "description": ""}], "test-key"
        )

        self.assertEqual(entries, ["Added a catalog target"])

    @patch("update_changelog.urlopen")
    def test_rewrite_entries_reads_structured_response_json(self, urlopen):
        response_body = {
            "output": [
                {
                    "type": "message",
                    "content": {"output_json": {"entries": ["Added a catalog target"]}},
                }
            ]
        }
        urlopen.return_value = io.BytesIO(json.dumps(response_body).encode("utf-8"))

        entries = update_changelog.rewrite_entries(
            [{"subject": "feat: add target", "description": ""}], "test-key"
        )

        self.assertEqual(entries, ["Added a catalog target"])

    @patch("update_changelog.urlopen")
    def test_invalid_model_output_fails_instead_of_using_commit_subjects(self, urlopen):
        response_body = {
            "output": [
                {
                    "type": "message",
                    "content": [{"type": "output_text", "text": "not JSON"}],
                }
            ]
        }
        urlopen.return_value = io.BytesIO(json.dumps(response_body).encode("utf-8"))

        with self.assertRaisesRegex(ValueError, "required JSON"):
            update_changelog.rewrite_entries(
                [{"subject": "feat: add target", "description": ""}], "test-key"
            )

    @patch("update_changelog.urlopen")
    def test_missing_generated_text_reports_response_status_and_types(self, urlopen):
        response_body = {
            "status": "incomplete",
            "output": [{"type": "reasoning", "summary": []}],
        }
        urlopen.return_value = io.BytesIO(json.dumps(response_body).encode("utf-8"))

        with self.assertRaisesRegex(
            ValueError, "status: incomplete; output types: reasoning"
        ):
            update_changelog.rewrite_entries(
                [{"subject": "feat: add target", "description": ""}], "test-key"
            )

    @patch("update_changelog.urlopen")
    def test_main_generates_release_from_tag_range_with_mocked_model(self, urlopen):
        response_body = {
            "output": [
                {
                    "type": "message",
                    "content": [
                        {
                            "type": "output_text",
                            "text": json.dumps(
                                {"entries": ["Added a catalog target"]}
                            ),
                        }
                    ],
                }
            ]
        }
        urlopen.return_value = io.BytesIO(json.dumps(response_body).encode("utf-8"))
        self.commit(
            "feat: add visible catalog target",
            "feature.txt",
            "Allow viewers to add individual objects.",
        )
        self.run_git("tag", "v1.1.0")
        with patch.dict(
            os.environ,
            {"RELEASE_TAG": "v1.1.0", "OPENROUTER_API_KEY": "test-key"},
        ):
            update_changelog.main()

        payload = json.loads(urlopen.call_args.args[0].data)
        self.assertEqual(
            json.loads(payload["input"]),
            [
                {
                    "subject": "feat: add visible catalog target",
                    "description": "Allow viewers to add individual objects.",
                }
            ],
        )
        result = Path("CHANGELOG.md").read_text(encoding="utf-8")
        self.assertIn("## 1.1.0", result)
        self.assertIn("* Added a catalog target", result)

    @patch("update_changelog.urlopen")
    def test_dry_run_prints_diff_without_writing(self, urlopen):
        response_body = {
            "output": [
                {
                    "type": "message",
                    "content": [
                        {
                            "type": "output_text",
                            "text": json.dumps({"entries": ["Added a catalog target"]}),
                        }
                    ],
                }
            ]
        }
        urlopen.return_value = io.BytesIO(json.dumps(response_body).encode("utf-8"))
        self.commit("feat: add visible catalog target", "feature.txt")
        self.run_git("tag", "v1.1.0")
        original = Path("CHANGELOG.md").read_text(encoding="utf-8")
        output = io.StringIO()
        with patch.dict(
            os.environ,
            {"RELEASE_TAG": "v1.1.0", "OPENROUTER_API_KEY": "test-key"},
        ), redirect_stdout(output):
            update_changelog.main(["--dry-run"])

        self.assertIn("+* Added a catalog target", output.getvalue())
        self.assertEqual(Path("CHANGELOG.md").read_text(encoding="utf-8"), original)

    def test_release_without_previous_tag_fails(self):
        with self.assertRaisesRegex(ValueError, "No previous version tag"):
            update_changelog.release_entries("v1.0.0")

    def test_invalid_tag_fails(self):
        with self.assertRaisesRegex(ValueError, "Invalid release tag"):
            update_changelog.release_entries("release-1.1.0")


if __name__ == "__main__":
    unittest.main()
