#include <flutter/runtime_effect.glsl>

uniform vec2  u_resolution;
uniform float u_time;

out vec4 fragColor;

// --- Hash / noise ---------------------------------------------------
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = 0.8 * p * 2.0 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

float warpedFbm(vec2 p, float t) {
	vec2 q = vec2(
		fbm(p + vec2(0.0, 0.0) + t * 0.05),
		fbm(p + vec2(5.2, 1.3) - t * 0.04)
	);
	vec2 r = vec2(
		fbm(p + 4.0 * q + vec2(1.7, 9.2) + t * 0.03),
		fbm(p + 4.0 * q + vec2(8.3, 2.8) - t * 0.02)
	);
	return fbm(p + 4.0 * r);
}

// Warm golden-hour cloudscape — the near-white canvas warms through the
// sunshine scale to a signal-orange ember core low on the canvas. Clouds read
// through sunlit tops and warm taupe-rose bellies (the day counterpart of the
// dark scene's ember glow + near-black wisp), never a flat cream wash.
vec3 sceneColor(vec2 uv) {
	float aspect = u_resolution.x / u_resolution.y;
	vec2 p = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);

	float t = u_time * 0.20;
	vec2 q = p * 1.6 + vec2(t * 0.15, -t * 0.05);
	float n = warpedFbm(q, t);

	vec3 canvasWhite  = vec3(0.988, 0.984, 0.976);
	vec3 hazeGold     = vec3(1.000, 0.898, 0.663);
	vec3 sunGold      = vec3(1.000, 0.816, 0.416);
	vec3 horizonAmber = vec3(1.000, 0.722, 0.243);
	vec3 emberCore    = vec3(0.980, 0.322, 0.059);
	vec3 sunlitWisp   = vec3(1.000, 0.976, 0.918);

	vec3 base = mix(canvasWhite, hazeGold, smoothstep(0.05, 0.60, uv.y));
	base = mix(base, sunGold, smoothstep(0.45, 0.92, uv.y));
	base = mix(base, horizonAmber, smoothstep(0.68, 1.02, uv.y) * 0.75);
	base = mix(base, emberCore, smoothstep(0.90, 1.14, uv.y) * 0.32);

	float cloud = smoothstep(0.35, 0.75, n);
	float band  = smoothstep(0.15, 0.55, uv.y) * smoothstep(0.95, 0.45, uv.y);
	float glow  = cloud * band;

	vec3 color = base;
	color = mix(color, sunlitWisp, glow * 0.50);
	color = mix(color, sunlitWisp, pow(glow, 3.0) * 0.40);

	float wisp = smoothstep(0.45, 0.15, n) * smoothstep(0.85, 0.05, uv.y);
	vec3 cloudShade = vec3(0.792, 0.616, 0.537);
	color = mix(color, cloudShade, wisp * 0.45);

	return color;
}

void main() {
	vec2 uv = FlutterFragCoord().xy / u_resolution.xy;

	vec3 color = sceneColor(uv);

	// Gentle vignette — a touch deeper so the corners hold the gold.
	vec2 vp = uv - 0.5;
	vp.x *= u_resolution.x / u_resolution.y;
	float vignette = smoothstep(1.0, 0.35, length(vp));
	color *= mix(0.92, 1.0, vignette);

	// Subtle grain so the light field doesn't look plasticky.
	float grain = (hash(FlutterFragCoord().xy + u_time) - 0.5) * 0.012;
	color += grain;

	fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
