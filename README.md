# Valknut

A Norse-themed 2D platform fighter for **Godot 4.3+** (tested on 4.3 and 4.7.2; GL Compatibility renderer). Smash-style
percent knockback, DI, teching, ledges, blast zones, best-of-3 rounds with sudden death.

**Current build:** Valkyrie and Berserker playable · Midgard Arena · local 1v1 (shared
keyboard, keyboard + pad, or two pads) · Training mode with a dummy. Art is code-drawn
placeholder shapes, animated with `AnimationPlayer`.

## Run it
Open the folder in Godot 4.3 or newer (4.7.2 works), press **F5** (main scene: `res://valknut/main.tscn`).

## Controls
|            | P1 keyboard | P2 keyboard | Gamepad |
|------------|-------------|-------------|---------|
| Move       | WASD        | Arrows      | Left stick / D-pad |
| Jump       | Space       | Numpad 0    | A / Y |
| Attack     | J           | Numpad 1    | X |
| Special    | K           | Numpad 2    | B |
| Strong     | L           | Numpad 3    | LB / LT / right stick (aimed) |
| Dodge      | Shift / ;   | Numpad . / Enter | RB / RT |
| Pause      | Esc         | Backspace   | Start |

One pad connected → it goes to P2 (keyboard vs controller); two pads → one each. Change it in
the Versus setup screen. Bindings live in `valknut/autoload/input_setup.gd`.

- **Attacks:** Attack + direction = neutral / side / down. **Smash** = flick the direction *with* Attack,
  or use Strong. Hold to charge (up to 1 s, ×1.4 damage). Side air turns you to face the direction.
- **Specials (Valkyrie):** neutral/up = *Wings of Valhalla* (rise, hold Special to hover, ends helpless) ·
  side = *Shield Charge* · down = *Spear Dive* (signature; spikes, bounces off on hit).
- **Specials (Berserker):** neutral/up = *Skull Leap* (short hop, weak recovery, ends helpless) ·
  side = *Cleaving Lunge* · down = *Rage Spin* (signature; multi-hit + launcher, long punishable endlag).
  Full move list: `valknut/characters/berserker/README.md`.
- **Movement:** double-tap to dash → run · tap down in the air to fast-fall · tap down on a platform to drop.
- **Defense:** Dodge on the ground = spot dodge / roll; in the air = air dodge (directional, once per airtime,
  wavelands on landing). **Tech:** press Dodge just before you hit the ground or a wall while tumbling.
- **DI:** hold a direction while getting hit — rotates your launch up to 18°.
- **Debug:** F1 hitboxes/hurtboxes/blast zone · F11 fullscreen · Training: F3/F4 dummy %, F5 reset, F6 dummy DI.

## Combat model (where to tune)
| What | Where |
|------|-------|
| Knockback formula, % ramp, hitstun, hitlag, DI, combo decay | `valknut/core/combat/knockback.gd` |
| Frame data | `valknut/characters/<legend>/<legend>_moves.gd` |
| Movement stats | `_make_stats()` in `valkyrie.gd` / `berserker.gd` |
| Buffer (7 f), flick window, double-tap | `valknut/core/input/player_input.gd` |
| Tech window/lockout, ledge timings | constants at the top of `fighter.gd` / state files |

- Knockback is Smash's formula (`((p/10 + p·d/20)·200/(w+100)·1.4 + 18)·g/100 + b`) using the percent
  *after* the hit, plus a ramp past 100% so kills come online sharply. Uncharged forward smash KOs
  around 100–110% near center; forward air off-stage around 130%.
- Hits apply on the same tick for both fighters (trades work); attacker and victim share hitlag; DI is
  read on the last hitlag frame; the input buffer pauses during hitlag.
- Combo decay: from the 4th consecutive true hit, hitstun shrinks (×0.8, ×0.6, ×0.45), so nothing loops.
  Multi-hit moves mark their early hits `as_link()` (they don't advance decay) and put the finisher
  in its own hitbox `group` so it can connect after them.
- Weight matters: the same Valkyrie forward smash KOs the Valkyrie at ~80% but the Berserker at ~100%;
  the Berserker's forward smash KOs the Valkyrie at ~65%.

## Layout
```
valknut/
  main.tscn / main.gd        screen router (title → setup → match)
  autoload/                  InputSetup (bindings), Game (settings, F1/F11), Sfx (synthesized placeholder sounds)
  data/                      Roster (legends + stages, availability), Palette
  core/combat/               Knockback math, MoveData/HitboxData, Hitbox/Hurtbox areas, CombatResolver
  core/input/                PlayerInput (buffer, flicks, double-taps, c-stick)
  core/fighter/              Fighter base class, FighterStats, state machine, states/ (20 states)
  core/visual/               ShapePart (outlined placeholder shapes), AnimBuilder (frame-keyed animations)
  characters/valkyrie/       scene (rig), stats + specials, frame data, animations
  characters/berserker/      same structure: heavy, twin hand axes
  characters/<others>/       design notes for the next four legends
  stages/                    Stage base, Ledge; midgard_arena/ (playable), jotunheim/ (notes)
  match/                     match flow (rounds, timer, sudden death, training), camera, HUD, effects, pause
  ui/                        title, versus setup, controls screens, MenuList widget
  tests/                     headless gameplay tests + screenshot tool
```

### Adding a legend
1. Copy `characters/valkyrie/` and rename. Subclass `Fighter`: set stats, return moves from
   `build_moves()` and animations from `build_animations()`, override `get_special()` if needed.
2. Specials with custom motion use `MoveData.on_frame` / `on_hit` callbacks (see Valkyrie's three).
3. Flip `available` in `data/roster.gd`.

## Tests
```
godot --headless --path . --fixed-fps 60 res://valknut/tests/sim_test.tscn         # mechanics (37 checks)
godot --headless --path . --fixed-fps 60 res://valknut/tests/round_flow_test.tscn  # rounds, sudden death, menus
godot --headless --path . --fixed-fps 60 res://valknut/tests/berserker_test.tscn   # Berserker vs Valkyrie comparisons
godot --path . --fixed-fps 60 res://valknut/tests/screenshot.tscn -- /tmp/shots --poses --legend=berserker  # hitbox pose sheet
```
They drive real input actions through a live match. Both exit non-zero on failure.

## Exporting
Project settings are export-ready (main scene set, GL Compatibility, nearest filtering, 1280×720
canvas-items stretch). Install export templates, then *Project → Export → Add preset*.
