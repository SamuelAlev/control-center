import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS, EXTMeshoptCompression } from '@gltf-transform/extensions';
import { quantize, reorder } from '@gltf-transform/functions';
import { MeshoptDecoder, MeshoptEncoder } from 'meshoptimizer';

// Run after Blender's pose/attachment checks. No simplification, texture
// recompression, animation resampling or skin-weight quantization is applied.
await Promise.all([MeshoptEncoder.ready, MeshoptDecoder.ready]);
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'meshopt.encoder': MeshoptEncoder,
  'meshopt.decoder': MeshoptDecoder,
});

function contract(document) {
  const root = document.getRoot();
  return {
    scenes: root.listScenes().map(scene => [scene.getName(), scene.getExtras()]),
    nodes: root.listNodes().map(node => [
      node.getName(), node.getExtras(),
      node.getSkin()?.listJoints().map(joint => joint.getName()),
    ]),
    meshes: root.listMeshes().map(mesh => [
      mesh.getName(), mesh.getExtras(), mesh.listPrimitives().map(primitive => [
        primitive.getMode(), primitive.getIndices()?.getCount(),
        primitive.getAttribute('POSITION').getCount(),
        primitive.listTargets().map(target => target.listSemantics().sort()),
      ]),
    ]),
    textures: root.listTextures().map(texture => texture.getImage()),
    animations: root.listAnimations().map(animation => [
      animation.getName(), animation.listChannels().map(channel => {
        const sampler = channel.getSampler();
        return [channel.getTargetNode().getName(), channel.getTargetPath(),
          sampler.getInterpolation(), sampler.getInput().getArray(), sampler.getOutput().getArray()];
      }),
    ]),
  };
}

function morphNormalPeaks(document) {
  return document.getRoot().listMeshes().flatMap(mesh =>
    mesh.listPrimitives().flatMap(primitive => primitive.listTargets().map(target =>
      target.getAttribute('NORMAL')?.getArray().reduce((peak, value) =>
        Math.max(peak, Math.abs(value)), 0) ?? 0)));
}

const paths = process.argv.slice(2);
assert(paths.length > 0, 'Pass the Blender-exported pilot GLB paths.');
for (const path of paths) {
  const source = await readFile(path);
  const document = await io.readBinary(source);
  const before = contract(document);
  const normalPeaks = morphNormalPeaks(document);
  await document.transform(
    reorder({ encoder: MeshoptEncoder }),
    quantize({
      pattern: /^(POSITION|NORMAL|TEXCOORD_\d+)$/,
      patternTargets: /^POSITION$/,
      quantizePosition: 16,
      quantizeNormal: 16,
      quantizeTexcoord: 16,
      normalizeWeights: false,
    }),
  );

  // Morph normals are DELTAS in [-2, 2], not unit normals. SNORM would clip
  // the pilots' ~1.99 values. Retain FLOAT and round to a 1/65536 grid instead:
  // <= 0.00000763 component error, without clipping or changing the morphs.
  for (const mesh of document.getRoot().listMeshes()) {
    for (const primitive of mesh.listPrimitives()) {
      for (const target of primitive.listTargets()) {
        const normals = target.getAttribute('NORMAL')?.getArray();
        if (!normals) continue;
        for (let i = 0; i < normals.length; i++) {
          normals[i] = Math.round(normals[i] * 65536) / 65536;
        }
      }
    }
  }

  // glTF Transform skips Meshopt on sparse accessors. Dense zero runs compress
  // well and let the codec cover the hair, canopy and brake morphs too.
  for (const accessor of document.getRoot().listAccessors()) accessor.setSparse(false);
  document.createExtension(EXTMeshoptCompression).setRequired(true).setEncoderOptions({
    // No lossy animation filters: retain every original keyframe verbatim.
    method: EXTMeshoptCompression.EncoderMethod.QUANTIZE,
  });
  const compressed = await io.writeBinary(document);
  const decoded = await io.readBinary(compressed);
  assert.deepStrictEqual(contract(decoded), before,
    `${path}: compression changed topology, metadata, textures or animation`);
  assert(morphNormalPeaks(decoded).every((peak, i) => Math.abs(peak - normalPeaks[i]) <= 1 / 65536),
    `${path}: compression clipped a morph normal`);
  assert(compressed.length < source.length, `${path}: compression increased the asset size`);
  await writeFile(path, compressed);
  console.log(`${path}: ${source.length} → ${compressed.length} bytes ` +
    `(${(100 * (1 - compressed.length / source.length)).toFixed(1)}% smaller)`);
}
