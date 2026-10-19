"""Generates the art request for the combo/heavy pose slots.

  python3 tools/make_art_requests.py

Writes docs/art_requests/<legend>_template.png (empty, correctly sized cells with the
feet baseline, anchor and an idle-pose ghost for scale, one row per attack) and
docs/art_requests/<legend>.md (per-slot brief + how long each pose is on screen, parsed
from <legend>_anims.gd so it can't drift from the game).
"""
import os, re
from PIL import Image, ImageDraw
from pose_slots import SLOTS

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
CHARS = os.path.join(ROOT, "valknut", "characters")
OUT = os.path.join(ROOT, "docs", "art_requests")
MOVES = {"jab1": "Combo hit 1", "jab2": "Combo hit 2", "jab3": "Combo hit 3 (finisher)", "fsmash": "Heavy attack"}
NAMES = {"valkyrie": {"jab1": "Spear Slash", "jab2": "Shield Bash", "jab3": "Spear Finisher", "fsmash": "Heavy Spear"},
         "berserker": {"jab1": "Right Axe Swing", "jab2": "Left Axe Swing", "jab3": "Double-Axe Overhead", "fsmash": "Heavy Axe"}}


def timings(legend):
    """move -> (total_frames, [(slot, from_frame, to_frame)]) from the anims file."""
    src = open(os.path.join(CHARS, legend, "%s_anims.gd" % legend)).read()
    out = {}
    for move in MOVES:
        m = re.search(r'b\.add\("%s", (\d+),.*?FRAME: \[(.*?)\]\],' % move, src, re.S)
        total = int(m.group(1))
        keys = re.findall(r'\[(\d+), (?:&"(\w+)"|(\w+))\]', m.group(2) + "]")
        base = {"RECOVERY": "attack_recovery", "STARTUP": "attack_startup", "ACTIVE": "attack_active", "IDLE": "idle"}
        seq = [(int(f), a or base.get(b, b.lower())) for f, a, b in keys]
        spans = [(name, f, (seq[i + 1][0] if i + 1 < len(seq) else total) - 1) for i, (f, name) in enumerate(seq)]
        out[move] = (total, spans)
    return out


def template(legend, t):
    idle = Image.open(os.path.join(CHARS, legend, "frames", "%s_idle.png" % legend)).convert("RGBA")
    ghost = idle.copy()
    ghost.putalpha(ghost.getchannel("A").point(lambda a: a * 0.22))
    rows = [[s for s, _f, _t in t[mv][1] if s in SLOTS[legend]] for mv in MOVES]
    pad, head, label = 10, 34, 40
    width = max(sum((256 if SLOTS[legend][s][1] else 128) + pad for s in r) for r in rows) + 170
    height = head + len(rows) * (128 + label + pad)
    img = Image.new("RGBA", (width, height), (24, 24, 30, 255))
    d = ImageDraw.Draw(img)
    d.text((10, 8), "%s - combo & heavy art request. Save each cell as frames/%s_<slot>.png: transparent, facing right, "
           "feet on the magenta line at the yellow cross, same scale/style as the ghosted idle." % (legend.capitalize(), legend),
           fill=(255, 255, 255))
    y = head
    for mv, r in zip(MOVES, rows):
        d.text((10, y + 50), "%s\n%s\n%d frames" % (MOVES[mv], NAMES[legend][mv], t[mv][0]), fill=(255, 220, 120))
        x = 170
        for s in r:
            w = 256 if SLOTS[legend][s][1] else 128
            cell = Image.new("RGBA", (w, 128), (52, 58, 70, 255))
            cell.alpha_composite(ghost, ((w - 128) // 2, 0))
            cd = ImageDraw.Draw(cell)
            cd.line((0, 124, w, 124), fill=(255, 0, 255))
            cx = w // 2
            cd.line((cx - 5, 124, cx + 5, 124), fill=(255, 255, 0))
            cd.line((cx, 119, cx, 129), fill=(255, 255, 0))
            img.alpha_composite(cell, (x, y))
            d.rectangle((x - 1, y - 1, x + w, y + 128), outline=(130, 130, 150))
            span = next((a, b) for n, a, b in t[mv][1] if n == s)
            d.text((x, y + 131), s, fill=(255, 255, 255))
            d.text((x, y + 144), "%dx128 · frames %d-%d" % (w, span[0], span[1]), fill=(170, 170, 190))
            x += w + pad
        y += 128 + label + pad
    img.save(os.path.join(OUT, "%s_template.png" % legend))


def markdown(legend, t):
    L = ["# %s — combo & heavy pose art request" % legend.capitalize(), "",
         "Template: `%s_template.png` (cells are the exact canvas sizes; magenta line = floor, "
         "yellow cross = feet anchor, ghost = current idle for scale)." % legend, "",
         "Deliver each pose as `valknut/characters/%s/frames/%s_<slot>.png`, then run "
         "`python3 tools/build_sprite_frames.py`. No code changes are needed." % (legend, legend), "",
         "Style: match the existing frames exactly — same pixel density, outline weight, palette, "
         "proportions and lighting; facing right; transparent background.", ""]
    for mv in MOVES:
        total, spans = t[mv]
        L += ["## %s — %s (%d frames at 60 fps)" % (MOVES[mv], NAMES[legend][mv], total), "",
              "| Slot | Canvas | On screen | What it must show |", "|---|---|---|---|"]
        for name, a, b in spans:
            if name in SLOTS[legend]:
                fb, wide, brief = SLOTS[legend][name]
                L.append("| `%s` | %s | frames %d–%d | %s |" % (name, "256×128" if wide else "128×128", a, b, brief))
            else:
                L.append("| `%s` (existing) | — | frames %d–%d | Return to stance (already drawn). |" % (name, a, b))
        L.append("")
    open(os.path.join(OUT, "%s.md" % legend), "w").write("\n".join(L))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for legend in SLOTS:
        t = timings(legend)
        template(legend, t)
        markdown(legend, t)
        print(legend, {mv: [s for s, _a, _b in t[mv][1]] for mv in MOVES})
