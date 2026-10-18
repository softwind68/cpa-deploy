"""Offline checks. No system services, real accounts, or network calls."""

from __future__ import annotations

import importlib.util
import re
import shutil
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "cpa-deploy.sh"


def heredocs() -> list[tuple[str, str]]:
    lines = SOURCE.read_text(encoding="utf-8").splitlines(keepends=True)
    result = []
    index = 0
    while index < len(lines):
        match = re.search(r"<<'([A-Z][A-Z0-9_]*)'", lines[index])
        if not match:
            index += 1
            continue
        delimiter = match.group(1)
        start = index + 1
        index = start
        while index < len(lines) and lines[index].rstrip("\r\n") != delimiter:
            index += 1
        if index == len(lines):
            raise AssertionError(f"Unclosed heredoc: {delimiter}")
        result.append((delimiter, "".join(lines[start:index])))
        index += 1
    return result


def load_scanner():
    spec = importlib.util.spec_from_file_location("scan_release", ROOT / "tools" / "scan_release.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ReleaseTests(unittest.TestCase):
    def test_readme_menus_match_script(self):
        source = SOURCE.read_text(encoding="utf-8")
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        documented = [
            [" ".join(line.split()) for line in block.splitlines()
             if re.match(r"^\s*\d+\.\s+", line)]
            for block in re.findall(r"```text\n(.*?)```", readme, re.S)
        ]
        menus = (
            "show_menu", "deployment_menu", "log_cleanup_menu",
            "fail2ban_management_menu", "fail2ban_whitelist_menu",
            "cpamp_maintenance_menu", "public_status_menu",
            "public_status_quota_menu", "public_status_quota_refresh_settings",
            "admission_menu",
        )
        for name in menus:
            with self.subTest(menu=name):
                match = re.search(rf"^{name}\(\) \{{\n(.*?)^\}}$", source, re.M | re.S)
                self.assertIsNotNone(match, name)
                body = re.split(
                    r"^\s*(?:if ! )?read -r -p ", match.group(1), maxsplit=1, flags=re.M,
                )[0]
                labels = []
                for line in body.splitlines():
                    line = line.strip()
                    if line.startswith("printf '") and line.endswith("'"):
                        line = line[len("printf '"):-1].replace(r"\n", "\n")
                    labels.extend(
                        " ".join(label.split()) for label in line.splitlines()
                        if re.match(r"^\s*\d+\.\s+", label)
                    )
                self.assertTrue(labels, name)
                self.assertIn(labels, documented, f"README menu is out of sync: {name}")

    def test_source_encoding(self):
        raw = SOURCE.read_bytes()
        self.assertNotIn(b"\r", raw)
        self.assertFalse(raw.startswith(b"\xef\xbb\xbf"))
        self.assertNotIn("\ufffd", raw.decode("utf-8"))
        self.assertTrue(raw.endswith(b"\n"))

    def test_embedded_python_compiles(self):
        blocks = [
            (tag, body) for tag, body in heredocs()
            if tag.startswith("PY") or tag in {"CPA229_RICH_HELPER_EOF", "CPA239_LIMIT_PROBE"}
        ]
        self.assertGreaterEqual(len(blocks), 10)
        for tag, body in blocks:
            with self.subTest(tag=tag):
                compile(body, f"cpa-deploy.sh:{tag}", "exec")

    def test_embedded_helper_regressions(self):
        blocks = heredocs()
        helper = next(body for tag, body in blocks if tag == "CPA229_RICH_HELPER_EOF")
        checks = next(
            body for tag, body in blocks
            if tag == "PY" and body.startswith("import importlib.util\n")
        )
        with tempfile.TemporaryDirectory(prefix="cpa-helper-tests-") as directory:
            helper_path = Path(directory) / "rich_helper.py"
            helper_path.write_text(helper, encoding="utf-8")
            result = subprocess.run(
                [sys.executable, "-B", "-", str(helper_path)],
                input=checks, text=True, encoding="utf-8", capture_output=True, timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stderr)

    @unittest.skipUnless(shutil.which("node"), "Node.js is required for frontend syntax checks")
    def test_embedded_javascript_syntax(self):
        javascript = next(body for tag, body in heredocs() if tag == "CPA229_JS_EOF")
        result = subprocess.run(
            ["node", "--check", "-"], input=javascript, text=True,
            encoding="utf-8", capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_release_has_no_configured_sensitive_patterns(self):
        count, findings = load_scanner().scan_tree(ROOT)
        self.assertGreater(count, 10)
        self.assertEqual(findings, [])

    def test_scanner_rejects_synthetic_credentials(self):
        scanner = load_scanner()
        samples = [
            "gh" + "p_" + "A1" * 20,
            "sk-" + "test1234" * 5,
            "-----BEGIN " + "PRIVATE KEY-----",
            "https://" + "user:password" + "@example.com",
        ]
        for value in samples:
            with self.subTest(kind=value[:2]):
                self.assertTrue(scanner.inspect_text(value))

    def test_scanner_rejects_non_example_identity(self):
        address = "fixture" + "@" + "mail.invalid"
        self.assertTrue(load_scanner().inspect_text(address))
        self.assertTrue(load_scanner().inspect_text(f"codex-aaaaaa-{address}-team.json"))

    def test_scanner_allows_example_identity(self):
        text = "codex-aaaaaa-main@example.com-team.json user@server.example.com 203.0.113.9 127.0.0.1 0.0.0.0"
        self.assertEqual(load_scanner().inspect_text(text), [])

    def test_scanner_rejects_runtime_files(self):
        with tempfile.TemporaryDirectory(prefix="cpa-release-tests-") as directory:
            (Path(directory) / ".env").write_text("LOCAL_SETTING=example\n", encoding="utf-8")
            count, findings = load_scanner().scan_tree(Path(directory))
            self.assertEqual(count, 1)
            self.assertTrue(any("runtime-or-private-file" in item for item in findings))

    def test_helper_drops_sensitive_event_fields(self):
        body = next(body for tag, body in heredocs() if tag == "CPA229_RICH_HELPER_EOF")
        module = types.ModuleType("rich_test")
        exec(compile(body, "embedded-rich-helper", "exec"), module.__dict__)
        payload = module.sanitize_calls({"events": {"items": [{
            "timestamp_ms": 1, "model": "test-model", "failed": False,
            "api_key_hash": "fixture-hash", "source": "fixture-unmasked-value",
            "client_ip": "203.0.113.9", "request_body": "private-request",
            "response_body": "private-response", "account_snapshot": "private-account",
        }]}}, {})
        encoded = module.dump_bytes(payload).decode("utf-8")
        for value in (
            "fixture-hash", "fixture-unmasked-value", "203.0.113.9",
            "private-request", "private-response", "private-account",
        ):
            self.assertNotIn(value, encoded)
        self.assertEqual(len(payload), 1)


if __name__ == "__main__":
    unittest.main()
