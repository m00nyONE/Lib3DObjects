#!/usr/bin/env python3
"""Smoke test for `gen-font-dds.py`.

This is intentionally lightweight (no pytest dependency). It:
- Locates a font file to use (CLI arg or common Windows font locations)
- Calls `gen-font-dds.py` to produce an output image
- Asserts the output exists and is non-empty

Run (PowerShell):
  py .github/scripts/font/smoke_test.py
  py .github/scripts/font/smoke_test.py "C:\\Windows\\Fonts\\arial.ttf"
"""

import os
import subprocess
import sys
from pathlib import Path


def _find_default_font() -> Path:
    candidates = [
        Path(r"C:\Windows\Fonts\arial.ttf"),
        Path(r"C:\Windows\Fonts\segoeui.ttf"),
        Path(r"C:\Windows\Fonts\calibri.ttf"),
        Path(r"C:\Windows\Fonts\consola.ttf"),
    ]
    for c in candidates:
        if c.exists():
            return c
    raise FileNotFoundError(
        "Couldn't find a default font. Pass a font path explicitly, e.g. "
        "py .github/scripts/font/smoke_test.py C:\\path\\to\\font.ttf"
    )


def main(argv: list[str]) -> int:
    repo_root = Path(__file__).resolve().parents[3]
    script = repo_root / ".github" / "scripts" / "font" / "gen-font-dds.py"

    font_file = Path(argv[1]) if len(argv) > 1 else _find_default_font()
    out_dir = repo_root / ".github" / "scripts" / "font" / "_out"
    out_dir.mkdir(parents=True, exist_ok=True)

    # Use PNG for the smoke test initially. We'll switch to DDS once the pipeline is ready.
    output_file = out_dir / "atlas_smoke.png"

    cmd = [sys.executable, str(script), str(font_file), str(output_file)]
    print("Running:", " ".join(cmd))

    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout, end="")
    print(result.stderr, end="", file=sys.stderr)

    if result.returncode != 0:
        return result.returncode

    if not output_file.exists():
        raise AssertionError(f"Output file was not created: {output_file}")

    size = output_file.stat().st_size
    if size <= 0:
        raise AssertionError(f"Output file is empty: {output_file}")

    print(f"OK: created {output_file} ({size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

