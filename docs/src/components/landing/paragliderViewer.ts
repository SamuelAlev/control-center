import {
  AgXToneMapping, AnimationMixer, AnimationUtils, CatmullRomCurve3, DirectionalLight,
  Group, HemisphereLight, LoopOnce, Mesh, MeshBasicMaterial, PerspectiveCamera,
  PMREMGenerator, Scene, SRGBColorSpace, TubeGeometry, Vector3, WebGLRenderer,
} from 'three';
import type { AnimationAction, SkinnedMesh, Texture, WebGLRenderTarget } from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { orbitFitDistance } from './paragliderFraming';
import { ParagliderHair } from './paragliderHair';

export async function mountParaglider(root: HTMLElement, signal: AbortSignal): Promise<void> {
  if (signal.aborted) return;
  const stage = root.querySelector<HTMLElement>('.paraglider-stage')!;
  const install = root.closest<HTMLElement>('.landing-install');
  const cards = install?.querySelectorAll<HTMLElement>('.install-platforms, .install-remote');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const scene = new Scene();
  const camera = new PerspectiveCamera(35, 8 / 7, .1, 100);
  const renderer = new WebGLRenderer({ alpha: true, antialias: true, powerPreference: 'low-power' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = SRGBColorSpace;
  renderer.toneMapping = AgXToneMapping;
  renderer.toneMappingExposure = 1.25;
  renderer.setClearColor(0, 0);
  stage.append(renderer.domElement);
  const canvas = renderer.domElement;
  canvas.tabIndex = 0;
  canvas.setAttribute('aria-label', root.dataset.controls!);
  canvas.setAttribute('aria-keyshortcuts', 'ArrowLeft ArrowRight ArrowUp ArrowDown R Space');

  // The prefiltered softboxes supply indirect light and restrained reflections;
  // a single key keeps the canopy folds legible without washing out the fabric.
  scene.environmentIntensity = .45;
  scene.add(new HemisphereLight(0xe7efff, 0x99949a, .15));
  const key = new DirectionalLight(0xfff5e8, 1.4);
  key.position.set(-4, 8, 7);
  scene.add(key);
  const controls = new OrbitControls(camera, canvas);
  controls.enablePan = false;
  controls.enableZoom = false;
  controls.rotateSpeed = .65;
  controls.minPolarAngle = Math.PI / 3;
  controls.maxPolarAngle = Math.PI * .7;
  canvas.style.touchAction = 'pan-y'; // OrbitControls defaults to none; allow vertical touch scrolling.
  const upAxis = new Vector3(0, 1, 0);
  // The install pilot faces the reader; the hero retains its three-quarter view.
  const initialDirection = new Vector3(install ? 0 : 8, install ? 1.7 : 3.7, 11).normalize();
  const center = new Vector3();
  let fitRadius = 0;
  let fitDistance = 0;
  let model: Group | undefined;
  let loopPivot: Group | undefined;
  let environmentTarget: WebGLRenderTarget | undefined;
  let mixer: AnimationMixer | undefined;
  let leftTurn: AnimationAction | undefined;
  let rightTurn: AnimationAction | undefined;
  let turn = 0;
  const maxPitch = Math.PI / 10;
  let pitch = 0;
  let targetPitch = 0;
  let targetTurn = 0;
  let yaw = 0;
  let targetYaw = 0;
  let tracking = false;
  let loopStart = 0;
  const loopDuration = 900;
  let steeringUntil = 0;
  let dragging = false;
  let lastAzimuth = 0;
  let lastPolar = 0;
  let hair: ParagliderHair | undefined;
  let airflowPhase = 0;
  let wind: Group | undefined;
  const windTrails: Mesh<TubeGeometry, MeshBasicMaterial>[] = [];
  let themeObserver: MutationObserver | undefined;
  let visible = false;
  let userPaused = false;
  let disposed = false;
  let frame = 0;
  let elapsed = 0;
  let previousFrame = 0;
  const render = () => renderer.render(scene, camera);
  const animate = (time: number) => {
    frame = 0;
    if (disposed || !visible || document.hidden || reduced.matches || userPaused || !model || !hair) return;
    const delta = previousFrame ? Math.min(time - previousFrame, 100) / 1000 : 0;
    previousFrame = time;
    elapsed += delta;
    if (!dragging && !tracking && time >= steeringUntil) targetTurn = targetPitch = 0;
    turn += (targetTurn - turn) * (1 - Math.exp(-delta * 8));
    pitch += (targetPitch - pitch) * (1 - Math.exp(-delta * 7));
    yaw += (targetYaw - yaw) * (1 - Math.exp(-delta * 7));
    if (targetTurn === 0 && Math.abs(turn) < .001) turn = 0;
    if (targetPitch === 0 && Math.abs(pitch) < .0003) pitch = 0;
    // Sample the baked IK/cord/bank timelines together, never cross-fade just
    // the arms away from their handles. Only one brake can be pulled at a time.
    if (leftTurn) leftTurn.time = Math.max(0, -turn) * leftTurn.getClip().duration;
    if (rightTurn) rightTurn.time = Math.max(0, turn) * rightTurn.getClip().duration;
    mixer?.update(delta);
    model.position.y = (loopPivot ? -center.y : 0) + Math.sin(elapsed * .9) * .035;
    model.position.x = (loopPivot ? -center.x : 0) + Math.sin(elapsed * .65) * .035;
    model.rotation.set(pitch, yaw, Math.sin(elapsed * .55) * .007);
    if (loopPivot && loopStart) {
      const progress = Math.min((time - loopStart) / loopDuration, 1);
      const eased = progress * progress * (3 - 2 * progress);
      // Around the flight envelope's center: nose down first, then over the top.
      loopPivot.rotation.x = eased * Math.PI * 2;
      if (progress === 1) {
        loopPivot.rotation.x = 0;
        loopStart = 0;
      }
    }
    hair.update(delta);
    airflowPhase = (airflowPhase + delta * .42 * hair.windSpeed) % 1;
    // The trails are local to the glider, not the camera: +Z is the nose,
    // and the airflow travels toward -Z on either side of the suspension.
    for (let index = 0; index < windTrails.length; index++) {
      const progress = (airflowPhase + index / windTrails.length) % 1;
      const trail = windTrails[index];
      trail.position.z = .68 - progress * 1.36;
      trail.material.opacity = (.18 + .08 * hair.windSpeed) * Math.sin(Math.PI * progress);
    }
    render();
    frame = requestAnimationFrame(animate);
  };
  const update = () => {
    const active = !!model && !!hair && visible && !document.hidden && !reduced.matches && !userPaused;
    if (!visible || document.hidden) {
      dragging = tracking = false;
      targetTurn = targetPitch = targetYaw = steeringUntil = 0;
    }
    if (wind) {
      const wasVisible = wind.visible;
      wind.visible = !reduced.matches;
      if (wasVisible !== wind.visible && visible && !document.hidden) render();
    }
    if (reduced.matches && model) {
      turn = targetTurn = pitch = targetPitch = yaw = targetYaw = steeringUntil = loopStart = 0;
      // A fixed neutral keyframe also lets manual orbit remain responsive.
      mixer?.setTime(0);
      elapsed = airflowPhase = 0;
      model.position.copy(center).multiplyScalar(loopPivot ? -1 : 0);
      model.rotation.set(0, 0, 0);
      if (loopPivot) loopPivot.rotation.x = 0;
      hair?.reset();
      if (visible && !document.hidden) render();
    }
    if (active && !frame) {
      previousFrame = 0;
      frame = requestAnimationFrame(animate);
    } else if (!active && frame) {
      cancelAnimationFrame(frame);
      frame = 0;
    }
  };
  const resize = () => {
    const { width, height } = stage.getBoundingClientRect();
    if (!width || !height) return;
    camera.aspect = width / height;
    renderer.setSize(width, height, false);
    if (fitRadius) {
      fitDistance = orbitFitDistance(fitRadius, camera.fov * Math.PI / 180, camera.aspect);
      // Retain the user's yaw/pitch. R restores the original direction at this
      // new distance rather than OrbitControls' stale pre-resize saved position.
      camera.position.sub(controls.target).normalize().multiplyScalar(fitDistance).add(controls.target);
      camera.near = Math.max(.01, (fitDistance - fitRadius) * .5);
      camera.far = fitDistance + fitRadius * 2;
      camera.updateProjectionMatrix();
      controls.update();
    } else {
      camera.updateProjectionMatrix();
    }
    render();
  };
  const steer = (direction: number) => {
    if (userPaused || reduced.matches || !visible || document.hidden) return;
    targetTurn = direction;
    steeringUntil = performance.now() + 450;
  };
  const pitchTo = (angle: number) => {
    if (userPaused || reduced.matches || !visible || document.hidden) return;
    targetPitch = Math.max(-maxPitch, Math.min(maxPitch, angle));
    steeringUntil = performance.now() + 450;
  };
  const onCardMove = (event: PointerEvent) => {
    if (event.pointerType === 'touch' || userPaused || reduced.matches || !visible || document.hidden) return;
    const bounds = root.getBoundingClientRect();
    tracking = true;
    // A restrained glance keeps the face visible even over the far card edges.
    targetYaw = Math.max(-.2, Math.min(.2,
      Math.atan2(event.clientX - bounds.left - bounds.width / 2, bounds.width * 3.5)));
    targetPitch = Math.max(0, Math.min(.12,
      Math.atan2(event.clientY - bounds.top - bounds.height / 2, bounds.height * 4)));
    targetTurn = Math.max(-.85, Math.min(.85, targetYaw * 4));
  };
  const onCardLeave = () => {
    tracking = false;
    targetYaw = targetTurn = targetPitch = 0;
  };
  const onDownload = (event: MouseEvent) => {
    const link = (event.target as Element).closest<HTMLAnchorElement>('.install-platform');
    if (!link || event.defaultPrevented || event.button !== 0 || event.metaKey ||
        event.ctrlKey || event.shiftKey || event.altKey || link.target ||
        !model || !visible || document.hidden || reduced.matches || userPaused) return;
    // Native navigation starts the installer immediately and leaves this page
    // in place for an attachment; no timer holds up the download.
    loopStart = performance.now();
  };
  const onOrbit = () => {
    const azimuth = controls.getAzimuthalAngle();
    const polar = controls.getPolarAngle();
    const polarDelta = polar - lastPolar;
    const delta = Math.atan2(Math.sin(azimuth - lastAzimuth), Math.cos(azimuth - lastAzimuth));
    // Camera orbit is inverse model yaw: negative azimuth is pilot-left.
    if (dragging && Math.abs(delta) > .001) steer(Math.sign(delta));
    // Dragging upward lowers the camera's view and pitches the actual glider
    // nose up; its hair can now lag against world gravity, not just the view.
    if (dragging && Math.abs(polarDelta) > .001) pitchTo(targetPitch - polarDelta * .8);
    lastAzimuth = azimuth;
    lastPolar = polar;
    render();
  };
  const onStart = () => {
    dragging = true;
    targetTurn = targetPitch = 0;
    lastAzimuth = controls.getAzimuthalAngle();
    lastPolar = controls.getPolarAngle();
  };
  const onEnd = () => {
    dragging = false;
    targetTurn = targetPitch = steeringUntil = 0;
  };
  const onKey = (event: KeyboardEvent) => {
    if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      event.preventDefault();
      steer(event.key === 'ArrowLeft' ? -1 : 1);
      camera.position.sub(controls.target).applyAxisAngle(upAxis, event.key === 'ArrowLeft' ? -.16 : .16).add(controls.target);
      controls.update();
    } else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      event.preventDefault();
      const upward = event.key === 'ArrowUp';
      pitchTo(upward ? -maxPitch : maxPitch);
      const polar = Math.max(controls.minPolarAngle, Math.min(controls.maxPolarAngle,
        controls.getPolarAngle() + (upward ? .12 : -.12)));
      camera.position.setFromSphericalCoords(fitDistance, polar, controls.getAzimuthalAngle()).add(controls.target);
      controls.update();
    } else if (event.key.toLowerCase() === 'r') {
      event.preventDefault();
      turn = targetTurn = pitch = targetPitch = yaw = targetYaw = steeringUntil = loopStart = 0;
      if (leftTurn) leftTurn.time = 0;
      if (rightTurn) rightTurn.time = 0;
      mixer?.update(0);
      if (model) model.rotation.set(0, 0, 0);
      if (loopPivot) loopPivot.rotation.x = 0;
      hair?.reset();
      lastAzimuth = Math.atan2(initialDirection.x, initialDirection.z);
      camera.position.copy(center).addScaledVector(initialDirection, fitDistance);
      controls.target.copy(center);
      if (!controls.update()) render();
    } else if (event.key === ' ' || event.key === 'Spacebar') {
      event.preventDefault();
      userPaused = !userPaused;
      update();
    }
  };
  cards?.forEach(card => {
    card.addEventListener('pointermove', onCardMove);
    card.addEventListener('pointerleave', onCardLeave);
  });
  install?.addEventListener('click', onDownload);
  controls.addEventListener('change', onOrbit);
  controls.addEventListener('start', onStart);
  controls.addEventListener('end', onEnd);
  canvas.addEventListener('keydown', onKey);
  reduced.addEventListener('change', update);
  document.addEventListener('visibilitychange', update);
  const visibility = new IntersectionObserver(entries => {
    visible = entries[0].isIntersecting;
    update();
  }, { threshold: .05 });
  visibility.observe(root);
  const sizes = new ResizeObserver(resize);
  sizes.observe(stage);
  const dispose = () => {
    if (disposed) return;
    disposed = true;
    cancelAnimationFrame(frame);
    visibility.disconnect();
    sizes.disconnect();
    controls.removeEventListener('change', onOrbit);
    controls.removeEventListener('start', onStart);
    controls.removeEventListener('end', onEnd);
    controls.dispose();
    cards?.forEach(card => {
      card.removeEventListener('pointermove', onCardMove);
      card.removeEventListener('pointerleave', onCardLeave);
    });
    install?.removeEventListener('click', onDownload);
    canvas.removeEventListener('keydown', onKey);
    reduced.removeEventListener('change', update);
    document.removeEventListener('visibilitychange', update);
    signal.removeEventListener('abort', dispose);
    themeObserver?.disconnect();
    scene.environment = null;
    environmentTarget?.dispose();
    if (model) {
      mixer?.stopAllAction();
      mixer?.uncacheRoot(model);
      disposeModel(model);
    }
    renderer.dispose();
    renderer.forceContextLoss();
  };
  signal.addEventListener('abort', dispose, { once: true });

  try {
    const gltf = await new GLTFLoader().setMeshoptDecoder(MeshoptDecoder).loadAsync(root.dataset.model!);
    if (disposed) {
      disposeModel(gltf.scene);
      return;
    }
    model = gltf.scene;
    scene.add(model);
    let room: RoomEnvironment | undefined;
    let pmrem: PMREMGenerator | undefined;
    try {
      room = new RoomEnvironment();
      pmrem = new PMREMGenerator(renderer);
      // A small environment is sufficient at the displayed model size. Bake it
      // once per renderer, after the lazy model load, never in the frame loop.
      environmentTarget = pmrem.fromScene(room, 0, .1, 100, { size: 128 });
      scene.environment = environmentTarget.texture;
    } finally {
      room?.dispose();
      pmrem?.dispose();
    }
    const clip = gltf.animations.find(animation => animation.name === 'Flight idle');
    const leftClip = gltf.animations.find(animation => animation.name === 'Turn left');
    const rightClip = gltf.animations.find(animation => animation.name === 'Turn right');
    const bank = model.getObjectByName('FlightBank');
    if (!clip || !leftClip || !rightClip || !bank) {
      throw new Error('Paraglider is missing its idle, brake-pull or banking animation');
    }
    hair = new ParagliderHair(model, bank);
    mixer = new AnimationMixer(model);
    mixer.clipAction(clip).play();
    for (const turnClip of [leftClip, rightClip]) {
      // glTF deduplicates buffers across clips, including idle bone scales.
      // Additive conversion mutates tracks: own the buffers before converting.
      const action = mixer.clipAction(AnimationUtils.makeClipAdditive(turnClip.clone()));
      action.setLoop(LoopOnce, 1);
      action.clampWhenFinished = true;
      action.play();
      action.paused = true;
      if (turnClip === leftClip) leftTurn = action;
      else rightTurn = action;
    }
    const authoredBounds = model.userData.flightBounds as
      | { center?: number[]; radius?: number } | undefined;
    if (authoredBounds?.center?.length !== 3 ||
        !authoredBounds.center.every(Number.isFinite) ||
        typeof authoredBounds.radius !== 'number' ||
        !Number.isFinite(authoredBounds.radius) || authoredBounds.radius <= 0) {
      throw new Error('Paraglider is missing its animated flight bounds');
    }
    center.fromArray(authoredBounds.center);
    fitRadius = authoredBounds.radius;
    if (install) {
      loopPivot = new Group();
      loopPivot.position.copy(center);
      scene.add(loopPivot);
      loopPivot.add(model);
      model.position.copy(center).multiplyScalar(-1);
    }
    mixer?.setTime(0);
    // The animation envelope is in local model coordinates. Its center moves
    // slightly when the idle roll rotates the whole group around the origin.
    fitRadius += 2 * center.length() * Math.sin(.007 / 2) + Math.SQRT2 * .035;
    wind = new Group();
    wind.name = 'Airflow';
    // Short, prebuilt tubes never enter the pilot/wing envelope or expand the
    // authored flight sphere. Only transforms and opacity change per frame.
    for (const side of [-1, 1]) {
      for (const height of [-.82, -1.19]) {
        const curve = new CatmullRomCurve3([
          new Vector3(0, -.025, .24),
          new Vector3(side * .045, 0, .08),
          new Vector3(side * .06, .02, -.10),
          new Vector3(side * .035, .015, -.27),
        ]);
        const geometry = new TubeGeometry(curve, 12, .011, 4, false);
        const material = new MeshBasicMaterial({
          transparent: true, depthWrite: false, toneMapped: false, opacity: 0,
        });
        const trail = new Mesh(geometry, material);
        trail.position.set(side * 1.48, height, .68);
        wind.add(trail);
        windTrails.push(trail);
      }
    }
    wind.visible = !reduced.matches;
    bank.add(wind);
    const syncWindColor = () => {
      const color = getComputedStyle(document.documentElement).getPropertyValue('--color-fg').trim();
      for (const trail of windTrails) trail.material.color.setStyle(color);
      if (visible && !document.hidden) render();
    };
    syncWindColor();
    themeObserver = new MutationObserver(syncWindColor);
    themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
    controls.target.copy(center);
    camera.position.copy(center).addScaledVector(initialDirection, 1);
    stage.hidden = false;
    root.classList.add('is-ready');
    resize();
    update();
  } catch (error) {
    dispose();
    throw error;
  }
}

function disposeModel(model: Group): void {
  const skeletons = new Set<SkinnedMesh['skeleton']>();
  model.traverse(object => {
    if (!('isMesh' in object)) return;
    const mesh = object as Mesh;
    if ('isSkinnedMesh' in mesh && mesh.isSkinnedMesh) {
      const skeleton = (mesh as SkinnedMesh).skeleton;
      if (!skeletons.has(skeleton)) {
        skeleton.dispose(); // Releases the bone texture allocated by the renderer.
        skeletons.add(skeleton);
      }
    }
    mesh.geometry?.dispose();
    for (const material of Array.isArray(mesh.material) ? mesh.material : [mesh.material]) {
      for (const value of Object.values(material)) {
        if (value && typeof value === 'object' && 'isTexture' in value) (value as Texture).dispose();
      }
      material.dispose();
    }
  });
}
