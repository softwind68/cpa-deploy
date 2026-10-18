#!/usr/bin/env python3
"""Conservative release-tree checks; not a replacement for a history audit."""

from __future__ import annotations

import ipaddress
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IGNORED_DIRS = {".git", "__pycache__", ".venv", "node_modules", ".pytest_cache"}
ALLOWED_EMAIL_DOMAINS = {"example.com", "example.net", "example.org", "example.invalid"}
PRIVATE_NAMES = {
    ".env", "config.yaml", "config.yml", "Caddyfile", "status.conf", "quota.conf",
    "quota-remarks.json", "snapshot.json", "id_rsa", "id_ed25519",
    "cpa-deploy-credentials.conf",
}
PRIVATE_SUFFIXES = {".key", ".pem", ".p12", ".pfx", ".db", ".sqlite", ".sqlite3", ".log"}
EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.[A-Za-z]{2,})")
AUTH_FILE_RE = re.compile(r"codex-[0-9a-f]{6,64}-([^\s\"'<>]+)-team\.json", re.I)
IPV4_RE = re.compile(r"(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])")
DOCUMENTATION_NETWORKS = tuple(
    ipaddress.ip_network(value) for value in ("192.0.2.0/24", "198.51.100.0/24", "203.0.113.0/24")
)
SECRET_PATTERNS = {
    "private-key": re.compile(r"-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----"),
    "aws-access-key": re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"),
    "github-token": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{30,})\b"),
    "api-token": re.compile(r"\bsk-(?:proj-|ant-)?[A-Za-z0-9_-]{24,}\b"),
    "jwt": re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
    "credential-url": re.compile(r"https?://[^\s/@:\"']+:[^\s/@\"']+@"),
}


def inspect_text(text: str) -> list[tuple[int, str]]:
    findings: list[tuple[int, str]] = []
    for line_no, line in enumerate(text.splitlines(), 1):
        for name, pattern in SECRET_PATTERNS.items():
            if pattern.search(line):
                findings.append((line_no, name))
        # Strip the auth-file wrapper before treating an address as an email.
        normalized = AUTH_FILE_RE.sub(lambda match: match.group(1), line)
        for match in EMAIL_RE.finditer(normalized):
            domain = match.group(1).lower()
            if not any(
                domain == allowed or domain.endswith("." + allowed)
                for allowed in ALLOWED_EMAIL_DOMAINS
            ):
                findings.append((line_no, "non-example-email"))
        for match in IPV4_RE.finditer(line):
            try:
                address = ipaddress.ip_address(match.group())
            except ValueError:
                continue
            if not (
                address.is_loopback or address.is_unspecified
                or any(address in network for network in DOCUMENTATION_NETWORKS)
            ):
                findings.append((line_no, "non-example-ipv4"))
    return findings


def scan_tree(root: Path) -> tuple[int, list[str]]:
    count = 0
    findings: list[str] = []
    paths: list[Path] = []

    def unreadable_directory(error: OSError) -> None:
        findings.append(f"unreadable-directory: {Path(error.filename).name}")

    for directory, names, files in os.walk(root, onerror=unreadable_directory):
        for name in sorted(names):
            path = Path(directory) / name
            if name not in IGNORED_DIRS and path.is_symlink():
                findings.append(f"{path.relative_to(root).as_posix()}: symlink-not-allowed")
        names[:] = sorted(
            name for name in names
            if name not in IGNORED_DIRS and not (Path(directory) / name).is_symlink()
        )
        paths.extend(Path(directory) / name for name in files)
    for path in sorted(paths):
        relative = path.relative_to(root)
        if path.is_symlink():
            findings.append(f"{relative.as_posix()}: symlink-not-allowed")
            continue
        count += 1
        if (
            path.name in PRIVATE_NAMES or path.suffix.lower() in PRIVATE_SUFFIXES
            or (path.name.startswith(".env.") and not path.name.endswith((".example", ".template")))
            or any(part in {"backups", "exports", ".cli-proxy-api"} for part in relative.parts)
        ):
            findings.append(f"{relative.as_posix()}: runtime-or-private-file")
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeError, OSError):
            findings.append(f"{relative.as_posix()}: binary-or-unreadable-file")
            continue
        for line_no, kind in inspect_text(text):
            # Never print a matched value into CI logs.
            findings.append(f"{relative.as_posix()}:{line_no}: {kind}")
    return count, findings


def main() -> int:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT
    if not root.is_dir():
        print("Release root is not a directory.", file=sys.stderr)
        return 2
    count, findings = scan_tree(root)
    if findings:
        print("\n".join(findings), file=sys.stderr)
        print(f"FAIL: {len(findings)} findings in {count} files.", file=sys.stderr)
        return 1
    print(f"PASS: {count} release files; no configured privacy/secret patterns found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
