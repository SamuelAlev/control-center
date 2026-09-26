"""Root-pinned hair morphs on the supplied pilot skins, not a replacement wig."""
import heapq
import math
from array import array

import bpy
from mathutils import Matrix, Vector

from isolated_flight import _smooth


def _hair_weight(point, color, long_hair):
    x, back, height = point
    red, green, blue = color
    # The two supplied skins share a brown hair palette. Spatial guards exclude
    # faces/beards, gloves and clothing; color excludes helmet plastic and straps.
    brown = (.07 < red < .90 and 1.18 * green < red < 2.2 * green and
             1.22 * blue < green < 4.2 * blue and blue > .018)
    if not brown:
        return 0., 0.
    if long_hair:
        if not (-.82 < height < .035 and abs(x) < .35 and -.115 < back < .42
                and (back > .055 or abs(x) > .125)):
            return 0., 0.
        length = max(0., min(1., (.035 - height) / .64))
        return _smooth(length) ** 1.3, length
    # Short quiff: keep its helmet-level base rigid. The rear fringe moves much
    # less than the exposed tips, and the face/beard never enter either region.
    if height > .275 and abs(x) < .16 and (back < -.075 or height > .335):
        length = max(0., min(1., (height - .275) / .105))
        return _smooth(length), length
    if -.005 < height < .10 and back > .015 and abs(x) < .17:
        length = max(0., min(1., (.10 - height) / .085))
        return .12 * _smooth(length), length
    return 0., 0.


def _posed_points(body):
    evaluated = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    try:
        if len(mesh.vertices) != len(body.data.vertices):
            raise RuntimeError('Hair baking requires the original skin topology')
        return [evaluated.matrix_world @ vertex.co for vertex in mesh.vertices]
    finally:
        evaluated.to_mesh_clear()


def _remove_isolated_texels(body, motion, keys):
    """Discard small brown strap patches disconnected from the actual hair."""
    neighbors = {index: [] for index in motion}
    for edge in body.data.edges:
        a, b = edge.vertices
        if a in motion and b in motion:
            neighbors[a].append(b)
            neighbors[b].append(a)
    # UV seams duplicate vertices in the supplied meshes. Join coincident
    # positions for mask connectivity only; never weld or change the source skin.
    positions = {}
    for index in motion:
        point = tuple(body.data.vertices[index].co)
        if point in positions:
            other = positions[point]
            neighbors[index].append(other)
            neighbors[other].append(index)
        else:
            positions[point] = index
    remaining = set(motion)
    while remaining:
        pending, island = [remaining.pop()], []
        while pending:
            index = pending.pop()
            island.append(index)
            for other in neighbors[index]:
                if other in remaining:
                    remaining.remove(other)
                    pending.append(other)
        if len(island) < 32:
            for index in island:
                del motion[index]
                del neighbors[index]
                for key in keys:
                    key.data[index].co = body.data.vertices[index].co
    return neighbors


def _pin_clothing_contacts(body, baseline, motion, keys, neighbors, clothing):
    """Keep the supplied mesh's fused hair/harness seams from stretching."""
    mesh = body.data
    clothing_positions = {tuple(mesh.vertices[index].co) for index in clothing}
    contacts = {index for index in motion
                if tuple(mesh.vertices[index].co) in clothing_positions}
    for edge in mesh.edges:
        a, b = edge.vertices
        if a in motion and b in clothing:
            contacts.add(a)
        if b in motion and a in clothing:
            contacts.add(b)
    # Feather along the actual curl surface, not through space: a free curl
    # beside a strap must still move. Coincident UV seams share the same graph.
    feather = .12
    distances = {index: 0. for index in contacts}
    pending = [(0., index) for index in contacts]
    heapq.heapify(pending)
    while pending:
        distance, index = heapq.heappop(pending)
        if distance > distances[index]:
            continue
        for other in neighbors[index]:
            candidate = distance + (baseline[index] - baseline[other]).length
            if candidate < min(feather, distances.get(other, math.inf)):
                distances[other] = candidate
                heapq.heappush(pending, (candidate, other))
    for index, distance in distances.items():
        weight = _smooth(distance / feather)
        original = mesh.vertices[index].co
        for key in keys:
            key.data[index].co = original + (key.data[index].co - original) * weight
        if weight == 0:
            del motion[index]
        else:
            motion[index] = tuple(offset * weight for offset in motion[index])
    return len(contacts)


def bake_hair_modes(scene, body, rig, long_hair):
    """Bake rooted deformation fields for the runtime gravity/wind solver.

    Offsets are authored in flight space and converted through each vertex's
    existing skin matrix. The three axis fields follow gravity and inertia;
    two spatially delayed fields ripple the curls. No timeline drives them.
    Bone weights, protected geometry and the neutral mesh remain unchanged.
    """
    scene.frame_set(1)
    bpy.context.view_layer.update()
    baseline = _posed_points(body)
    head = rig.matrix_world @ rig.pose.bones['Head'].head
    shader = next(node for node in body.data.materials[0].node_tree.nodes
                  if node.type == 'BSDF_PRINCIPLED')
    texture = shader.inputs['Base Color'].links[0].from_node.image
    pixels = array('f', [0.]) * len(texture.pixels)
    texture.pixels.foreach_get(pixels)
    width, height = texture.size
    uv = [None] * len(body.data.vertices)
    for loop in body.data.loops:
        uv[loop.vertex_index] = body.data.uv_layers[0].data[loop.index].uv.copy()
    to_arm = rig.matrix_world.inverted() @ body.matrix_world
    bone_matrices = {
        group.index: rig.pose.bones[group.name].matrix @
        rig.pose.bones[group.name].bone.matrix_local.inverted()
        for group in body.vertex_groups if group.name in rig.pose.bones}
    bend = .10 if long_hair else .04
    sway, flutter = (.011, .003) if long_hair else (.004, .0015)
    body['hairPhysics'] = {
        'bendScale': bend,
        'windFlex': .035 if long_hair else .015,
        'gravityFlex': .24 if long_hair else .045,
        'inertiaFlex': .33 if long_hair else .065,
        'frequency': 9. if long_hair else 15.,
        'damping': .8 if long_hair else .85,
        'maxBend': .16 if long_hair else .05,
        'rippleRadius': math.hypot(sway, flutter),
    }
    body.shape_key_add(name='Basis')
    keys = [body.shape_key_add(name=name) for name in
            ('Hair lateral', 'Hair lift', 'Hair aft',
             'Hair wave sine', 'Hair wave cosine')]
    for key in keys:
        key.slider_min = -3
        key.slider_max = 3
        key.value = 0
    motion = {}
    clothing = set()
    for vertex, world in zip(body.data.vertices, baseline):
        u, v = uv[vertex.index]
        pixel = (min(height - 1, int((v % 1) * height)) * width +
                 min(width - 1, int((u % 1) * width))) * 4
        point = world - head
        color = pixels[pixel:pixel + 3]
        if long_hair and point.z < -.2:
            red, green, blue = color
            if green >= red or (red < 1.12 * green and green < 1.15 * blue):
                clothing.add(vertex.index)
        weight, length = _hair_weight(point, color, long_hair)
        if weight <= 1e-5:
            continue
        skin = Matrix(((0.,) * 4,) * 4)
        total = 0.
        for group in vertex.groups:
            if group.group in bone_matrices:
                skin += bone_matrices[group.group] * group.weight
                total += group.weight
        if total <= 0:
            raise RuntimeError('An animated hair vertex has no skeleton weight')
        inverse = (rig.matrix_world @ (skin * (1 / total)) @ to_arm).to_3x3().inverted()
        # Axis fields bend toward the local force; neighboring curls share the
        # gust with different tip delays instead of translating as a rigid wig.
        lag = -1.8 * length + .8 * math.sin(point.x * 28) + .35 * math.sin(point.y * 35)
        wave = Vector((sway, 0, flutter)) * weight
        offsets = (Vector((bend, 0, 0)) * weight,
                   Vector((0, 0, bend)) * weight,
                   Vector((0, bend, 0)) * weight,
                   wave * math.cos(lag), wave * math.sin(lag))
        motion[vertex.index] = offsets
        for key, offset in zip(keys, offsets):
            key.data[vertex.index].co = vertex.co + inverse @ offset
    neighbors = _remove_isolated_texels(body, motion, keys)
    contacts = _pin_clothing_contacts(body, baseline, motion, keys, neighbors, clothing) if long_hair else 0
    if len(motion) < (5000 if long_hair else 200):
        raise RuntimeError(f'Hair mask missed the supplied hairstyle: {len(motion)} vertices')

    # Validate the skinned result, not merely the rest-space morph deltas.
    # This also checks that the untouched face, helmet and costume remain fixed.
    max_error = 0.
    for mode, key in enumerate(keys):
        key.value = 1
        bpy.context.view_layer.update()
        for index, (before, after) in enumerate(zip(baseline, _posed_points(body))):
            expected = motion[index][mode] if index in motion else Vector()
            max_error = max(max_error, (after - before - expected).length)
        key.value = 0
    if max_error > .00002:
        raise RuntimeError(f'Hair skin projection changed protected geometry: {max_error:.7f}m')
    # The runtime alone owns these weights. Baking them into Flight idle would
    # overwrite the solver on each AnimationMixer update and force an 8s replay.
    scene.frame_set(1)
    print(f'{body.name} hair: {len(motion)} moving vertices, five rooted fields, '
          f'{contacts} clothing-contact vertices pinned, '
          f'skin/protected-geometry error {max_error:.7f}m, '
          f'physics envelope {body["hairPhysics"]["maxBend"] + math.hypot(sway, flutter):.4f}m')
