// Generates the Open Graph / Twitter social card at public/og.png (1200×630).
// The background is a CPU port of the ember cloudscape fragment shader
// (assets/shaders/dashboard_background_dark.frag, mirrored as the dark scene in
// src/components/shared/ShaderBackground.astro), rendered at the frozen frame
// (u_time = 0) — the same single frame the app shows under reduced-motion. The
// dark scene reads as a brand moment on a social card where the light one washes
// out. The brand lockup + headline are composited over it via sharp.
// Re-run after changing the headline/palette/scene:  node scripts/gen-og.mjs
// (sceneColorLight is kept for reference / a future light variant.)
import sharpFn from "sharp";
import { readFileSync } from "node:fs";

const W = 1200;
const H = 630;

/* ── Shader maths (ported verbatim from the .frag) ────────────────────── */
const fract = (x) => x - Math.floor(x);
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const mix = (a, b, t) => a + (b - a) * t;
const mix3 = (a, b, t) => [mix(a[0], b[0], t), mix(a[1], b[1], t), mix(a[2], b[2], t)];
function smoothstep(e0, e1, x) {
  const t = clamp((x - e0) / (e1 - e0), 0, 1);
  return t * t * (3 - 2 * t);
}
function hash(x, y) {
  let px = fract(x * 123.34);
  let py = fract(y * 456.21);
  const d = px * (px + 45.32) + py * (py + 45.32);
  px += d;
  py += d;
  return fract(px * py);
}
function noise(x, y) {
  const ix = Math.floor(x), iy = Math.floor(y);
  const fx = x - ix, fy = y - iy;
  const ux = fx * fx * (3 - 2 * fx);
  const uy = fy * fy * (3 - 2 * fy);
  const a = hash(ix, iy);
  const b = hash(ix + 1, iy);
  const c = hash(ix, iy + 1);
  const d = hash(ix + 1, iy + 1);
  return mix(mix(a, b, ux), mix(c, d, ux), uy);
}
function fbm(x, y) {
  let v = 0, a = 0.5, px = x, py = y;
  for (let i = 0; i < 4; i++) {
    v += a * noise(px, py);
    px = 1.6 * px + 1.7; // 0.8 * p * 2.0 + (1.7, 9.2)
    py = 1.6 * py + 9.2;
    a *= 0.5;
  }
  return v;
}
function warpedFbm(x, y) {
  // t = 0 → the time terms drop out.
  const qx = fbm(x, y);
  const qy = fbm(x + 5.2, y + 1.3);
  const rx = fbm(x + 4 * qx + 1.7, y + 4 * qy + 9.2);
  const ry = fbm(x + 4 * qx + 8.3, y + 4 * qy + 2.8);
  return fbm(x + 4 * rx, y + 4 * ry);
}
function sceneColorLight(ux, uy) {
  const aspect = W / H;
  const px = (ux - 0.5) * aspect;
  const py = uy - 0.5;
  const n = warpedFbm(px * 1.6, py * 1.6);

  const nearWhite = [0.988, 0.984, 0.976];
  const warmCream = [0.972, 0.93, 0.86];
  const lightGold = [0.965, 0.855, 0.64];
  const goldAmber = [0.98, 0.72, 0.38];
  const brightWisp = [1.0, 0.992, 0.96];

  let color = mix3(nearWhite, warmCream, smoothstep(0.0, 0.55, uy));
  color = mix3(color, lightGold, smoothstep(0.4, 0.95, uy));
  color = mix3(color, goldAmber, smoothstep(0.7, 1.05, uy) * 0.6);

  const cloud = smoothstep(0.35, 0.75, n);
  const band = smoothstep(0.15, 0.55, uy) * smoothstep(0.95, 0.45, uy);
  const glow = cloud * band;

  color = mix3(color, brightWisp, glow * 0.55);
  color = mix3(color, brightWisp, Math.pow(glow, 3) * 0.45);

  const wisp = smoothstep(0.45, 0.15, n) * smoothstep(0.55, 0.0, uy);
  color = mix3(color, [0.86, 0.78, 0.64], wisp * 0.3);
  return color;
}
function sceneColorDark(ux, uy) {
  const aspect = W / H;
  const px = (ux - 0.5) * aspect;
  const py = uy - 0.5;
  const n = warpedFbm(px * 1.6, py * 1.6);

  const nearBlack = [0.09, 0.082, 0.072];
  const warmBrown = [0.2, 0.17, 0.14];
  const dustyRose = [0.55, 0.38, 0.36];
  const ember = [0.92, 0.55, 0.32];
  const hot = [1.0, 0.78, 0.55];

  let color = mix3(nearBlack, warmBrown, smoothstep(0.0, 0.55, uy));
  color = mix3(color, dustyRose, smoothstep(0.35, 0.85, uy) * 0.55);

  const cloud = smoothstep(0.35, 0.75, n);
  const band = smoothstep(0.15, 0.55, uy) * smoothstep(0.95, 0.45, uy);
  const glow = cloud * band;

  color = mix3(color, ember, glow * 0.85);
  color = mix3(color, hot, Math.pow(glow, 3) * 0.65);

  const wisp = smoothstep(0.45, 0.15, n) * smoothstep(0.55, 0.0, uy);
  color = mix3(color, [nearBlack[0] * 0.7, nearBlack[1] * 0.7, nearBlack[2] * 0.7], wisp * 0.35);
  return color;
}

/* ── Render the cloudscape to a raw RGB buffer ────────────────────────── */
const buf = Buffer.alloc(W * H * 3);
for (let py = 0; py < H; py++) {
  for (let px = 0; px < W; px++) {
    const ux = (px + 0.5) / W;
    const uy = (py + 0.5) / H; // top-origin; matches the shader's flipped uv
    let color = sceneColorDark(ux, uy);

    // Vignette (same as the .frag — dark scene darkens edges more).
    const vx = (ux - 0.5) * (W / H);
    const vy = uy - 0.5;
    const vignette = smoothstep(1.0, 0.35, Math.hypot(vx, vy));
    const v = mix(0.82, 1.0, vignette);
    // Grain (dark scene, ±0.02), deterministic at t = 0.
    const grain = (hash(px + 0.5, H - py - 0.5) - 0.5) * 0.02;

    const i = (py * W + px) * 3;
    buf[i] = clamp(color[0] * v + grain, 0, 1) * 255;
    buf[i + 1] = clamp(color[1] * v + grain, 0, 1) * 255;
    buf[i + 2] = clamp(color[2] * v + grain, 0, 1) * 255;
  }
}

/* ── Foreground: veil + brand lockup + headline (transparent overlay) ─── */
// The brand lockup uses the real app logo (public/favicon.svg) — the orange
// gradient tile with the white agent figure — instead of a placeholder grid.
const LOGO = 64; // displayed size in px
const LOGO_X = 72;
const LOGO_Y = 68;
const LOGO_R = 12; // corner radius (matches BrandMark's rounded tile)
const faviconRaw = readFileSync(new URL("../public/favicon.svg", import.meta.url), "utf8");
const faviconInner = faviconRaw
  .replace(/^[\s\S]*?<svg[^>]*>/, "") // drop the outer <svg ...> open tag
  .replace(/<\/svg>\s*$/, ""); // drop the outer </svg> close tag
const logo = `<defs><clipPath id="logoClip"><rect x="${LOGO_X}" y="${LOGO_Y}" width="${LOGO}" height="${LOGO}" rx="${LOGO_R}"/></clipPath></defs>
  <g clip-path="url(#logoClip)"><svg x="${LOGO_X}" y="${LOGO_Y}" width="${LOGO}" height="${LOGO}" viewBox="0 0 1024 1024">${faviconInner}</svg></g>`;
const sans = "Manrope, 'Helvetica Neue', Arial, sans-serif";
const mono = "'JetBrains Mono', ui-monospace, 'SF Mono', Menlo, Consolas, monospace";

const overlay = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <!-- Dark scrim, strongest top-left (behind the lockup + headline), fading to
         clear lower-right so the ember cloudscape glows through. -->
    <linearGradient id="scrim" x1="0" y1="0" x2="1" y2="0.62">
      <stop offset="0" stop-color="#100f0e" stop-opacity="0.82"/>
      <stop offset="0.5" stop-color="#100f0e" stop-opacity="0.5"/>
      <stop offset="1" stop-color="#100f0e" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#scrim)"/>

  ${logo}
  <text x="152" y="116" font-family="${sans}" font-size="34" font-weight="600" letter-spacing="-0.3" fill="#fcfbf9">Control Center</text>

  <rect x="72" y="232" width="20" height="2" fill="#fb6424"/>
  <text x="104" y="240" font-family="${mono}" font-size="18" letter-spacing="1.8" fill="#cfc8ba">MULTI-AGENT DEVELOPER COCKPIT</text>

  <text x="70" y="338" font-family="${sans}" font-size="84" font-weight="400" letter-spacing="-2.4" fill="#fcfbf9">Command a fleet</text>
  <text x="70" y="426" font-family="${sans}" font-size="84" font-weight="400" letter-spacing="-2.4" fill="#fcfbf9">of coding agents.</text>

  <text x="72" y="492" font-family="${mono}" font-size="23" fill="#cfc8ba">Spawn &#183; watch &#183; review &#8212; from one deck.  Native desktop, macOS today.</text>
</svg>`;

await sharpFn(buf, { raw: { width: W, height: H, channels: 3 } })
  .composite([{ input: Buffer.from(overlay) }])
  .png()
  .toFile("public/og.png");

console.log("[gen-og] wrote public/og.png (1200x630) — shader cloudscape background");
