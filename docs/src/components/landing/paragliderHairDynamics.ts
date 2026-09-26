export interface HairDynamicsConfig {
  windFlex: number;
  gravityFlex: number;
  inertiaFlex: number;
  frequency: number;
  damping: number;
  maxBend: number;
}

/** Pilot-local tip displacement in metres, driven by local gravity and passing gusts. */
export class ParagliderHairDynamics {
  bendX = 0;
  bendY = 0;
  bendZ = 0;
  rippleSine = 0;
  rippleCosine = 0;
  windSpeed = 1;

  private readonly config: HairDynamicsConfig;
  private readonly random: () => number;
  private velocityX = 0;
  private velocityY = 0;
  private velocityZ = 0;
  private gravityX = 0;
  private gravityY = -1;
  private gravityZ = 0;
  private gustFrom = 1;
  private gustTo = 1;
  private gustDuration = 0;
  private gustElapsed = 0;
  private phase = 0;
  private rippleFade = 0;

  constructor(config: HairDynamicsConfig, random: () => number = Math.random) {
    this.config = config;
    this.random = random;
  }

  reset(): void {
    this.bendX = 0;
    this.bendY = 0;
    this.bendZ = 0;
    this.velocityX = 0;
    this.velocityY = 0;
    this.velocityZ = 0;
    this.gravityX = 0;
    this.gravityY = -1;
    this.gravityZ = 0;
    this.windSpeed = 1;
    this.gustFrom = 1;
    this.gustTo = 1;
    this.gustDuration = 0;
    this.gustElapsed = 0;
    this.phase = 0;
    this.rippleFade = 0;
    this.rippleSine = 0;
    this.rippleCosine = 0;
  }

  update(deltaSeconds: number, gravityX: number, gravityY: number, gravityZ: number): void {
    if (!(deltaSeconds > 0) || !Number.isFinite(deltaSeconds)) return;

    // A newly tilted pilot leaves the tips briefly in their previous world-space
    // orientation. The spring subsequently brings them toward hanging gravity.
    const inertia = this.config.inertiaFlex;
    this.bendX += (gravityX - this.gravityX) * inertia;
    this.bendY += (gravityY - this.gravityY) * inertia;
    this.bendZ += (gravityZ - this.gravityZ) * inertia;
    this.gravityX = gravityX;
    this.gravityY = gravityY;
    this.gravityZ = gravityZ;
    this.limitBend();

    // Ignore excess wall time after suspension rather than simulating minutes
    // of stale motion. Every integrated interval remains small and bounded.
    let remaining = Math.min(deltaSeconds, .25);
    const frequency = this.config.frequency;
    const stiffness = frequency * frequency;
    const drag = 2 * this.config.damping * frequency;
    while (remaining > 0) {
      const step = Math.min(remaining, 1 / 120);
      remaining -= step;

      if (this.gustElapsed >= this.gustDuration) {
        this.gustFrom = this.gustTo;
        this.gustTo = .55 + 1.05 * this.unitRandom();
        this.gustDuration = .8 + 1.9 * this.unitRandom();
        this.gustElapsed = 0;
      }
      this.gustElapsed = Math.min(this.gustElapsed + step, this.gustDuration);
      const t = this.gustElapsed / this.gustDuration;
      const ease = t * t * (3 - 2 * t);
      this.windSpeed = this.gustFrom + (this.gustTo - this.gustFrom) * ease;
      const windForce = this.config.windFlex * this.windSpeed * this.windSpeed;
      // A smaller lateral component follows a slower, non-repeating breeze.
      const crosswind = windForce * .22 * Math.sin(this.phase * .37);
      const targetX = gravityX * this.config.gravityFlex + crosswind;
      const targetY = (gravityY + 1) * this.config.gravityFlex;
      const targetZ = gravityZ * this.config.gravityFlex - windForce;
      this.velocityX += ((targetX - this.bendX) * stiffness - drag * this.velocityX) * step;
      this.velocityY += ((targetY - this.bendY) * stiffness - drag * this.velocityY) * step;
      this.velocityZ += ((targetZ - this.bendZ) * stiffness - drag * this.velocityZ) * step;
      this.bendX += this.velocityX * step;
      this.bendY += this.velocityY * step;
      this.bendZ += this.velocityZ * step;
      this.limitBend();

      this.phase += frequency * (.65 + .35 * this.windSpeed) * step;
      this.rippleFade = Math.min(1, this.rippleFade + step * 1.25);
      const amplitude = this.rippleFade * (.5 + .3 * (this.windSpeed - .55) / 1.05);
      this.rippleSine = Math.sin(this.phase) * amplitude;
      this.rippleCosine = Math.cos(this.phase) * amplitude;
    }
  }

  private unitRandom(): number {
    return Math.max(0, Math.min(1, this.random()));
  }

  private limitBend(): void {
    const radius = this.config.maxBend;
    const lengthSquared = this.bendX * this.bendX + this.bendY * this.bendY + this.bendZ * this.bendZ;
    if (lengthSquared <= radius * radius) return;
    const scale = radius / Math.sqrt(lengthSquared);
    this.bendX *= scale;
    this.bendY *= scale;
    this.bendZ *= scale;
    const outward = (this.bendX * this.velocityX + this.bendY * this.velocityY + this.bendZ * this.velocityZ) / (radius * radius);
    if (outward > 0) {
      this.velocityX -= outward * this.bendX;
      this.velocityY -= outward * this.bendY;
      this.velocityZ -= outward * this.bendZ;
    }
  }
}
