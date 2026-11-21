#!/usr/bin/env python3
"""Scan APK entries (.dex, .arsc, .xml, .res) for developer-settings / ADB keywords."""

import argparse
import os
import re
import sys
import zipfile

DEFAULT_KEYS = [
    "development_settings_enabled",
    "adb_enabled",
    "putGlobal",
    "putSecure",
    "putStringForUser",
    "DwDevelop",
    "StayOnWhilePlugged",
    "usb_debugging",
]


def scan_apk(apk_path: str, keys: list[str], interest_re: re.Pattern[bytes]) -> bool:
    """Scan a single APK file and print matching entries. Returns True on success."""
    if not os.path.isfile(apk_path):
        print(f"[ERROR] File not found: {apk_path}", file=sys.stderr)
        return False

    raw_keys = [k.encode("utf-8") for k in keys]
    wide_keys = [k.encode("utf-16-le") for k in keys]

    print("=" * 20, os.path.basename(apk_path), "=" * 20)
    try:
        with zipfile.ZipFile(apk_path, "r") as zf:
            for name in zf.namelist():
                if not name.endswith((".dex", ".arsc", ".xml", ".res")):
                    continue
                data = zf.read(name)
                hits = set()
                for rk, orig in zip(raw_keys, keys):
                    if rk in data:
                        hits.add(orig)
                for wk, orig in zip(wide_keys, keys):
                    if wk in data:
                        hits.add(orig)
                if hits:
                    print(f"  [{name}] contains: {sorted(hits)}")
                if name.endswith(".dex") and (
                    b"adb_enabled" in data or b"development_settings" in data
                ):
                    for match in interest_re.finditer(data):
                        snippet = match.group(0).decode("ascii", "replace").strip()
                        if len(snippet) > 8:
                            print(f"    ctx: {snippet[:120]}")
    except (zipfile.BadZipFile, OSError) as exc:
        print(f"[ERROR] Failed to read {apk_path}: {exc}", file=sys.stderr)
        return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Scan Android APK files for ADB / Developer Options settings writes."
    )
    parser.add_argument("apks", nargs="+", help="Path(s) to APK files to inspect")
    parser.add_argument(
        "--extra",
        nargs="+",
        default=[],
        metavar="KEY",
        help="Additional case-sensitive keywords to search for",
    )
    args = parser.parse_args()

    keys = list(dict.fromkeys(DEFAULT_KEYS + args.extra))
    interest_re = re.compile(
        rb"[ -~]{0,60}(adb_enabled|development_settings|DwDevelop|StayOn|adb)[ -~]{0,60}",
        re.IGNORECASE,
    )

    had_error = False
    for apk in args.apks:
        if not scan_apk(apk, keys, interest_re):
            had_error = True
    return 1 if had_error else 0


if __name__ == "__main__":
    sys.exit(main())
