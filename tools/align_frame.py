"""Shift a frame on its canvas (whole pixels, transparent fill) without touching the art.

    python3 tools/align_frame.py <in.png> <out.png> <dx> <dy>

Used to put a supplied drawing's feet on the art set's anchor when the drawing was
placed off it. The originals stay in valknut/art/source/<set>_supplied/.
"""
import sys
from PIL import Image

src, dst, dx, dy = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
im = Image.open(src).convert("RGBA")
out = Image.new("RGBA", im.size, (0, 0, 0, 0))
out.alpha_composite(im, (max(dx, 0), max(dy, 0)), (max(-dx, 0), max(-dy, 0)))
out.save(dst)
