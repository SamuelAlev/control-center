"""Flight-only rigging for the isolated pilot exports (never modifies the journey file).

All anchors are obtained from the evaluated source wing and the posed original
skeleton. Cords live in world coordinates until the exporter recenters them.
"""
import math

import bpy
from mathutils import Matrix, Quaternion, Vector

# Grid of each fabric skin in the packed source canopy.
COLUMNS = 37
ROWS = 9

FPS = 25
DURATION = 8
LAST = FPS * DURATION + 1


def _point_bone(bone, head, direction):
    """Set an actual pose matrix, preserving the bone's original roll and skin."""
    rest = bone.bone.matrix_local.to_quaternion()
    rest_direction = rest @ Vector((0, 1, 0))
    rotation = rest_direction.rotation_difference(direction) @ rest
    bone.matrix = Matrix.Translation(head) @ rotation.to_matrix().to_4x4()


def _solve_chain(upper, lower, end, target, pole, end_rotation=None):
    """Two-bone IK solved from the *current* skinned armature pose.

    Pose-bone matrices are writable in armature space, but a child matrix set
    before its parent is evaluated gains a spurious local translation. Update
    the parent between joints and zero those translations: the wrist/ankle
    cannot detach from its short source limb to chase an unreachable goal.
    """
    origin = upper.head.copy()
    toward = target - origin
    distance = toward.length
    if distance < 1e-6:
        toward = Vector((0, 0, -1))
        distance = 1.0
    axis = toward / distance
    a, b = upper.bone.length, lower.bone.length
    distance = max(abs(a - b) + 1e-5, min(distance, a + b - 1e-5))
    reachable = origin + axis * distance
    extension = (a * a + distance * distance - b * b) / (2 * distance)
    lateral = math.sqrt(max(0.0, a * a - extension * extension))
    pole = pole - axis * pole.dot(axis)
    if pole.length < 1e-5:
        pole = Vector((0, -1, 0)) + axis * axis.y
    pole.normalize()
    joint = origin + axis * extension + pole * lateral
    _point_bone(upper, origin, (joint - origin).normalized())
    upper.location = (0, 0, 0)
    bpy.context.view_layer.update()
    _point_bone(lower, lower.head.copy(), (reachable - lower.head).normalized())
    lower.location = (0, 0, 0)
    bpy.context.view_layer.update()
    if end is not None:
        rotation = end_rotation if end_rotation is not None else end.bone.matrix_local.to_quaternion()
        end.matrix = Matrix.Translation(end.head.copy()) @ rotation.to_matrix().to_4x4()
        end.location = (0, 0, 0)


def _smooth(t):
    t = max(0., min(1., t))
    return t*t*(3-2*t)


def rigged_pilot(skin, armature, center):
    """Duplicate the original skin, UV0/materials and armature in the flight pose."""
    rig = armature.copy()
    rig.data = armature.data.copy()
    bpy.context.scene.collection.objects.link(rig)
    rig.parent = None
    rig.animation_data_clear()  # Not a single journey action/NLA track enters the GLB.
    rig.matrix_world = Matrix.Translation(-center) @ armature.matrix_world
    rig.name = 'Flight skeleton'
    for bone in armature.pose.bones:
        dest = rig.pose.bones[bone.name]
        dest.rotation_mode = bone.rotation_mode
        dest.location = bone.location.copy()
        dest.scale = bone.scale.copy()
        dest.rotation_quaternion = bone.rotation_quaternion.copy()
        dest.rotation_euler = bone.rotation_euler.copy()
    bpy.context.view_layer.update()
    body = skin.copy()
    body.data = skin.data.copy()
    bpy.context.scene.collection.objects.link(body)
    body.parent = rig
    body.matrix_world = Matrix.Translation(-center) @ skin.matrix_world
    for modifier in body.modifiers:
        if modifier.type == 'ARMATURE':
            modifier.object = rig
    body.name = 'Pilot'
    pose_brake_grips(rig)
    close_fingers(body, rig)
    return body, rig


def pose_brake_grips(rig):
    """Lift both original skinned arms into relaxed, reachable brake grips."""
    sources = sorted(('Left', 'Right'),
                     key=lambda name: rig.pose.bones[name+'Hand'].head.x)
    for side, source in zip((-1, 1), sources):
        shoulder, elbow, wrist = (rig.pose.bones[source + suffix]
                                  for suffix in ('Arm', 'ForeArm', 'Hand'))
        grip = shoulder.head + Vector((side*.19, -.29, .09))
        # The original artist points the open hands sideways. Turn the palm
        # forward toward the brake toggle rather than gripping a riser cord.
        rotation = Quaternion(Vector((0, 0, 1)), -side*1.40) @ wrist.matrix.to_quaternion()
        wrist_origin = grip - rotation @ Vector((0, wrist.bone.length*.78, 0))
        _solve_chain(shoulder, elbow, wrist, wrist_origin,
                     Vector((side*.36, .30, -.62)), rotation)


def close_fingers(body, rig):
    """Bend the supplied fingers over a brake grip without replacing the skin.

    Meshy supplied hand skin but no finger joints. Flex the weighted digit
    vertices in two smooth proximal/distal arcs in each hand's rest frame;
    preserve the palm, source UVs, weights and original armature deformation.
    """
    to_arm = rig.matrix_world.inverted() @ body.matrix_world
    to_mesh = body.matrix_world.inverted() @ rig.matrix_world
    for source in ('Left', 'Right'):
        bone = rig.data.bones[source + 'Hand']
        local = bone.matrix_local.inverted() @ to_arm
        restore = to_mesh @ bone.matrix_local
        group = body.vertex_groups[source + 'Hand']
        for vertex in body.data.vertices:
            try:
                weight = group.weight(vertex.index)
            except RuntimeError:
                continue
            if weight < .60:
                continue
            point = local @ vertex.co
            side = 1 if source == 'Left' else -1
            thumb = (_smooth((side*point.x-.023)/.025) *
                     _smooth((point.z-.045)/.025))
            distance = point.y-.085
            if distance <= 0 and not thumb:
                continue
            if distance <= .035:
                angle = 1.20*_smooth(distance/.035)
                y = .085 + distance*math.cos(angle)
                z = point.z + distance*math.sin(angle)
            else:
                distal = distance-.035
                angle = 1.20 + 1.20*_smooth(distal/.07)
                y = .085 + .035*math.cos(1.20) + distal*math.cos(angle)
                z = point.z + .035*math.sin(1.20) + distal*math.sin(angle)
            curl = _smooth(distance/.08)
            point.x = point.x*(1-.48*curl)-side*.019*thumb
            point.y, point.z = y+.012*thumb, z
            vertex.co = vertex.co.lerp(
                restore @ point, _smooth((weight-.60)/.30))


def key_neutral_pose(rig, last):
    # NLA evaluates unkeyed channels at their base values, not the hand pose
    # left in memory by IK. Every clip must share the same neutral reference.
    for bone in rig.pose.bones:
        rotation = ('rotation_quaternion' if bone.rotation_mode == 'QUATERNION'
                    else 'rotation_euler')
        for frame in (1, last):
            for channel in ('location', rotation, 'scale'):
                bone.keyframe_insert(channel, frame=frame, group='Neutral flight pose')


def flight_idle(rig, sides):
    """Key the weighted knees and ankles for a seamless airborne idle."""
    bpy.context.view_layer.update()
    initial = {}
    for side, source in sides.items():
        prefix = source[:-4]
        thigh, shin, ankle = (rig.pose.bones[prefix + suffix]
                              for suffix in ('UpLeg', 'Leg', 'Foot'))
        initial[side] = (thigh, shin, ankle, ankle.head.copy(),
                         ankle.matrix.to_quaternion().copy())
    action = bpy.data.actions.new('Flight idle')
    rig.animation_data_create().action = action
    key_neutral_pose(rig, LAST)
    for frame in range(1, LAST+1):
        phase = math.tau * (frame-1) / (LAST-1)
        for side, (thigh, shin, ankle, neutral, rotation) in initial.items():
            sign = -1 if side == 'L' else 1
            offset = phase + (.3 if side == 'L' else 1.8)
            # Not a walking alternation: persistent soft knee flex with a
            # little different, non-synchronous settling in each suspended leg.
            target = neutral + Vector((sign*.013*math.sin(offset),
                                       -.025*math.sin(offset),
                                       .027*(1-math.cos(offset)) +
                                       .012*(1-math.cos(2*phase + (0 if sign<0 else .7)))))
            _solve_chain(thigh, shin, ankle, target,
                         Vector((sign*.18, -.9, -.05)), rotation)
            for bone in (thigh, shin, ankle):
                bone.keyframe_insert('rotation_quaternion', frame=frame,
                                     group='Airborne knees and ankles')
    action.name = 'Flight idle'
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    return action


def _tube(points, radius, vertices, faces, material_ids, material):
    """A smooth slender six-sided cord, including its exact physical endpoints."""
    points = [Vector(p) for p in points]
    first = len(vertices)
    for index, point in enumerate(points):
        tangent = (points[min(index+1, len(points)-1)] -
                   points[max(index-1, 0)]).normalized()
        u = tangent.cross(Vector((0, 1, 0)))
        if u.length < .01:
            u = tangent.cross(Vector((1, 0, 0)))
        u.normalize()
        v = tangent.cross(u).normalized()
        for spoke in range(6):
            theta = math.tau*spoke/6
            vertices.append(tuple(point + radius*(u*math.cos(theta)+v*math.sin(theta))))
        if index:
            for spoke in range(6):
                a = first+(index-1)*6+spoke
                b = first+(index-1)*6+(spoke+1)%6
                faces.append((a,b,b+6,a+6))
                material_ids.append(material)
    return first+(len(points)-1)*6


def flight_lines(scene, root, armature, hands, wing, center, line_material,
                 wing_offsets=None, positions_only=False, attachments=None,
                 fixed_ends=None):
    """Paired risers and brake lines; optional wing offsets preserve every attachment."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = wing.evaluated_get(depsgraph)
    evaluated_mesh = evaluated.to_mesh()
    try:
        def sewn(row, column):
            # Layer 1 is the lower fabric; morphs use the SAME vertex index.
            index = COLUMNS*ROWS + row*COLUMNS + column
            vertex = evaluated_mesh.vertices[index]
            point = evaluated.matrix_world @ vertex.co
            return point + (wing_offsets[index] if wing_offsets is not None else Vector())
        vertices, faces, materials = [], [], []
        root_world = root.matrix_world
        arm_world = armature.matrix_world
        for side, sign in (('L', -1), ('R', 1)):
            hand_name = hands[side]
            wrist = armature.pose.bones[hand_name]
            grip = center + arm_world @ (wrist.matrix @ Vector((0, wrist.bone.length*.78, 0)))
            spine = armature.pose.bones['Spine01']
            chest = center + arm_world @ spine.head
            # Each tensioned riser runs straight from the shoulder harness
            # to one compact A/B/C split above the shoulder, behind the hand.
            # A free-standing dogleg cannot carry a paraglider's load.
            harness = root_world @ Vector(
                (sign*.24, .04, (root_world.inverted()@chest).z-.04))
            split = root_world @ Vector((sign*.48, .08, 2.12))
            if fixed_ends is not None:
                fixed_ends.append((len(vertices), harness-center))
            _tube((harness, split), .007, vertices, faces, materials, 0)
            # A/B/C row-specific fork junctions are held by one lower and
            # two upper branches. There are no unsupported guide points.
            for row in (1, 3, 5):
                for pair in ((5,8), (11,14)):
                    columns = (18 + sign*pair[0], 18 + sign*pair[1])
                    ends = [sewn(row, column) for column in columns]
                    branch = split.lerp((ends[0]+ends[1])*.5, .72)
                    _tube((split, branch), .0033, vertices, faces, materials, 0)
                    for column, end in zip(columns, ends):
                        tip = _tube((branch, end), .0027, vertices, faces, materials, 0)
                        if attachments is not None:
                            attachments.append((COLUMNS*ROWS+row*COLUMNS+column, tip))
            # Rear trailing-edge brake cascade remains its own circuit, over
            # the outside of the face, terminating at a closed-hand toggle.
            ends = [sewn(ROWS-1, 18+sign*col) for col in (8, 12, 16)]
            brake_fork = grip.lerp(sum(ends, Vector()) / len(ends), .81)
            for col, end in zip((8, 12, 16), ends):
                tip = _tube((brake_fork, end), .0025, vertices, faces, materials, 1)
                if attachments is not None:
                    attachments.append((COLUMNS*ROWS+(ROWS-1)*COLUMNS+18+sign*col, tip))
            hand = wrist.matrix
            handle_left = center + arm_world @ (hand @ Vector((-.047, wrist.bone.length*.78, .025)))
            handle_right = center + arm_world @ (hand @ Vector((.047, wrist.bone.length*.78, .025)))
            handle_center = (handle_left+handle_right)*.5
            toggle_top = handle_center + root_world.to_quaternion() @ Vector((0, 0, .037))
            toggle_tip = _tube((brake_fork, toggle_top), .0034,
                               vertices, faces, materials, 1)
            if fixed_ends is not None:
                fixed_ends.append((toggle_tip, toggle_top-center))
            # A padded closed brake loop is actually wound around the grip,
            # not confused with either the A/B/C load-bearing risers.
            right = root_world.to_quaternion() @ Vector((sign*.029, 0, 0))
            forward = root_world.to_quaternion() @ Vector((0, -.026, 0))
            upper = root_world.to_quaternion() @ Vector((0, 0, .047))
            loop = [grip+right*math.cos(math.tau*i/12)+forward*math.sin(math.tau*i/12)
                    + upper*math.cos(math.tau*i/12) for i in range(13)]
            _tube(loop, .007, vertices, faces, materials, 2)
            _tube((toggle_top, handle_center), .0034, vertices, faces, materials, 1)
            _tube((handle_left, handle_right), .012, vertices, faces, materials, 2)
        if positions_only:
            return [Vector(point)-center for point in vertices]
        data = bpy.data.meshes.new('Suspension and brake geometry')
        data.from_pydata([Vector(point)-center for point in vertices], [], faces)
        data.update()
        obj = bpy.data.objects.new('Suspension cords', data)
        scene.collection.objects.link(obj)
        for material in line_material:
            data.materials.append(material)
        for face, material in zip(data.polygons, materials):
            face.material_index = material
            face.use_smooth = True
        return obj
    finally:
        evaluated.to_mesh_clear()


def _wind_weights(frame):
    phase = math.tau * (frame-1) / (LAST-1)
    return (.72*math.sin(phase) + .22*math.sin(2*phase),
            .56*(math.cos(phase)-1),
            .70*(math.sin(phase+.28)-math.sin(.28)) + .12*math.sin(2*phase),
            .75*math.sin(3*phase) + .18*math.sin(phase))


def _wind_modes(canopy, center):
    """Four smooth displacements, shared by both skins so cells never collapse."""
    result = [[], [], [], []]
    for vertex in canopy.data.vertices:
        x = vertex.co.x + center.x
        y = vertex.co.y + center.y
        u = max(-1., min(1., x/2.3))
        chord = max(0., min(1., (y+.68-.115*u*u)/1.5))
        tip = abs(u)**1.55
        flutter = math.sin(math.pi*2.5*u)
        offsets = (
            Vector((.012*u*tip, 0, .105*tip*(.62+.38*math.sin(math.pi*chord)**2))),
            Vector((0, .015*u*tip, .072*u*(.75+.25*chord))),
            Vector((0, .085*u*(chord-.38), .025*u*(chord-.38))),
            Vector((0, .014*chord**2*math.cos(math.pi*2.5*u),
                    .040*chord**3*flutter)),
        )
        for mode, offset in zip(result, offsets):
            mode.append(offset)
    return result


def bake_canopy_wind(scene, canopy, cords, root, rig, hands, source_wing,
                     center, materials, attachments, fixed_ends):
    """One compact morph basis on fabric AND lines, keyed in the skinned idle."""
    modes = _wind_modes(canopy, center)
    for obj in (canopy, cords):
        obj.shape_key_add(name='Basis')
    for index, offsets in enumerate(modes):
        wing_key = canopy.shape_key_add(name=f'Wind {index+1}')
        wing_key.data.foreach_set('co', [
            value for vertex, offset in zip(canopy.data.vertices, offsets)
            for value in vertex.co+offset])
        points = flight_lines(scene, root, rig, hands, source_wing, center,
                              materials, wing_offsets=offsets, positions_only=True)
        if len(points) != len(cords.data.vertices):
            raise RuntimeError('Wind line topology changed between morph poses')
        cord_key = cords.shape_key_add(name=f'Wind {index+1}')
        cord_key.data.foreach_set('co', [v for point in points for v in point])
        for key in (wing_key, cord_key):
            key.slider_min = -2
            key.slider_max = 2
            for frame, weights in enumerate((_wind_weights(f) for f in range(1, LAST+1)), 1):
                key.value = weights[index]
                key.keyframe_insert('value', frame=frame, group='Wind')
    for obj in (canopy, cords):
        keys = obj.data.shape_keys
        keys.animation_data.action.name = 'Flight idle'
    scene.frame_set(1)
    if len(attachments) != 30 or len(fixed_ends) != 4:
        raise RuntimeError(f'Expected 30 fabric tips and 4 harness/toggle ends; '
                           f'found {len(attachments)} and {len(fixed_ends)}')
    # The six vertices of each line's tip ring surround its exact sewn point.
    # Morphs blend both meshes with the same weights, so their centers must
    # coincide throughout the clip, not just in four authored extreme poses.
    line_keys = list(cords.data.shape_keys.key_blocks)[1:]
    max_gap = max_motion = max_fixed_gap = 0.
    for frame in range(1, LAST+1):
        weights = _wind_weights(frame)
        for source, tip in attachments:
            wing_point = canopy.data.vertices[source].co.copy()
            line_point = sum((cords.data.vertices[tip+spoke].co
                              for spoke in range(6)), Vector())/6
            for weight, offsets, line_key in zip(weights, modes, line_keys):
                wing_point += weight*offsets[source]
                line_point += weight*sum((
                    line_key.data[tip+spoke].co -
                    cords.data.vertices[tip+spoke].co
                    for spoke in range(6)), Vector())/6
            max_gap = max(max_gap, (wing_point-line_point).length)
        for tip, anchor in fixed_ends:
            line_point = sum((cords.data.vertices[tip+spoke].co
                              for spoke in range(6)), Vector())/6
            for weight, line_key in zip(weights, line_keys):
                line_point += weight*sum((
                    line_key.data[tip+spoke].co -
                    cords.data.vertices[tip+spoke].co
                    for spoke in range(6)), Vector())/6
            max_fixed_gap = max(max_fixed_gap, (line_point-anchor).length)
        for offsets in zip(*modes):
            displacement = sum((weight*offset for weight, offset
                                in zip(weights, offsets)), Vector())
            max_motion = max(max_motion, displacement.length)
    seam_gap = max(abs(weight) for weight in _wind_weights(LAST))
    if max_gap > .003 or max_fixed_gap > .003 or seam_gap > 1e-10:
        raise RuntimeError(f'Flight wind mismatch: fabric={max_gap:.6f}, '
                           f'harness/toggles={max_fixed_gap:.6f}, seam={seam_gap:.6f}')
    print(f'{canopy.name} wind: maximum fabric motion {max_motion:.4f}m, '
          f'{len(attachments)} canopy tips {max_gap:.6f}m, '
          f'{len(fixed_ends)} harness/toggle ends {max_fixed_gap:.6f}m, '
          f'seam {seam_gap:.8f}')
    return max_motion, max_gap


def sampled_bounds(objects, rig, scene):
    """Cover baked clips plus the bounded runtime hair displacement and banking."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    radius_squared = 0.
    hair_padding = {
        obj: obj['hairPhysics']['maxBend'] + obj['hairPhysics']['rippleRadius']
        if 'hairPhysics' in obj else 0.
        for obj in objects}
    for frame in range(scene.frame_start, scene.frame_end + 1):
        scene.frame_set(frame)
        for obj in objects:
            evaluated = obj.evaluated_get(depsgraph)
            mesh = evaluated.to_mesh()
            try:
                transform = evaluated.matrix_world
                object_radius_squared = 0.
                for vertex in mesh.vertices:
                    object_radius_squared = max(
                        object_radius_squared,
                        (transform @ vertex.co).length_squared)
                # Expanding the whole skin is conservative: only rooted hair
                # vertices move, but every bounded spring state must fit, not
                # just a few sampled gusts. Rigid pitch/bank preserve the radius.
                if hair_padding[obj]:
                    object_radius_squared = (
                        math.sqrt(object_radius_squared) + hair_padding[obj]) ** 2
                radius_squared = max(radius_squared, object_radius_squared)
            finally:
                evaluated.to_mesh_clear()
    # Fabric and cords are bank-pivot-local. Rotation preserves their radius.
    # Their morphs are affine: every intermediate pull lies inside the envelope
    # of neutral/full left/full right, even while the idle wind keeps running.
    for obj in objects:
        keys = obj.data.shape_keys
        if keys is None or 'Brake left' not in keys.key_blocks:
            continue
        wind = [keys.key_blocks[f'Wind {i}'] for i in range(1, 5)]
        brakes = [keys.key_blocks[f'Brake {side}'] for side in ('left', 'right')]
        for frame in range(1, LAST + 1):
            weights = _wind_weights(frame)
            for vertex in obj.data.vertices:
                point = vertex.co.copy()
                for weight, key in zip(weights, wind):
                    point += weight * (key.data[vertex.index].co - vertex.co)
                for key in brakes:
                    combined = point + key.data[vertex.index].co - vertex.co
                    radius_squared = max(radius_squared, combined.length_squared)
    scene.frame_set(1)
    # Cover sub-frame interpolation without padding empty AABB corners.
    return {'center': [0., 0., 0.], 'radius': math.sqrt(radius_squared) * 1.01}
