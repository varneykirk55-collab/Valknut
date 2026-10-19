class_name CombatResolver
extends RefCounted
## Runs once per tick after every fighter has moved. Gathers all hitbox/hurtbox overlaps
## first and applies them afterwards, so two attacks connecting on the same frame trade
## instead of whoever happened to update first winning.

signal hit_landed(attacker: Fighter, target: Fighter, data: HitboxData, point: Vector2)


func resolve(fighters: Array[Fighter]) -> void:
	var hits: Array[Dictionary] = []
	for attacker in fighters:
		var boxes := attacker.get_active_hitboxes()
		if boxes.is_empty():
			continue
		for target in fighters:
			if target == attacker or not target.can_be_hit():
				continue
			var hurt := target.hurtbox.world_rect()
			# First listed hitbox wins when several overlap, so moves list sweetspots first.
			for hb in boxes:
				if not attacker.can_hit_with(target, hb.data):
					continue
				var r := hb.world_rect()
				if r.intersects(hurt):
					var contact := r.intersection(hurt)
					hits.append({"attacker": attacker, "target": target, "data": hb.data,
						"point": contact.get_center()})
					break

	var victims := {}
	for h in hits:
		victims[h.target] = true
	for h in hits:
		var attacker: Fighter = h.attacker
		attacker.register_hit(h.target, h.data)
		h.target.receive_hit(attacker, h.data, attacker.charge_mult)
		hit_landed.emit(attacker, h.target, h.data, h.point)
	for h in hits:
		# An attacker that got hit on this same frame stays in hitstun (a trade).
		if not victims.has(h.attacker):
			h.attacker.on_hit_landed(h.target, h.data)
