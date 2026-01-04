# Lib3DObjects – ObjectGroups

`ObjectGroups` are a lightweight way to treat multiple `Objects` as a single unit.

A group does **not** render anything by itself.
Instead, it owns a list of regular Lib3DObjects `Objects` (usually subclasses of `lib.BaseObject`) and coordinates common operations like:

- moving the whole set together
- rotating the whole set around a shared reference point
- enabling/disabling or hiding/showing all members
- running group-level callbacks every frame

The group is updated by `lib.core.ObjectGroupManager` on a separate update loop from the object pool.

---

## Implemented ObjectGroups

### Base group

- `lib.BaseObjectGroup` (`objectGroups/BaseObjectGroup.lua`)
  - Core implementation: member management, group transforms, callbacks, and lifecycle.

### Helper / debug groups

These are provided as convenience groups built on top of `BaseObjectGroup`.

- `lib.BoundingBox` (`objectGroups/helper/BoundingBox.lua`)
  - Creates a dynamic axis-aligned bounding box around another group.
  - Internally spawns 8 `Point`s (corners) and 12 `Line`s (edges) and updates them each frame.

- `lib.DirectionVectors` (`objectGroups/helper/DirectionVectors.lua`)
  - Visualizes an object’s forward/up/right vectors as three arrows + labels.

- `lib.NormalVector` (`objectGroups/helper/NormalVector.lua`)
  - Visualizes an object’s normal vector as an arrow + label.

- `lib.PositionAxis` (`objectGroups/helper/PositionAxis.lua`)
  - Draws X/Y/Z axes at either:
    - an object’s position, or
    - a unit’s position (defaults to `player`)

---

## How `BaseObjectGroup` works

### 1) Construction and registration

`BaseObjectGroup:Initialize(...)` takes any number of object instances as initial members.

On initialization it:

- creates `self.groupMembers` and `self.callbacks`
- sets its internal transform state (`x/y/z`, `pitch/yaw/roll`, `scale`)
- picks an initial reference point:
  - if members exist → midpoint of all members (`GetMidpoint()`)
  - otherwise → player world position
- registers itself with `lib.core.ObjectGroupManager` so it will be updated every frame

### 2) Update loop (every frame)

A group’s `Update()` is called by `ObjectGroupManager`.

Current behavior:

- if the group is disabled (`self.isEnabled == false`) it returns early
- otherwise it computes distance to player/camera based on the group reference point (`self.x/self.y/self.z`)
- then runs every callback in `self.callbacks` with signature:
  - `callback(group, distanceToPlayer, distanceToCamera)`
  - if the callback returns `true`, it is removed

Important: the group update does **not** automatically update members.
Members are still updated by the normal object update loop (object pool manager).

### 3) Member list

A group member is expected to behave like a Lib3DObjects object (i.e. `SetEnabled`, `SetHidden`, `GetFullPosition`, `Move`, `RotateAroundPoint`, etc.).

Core APIs:

- `Add(...)` / `Remove(...)`
- `GetMembers()`
- `GetMemberCount()`

`Destroy()` will call `:Destroy()` on every member and unregister the group from `ObjectGroupManager`.

### 4) Reference point and midpoint

The group stores a *reference point* at `self.x/self.y/self.z`.

- `GetPosition()` returns the current reference point.
- `SetReferencePoint(x, y, z)` directly overwrites `self.x/self.y/self.z` without moving members.
  - This is mostly useful for “tracking” groups (helpers) where the group’s reference point is derived from something else.

`GetMidpoint()` computes the average of all members’ full positions.

Many operations (rotation, distance checks) assume the reference point is meaningful for the group.

### 5) Group transforms

#### Translation

- `SetPosition(x, y, z)`
  - moves every member by the delta between new and old reference point
  - updates the reference point

- `Move(dx, dy, dz)` and `MoveX/Y/Z(...)`
  - translates every member by the given delta
  - updates the reference point

#### Rotation

Rotation is implemented by calling `member:RotateAroundPoint(self.x, self.y, self.z, ...)` for each member.

- `SetRotation(pitch, yaw, roll)` rotates members by the *delta* from current angles
- `Rotate(dp, dy, dr)` rotates by deltas directly
- `SetRotationPitch/Yaw/Roll` and `RotatePitch/Yaw/Roll` are convenience variants

Performance note: `RotateAroundPoint()` is explicitly marked “costly” in `BaseObject`, so rotating large groups every frame can get expensive.

#### Scale

`SetScale(scale)` scales each member’s position **relative to the group reference point** and also calls `member:SetScale(scale)`.

This means scaling a group affects both:

- the distance of members from the group’s reference point, and
- each member’s own UI scale.

### 6) Visibility / enabled

- `SetEnabled(enabled)` forwards to all members and updates the group flag.
- `SetHidden(hidden)` forwards to all members.

### 7) Auto rotation

`SetAutoRotationMode(mode)` forwards the mode to all members.

At the moment the group itself doesn’t have a true “rotate group to camera” implementation; it just delegates to members.

---

## Creating a new ObjectGroup (subclassing `BaseObjectGroup`)

ObjectGroups are pure Lua. There is no XML template requirement.

Typical pattern used by the helper groups:

1. `local MyGroup = BaseObjectGroup:Subclass()`
2. `lib.MyGroup = MyGroup`
3. `function MyGroup:Initialize(...) BaseObjectGroup.Initialize(self) ... end`
4. Create member objects (`lib.Point:New(...)`, `lib.Line:New(...)`, etc.) and add them via `self:Add(member1, member2, ...)`.
5. Register callbacks with `self:AddCallback(self._UpdateSomething)`.

### Recommendations

- If your group “tracks” something (an object, another group, a unit), update `self:SetReferencePoint(...)` in a callback so distance calculations remain meaningful.
- If your group spawns objects, override `Destroy()` and nil out any references you keep, then call `BaseObjectGroup.Destroy(self)` - This will clean up all members.
- Be careful about per-frame rotations/scaling of large member sets. It’s easy to make something pretty that becomes expensive.

---

## When to use an ObjectGroup

Use a group when you want to:

- if you want to create a real 3D Object that does not only use the 2D plane of a Control and it's Children.
- move/rotate/scale several objects together
- run coordinated per-frame logic across multiple objects
- "select" a set of objects for editing purposes.
- implement reusable multi-object helpers (debug gizmos, visualizers)
- manage lifetime of a set of objects via a single `Destroy()`

If you don’t need coordination, creating plain objects is simpler and usually cheaper.

