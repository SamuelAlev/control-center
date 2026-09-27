"""Render both isolated pilots from the preserved Alpine Journey source scene.

Run from the repository root:
  /Applications/Blender.app/Contents/MacOS/Blender -b docs/art/alpine/alpine-journey.blend --python docs/art/alpine/render_install_pilot.py

Requires ffmpeg for lossless-alpha WebP, plus Node and `pnpm -C docs install`
for Meshopt compression. The source .blend is only read; scene changes are local.

For a fast pose/attachment check without rendering or AO, append -- --quick-check.
"""
import json
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

import bpy
from mathutils import Vector

ART = Path(__file__).resolve().parent
PUBLIC = ART.parents[1] / 'public' / 'alpine'
if str(ART) not in sys.path:
    sys.path.insert(0, str(ART))
from isolated_flight import (bake_canopy_wind, flight_idle,
                             flight_lines, rigged_pilot, sampled_bounds)
from isolated_hair import bake_hair_modes
from isolated_turns import bake_brake_turns

SCENE = bpy.data.scenes['Alpine Journey']
FRAME = 120  # Fully airborne, in the original articulated flight pose.
SOURCE_NAMES = {'girl': 'Mira', 'boy': 'Tao'}
FFMPEG = shutil.which('ffmpeg')
if not FFMPEG:
    raise RuntimeError('ffmpeg is required to encode smooth, lossless-alpha WebP')
NODE = shutil.which('node')
if not NODE and '--quick-check' not in sys.argv:
    raise RuntimeError('Node is required for pilot compression; run pnpm -C docs install first')

bpy.context.window.scene = SCENE
SCENE.frame_set(FRAME)
PUBLIC.mkdir(parents=True, exist_ok=True)

# One neutral studio setup, shared by both source skins and their canopies.
world = bpy.data.worlds.new('Pilot neutral studio')
world.use_nodes = True
background = world.node_tree.nodes.get('Background')
background.inputs['Color'].default_value = (.68, .70, .73, 1)
background.inputs['Strength'].default_value = .75
SCENE.world = world

line_material = bpy.data.materials.new('Pilot graphite suspension lines')
line_material.diffuse_color = (.20, .22, .21, 1)
line_material.use_nodes = True
line_shader = next(node for node in line_material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
line_shader.inputs['Base Color'].default_value = (.20, .22, .21, 1)
line_shader.inputs['Roughness'].default_value = .9

SCENE.render.engine = 'CYCLES'
SCENE.cycles.samples = 256
# Accumulate narrow cord coverage without spatial denoising, then downsample
# a two-times render for smooth canopy, boot and suspension-line silhouettes.
SCENE.cycles.use_denoising = False
SCENE.render.film_transparent = True
SCENE.render.resolution_x = 2400
SCENE.render.resolution_y = 2100
SCENE.render.resolution_percentage = 100
SCENE.render.image_settings.file_format = 'PNG'
SCENE.render.image_settings.color_mode = 'RGBA'
SCENE.render.image_settings.color_depth = '8'
SCENE.view_settings.view_transform = 'AgX'
SCENE.render.use_compositing = False


# The body source already has an atlas for its baked color/ORM. The sewn wing's
# textile UVs deliberately tile beyond 0..1, so only its AO needs a fresh
# unwrap. Neither source UV set may be replaced by the occlusion atlas.
AO_UV = 'Contact AO'
AO_SIZE = 1024
AO_SAMPLES = 96


def bake_contact_ao(obj, radius, image_path, unwrap):
    mesh = obj.data
    source_uv = mesh.uv_layers[0]
    atlas = mesh.uv_layers.new(name=AO_UV, do_init=True)
    if unwrap:
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        atlas.active = True
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(island_margin=.02)
        bpy.ops.object.mode_set(mode='OBJECT')
    # All existing base-color, normal and ORM nodes continue to use UV0.
    mesh.uv_layers.active_render_index = 0
    mesh.uv_layers.active_index = mesh.uv_layers.find(AO_UV)

    image = bpy.data.images.new(obj.name + ' contact AO', AO_SIZE, AO_SIZE,
                                alpha=False, float_buffer=False)
    image.generated_color = (1, 1, 1, 1)
    image.colorspace_settings.name = 'Non-Color'
    image.filepath_raw = str(image_path)
    image.file_format = 'PNG'

    bake_material = bpy.data.materials.new(obj.name + ' AO bake')
    bake_material.use_nodes = True
    nodes = bake_material.node_tree.nodes
    nodes.clear()
    occlusion = nodes.new('ShaderNodeAmbientOcclusion')
    occlusion.inputs['Distance'].default_value = radius
    occlusion.only_local = True
    emission = nodes.new('ShaderNodeEmission')
    target = nodes.new('ShaderNodeTexImage')
    target.image = image
    nodes.active = target
    output = nodes.new('ShaderNodeOutputMaterial')
    bake_material.node_tree.links.new(occlusion.outputs['Color'], emission.inputs['Color'])
    bake_material.node_tree.links.new(emission.outputs[0], output.inputs['Surface'])

    original_materials = list(mesh.materials)
    try:
        for slot in range(len(original_materials)):
            mesh.materials[slot] = bake_material
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        mesh.uv_layers.active_index = mesh.uv_layers.find(AO_UV)
        if mesh.uv_layers.active is None:
            raise RuntimeError(f'{obj.name}: missing active AO UV atlas')
        SCENE.cycles.samples = AO_SAMPLES
        # Keep untouched texels white. Clearing the target image would turn
        # empty atlas space black and create dark seams in downsampled mips.
        SCENE.render.bake.margin = 6
        SCENE.render.bake.use_clear = False
        bpy.ops.object.bake(type='EMIT')
        image.save()
        image.pack()
    finally:
        for slot, material in enumerate(original_materials):
            mesh.materials[slot] = material
        bpy.data.materials.remove(bake_material)
        source_uv.active = True

    # Blender's glTF exporter reads this group's Occlusion input, including
    # the explicit UVMap. Mixing white sets glTF occlusionTexture.strength,
    # rather than permanently darkening the baked pixels.
    settings = bpy.data.node_groups.get('glTF Material Output')
    if settings is None:
        settings = bpy.data.node_groups.new('glTF Material Output', 'ShaderNodeTree')
        settings.interface.new_socket(name='Occlusion', in_out='INPUT',
                                      socket_type='NodeSocketFloat')
        settings.nodes.new('NodeGroupInput')
        settings.nodes.new('NodeGroupOutput')
    for slot, source in enumerate(original_materials):
        material = source.copy()  # The preserved source scene stays untouched.
        mesh.materials[slot] = material
        nodes = material.node_tree.nodes
        links = material.node_tree.links
        # New AO UVs cannot become the implicit sampling coordinates of the
        # original color/normal/ORM nodes. Pin those maps to the source UV0.
        implicit_textures = [node for node in nodes if node.type == 'TEX_IMAGE'
                             and not node.inputs['Vector'].is_linked]
        if implicit_textures:
            base_uv = nodes.new('ShaderNodeUVMap')
            base_uv.uv_map = source_uv.name
            for original_texture in implicit_textures:
                links.new(base_uv.outputs['UV'], original_texture.inputs['Vector'])
        uv = nodes.new('ShaderNodeUVMap')
        uv.uv_map = AO_UV
        texture = nodes.new('ShaderNodeTexImage')
        texture.image = image
        mix = nodes.new('ShaderNodeMix')
        mix.data_type = 'RGBA'
        mix.blend_type = 'MIX'
        mix.inputs['Factor'].default_value = .72
        mix.inputs[6].default_value = (1, 1, 1, 1)
        group = nodes.new('ShaderNodeGroup')
        group.node_tree = settings
        links.new(uv.outputs['UV'], texture.inputs['Vector'])
        links.new(texture.outputs['Color'], mix.inputs[7])
        links.new(mix.outputs[2], group.inputs['Occlusion'])



def softbox(name, target, offset, power, size):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = power
    data.shape = 'DISK'
    data.size = size
    light = bpy.data.objects.new(name, data)
    SCENE.collection.objects.link(light)
    light.location = target + Vector(offset)
    light.rotation_euler = (target - light.location).to_track_quat('-Z', 'Y').to_euler()


def validate_export(path):
    """Check the file, not just Blender's pose: NLA export can reset unkeyed arms."""
    payload = path.read_bytes()
    json_size = struct.unpack_from('<I', payload, 12)[0]
    gltf = json.loads(payload[20:20 + json_size])
    binary_start = 28 + json_size
    clips = {clip['name']: clip for clip in gltf['animations']}
    if set(clips) != {'Flight idle', 'Turn left', 'Turn right'}:
        raise RuntimeError(f'{path.name}: incorrect exported clips {list(clips)}')

    def neutral(clip):
        pose = {}
        for channel in clip['channels']:
            node, prop = channel['target']['node'], channel['target']['path']
            if prop not in ('translation', 'rotation', 'scale'):
                continue
            sampler = clip['samplers'][channel['sampler']]
            output = gltf['accessors'][sampler['output']]
            view = gltf['bufferViews'][output['bufferView']]
            size = 4 if prop == 'rotation' else 3
            offset = binary_start + view.get('byteOffset', 0) + output.get('byteOffset', 0)
            pose[node, prop] = struct.unpack_from(f'<{size}f', payload, offset)
        return pose

    reference = neutral(clips['Flight idle'])
    for name, clip in clips.items():
        inputs = [gltf['accessors'][sampler['input']] for sampler in clip['samplers']]
        start = min(accessor['min'][0] for accessor in inputs)
        end = max(accessor['max'][0] for accessor in inputs)
        if abs(start) > 1e-6 or abs(end - (8 if name == 'Flight idle' else 1)) > 1e-6:
            raise RuntimeError(f'{path.name}: {name} has incorrect timing {start}–{end}')
        for target, value in neutral(clip).items():
            if target not in reference:
                continue
            other = reference[target]
            gap = max(abs(a - b) for a, b in zip(value, other))
            if target[1] == 'rotation':  # q and -q represent the same pose.
                gap = min(gap, max(abs(a + b) for a, b in zip(value, other)))
            if gap > 1e-4:
                raise RuntimeError(f'{path.name}: {name} neutral mismatch on {target}: {gap}')
    print(f'{path.name}: three exported clips share one neutral pose')


def render_pilot(name, basename):
    SCENE.frame_set(FRAME)
    SCENE.cycles.samples = 256
    root = SCENE.objects[name + ' PilotRig']
    wing = SCENE.objects[name + ' sewn ram-air wing']
    armature = next(obj for obj in root.children if obj.type == 'ARMATURE'
                    and obj.name != name + ' WingRig')
    skin = next(obj for obj in armature.children if obj.type == 'MESH')
    # Camera and export origin come from the evaluated airborne geometry,
    # never the source rest-pose bounding boxes.

    # Frame on deformed geometry, not the rest-pose mesh bounding boxes.
    depsgraph = bpy.context.evaluated_depsgraph_get()
    points = []
    for obj in (skin, wing):
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        try:
            points.extend(evaluated.matrix_world @ vertex.co for vertex in mesh.vertices)
        finally:
            evaluated.to_mesh_clear()
    bounds_min = Vector(tuple(min(point[i] for point in points) for i in range(3)))
    bounds_max = Vector(tuple(max(point[i] for point in points) for i in range(3)))
    target = (bounds_min + bounds_max) / 2
    body, flight_rig = rigged_pilot(skin, armature, target)
    side_sources = sorted(('Left', 'Right'), key=lambda source:
                          (armature.matrix_world @ armature.pose.bones[source+'Hand'].head).x)
    hands = {'L': side_sources[0]+'Hand', 'R': side_sources[1]+'Hand'}
    flight_idle(flight_rig, hands)
    bpy.context.view_layer.update()
    # The idle key generation seeks the scene. Restore the authored flight
    # frame before evaluating any source canopy rib or skeleton endpoint.
    SCENE.frame_set(FRAME)
    bpy.context.view_layer.update()
    # Preserve the authored canopy shape and UV0 while replacing only the
    # source's sparse, head-crossing lines with paired load-bearing cascades.
    evaluated = wing.evaluated_get(bpy.context.evaluated_depsgraph_get())
    canopy_mesh = bpy.data.meshes.new_from_object(
        evaluated, preserve_all_data_layers=True,
        depsgraph=bpy.context.evaluated_depsgraph_get())
    canopy_mesh.transform(evaluated.matrix_world)
    for vertex in canopy_mesh.vertices:
        vertex.co -= target
    canopy = bpy.data.objects.new('Canopy', canopy_mesh)
    SCENE.collection.objects.link(canopy)
    brake_material = line_material.copy()
    brake_material.name = 'Pilot independent amber brake line'
    brake_material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (.32, .19, .09, 1)
    toggle_material = line_material.copy()
    toggle_material.name = 'Pilot padded brake toggles'
    toggle_material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (.065, .075, .07, 1)
    attachments, fixed_ends = [], []
    cords = flight_lines(SCENE, root, flight_rig, hands, wing, target,
                         (line_material, brake_material, toggle_material),
                         attachments=attachments, fixed_ends=fixed_ends)
    bake_canopy_wind(SCENE, canopy, cords, root, flight_rig, hands, wing,
                     target, (line_material, brake_material, toggle_material),
                     attachments, fixed_ends)
    bake_hair_modes(SCENE, body, flight_rig, long_hair=name == SOURCE_NAMES['girl'])
    bank, clips = bake_brake_turns(
        SCENE, flight_rig, canopy, cords, root, hands, wing, target,
        (line_material, brake_material, toggle_material), attachments, fixed_ends,
        FRAME)
    display = (body, canopy, cords)
    # Hidden parents also hide their children from Cycles, even when the mesh
    # itself is renderable. Keep the transform/skin parents visible.
    for obj in SCENE.objects:
        obj.hide_render = obj not in (*display, flight_rig, bank)
    SCENE.frame_set(1)  # Clip neutral is also the poster pose.
    points = [point-target for point in points]
    target = Vector((0, 0, 0))

    # Source pilots fly along world -Y; glTF exports that front as +Z.
    # Keep the install poster head-on like its default interactive camera.
    # The hero retains its three-quarter profile.
    camera = bpy.data.objects.new(name + ' studio camera', bpy.data.cameras.new(name + ' orthographic'))
    SCENE.collection.objects.link(camera)
    SCENE.camera = camera
    camera.location = target + (Vector((0, -11, 1.7)) if basename == 'install-pilot'
                                else Vector((8, -11, 3.7)))
    camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'
    right = camera.rotation_euler.to_matrix() @ Vector((1, 0, 0))
    up = camera.rotation_euler.to_matrix() @ Vector((0, 1, 0))
    x_values = [(point - target).dot(right) for point in points]
    y_values = [(point - target).dot(up) for point in points]
    camera.location += right * ((min(x_values) + max(x_values)) / 2)
    camera.location += up * ((min(y_values) + max(y_values)) / 2)
    camera.data.ortho_scale = max((max(y_values) - min(y_values)) * (1200 / 1050) / .90,
                                  (max(x_values) - min(x_values)) / .90)
    camera.data.ortho_scale *= 1.08  # Keep full rotating-wing silhouette clear.
    camera.data.clip_end = 1000

    softbox(name + ' key', target, (4, -6, 8), 1150, 7)
    softbox(name + ' fill', target, (-6, -3, 2), 600, 7)
    softbox(name + ' rim', target, (1, 6, 7), 1100, 5)
    if '--quick-check' in sys.argv:
        return
    poster, model = PUBLIC / (basename + '.webp'), PUBLIC / (basename + '.glb')
    with tempfile.TemporaryDirectory(prefix=basename + '-') as temporary:
        png = Path(temporary) / 'poster.png'
        SCENE.render.filepath = str(png)
        bpy.context.view_layer.update()
        bpy.ops.render.render(write_still=True, scene=SCENE.name)
        subprocess.run((FFMPEG, '-hide_banner', '-loglevel', 'error', '-y',
                        '-i', str(png), '-vf', ('scale=1800:1575:flags=lanczos,format=rgba'
                                               if basename == 'install-pilot'
                                               else 'scale=1200:1050:flags=lanczos,format=rgba'),
                        '-c:v', 'libwebp', '-lossless', '1', '-compression_level', '6',
                        str(poster)), check=True)
    print(f'{name} poster: {poster} ({poster.stat().st_size} bytes), frame {FRAME}')
    if '--install-poster-only' in sys.argv:
        return

    # AO is baked directly on the flight-pose skinned mesh. No modifier is
    # applied: the authored armature, weights, UV0 and PBR maps remain live.
    with tempfile.TemporaryDirectory(prefix=basename + '-ao-') as temporary:
        bake_contact_ao(body, .36, Path(temporary) / 'pilot-ao.png', False)
        bake_contact_ao(canopy, .20, Path(temporary) / 'canopy-ao.png', True)
        SCENE['flightBounds'] = sampled_bounds(display, flight_rig, SCENE)
        bpy.ops.object.select_all(action='DESELECT')
        for obj in (*display, flight_rig, bank):
            obj.select_set(True)
        SCENE.frame_set(1)
        bpy.ops.export_scene.gltf(
            filepath=str(model), export_format='GLB', use_selection=True,
            export_animations=True, export_animation_mode='NLA_TRACKS',
            export_anim_slide_to_zero=True, export_frame_range=True,
            export_skins=True, export_morph=True, export_morph_normal=True,
            export_extras=True,
            export_image_format='WEBP',
            export_image_quality=85, export_yup=True,
        )
    validate_export(model)
    subprocess.run((NODE, str(ART / 'compress_pilots.mjs'), str(model)), check=True)
    print(f'{name} model: {model} ({model.stat().st_size} bytes), '
          f'clips {list(clips)}, bounds {dict(SCENE["flightBounds"])}')
    for obj in (*display, flight_rig, bank):
        data, obj_type = obj.data, obj.type
        bpy.data.objects.remove(obj, do_unlink=True)
        if obj_type == 'MESH':
            bpy.data.meshes.remove(data)
        elif obj_type == 'ARMATURE':
            bpy.data.armatures.remove(data)
    for action in {action for bindings in clips.values() for _, action in bindings}:
        bpy.data.actions.remove(action)
    del SCENE['flightBounds']

render_pilot(SOURCE_NAMES['boy'], 'install-pilot')
if '--install-poster-only' not in sys.argv:
    render_pilot(SOURCE_NAMES['girl'], 'hero-pilot')
