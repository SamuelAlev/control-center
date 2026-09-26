import assert from 'node:assert/strict';
import { it } from 'node:test';
import { ParagliderHairDynamics, type HairDynamicsConfig } from '../src/components/landing/paragliderHairDynamics.ts';

const longHair: HairDynamicsConfig = {
  windFlex: .035,
  gravityFlex: .24,
  inertiaFlex: .33,
  frequency: 9,
  damping: .8,
  maxBend: .16,
};

it('responds oppositely to opposite banks and pitches, including the vertical gravity component', () => {
  const tilt = .32;
  const down = -Math.sqrt(1 - tilt * tilt);
  const positiveBank = new ParagliderHairDynamics(longHair, () => .5);
  const negativeBank = new ParagliderHairDynamics(longHair, () => .5);
  const positivePitch = new ParagliderHairDynamics(longHair, () => .5);
  const negativePitch = new ParagliderHairDynamics(longHair, () => .5);
  for (let i = 0; i < 180; i++) {
    positiveBank.update(1 / 60, tilt, down, 0);
    negativeBank.update(1 / 60, -tilt, down, 0);
    positivePitch.update(1 / 60, 0, down, tilt);
    negativePitch.update(1 / 60, 0, down, -tilt);
  }
  assert.ok(positiveBank.bendX > .05 && negativeBank.bendX < -.05);
  assert.ok(positivePitch.bendZ > .02 && negativePitch.bendZ < -.05);
  assert.ok(positiveBank.bendY > .008 && positivePitch.bendY > .008);
  assert.ok(Math.abs(positiveBank.bendX + negativeBank.bendX) < .025);
});

it('initially resists a sudden attitude change, then settles toward the new hanging direction', () => {
  const hair = new ParagliderHairDynamics(longHair, () => .5);
  const gravityX = .4;
  const gravityY = -Math.sqrt(1 - gravityX * gravityX);
  hair.update(1 / 120, gravityX, gravityY, 0);
  const initial = hair.bendX;
  assert.ok(initial > .11 && initial < .15, `initial inertial offset ${initial}`);
  for (let i = 0; i < 240; i++) hair.update(1 / 120, gravityX, gravityY, 0);
  assert.ok(hair.bendX > .075 && hair.bendX < .115, `settled displacement ${hair.bendX}`);
  assert.ok(hair.bendX < initial - .015);
  hair.update(1 / 120, -gravityX, gravityY, 0);
  assert.ok(hair.bendX < 0, 'the reversed turn initially leaves the tips behind');
});

it('bounds displacement and ripple after long frames and abrupt opposing attitudes', () => {
  const hair = new ParagliderHairDynamics(longHair, () => .99);
  for (let i = 0; i < 100; i++) {
    hair.update(3600, i % 2 ? -.95 : .95, -.1, i % 2 ? .3 : -.3);
    const length = Math.hypot(hair.bendX, hair.bendY, hair.bendZ);
    assert.ok(Number.isFinite(length) && length <= longHair.maxBend + 1e-10, `displacement ${length}`);
    assert.ok(Number.isFinite(hair.rippleSine) && Number.isFinite(hair.rippleCosine));
    assert.ok(Math.hypot(hair.rippleSine, hair.rippleCosine) <= 1);
  }
});

it('interpolates irregular gusts without stopping the wind or replaying an eight-second loop', () => {
  let seed = 431;
  const hair = new ParagliderHairDynamics(longHair, () => {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return seed / 4294967296;
  });
  let minimum = Infinity;
  let maximum = 0;
  let largestStep = 0;
  let earlierSpeed = 0;
  let laterSpeed = 0;
  let previous = hair.windSpeed;
  for (let i = 1; i <= 30 * 60; i++) {
    hair.update(1 / 60, 0, -1, 0);
    minimum = Math.min(minimum, hair.windSpeed);
    maximum = Math.max(maximum, hair.windSpeed);
    largestStep = Math.max(largestStep, Math.abs(hair.windSpeed - previous));
    previous = hair.windSpeed;
    if (i === 5 * 60) earlierSpeed = hair.windSpeed;
    if (i === 13 * 60) laterSpeed = hair.windSpeed;
  }
  assert.ok(minimum >= .55 && maximum <= 1.6);
  assert.ok(maximum - minimum > .3, `gust variation ${maximum - minimum}`);
  assert.ok(largestStep < .04, `gust discontinuity ${largestStep}`);
  assert.ok(Math.abs(earlierSpeed - laterSpeed) > .02, 'wind must not replay at eight seconds');
});

it('reset and zero elapsed time leave neutral output untouched, including after motion', () => {
  const hair = new ParagliderHairDynamics(longHair, () => .8);
  hair.update(0, .4, -Math.sqrt(.84), 0);
  assert.equal(hair.bendX, 0);
  assert.equal(hair.rippleSine, 0);
  assert.equal(hair.rippleCosine, 0);
  hair.update(1 / 120, .4, -Math.sqrt(.84), 0);
  assert.ok(hair.bendX > .1, 'zero-delta attitude must not consume the inertial turn');
  hair.reset();
  assert.deepEqual([hair.bendX, hair.bendY, hair.bendZ, hair.rippleSine, hair.rippleCosine], [0, 0, 0, 0, 0]);
  hair.update(0, 0, -1, 0);
  assert.deepEqual([hair.bendX, hair.bendY, hair.bendZ, hair.rippleSine, hair.rippleCosine], [0, 0, 0, 0, 0]);
});
