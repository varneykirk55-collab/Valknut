shader_type canvas_item;
// Alternate costume for sprite legends: rotates the hue of one colour family
// (by default the crimson/red cloth) and leaves skin, gold, steel and hair alone.

uniform float hue_shift = 0.0;     // turns (0..1) added to matching hues
uniform float hue_center = 0.985;  // hue to recolour (0.985 ≈ crimson)
uniform float hue_width = 0.055;   // how far from hue_center still counts
uniform float min_saturation = 0.45;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	// COLOR already holds texture × modulate here, so recolour it in place.
	vec3 hsv = rgb2hsv(COLOR.rgb);
	float dist = abs(fract(hsv.x - hue_center + 0.5) - 0.5);
	float weight = (1.0 - smoothstep(hue_width * 0.6, hue_width, dist))
		* smoothstep(min_saturation - 0.1, min_saturation, hsv.y);
	// Blend toward the fully shifted colour rather than partially rotating the hue,
	// which would sweep edge pixels through unrelated hues (orange → yellow → green).
	vec3 shifted = hsv2rgb(vec3(fract(hsv.x + hue_shift), hsv.y, hsv.z));
	COLOR.rgb = mix(COLOR.rgb, shifted, weight);
}
