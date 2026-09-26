import assert from 'node:assert/strict';
import { it } from 'node:test';
import { PerspectiveCamera, Vector3 } from 'three';
import { orbitFitDistance } from '../src/components/landing/paragliderFraming.ts';

it('keeps the animated-envelope sphere inside the frustum across yaw, pitch limits and viewport aspects', () => {
  const radius = 2.45;
  const center = new Vector3(.18, 1.7, -.34);
  const camera = new PerspectiveCamera(35, 1, .1, 100);
  const sample = new Vector3();
  for (const aspect of [2, 1.14, .78, .43]) {
    camera.aspect = aspect;
    camera.updateProjectionMatrix();
    const distance = orbitFitDistance(radius, camera.fov * Math.PI / 180, aspect);
    for (const pitch of [Math.PI / 3, Math.PI / 2, Math.PI * .7]) {
      for (let yaw = 0; yaw < Math.PI * 2; yaw += Math.PI / 12) {
        camera.position.set(
          center.x + distance * Math.sin(pitch) * Math.sin(yaw),
          center.y + distance * Math.cos(pitch),
          center.z + distance * Math.sin(pitch) * Math.cos(yaw),
        );
        camera.lookAt(center);
        camera.updateMatrixWorld();
        for (let longitude = 0; longitude < Math.PI * 2; longitude += Math.PI / 12) {
          for (let latitude = -Math.PI / 2; latitude <= Math.PI / 2; latitude += Math.PI / 12) {
            sample.set(
              center.x + radius * Math.cos(latitude) * Math.cos(longitude),
              center.y + radius * Math.sin(latitude),
              center.z + radius * Math.cos(latitude) * Math.sin(longitude),
            ).project(camera);
            assert.ok(Math.abs(sample.x) < 1 && Math.abs(sample.y) < 1 && sample.z > -1 && sample.z < 1,
              `sphere clipped at aspect ${aspect}, pitch ${pitch}, yaw ${yaw}: ${sample.toArray()}`);
          }
        }
      }
    }
  }
});
