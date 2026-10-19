extends FighterState
## Free fall after a recovery special. Can drift and grab ledges, nothing else.

var landing_lag := 18


func enter(data: Dictionary) -> void:
	landing_lag = data.get("landing_lag", 18)
	f.play_anim("helpless", true)


func tick() -> void:
	if f.try_ledge_grab():
		return
	f.apply_gravity()
	f.air_drift(0.6)
	f.move_body()
	if f.is_on_floor():
		f.land(landing_lag)
