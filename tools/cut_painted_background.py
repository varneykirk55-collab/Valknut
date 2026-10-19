"""Remove a smooth painted backdrop (gradients, glows) from an outlined character.

    python3 tools/cut_painted_background.py <in.png> <out.png>

Needs opencv-python. The backdrop has no hard edges and the character has a continuous
dark outline, so: edges (Canny) become walls, everything reachable from the image border
without crossing a wall is background, and the largest remaining region is the
character. Colours are untouched (a glow behind the hair or a halo around the axes is
cut off at the outline instead of being keyed by colour). Check the result for holes
or gaps in the outline before use.
"""
import sys
import cv2
import numpy as np

img = cv2.imread(sys.argv[1])
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
walls = cv2.dilate(cv2.Canny(cv2.GaussianBlur(gray, (3, 3), 0), 40, 100), np.ones((3, 3), np.uint8))
_, lab = cv2.connectedComponents((walls == 0).astype(np.uint8), connectivity=4)
border = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
fg = (~np.isin(lab, border[border > 0])).astype(np.uint8)
_, lab2, stats, _ = cv2.connectedComponentsWithStats(fg)
keep = 1 + np.argmax(stats[1:, cv2.CC_STAT_AREA])
rgba = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
rgba[:, :, 3] = np.where(lab2 == keep, 255, 0).astype(np.uint8)
cv2.imwrite(sys.argv[2], rgba)
