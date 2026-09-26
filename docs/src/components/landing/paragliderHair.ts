import { Quaternion, Vector3 } from 'three';
import type { Group, Object3D, SkinnedMesh } from 'three';
import { ParagliderHairDynamics, type HairDynamicsConfig } from './paragliderHairDynamics';

const fields = ['Hair lateral', 'Hair lift', 'Hair aft', 'Hair wave sine', 'Hair wave cosine'];
const configKeys = ['windFlex', 'gravityFlex', 'inertiaFlex', 'frequency', 'damping', 'maxBend', 'bendScale'] as const;
type HairAssetConfig = HairDynamicsConfig & { bendScale: number };

/** Converts world gravity into the pilot's current attitude and drives rooted fields. */
export class ParagliderHair {
  private readonly dynamics: ParagliderHairDynamics;
  private readonly bank: Object3D;
  private readonly weights: number[];
  private readonly indices: number[];
  private readonly bendScale: number;
  private readonly inverseAttitude = new Quaternion();
  private readonly gravity = new Vector3();

  constructor(model: Group, bank: Object3D) {
    const pilot = model.getObjectByName('Pilot') as SkinnedMesh | undefined;
    const config = pilot?.userData.hairPhysics as HairAssetConfig | undefined;
    const dictionary = pilot?.morphTargetDictionary;
    const weights = pilot?.morphTargetInfluences;
    if (!pilot?.isSkinnedMesh || !config || !dictionary || !weights ||
        !configKeys.every(key => typeof config[key] === 'number' && Number.isFinite(config[key]) && config[key] > 0)) {
      throw new Error('Paraglider is missing its rooted hair physics data');
    }
    const indices = fields.map(name => dictionary[name]);
    if (indices.some(index => !Number.isInteger(index) || index < 0 || index >= weights.length)) {
      throw new Error('Paraglider is missing its gravity and wind hair fields');
    }
    this.bank = bank;
    this.weights = weights;
    this.indices = indices;
    this.bendScale = config.bendScale;
    this.dynamics = new ParagliderHairDynamics(config);
  }

  get windSpeed(): number {
    return this.dynamics.windSpeed;
  }

  update(deltaSeconds: number): void {
    // Includes the outer pitch/idle roll and the baked brake bank. Camera orbit
    // never changes gravity: it changes the view, not the physical down vector.
    this.bank.getWorldQuaternion(this.inverseAttitude).invert();
    this.gravity.set(0, -1, 0).applyQuaternion(this.inverseAttitude);
    this.dynamics.update(deltaSeconds, this.gravity.x, this.gravity.y, this.gravity.z);
    this.writeWeights();
  }

  reset(): void {
    this.dynamics.reset();
    this.writeWeights();
  }

  private writeWeights(): void {
    const motion = this.dynamics;
    this.weights[this.indices[0]] = motion.bendX / this.bendScale;
    this.weights[this.indices[1]] = motion.bendY / this.bendScale;
    // The authored aft field points down local -Z, whereas bendZ is signed +Z.
    this.weights[this.indices[2]] = -motion.bendZ / this.bendScale;
    this.weights[this.indices[3]] = motion.rippleSine;
    this.weights[this.indices[4]] = motion.rippleCosine;
  }
}
