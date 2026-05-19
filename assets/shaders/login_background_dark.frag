#include <flutter/runtime_effect.glsl>

uniform vec2  u_resolution;
uniform float u_time;

out vec4 fragColor;

// --- Fluted glass parameters (mirrors @paper-design/shaders-react) --
// shape: "lines", distortionShape: "prism", angle: 0
const float GLASS_SIZE       = 0.05;   // stripe grid size
const float GLASS_DISTORTION = 0.5;   // refraction strength per stripe
const float GLASS_SHADOWS    = 0.25;  // dark gradient along distortion
const float GLASS_HIGHLIGHTS = 0.10;  // thin highlights at ridges
const float GLASS_EDGES      = 0.25;  // softening near image edges
const float GLASS_ANGLE      = 0.0;   // 0 = vertical flutes (radians)

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

// The underlying scene (cloudscape) sampled at a given normalized uv.
vec3 sceneColor(vec2 uv) {
	float aspect = u_resolution.x / u_resolution.y;
	vec2 p = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);

	float t = u_time * 0.20;
	vec2 q = p * 1.6 + vec2(t * 0.15, -t * 0.05);
	float n = warpedFbm(q, t);

	vec3 nearBlack  = vec3(0.090, 0.082, 0.072);
	vec3 warmBrown = vec3(0.200, 0.170, 0.140);
	vec3 dustyRose = vec3(0.55, 0.38, 0.36);
	vec3 ember     = vec3(0.92, 0.55, 0.32);
	vec3 hot       = vec3(1.00, 0.78, 0.55);

	vec3 base = mix(nearBlack, warmBrown, smoothstep(0.0, 0.55, uv.y));
	base = mix(base, dustyRose, smoothstep(0.35, 0.85, uv.y) * 0.55);

	float cloud = smoothstep(0.35, 0.75, n);
	float band  = smoothstep(0.15, 0.55, uv.y) * smoothstep(0.95, 0.45, uv.y);
	float glow  = cloud * band;

	vec3 color = base;
	color = mix(color, ember, glow * 0.85);
	color = mix(color, hot, pow(glow, 3.0) * 0.65);

	float wisp = smoothstep(0.45, 0.15, n) * smoothstep(0.55, 0.0, uv.y);
	color = mix(color, nearBlack * 0.7, wisp * 0.35);

	return color;
}

void main() {
	vec2 uv = FlutterFragCoord().xy / u_resolution.xy;

	// Rotate sampling axis so the flutes can be angled.
	float c = cos(GLASS_ANGLE);
	float s = sin(GLASS_ANGLE);
	vec2 centered = uv - 0.5;
	vec2 rotated  = vec2(c * centered.x + s * centered.y,
	                     -s * centered.x + c * centered.y) + 0.5;

	// Each stripe is one flute. Position within the stripe is in [-0.5, 0.5].
	float stripeWidth = mix(0.004, 0.05, GLASS_SIZE);
	float stripePos   = rotated.x / stripeWidth;
	float local       = fract(stripePos) - 0.5;

	// "Prism" distortion: linear refraction across the stripe width.
	float shift = local * GLASS_DISTORTION * stripeWidth * 6.0;
	vec2  shiftDir = vec2(c, -s); // back to world space
	vec2  distortedUv = uv + shiftDir * shift;

	// Soften toward the canvas edges so the glass blends out.
	float edgeMask = smoothstep(0.0, GLASS_EDGES,
		min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
	distortedUv = mix(uv, distortedUv, edgeMask);

	vec3 color = sceneColor(distortedUv);

	// Shadow gradient along the prism shape — darker toward ridge edges.
	float shadowMask = abs(local) * 2.0;
	color *= 1.0 - shadowMask * shadowMask * GLASS_SHADOWS;

	// Highlight strokes — thin bright lines at each ridge.
	float ridge = smoothstep(0.42, 0.50, abs(local));
	color += vec3(ridge * GLASS_HIGHLIGHTS);

	// Cinematic vignette + film grain.
	vec2 vp = uv - 0.5;
	vp.x *= u_resolution.x / u_resolution.y;
	float vignette = smoothstep(1.0, 0.35, length(vp));
	color *= mix(0.75, 1.0, vignette);

	float grain = (hash(FlutterFragCoord().xy + u_time) - 0.5) * 0.025;
	color += grain;

	fragColor = vec4(color, 1.0);
}
