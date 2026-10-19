"""Sprite pose slots for each legend: the single source of truth for which drawings the
game uses, what each one must show (the art brief), and which existing frame stands in
until it's drawn.

Base poses come from the sheets in valknut/art/source (cut by cut_frames.py). Combo and
heavy-attack slots need NEW drawings: drop <legend>_<slot>.png into
valknut/characters/<legend>/frames/ and re-run build_sprite_frames.py; nothing else
changes. Until then the slot uses `fallback` and is listed as a placeholder.

Canvas: 128x128 (256x128 where wide=True), transparent, facing right, feet anchored at
(64,124) on the 128 canvas / (128,124) on the 256 canvas, same scale and style as
<legend>_idle.png.
"""

BASE = ["idle", "walk_01", "walk_02", "walk_03", "walk_04", "jump", "fall", "hurt",
        "attack_startup", "attack_active", "attack_recovery"]

# slot: (fallback, wide, brief)
SLOTS = {
    "valkyrie": {
        # Hit 1 — Spear Slash (frames 1-18, hit 3-4)
        "slash_anticipation": ("attack_startup", False,
            "Spear drawn back across the body to her LEFT (rear) hip, spearhead low behind her; "
            "shoulders turned away from the target, shield tucked to the chest, knees bent, weight on the back foot."),
        "slash_smear": ("attack_active", True,
            "Mid-swing: torso and shoulders rotating toward the target, spear sweeping horizontally at chest "
            "height. Spearhead drawn as a smear (stretched arc), front foot planting."),
        "slash_contact": ("attack_active", True,
            "Swing completed IN FRONT at chest height: the shaft lies horizontally ACROSS her body with the "
            "spearhead out in front (swung across, not pushed straight out like a thrust); arms crossed slightly "
            "in front, shoulders square to the target."),
        "slash_follow": ("attack_recovery", False,
            "Follow-through: spear continues past the body to the front-right/down, torso over-rotated, "
            "shield arm swinging back for balance — this flows straight into the bash anticipation."),
        # Hit 2 — Shield Bash (frames 1-20, hit 4-5)
        "bash_anticipation": ("attack_startup", False,
            "Shield pulled back and slightly up, elbow cocked, spear held back along the body; "
            "torso leaning back, weight shifting to the rear foot."),
        "bash_contact": ("walk_02", False,
            "Shield punched FORWARD at full arm extension, face of the shield toward the target, torso and "
            "front knee driving forward, rear leg extended (clear weight transfer). Spear trails behind."),
        "bash_follow": ("attack_recovery", False,
            "Shield still forward but relaxing, small recoil; spear brought back to both hands for the finisher."),
        # Hit 3 — Spear Finisher (frames 1-34, hit 7-9)
        "finisher_windup": ("attack_startup", False,
            "Two-handed grip, spear raised high over the REAR shoulder, torso coiled away from the target, "
            "deep stance. Clearly bigger wind-up than the slash."),
        "finisher_smear": ("attack_active", True,
            "Fast two-handed horizontal sweep from rear-high to front, spear as a smear arc, body uncoiling, "
            "front foot stamping forward."),
        "finisher_contact": ("attack_active", True,
            "Sweep at full extension in front, both hands on the shaft, spear horizontal at hip-to-chest height, "
            "body fully rotated, cape flaring."),
        "finisher_follow": ("attack_recovery", False,
            "Spear carried through to the far side and low, torso over-rotated; sets up the return to idle."),
        # Heavy (forward smash, charge holds on heavy_charge)
        "heavy_windup": ("attack_startup", False,
            "Distinct heavy stance: low wide crouch, spear pulled far back with both hands at the rear hip, "
            "spearhead behind her, shield braced, wings slightly raised."),
        "heavy_charge": ("attack_startup", False,
            "Same stance coiled tighter (shown while the button is held). A subtle difference from windup "
            "(deeper knee bend, spear further back) so charging reads."),
        "heavy_smear": ("attack_active", True,
            "Explosive lunge: whole body launching forward, spear driven straight ahead as a long smear, "
            "rear leg fully extended."),
        "heavy_contact": ("attack_active", True,
            "Full forward extension: deepest lunge of the kit, spear at maximum reach, front knee far forward, "
            "wings swept back. Must not reuse the basic thrust drawing."),
        "heavy_recovery": ("attack_recovery", False,
            "Overextended recovery: weight still forward, spear tip dipping, starting to pull back to stance."),
    },
    "berserker": {
        # Hit 1 — Right Axe (frames 1-20, hit 4-5)
        "right_anticipation": ("attack_startup", False,
            "RIGHT (front) axe raised high above and behind the right shoulder, torso twisted away, "
            "left axe low and back, knees bent."),
        "right_smear": ("attack_active", True,
            "Right axe mid-swing on a DIAGONAL path from high-back to low-front, drawn as a curved smear; "
            "shoulders twisting toward the target."),
        "right_contact": ("attack_active", True,
            "Right axe at the bottom-front of the diagonal (around the opponent's waist), arm extended, "
            "body twisted toward the target, weight on the front foot."),
        "right_follow": ("attack_recovery", False,
            "Right axe carried through low and across the body; the LEFT axe is already cocking up behind "
            "the head (the momentum hand-off into hit 2). Not an idle-like pose."),
        # Hit 2 — Left Axe (frames 1-22, hit 5-6)
        "left_anticipation": ("attack_recovery", False,
            "LEFT (rear) axe fully cocked behind the head, torso twisted the other way from hit 1, "
            "right axe down and back for counter-balance."),
        "left_smear": ("attack_active", True,
            "Left axe swinging on the OPPOSITE diagonal (high-rear to front, crossing in front of the chest), "
            "curved smear, hips turning."),
        "left_contact": ("attack_active", True,
            "Left axe at the end of its arc in front of the chest, body square to the target, step forward."),
        "left_follow": ("attack_recovery", False,
            "Left axe carried across and down; both arms already starting to rise for the overhead."),
        # Hit 3 — Double-Axe Overhead (frames 1-46, hit 8-10)
        "overhead_windup": ("jump", False,
            "BOTH axes raised high above the head, arms fully extended up and slightly back, back arched, "
            "rising onto the toes / small hop — exaggerated anticipation."),
        "overhead_smear": ("attack_active", True,
            "Both axes chopping down in front on a vertical arc, smear trails from overhead to the ground."),
        "overhead_contact": ("attack_active", True,
            "Both axe heads buried at ground level in front of him, deep crouch, shoulders over the knees, "
            "debris / impact at the axe heads."),
        "overhead_impact": ("attack_recovery", False,
            "Recoil: axes bouncing up off the ground, body shaken back slightly, heavy breath. Held through "
            "the long recovery before returning to idle."),
        # Heavy (forward smash, charge holds on heavy_charge)
        "heavy_windup": ("attack_startup", False,
            "Deep wind-up unique to the heavy: both axes drawn far back to the side at hip height, body "
            "twisted almost 90 degrees away, back foot planted, mantle swinging."),
        "heavy_charge": ("attack_startup", False,
            "Same wind-up wound tighter (shown while charging): more twist, lower crouch, veins / war-paint glow."),
        "heavy_smear": ("attack_active", True,
            "Full-body double-axe horizontal sweep, huge curved smear in front, mantle flying."),
        "heavy_contact": ("attack_active", True,
            "Sweep completed in front, both arms extended, entire body rotated through, front foot stamped. "
            "Not an enlarged light swing."),
        "heavy_recovery": ("attack_recovery", False,
            "Overcommitted: body still twisted past the target, axes low, staggering back to stance."),
    },
}
