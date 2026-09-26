// The canopy can face any yaw; a sphere remains inside either camera frustum
// plane even as the pilot pitches or the canvas changes aspect ratio.
export function orbitFitDistance(radius: number, verticalFov: number, aspect: number): number {
  const halfVertical = verticalFov / 2;
  const halfHorizontal = Math.atan(Math.tan(halfVertical) * aspect);
  // The tangent from the camera to the sphere must fit within the narrower FOV.
  return radius / Math.sin(Math.min(halfVertical, halfHorizontal)) * 1.04;
}
