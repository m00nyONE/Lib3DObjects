# Lib3DObjects – Objects

This folder contains the concrete **Object** implementations you can render in the world using Lib3DObjects.

In Lib3DObjects an **Object** is:

- a Lua class (usually a subclass of `lib.BaseObject`) and
- a UI control (a virtual template defined in `objects/templates.xml`) that the renderer positions/rotates in 3D.

An object is updated every frame by the library’s object pool / update loop. The update decides whether the object should be rendered (distance checks, visibility flags), runs any registered callbacks, applies auto-rotation (optional), and then tells the renderer to apply position/rotation to the underlying control.

---

## Implemented objects

### Core objects

- `lib.BaseObject` (`objects/BaseObject.lua`)
  - Base class for all objects.

- `lib.Point` (`objects/Point.lua`)
  - A point marker with an icon (`plus.dds`), an optional label, and an optional position readout.

- `lib.Line` (`objects/Line.lua`)
  - A 3D line between two world positions. Internally it keeps start/end points and sizes/rotates the control accordingly.

- `lib.Text` (`objects/Text.lua`)
  - A world-space label.

- `lib.Texture` (`objects/Texture.lua`)
  - A world-space textured quad.

- `lib.Texture3D` (`objects/Texture3D.lua`)
  - A texture rendered via a **3D render space** (`RenderSpaceRenderer`) rather than world-space transform.

### Marker objects

Markers are higher-level “badge” objects built on top of `lib.Marker`.

- `lib.Marker` (`objects/markers/Marker.lua`)
  - A textured background + centered text + optional looping texture animation.

- `lib.GroundMarker` (`objects/markers/GroundMarker.lua`)
  - A marker laid flat on the ground (rotation set to `-ZO_PI/2`) with auto-rotation disabled.

- `lib.FloatingMarker` (`objects/markers/FloatingMarker.lua`)
  - A marker hovering above a world position (Y offset) that rotates to face the camera.

- `lib.UnitMarker` (`objects/markers/UnitMarker.lua`)
  - A floating marker attached to a `unitTag`. Repositions itself every update via a pre-hook.
  - Includes a priority system so only the highest-priority marker for a unit stays visible.

### “Mechanic” marker variants

These are convenience objects that start a counter and then self-destroy when it completes.

- `lib.GroundMarkerMechanic` (`objects/markers/GroundMarkerMechanic.lua`)
- `lib.FloatingMarkerMechanic` (`objects/markers/FloatingMarkerMechanic.lua`)
- `lib.UnitMarkerMechanic` (`objects/markers/UnitMarkerMechanic.lua`)

---

## How `BaseObject` works

### 1) Construction = template + properties + renderer

All objects are initialized via `BaseObject:Initialize(templateControlName, properties, Renderer)`.

- `templateControlName` is the **virtual template name** from `objects/templates.xml` (example: `Lib3DObjects_Text`) or anything you built on your own.
- `properties` is typically the object itself (most objects pass `self`) so that any fields you set before/after initialization can be applied.
- `Renderer` determines which Renderer to use. Defaults to `lib.renderer.WorldSpaceRenderer` as it is the only one which supports all Controls and not only textures like the `RenderSpaceRendere`.

During initialization, `BaseObject`:

- sets default state (`position`, `rotation`, `alpha`, `scale`, draw/fade distances, etc.)
- copies `properties` onto `self`
- stores `templateControlName`
- calls `Renderer:InitializeObject(self)` which wires:
  - `self.ObjectPool` + `self.ControlKey`
  - `self.Control` (the actual UI control instance)
  - and installs renderer-backed implementations for:
    - `self:UpdatePosition()`
    - `self:UpdateRotation()`
    - (and some renderer-specific overrides)

### 2) Update loop (every frame)

`BaseObject:Update()` is what the library calls each frame.

The update does (in this order):

1. **Enabled check**: if disabled, hides the control and returns.
2. **Distance cull**: if far beyond draw distance + fade range, hides and returns.
3. **Callbacks**: runs callbacks stored in `self.callbacks`.
   - callback signature is: `callback(object, distanceToPlayer, distanceToCamera)`
   - if the callback returns `true`, it gets removed.
4. **Alpha & fading**:
   - fades out when beyond draw distance (far fade)
   - fades out when too close to camera (near fade)
5. **Auto-rotation** (optional):
   - `AUTOROTATE_CAMERA` → `RotateToCamera()`
   - `AUTOROTATE_PLAYER_HEADING` → `RotateToPlayerHeading()`
   - `AUTOROTATE_PLAYER_POSITION` → `RotateToPlayerPosition()`
   - `AUTOROTATE_GROUND` → `RotateToGroundNormal()`
6. **Renderer updates**:
   - `self:UpdatePosition()`
   - `self:UpdateRotation()`
7. **Hidden flag**: if `isHidden` is set, hides and returns.

If all checks pass, it shows the control and returns `true` (meaning “rendered this frame”).

### 3) Position & rotation model

`BaseObject` stores transforms in tables:

- `self.position`: `x/y/z` plus
  - `offsetX/Y/Z` (relative positioning offset)
  - `animationOffsetX/Y/Z` (for animation systems)
- `self.rotation`: `pitch/yaw/roll` plus
  - `animationOffsetPitch/Yaw/Roll`

Most code should use:

- `GetFullPosition()` = base position + offsets
- `GetFullRotation()` = base rotation + animation offsets

Renderers consume the *full* values.

### 4) Callbacks and hooks

There are two extension points:

- **Callbacks** (`AddCallback`, `RemoveCallback`): run during `Update()` after distance checks.
- **Update pre/post hooks** (`CreateUpdatePreHook`, `CreateUpdatePostHook`):
  - these are intended for things that must be run regardless of enabled/visibility checks
  - example: `UnitMarker` uses a pre-hook to follow a unit every frame

### 5) Destroy lifecycle

Calling `:Destroy()`:

- clears callbacks
- optionally adds `onDestroyAnimation` into the callback list
- releases the underlying control back to the object pool when callbacks finish

Concrete objects typically override `Destroy()` to reset template-specific state (textures, sizes, text) and then call `BaseObject.Destroy(self)`.

---

## Creating a new object (subclassing `BaseObject`)

There are two parts:

1. a Lua class (subclass), and
2. a matching virtual UI template.

### Step 1: Add a virtual template

Create a new virtual control with a unique name, for example `My3DAddon_MyObjectTemplate`.

Guidelines:

- If the object is NOT a `Texture`, you can NOT use the RenderSpaceRenderer.
- Try keeping sizes accordingly. 100 = 1m in world space (because of the 0.01 scale factor).
- Use anchors/origins that make sense for 3D positioning (usually center-middle).
- Make sure the template has a stable child naming scheme if your Lua code uses `GetNamedChild()`.

### Step 2: Create the Lua subclass

Pattern used throughout this library:

- `local MyObject = BaseObject:Subclass()`
- `lib.MyObject = MyObject`
- `function MyObject:Initialize(...) BaseObject.Initialize(self, "TemplateName", self[, Renderer]) ... end`

Key points:

- Always call `BaseObject.Initialize(...)` first so `self.Control` exists.
- Pass the template name you created.
- Optionally pass a renderer:
  - omit it for world-space (`WorldSpaceRenderer` default)
  - use `RenderSpaceRenderer` if your control needs 3D render space (`Create3DRenderSpace`)

### Step 3: Implement object-specific API via the control

After initialization, you should cache references to child controls, so you do not need to call GetNamedChild() repeatedly.:

- `self.SomeChild = self.Control:GetNamedChild("_SomeChild")`

Then implement methods that wrap UI calls:

- textures → `SetTexture`, `SetTextureCoords`, `SetColor`
- labels → `SetText`, `SetFont`
- sizing → `SetDimensions`, `SetWidth/Height`

### Step 4: (Optional) Add per-frame behavior

If your object has derived state (like `Line`), add callbacks:

- `self:AddCallback(self._SomeUpdateCallback)`

Remember:

- callbacks are removed automatically only if they return `true` (this is useful for one-time updates or animations)
- distance values are passed to callbacks so you can work with them.

If you truly need logic to run even when disabled or culled, use pre/post hooks.

### Step 5: Override `Destroy()` to reset state

Because objects are pooled, always reset properties you changed, then call `BaseObject.Destroy(self)`.
Think about what needs to be reset for your specific object. If you for example forget to reset a color or texture, the next user of that object instance may see the wrong thing.

Examples in this folder:

- `Text:Destroy()` resets text, font, dimensions
- `Texture:Destroy()` clears texture, resets size/scale
- `Marker:Destroy()` stops animation, clears textures/text

---

## Notes on renderers

- **WorldSpaceRenderer** (default)
  - uses world-space transform APIs (`SetTransformOffset`, `SetTransformRotation`, etc.)
  - default transform scale is set to `0.01` so that 1 unit ≈ 1 meter (via centimeters-to-meters conversion in update)

- **RenderSpaceRenderer**
  - creates a `3DRenderSpace` on the control and sets its origin/orientation each update
  - useful when you need depth-buffered rendering behavior
  - This only works with Texture controls, because of ESO API limitations.

