"""DRAFT three-quarter torso for the Berserker (not a redraw, not integrated).

    python3 tools/berserker_torso_3q_draft.py

Method (what it is): the repaired idle torso is wrapped onto a vertical cylinder and
turned by the requested angle, so features move and narrow the way they would on a body
turning away from the viewer (the part of the chest that turns edge-on is compressed, the
part turning to the front is stretched a little). The rigid hardware (belt medallion, chest-strap
buckle) is NOT warped: it is cut out of the idle torso, kept round and moved with the surface.

What it is not: the sides of the torso that turn into view were never drawn, so they are
empty. They are left transparent and listed in the mask, because filling them would be
invention, not reconstruction. A convincing three-quarter torso needs a hand illustration;
this draft shows where the features should land and how large the missing region is.

Outputs (valknut/characters/berserker/layers_repaired/variants/):
  torso_3q_draft_<angle>.png   the draft at 25 and 40 degrees (620x655, same frame as the layer)
  torso_3q_draft_<angle>_missing.png   mask of newly revealed, undrawn pixels
"""
import os
import sys

import cv2
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "valknut/characters/berserker/layers_repaired/torso.png")
OUT = os.path.join(ROOT, "valknut/characters/berserker/layers_repaired/variants")

CENTRE_X = 345.0        # torso axis (belt medallion centre)
RADIUS = 112.0          # half chest width at the shoulders
MEDALLION = ((340.0, 268.0), 38)        # centre, radius (source px)
BUCKLE = ((386.0, 196.0), 26)


def turn(img, deg):
    h, w = img.shape[:2]
    theta = np.radians(deg)
    xs = np.arange(w, dtype=np.float32)
    u = np.clip((xs - CENTRE_X) / RADIUS, -1, 1)
    # output column -> source column: the surface point seen at u is the one at angle asin(u)+theta
    phi = np.arcsin(u) + theta
    src_x = CENTRE_X + RADIUS * np.sin(phi)
    valid = (np.abs(phi) <= np.pi / 2) & (np.abs((xs - CENTRE_X) / RADIUS) <= 1.0)
    # extend sideways (silhouette outline) for columns outside the cylinder
    map_x = np.tile(src_x, (h, 1)).astype(np.float32)
    map_y = np.tile(np.arange(h, dtype=np.float32)[:, None], (1, w))
    out = cv2.remap(img, map_x, map_y, cv2.INTER_CUBIC, borderValue=(0, 0, 0, 0))
    out[:, ~valid] = 0
    # columns whose source lies outside the drawn torso are the never-drawn sides
    return out, valid


def rigid(img, centre, radius, deg):
    """Cut a rigid disc out of the idle torso and return it with its turned centre."""
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    m = ((xx - centre[0]) ** 2 + (yy - centre[1]) ** 2) <= radius ** 2
    u = np.clip((centre[0] - CENTRE_X) / RADIUS, -1, 1)
    new_x = CENTRE_X + RADIUS * np.sin(np.arcsin(u) - np.radians(deg))
    return m, (new_x - centre[0])


def draft(deg):
    img = np.array(Image.open(SRC).convert("RGBA"))
    out, valid = turn(img, deg)
    for centre, radius in (MEDALLION, BUCKLE):
        m, dx = rigid(img, centre, radius, deg)
        # clear the warped (distorted) version of the hardware, then paste the round original
        yy, xx = np.mgrid[0:img.shape[0], 0:img.shape[1]]
        near = ((xx - (centre[0] + dx)) ** 2 + (yy - centre[1]) ** 2) <= radius ** 2
        out[near] = 0
        shifted = np.roll(np.where(m[:, :, None], img, 0), int(round(dx)), axis=1)
        mask = shifted[:, :, 3] > 0
        out[mask] = shifted[mask]
    return out, img


def main():
    os.makedirs(OUT, exist_ok=True)
    for deg in (25, 40):
        out, src = draft(deg)
        Image.fromarray(out).save(os.path.join(OUT, "torso_3q_draft_%d.png" % deg))
        # revealed-but-undrawn: inside the torso's own extent, where the turned body should
        # have pixels but the idle torso has none to give
        h, w = src.shape[:2]
        ys, xs = np.nonzero(src[:, :, 3] > 0)
        extent = np.zeros((h, w), bool)
        for y in range(ys.min(), ys.max() + 1):
            row = np.nonzero(src[y, :, 3] > 0)[0]
            if len(row):
                extent[y, row.min():row.max() + 1] = True
        missing = extent & (out[:, :, 3] == 0)
        Image.fromarray((missing * 255).astype(np.uint8)).save(os.path.join(OUT, "torso_3q_draft_%d_missing.png" % deg))
        print("turn %d deg: %d px of the torso frame are newly revealed and undrawn" % (deg, int(missing.sum())))


if __name__ == "__main__":
    main()
