# Jotunheim (planned)
Vertical ice cliffs, multiple ledges, wind that gently pushes airborne fighters.
- Extend `Stage`, override `get_wind(at)` (e.g. a slow sine-wave gust, stronger higher up). `Fighter.move_body()` already applies it to airborne fighters.
- Add one `Ledge` per cliff corner; walls of the cliffs are where wall teching matters.
- Flip `available` in `data/roster.gd`.
