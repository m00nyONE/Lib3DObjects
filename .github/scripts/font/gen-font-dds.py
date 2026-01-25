#!/usr/bin/env python3

import argparse
import os
from pathlib import Path
from typing import List, Optional


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a font texture atlas (DDS) + Lua metadata from an OTF/TTF font file."
    )
    parser.add_argument("inputFontFile", help="Path to the input .otf/.ttf font file")
    parser.add_argument(
        "outputFolder",
        help="Output folder that will contain <fontname>.dds and <fontname>.lua",
    )

    parser.add_argument(
        "--meta-lua-var",
        default=None,
        help=(
            "Lua variable/table name to generate. Defaults to the input font file name (stem)."
        ),
    )

    parser.add_argument("--cell", type=int, default=64, help="Cell size in pixels")
    parser.add_argument("--padding", type=int, default=6, help="Padding inside each cell (pixels)")

    # Dynamic atlas options
    parser.add_argument(
        "--mode",
        choices=["ascii", "all"],
        default="ascii",
        help="Which glyphs to include: 'ascii' (printable 32..127) or 'all' (all font cmap codepoints)",
    )
    parser.add_argument("--cols", type=int, default=16, help="Number of columns for ascii mode")
    parser.add_argument("--rows", type=int, default=6, help="Number of rows for ascii mode")
    parser.add_argument("--start", type=int, default=32, help="First ASCII code point for ascii mode")

    parser.add_argument(
        "--max-size",
        type=int,
        default=4096,
        help="Maximum atlas width/height in pixels (for dynamic mode).",
    )

    parser.add_argument(
        "--ink-center",
        action="store_true",
        help="Recenter glyphs by their ink bounds (trim + re-center inside the tile).",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Draw debug overlays on atlas (cell centers and row baselines)",
    )
    parser.add_argument(
        "--debug-tiles-dir",
        default=None,
        help="If set, save per-glyph tile images into this directory for inspection.",
    )
    parser.add_argument(
        "--meta-uv-inset-px",
        type=float,
        default=0.0,
        help="Inset UV rect by this many pixels on each side to reduce bleeding (e.g. 0.5).",
    )
    return parser.parse_args(argv)


def _ensure_parent_dir(path: Path) -> None:
    parent = path.parent
    if parent and str(parent) != ".":
        parent.mkdir(parents=True, exist_ok=True)


def _safe_char_for_filename(ch: str, codepoint: int) -> str:
    if ch.isalnum():
        return ch
    return f"U{codepoint:04X}"


def _dds_options(atlas) -> None:
    """Apply DDS writer defaults for ESO UI atlases."""

    # Only DXT5 requested.
    atlas.options["dds:compression"] = "dxt5"
    # Disable mipmaps by default (atlas bleeding).
    atlas.options["dds:mipmaps"] = "0"


def _compute_baseline_params(draw, img, cell: int, padding: int):
    """Compute font_size and baseline offset (within a tile) from representative metrics."""

    # Choose a size that fits comfortably into the cell.
    font_size = int((cell - 2 * padding) * 0.85)
    draw.font_size = font_size

    # Use a representative glyph with a typical ascender.
    rep_metrics = draw.get_font_metrics(img, "M", multiline=False)
    asc = rep_metrics.ascender
    desc = abs(rep_metrics.descender)
    font_height = asc + desc

    # Baseline position within the cell.
    baseline = (cell - font_height) / 2.0 + asc
    return font_size, baseline


def _render_glyph_tile(
    *,
    font_file: Path,
    ch: str,
    codepoint: int,
    cell: int,
    padding: int,
    ink_center: bool,
    baseline: float,
    font_size: int,
):
    """Render a single glyph into its own cell-sized RGBA tile.

    Important: Wand Images created via context managers are closed at the end of the block.
    This function therefore returns a *clone* whose lifetime is independent.

    Robustness notes:
    - Some fonts include extremely wide glyphs (e.g. decorative variants) whose advance width can
      exceed the cell size. Wand requires non-negative integer coordinates.
    - We therefore adapt font size down if the glyph doesn't fit and clamp x/y to >= 0.
    """

    from wand.color import Color
    from wand.drawing import Drawing
    from wand.image import Image

    def clamp_nonneg(v: float) -> int:
        return int(round(v)) if v > 0 else 0

    with Image(width=cell, height=cell, background=Color("transparent")) as tile:
        # Try a few decreasing font sizes if the glyph is too wide.
        size = int(font_size)
        for _ in range(6):
            with Drawing() as d:
                d.font = str(font_file)
                d.fill_color = Color("white")
                d.text_antialias = True
                d.stroke_opacity = 0.0
                d.stroke_width = 0
                d.font_size = size

                metrics = d.get_font_metrics(tile, ch, multiline=False)

                # If it doesn't fit horizontally, shrink and retry.
                max_w = max(1.0, cell - 2.0 * padding)
                if metrics.text_width > max_w and size > 1:
                    # scale down proportionally and retry
                    scale = max_w / float(metrics.text_width)
                    new_size = int(max(1, size * scale))
                    if new_size >= size:
                        new_size = size - 1
                    size = new_size
                    continue

                x = (cell - metrics.text_width) / 2.0
                y = baseline

                d.text(clamp_nonneg(x), clamp_nonneg(y), ch)
                d(tile)
                break

        if ink_center:
            # Try to center by actual ink bounds.
            # Use trim() to find the non-transparent bounds and composite into a fresh tile.
            # A small fuzz helps with antialiased edges.
            try:
                trimmed = tile.clone()
                trimmed.alpha_channel = True
                trimmed.trim(fuzz=0.02 * trimmed.quantum_range)
                tw, th = trimmed.width, trimmed.height
                if tw > 0 and th > 0 and (tw < cell or th < cell):
                    with Image(width=cell, height=cell, background=Color("transparent")) as centered:
                        left = int(round((cell - tw) / 2.0))
                        top = int(round((cell - th) / 2.0))
                        centered.composite(trimmed, left=left, top=top)
                        return centered.clone()
            except Exception:
                # If trimming fails for any reason, fall back to baseline-centered tile.
                pass

        return tile.clone()


def _lua_escape_string(s: str) -> str:
    # Escape backslash and quotes; keep it simple for single-char keys.
    return s.replace("\\", "\\\\").replace('"', '\\"')


def _lua_char_key(ch: str) -> str:
    """Return a Lua table key expression for a single character.

    Prefer ["x"] syntax; for special chars like newline, use string.byte to keep it unambiguous.
    """

    if len(ch) != 1:
        raise ValueError("expected single character")

    cp = ord(ch)
    # Avoid control chars; use numeric codepoint key.
    if cp < 32 or cp == 127:
        return f"[{cp}]"

    return f"[\"{_lua_escape_string(ch)}\"]"


def write_lua_metadata(
    *,
    output_path: Path,
    font_name: str,
    atlas_width: int,
    atlas_height: int,
    cell: int,
    cols: int,
    rows: int,
    mapping: List[tuple[str, int, int]],
    uv_inset_px: float = 0.0,
) -> None:
    """Write a Lua file describing the atlas layout.

    mapping: list of (char, col, row)
    Outputs UV coords: { left, right, top, bottom } in 0..1.
    """

    _ensure_parent_dir(output_path)

    u_inset = float(uv_inset_px) / float(atlas_width) if atlas_width > 0 else 0.0
    v_inset = float(uv_inset_px) / float(atlas_height) if atlas_height > 0 else 0.0

    def fmt(f: float) -> str:
        # Keep it stable & compact; ESO accepts normal decimal floats.
        return ("{:.8f}".format(f)).rstrip("0").rstrip(".")

    lines = []
    lines.append("-- Auto-generated by gen-font-dds.py")
    lines.append(f"-- atlas: {atlas_width}x{atlas_height}  cell: {cell}  grid: {cols}x{rows}")
    if uv_inset_px:
        lines.append(f"-- uvInsetPx: {uv_inset_px}")
    lines.append("")
    lines.append(f"local {font_name} = {{")
    lines.append(f"  atlasSize = {{ {atlas_width}, {atlas_height} }},")
    lines.append(f"  cellSize = {cell},")
    lines.append(f"  cols = {cols},")
    lines.append(f"  rows = {rows},")
    lines.append(f"  uvInsetPx = {fmt(float(uv_inset_px))},")
    lines.append("  map = {")

    mapping_sorted = sorted(mapping, key=lambda t: ord(t[0]))
    for ch, col, row in mapping_sorted:
        key = _lua_char_key(ch)

        left = (col * cell) / float(atlas_width) if atlas_width else 0.0
        right = ((col + 1) * cell) / float(atlas_width) if atlas_width else 0.0
        top = (row * cell) / float(atlas_height) if atlas_height else 0.0
        bottom = ((row + 1) * cell) / float(atlas_height) if atlas_height else 0.0

        # apply inset (clamped)
        left = min(max(left + u_inset, 0.0), 1.0)
        right = min(max(right - u_inset, 0.0), 1.0)
        top = min(max(top + v_inset, 0.0), 1.0)
        bottom = min(max(bottom - v_inset, 0.0), 1.0)

        lines.append(
            f"    {key} = {{ {fmt(left)}, {fmt(right)}, {fmt(top)}, {fmt(bottom)} }},"
        )

    lines.append("  },")
    lines.append("}")
    lines.append("")
    lines.append("Lib3DObjects.AddFontAtlas(\"" + font_name + "\", " + font_name + ")")
    lines.append("")

    output_path.write_text("\n".join(lines), encoding="utf-8")


def render_ascii_grid_atlas(
    font_file: Path,
    output_dds: Path,
    cell: int,
    cols: int,
    rows: int,
    start: int,
    padding: int = 6,
    debug: bool = False,
    ink_center: bool = False,
    debug_tiles_dir: Optional[Path] = None,
    meta_lua: Optional[Path] = None,
    meta_lua_var: str = "FONT_ATLAS",
    meta_uv_inset_px: float = 0.0,
) -> None:
    """Render an ASCII atlas by rendering into per-glyph tiles and compositing into the atlas."""

    from wand.color import Color
    from wand.drawing import Drawing
    from wand.image import Image

    if cols <= 0 or rows <= 0:
        raise ValueError("cols and rows must be > 0")
    if cell <= 0:
        raise ValueError("cell must be > 0")
    if padding < 0:
        raise ValueError("padding must be >= 0")

    width = cols * cell
    height = rows * cell

    mapping = []  # list of (char, col, row)

    if debug_tiles_dir is not None:
        debug_tiles_dir.mkdir(parents=True, exist_ok=True)

    with Image(width=width, height=height, background=Color("transparent")) as atlas:
        with Drawing() as m:
            m.font = str(font_file)
            m.text_antialias = True
            m.fill_color = Color("white")

            font_size, baseline = _compute_baseline_params(m, atlas, cell=cell, padding=padding)

        # Draw a faint grid + overlays directly onto the atlas.
        if debug or True:
            with Drawing() as grid:
                grid.stroke_color = Color("rgba(255,255,255,0.12)")
                grid.stroke_width = 1
                grid.stroke_opacity = 1.0
                for c in range(cols + 1):
                    x = c * cell
                    grid.line((x, 0), (x, height))
                for r in range(rows + 1):
                    y = r * cell
                    grid.line((0, y), (width, y))

                if debug:
                    grid.stroke_color = Color("rgba(0,255,0,0.35)")
                    grid.stroke_width = 1
                    for r in range(rows):
                        by = int(round(r * cell + baseline))
                        grid.line((0, by), (width, by))
                    for r in range(rows):
                        for c in range(cols):
                            cx = c * cell + cell / 2.0
                            cy = r * cell + cell / 2.0
                            grid.line(
                                (int(round(cx - 4)), int(round(cy))),
                                (int(round(cx + 4)), int(round(cy))),
                            )
                            grid.line(
                                (int(round(cx)), int(round(cy - 4))),
                                (int(round(cx)), int(round(cy + 4))),
                            )

                grid(atlas)

        max_chars = cols * rows
        for i in range(max_chars):
            codepoint = start + i
            ch = chr(codepoint)

            # For printable ASCII: skip control chars.
            if codepoint < 32:
                continue

            col = i % cols
            row = i // cols

            tile = _render_glyph_tile(
                font_file=font_file,
                ch=ch,
                codepoint=codepoint,
                cell=cell,
                padding=padding,
                ink_center=ink_center,
                baseline=baseline,
                font_size=font_size,
            )

            atlas.composite(tile, left=col * cell, top=row * cell)
            mapping.append((ch, col, row))

            if debug_tiles_dir is not None:
                safe = _safe_char_for_filename(ch, codepoint)
                tile_path = debug_tiles_dir / f"{codepoint:03d}_{safe}.png"
                tile.format = "png"
                tile.save(filename=str(tile_path))

        _ensure_parent_dir(output_dds)
        _dds_options(atlas)
        atlas.format = "dds"
        atlas.save(filename=str(output_dds))

    if meta_lua is not None:
        write_lua_metadata(
            output_path=meta_lua,
            font_name=meta_lua_var,
            atlas_width=width,
            atlas_height=height,
            cell=cell,
            cols=cols,
            rows=rows,
            mapping=mapping,
            uv_inset_px=meta_uv_inset_px,
        )


def _list_font_codepoints(font_file: Path) -> List[int]:
    """Return sorted unique Unicode codepoints supported by the font.

    Uses cmap tables via fontTools.
    """

    from fontTools.ttLib import TTFont

    cps = set()
    font = TTFont(str(font_file), recalcBBoxes=False, recalcTimestamp=False)
    try:
        cmap = font.getBestCmap() or {}
        cps.update(cmap.keys())
    finally:
        font.close()

    # Filter out invalid Unicode range and typical non-characters.
    out = []
    for cp in cps:
        if 0 <= cp <= 0x10FFFF:
            out.append(int(cp))
    out.sort()
    return out


def _choose_grid(num_cells: int, cell: int, max_size: int) -> (int, int):
    """Choose a cols/rows grid for num_cells given cell size and max atlas side."""

    if num_cells <= 0:
        return 0, 0

    max_cols = max(1, max_size // cell)

    import math

    # Start with a near-square layout.
    cols = int(math.ceil(math.sqrt(num_cells)))
    cols = min(cols, max_cols)
    rows = int(math.ceil(num_cells / float(cols)))

    # If that doesn't fit, use the widest possible atlas to reduce rows.
    if cols * cell > max_size or rows * cell > max_size:
        cols = max_cols
        rows = int(math.ceil(num_cells / float(cols)))

    if cols * cell > max_size or rows * cell > max_size:
        required_cols = max_cols
        required_rows = int(math.ceil(num_cells / float(required_cols)))
        raise ValueError(
            "Atlas too small for requested glyph set. "
            f"Need at least {required_cols}x{required_rows} cells "
            f"(={required_cols * cell}x{required_rows * cell}px) for {num_cells} glyphs at {cell}px cells, "
            f"but max-size is {max_size}px."
        )

    return cols, rows


def render_dynamic_atlas(
    *,
    font_file: Path,
    output_dds: Path,
    codepoints: List[int],
    cell: int,
    padding: int,
    debug: bool,
    ink_center: bool,
    debug_tiles_dir: Optional[Path],
    max_size: int,
    meta_lua: Optional[Path] = None,
    meta_lua_var: str = "FONT_ATLAS",
    meta_uv_inset_px: float = 0.0,
) -> None:
    """Render a dynamic atlas containing all given codepoints."""

    from wand.color import Color
    from wand.drawing import Drawing
    from wand.image import Image

    # Filter out control chars and surrogate range for safety.
    filtered = []
    for cp in codepoints:
        if cp < 32:
            continue
        if 0xD800 <= cp <= 0xDFFF:
            continue
        filtered.append(cp)

    cols, rows = _choose_grid(len(filtered), cell=cell, max_size=max_size)

    width = cols * cell
    height = rows * cell

    mapping = []  # list of (char, col, row)

    if debug_tiles_dir is not None:
        debug_tiles_dir.mkdir(parents=True, exist_ok=True)

    with Image(width=width, height=height, background=Color("transparent")) as atlas:
        with Drawing() as m:
            m.font = str(font_file)
            m.text_antialias = True
            m.fill_color = Color("white")
            font_size, baseline = _compute_baseline_params(m, atlas, cell=cell, padding=padding)

        # optional grid
        if debug:
            with Drawing() as grid:
                grid.stroke_color = Color("rgba(255,255,255,0.10)")
                grid.stroke_width = 1
                grid.stroke_opacity = 1.0
                for c in range(cols + 1):
                    x = c * cell
                    grid.line((x, 0), (x, height))
                for r in range(rows + 1):
                    y = r * cell
                    grid.line((0, y), (width, y))

                grid.stroke_color = Color("rgba(0,255,0,0.25)")
                for r in range(rows):
                    by = int(round(r * cell + baseline))
                    grid.line((0, by), (width, by))

                grid(atlas)

        for i, cp in enumerate(filtered):
            try:
                ch = chr(cp)
            except ValueError:
                continue

            col = i % cols
            row = i // cols
            if row >= rows:
                break

            tile = _render_glyph_tile(
                font_file=font_file,
                ch=ch,
                codepoint=cp,
                cell=cell,
                padding=padding,
                ink_center=ink_center,
                baseline=baseline,
                font_size=font_size,
            )

            atlas.composite(tile, left=col * cell, top=row * cell)

            mapping.append((ch, col, row))

            if debug_tiles_dir is not None:
                safe = _safe_char_for_filename(ch, cp)
                tile_path = debug_tiles_dir / f"{cp:06d}_{safe}.png"
                tile.format = "png"
                tile.save(filename=str(tile_path))

        _ensure_parent_dir(output_dds)
        _dds_options(atlas)
        atlas.format = "dds"
        atlas.save(filename=str(output_dds))

    if meta_lua is not None:
        write_lua_metadata(
            output_path=meta_lua,
            font_name=meta_lua_var,
            atlas_width=width,
            atlas_height=height,
            cell=cell,
            cols=cols,
            rows=rows,
            mapping=mapping,
            uv_inset_px=meta_uv_inset_px,
        )


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)

    font_file = Path(args.inputFontFile)
    output_folder = Path(args.outputFolder)

    if not font_file.exists():
        raise FileNotFoundError(f"Font file not found: {font_file}")

    output_folder.mkdir(parents=True, exist_ok=True)

    base_name = font_file.stem
    output_dds = output_folder / f"{base_name}.dds"
    output_lua = output_folder / f"{base_name}.lua"

    meta_lua_var = args.meta_lua_var or base_name

    print("inputFontFile: {}".format(font_file))
    print("outputFolder: {}".format(output_folder))
    print("dds: {}".format(output_dds))
    print("lua: {}".format(output_lua))
    print("luaVar: {}".format(meta_lua_var))

    os.environ.setdefault("MAGICK_CONFIGURE_PATH", "")

    debug_tiles_dir = Path(args.debug_tiles_dir) if args.debug_tiles_dir else None

    if args.mode == "ascii":
        render_ascii_grid_atlas(
            font_file=font_file,
            output_dds=output_dds,
            cell=args.cell,
            cols=args.cols,
            rows=args.rows,
            start=args.start,
            padding=args.padding,
            debug=args.debug,
            ink_center=args.ink_center,
            debug_tiles_dir=debug_tiles_dir,
            meta_lua=output_lua,
            meta_lua_var=meta_lua_var,
            meta_uv_inset_px=args.meta_uv_inset_px,
        )
        return 0

    cps = _list_font_codepoints(font_file)
    render_dynamic_atlas(
        font_file=font_file,
        output_dds=output_dds,
        codepoints=cps,
        cell=args.cell,
        padding=args.padding,
        debug=args.debug,
        ink_center=args.ink_center,
        debug_tiles_dir=debug_tiles_dir,
        max_size=args.max_size,
        meta_lua=output_lua,
        meta_lua_var=meta_lua_var,
        meta_uv_inset_px=args.meta_uv_inset_px,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
