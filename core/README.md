# `core/`

This folder contains the "engine room" of **Lib3DObjects**: small, low-level modules that keep update loops running and provide helper primitives that higher-level objects/renderers build on.

Most of the library’s public-facing behavior lives in `objects/`, `objectGroups/`, and `renderer/`. Those parts create objects and groups; the modules in `core/` make sure they’re **updated every frame** (or as fast as ESO’s update loop will allow) and provide essential infrastructure (pooling + camera position).

## Overview

- **`ObjectPoolManager.lua`**
  - Maintains one or more `ZO_ObjectPool`s (keyed by *template name*).
  - Runs a single `EVENT_MANAGER:RegisterForUpdate()` loop that updates *all active objects* in all pools.
  - Tracks performance/usage metrics (update times, counts, visible objects).

- **`ObjectGroupManager.lua`**
  - Keeps a list of active **object groups**.
  - Runs an `EVENT_MANAGER:RegisterForUpdate()` loop that calls `group:Update()` on each registered group so the groups callbacks are executed.

- **`CameraHelper.lua`**
  - Creates a hidden control with a 3D render space.
  - Uses it as a bridge to query the **current camera world position**.

---
## `ObjectPoolManager` (pooling + global object update loop)

### What it’s for

Creating and destroying UI controls every frame is expensive. Lib3DObjects uses pools (`ZO_ObjectPool`) so 3D controls can be reused.

`ObjectPoolManager` provides:

- A *per-template* pool via `ObjectPoolManager:Get(templateName, ControlFactory, ControlReset)`
- A global update loop that iterates active objects in all pools and calls `object:Update()`
- Lightweight metrics you can inspect for debugging/perf

### How pools are organized

When you request a pool, the manager:

1. Creates a dedicated top-level window (`WM:CreateTopLevelWindow("Lib3DObjects_<templateName>")`) to act as the pool’s parent.
2. Creates a `ZO_ObjectPool` using your factory/reset functions.
3. Wraps `pool:AcquireObject(...)` so that acquired controls:
   - are made visible (`control:SetHidden(false)`)
   - trigger the manager’s update loop to start
   - bump `metrics.totalCreatedObjects`

### Update loop behavior

`ObjectPoolManager:StartUpdateLoop()` registers `Lib3DObjects_Update` at interval `0` (every frame).
That callback runs `ObjectPoolManager:UpdateControls()` which:

- Iterates each pool’s `pool:GetActiveObjects()`
- For each active pool entry, calls `ObjectPoolManager:UpdateObject(object.obj)`
  - Runs optional `object._updatePreHooks`
  - Calls `object:Update()` and treats its return value as "is rendered"
  - Runs optional `object._updatePostHooks`

The loop also computes timing and counters using `GetGameTimeMilliseconds()` and stores them in `ObjectPoolManager.metrics`:

- update timing: `currentUpdateTime`, `peakUpdateTime`, `averageUpdateTime`, ...
- counts: `currentRegisteredObjects`, `currentVisibleObjects`, plus peaks

### Expectations for pooled objects

Objects managed by the pool are expected to expose:

- `:Update()` → should update its underlying control state and return `true/false` to indicate whether it’s currently being rendered/visible.
- Optional hook lists:
  - `object._updatePreHooks = { function(object) ... end, ... }`
  - `object._updatePostHooks = { function(object) ... end, ... }`

> Note: the pool iterates `object.obj` (not the pool entry itself). This is because every Control has the Instance of the BaseObject or any of its Subclasses attached to it when it gets created.

---
## `ObjectGroupManager` (group update loop)

### What it’s for

Some features are easier to manage as a **group of objects** (for example, collections, composites, or higher-level constructs).

`ObjectGroupManager`:

- Stores groups in `ObjectGroupManager.groups`
- Calls `group:Update()` for each registered group while its update loop is running

### Lifecycle

- `ObjectGroupManager:Add(group)`
  - Adds the group and starts the update loop if needed.

- `ObjectGroupManager:Remove(group)`
  - Removes the group from the list.
  - auto-stop the update loop when the list becomes empty.

- `ObjectGroupManager:StartUpdateLoop()` registers `Lib3DObjects_UpdateGroupObjects` at interval `0` (every frame).

### Expectations for groups

Groups are expected to implement:

- `:Update()`

In practice, groups live in `objectGroups/` (`BaseObjectGroup.lua` and derived implementations).

---
## `CameraHelper` (camera position bridge)

### What it’s for

ESO exposes functions for working with 3D render spaces, but not to get the position of the camera. `CameraHelper` creates a hidden UI control with a 3D render space so the library can query that information.

### Key functions

- `lib.GetCameraWorldPosition()`
  - Calls `Set3DRenderSpaceToCurrentCamera(cameraControlName)`
  - Converts the render space origin to world coordinates via `GuiRender3DPositionToWorldPosition(...)`
  - Returns `(x, y, z)` in world space

## How `core/` fits into the rest of the library

A typical flow looks like:

1. A renderer / object (`renderer/`, `objects/`) acquires a control from a pool managed by `ObjectPoolManager`.
2. The object’s `:Update()` method keeps its 3D position/orientation/visibility in sync.
3. `ObjectPoolManager` runs continuously while there are active objects and calls `:Update()` for them.
4. Higher-level group abstractions (`objectGroups/`) register themselves with `ObjectGroupManager` and get updated in a similar loop.
5. Camera-dependent logic can query `lib.GetCameraWorldPosition()` (after the camera helper control exists).

## Debugging tips

- If objects don’t move/update, verify the relevant update loop is running:
  - pools: `ObjectPoolManager.isUpdating`
  - groups: `ObjectGroupManager.isUpdating`

- If performance is a concern, inspect `ObjectPoolManager.metrics`:
  - `averageUpdateTime`, `peakUpdateTime`
  - `currentRegisteredObjects`, `currentVisibleObjects`
