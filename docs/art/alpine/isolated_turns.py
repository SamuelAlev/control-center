"""Baked brake pulls for the isolated pilots; the journey scene stays untouched."""
import math

import bpy
from mathutils import Vector

from isolated_flight import (COLUMNS, ROWS, FPS, LAST, _smooth, _solve_chain,
                             flight_lines, key_neutral_pose)

TURN_LAST = FPS + 1


def _brake_offsets(canopy, sign):
    # Both fabric skins use the same grid. Deflect the selected trailing edge,
    # not the leading edge or the inflated cell thickness.
    offsets = []
    for vertex in canopy.data.vertices:
        span = 2 * (vertex.index % COLUMNS) / (COLUMNS - 1) - 1
        chord = (vertex.index // COLUMNS % ROWS) / (ROWS - 1)
        pull = _smooth(sign * span) * _smooth((chord - .45) / .55)
        offsets.append(Vector((0, .025 * pull, -.17 * pull)))
    return offsets


def bake_brake_turns(scene, rig, canopy, cords, root, hands, source_wing,
                     center, materials, attachments, fixed_ends, source_frame):
    """Author neutral→full-pull clips, including the grip, cords and whole rig bank.

    The viewer samples their baked timelines additively over Flight idle. A
    linear wrist path and fixed palm orientation let one cord morph follow the
    entire pull exactly, rather than replacing the line mesh every frame.
    """
    scene.frame_set(1)
    owners = (rig, canopy.data.shape_keys, cords.data.shape_keys)
    clips = {'Flight idle': [(owner, owner.animation_data.action) for owner in owners]}
    pose = {bone.name: bone.matrix_basis.copy() for bone in rig.pose.bones}
    for owner in owners:
        owner.animation_data.action = None
    scene.frame_set(source_frame)
    arm_world = rig.matrix_world.copy()
    downward = arm_world.to_3x3().inverted() @ Vector((0, 0, -.30))

    bank = bpy.data.objects.new('FlightBank', None)
    scene.collection.objects.link(bank)
    for obj in (rig, canopy, cords):
        transform = obj.matrix_world.copy()
        obj.parent = bank
        obj.matrix_world = transform
    bank.animation_data_create().action = bpy.data.actions.new('Flight idle bank')
    for frame in (1, LAST):
        bank.keyframe_insert('rotation_euler', frame=frame)
    clips['Flight idle'].append((bank, bank.animation_data.action))
    bank.animation_data.action = None

    def restore():
        for owner in (*owners, bank):
            owner.animation_data.action = None
        for bone in rig.pose.bones:
            bone.matrix_basis = pose[bone.name]
        for obj in (canopy, cords):
            for key in list(obj.data.shape_keys.key_blocks)[1:]:
                key.value = 0
        bank.rotation_euler = (0, 0, 0)
        bpy.context.view_layer.update()

    for label, side, sign in (('left', 'R', 1), ('right', 'L', -1)):
        # Source L/R labels mean negative/positive X, not anatomical sides.
        # These pilots face Blender -Y (glTF +Z): their LEFT is positive X.
        restore()
        wrist = rig.pose.bones[hands[side]]
        prefix = wrist.name[:-4]
        shoulder, elbow = (rig.pose.bones[prefix + suffix]
                           for suffix in ('Arm', 'ForeArm'))
        neutral = wrist.head.copy()
        rotation = wrist.matrix.to_quaternion().copy()
        palm = Vector((0, wrist.bone.length * .78, 0))
        neutral_grip = arm_world @ (wrist.matrix @ palm)
        pole = Vector((sign * .36, .30, -.62))
        offsets = _brake_offsets(canopy, sign)
        _solve_chain(shoulder, elbow, wrist, neutral + downward, pole, rotation)
        bpy.context.view_layer.update()
        points = flight_lines(scene, root, rig, hands, source_wing, center,
                              materials, wing_offsets=offsets, positions_only=True)
        if len(points) != len(cords.data.vertices):
            raise RuntimeError('Brake pull changed the suspension topology')
        wing_key = canopy.shape_key_add(name=f'Brake {label}')
        wing_key.data.foreach_set('co', [v for vertex, offset in
                                       zip(canopy.data.vertices, offsets)
                                       for v in vertex.co + offset])
        cord_key = cords.shape_key_add(name=f'Brake {label}')
        cord_key.data.foreach_set('co', [v for point in points for v in point])
        restore()
        name = f'Turn {label}'
        clips[name] = []
        for owner in (*owners, bank):
            action = bpy.data.actions.new(name + ' ' + owner.name)
            owner.animation_data.action = action
            clips[name].append((owner, action))
        key_neutral_pose(rig, TURN_LAST)
        max_grip_gap = max_sewn_gap = max_reach_gap = 0.
        toggle_tip, toggle_anchor = fixed_ends[3 if side == 'R' else 1]
        for frame in range(1, TURN_LAST + 1):
            phase = (frame - 1) / (TURN_LAST - 1)
            pull = _smooth(phase)
            target = neutral + downward * pull
            _solve_chain(shoulder, elbow, wrist, target, pole, rotation)
            bpy.context.view_layer.update()
            max_reach_gap = max(max_reach_gap,
                                (arm_world.to_3x3() @ (wrist.head - target)).length)
            for bone in (shoulder, elbow, wrist):
                bone.keyframe_insert('rotation_quaternion', frame=frame)
            for obj in (canopy, cords):
                for key in list(obj.data.shape_keys.key_blocks)[1:]:
                    key.value = pull if key.name == f'Brake {label}' else 0
                    key.keyframe_insert('value', frame=frame)
            # The brake leads the bank. Left wing down with a small coordinated
            # heading change, around the same center as the exported envelope.
            lean = _smooth((phase - .15) / .85)
            bank.rotation_euler = (0, sign * math.radians(12) * lean,
                                   sign * math.radians(4) * lean)
            bank.keyframe_insert('rotation_euler', frame=frame)
            grip_delta = arm_world @ (wrist.matrix @ palm) - neutral_grip
            toggle = sum((cords.data.vertices[toggle_tip + k].co.lerp(
                          cord_key.data[toggle_tip + k].co, pull)
                          for k in range(6)), Vector()) / 6
            max_grip_gap = max(max_grip_gap,
                               (toggle - toggle_anchor - grip_delta).length)
            for source, tip in attachments:
                fabric = canopy.data.vertices[source].co + offsets[source] * pull
                line = sum((cords.data.vertices[tip + k].co.lerp(
                            cord_key.data[tip + k].co, pull)
                            for k in range(6)), Vector()) / 6
                max_sewn_gap = max(max_sewn_gap, (fabric - line).length)
        if max(max_grip_gap, max_sewn_gap, max_reach_gap) > .003:
            raise RuntimeError(f'{name}: grip={max_grip_gap:.6f}m, '
                               f'sewn={max_sewn_gap:.6f}m, reach={max_reach_gap:.6f}m')
        print(f'{rig.name} {name}: 0.30m brake pull, 12° bank, 4° heading; '
              f'grip={max_grip_gap:.6f}m, sewn={max_sewn_gap:.6f}m, '
              f'reach={max_reach_gap:.6f}m')
    restore()
    start = 1
    for name, bindings in clips.items():
        length = LAST if name == 'Flight idle' else TURN_LAST
        for owner, action in bindings:
            track = owner.animation_data.nla_tracks.new()
            track.name = name  # Matching names merge the owners into ONE clip.
            strip = track.strips.new(name, start, action)
            strip.action_slot = action.slots[0]
            strip.extrapolation = 'NOTHING'
        start += length
    scene.frame_start = 1
    scene.frame_end = start - 1
    scene.render.fps = FPS
    scene.frame_set(1)
    return bank, clips
