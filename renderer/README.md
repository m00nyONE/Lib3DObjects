# Renderer (`Lib3DObjects/renderer`)

In **Lib3DObjects**, renderers are the layer that "attaches" a `BaseObject` to the respective ESO UI 3D technique.

A `BaseObject` only knows its *data* (position, rotation, etc.).
The renderer is responsible for turning that into the correct API calls on the underlying UI control each frame.

At the moment, the library ships with two renderers:

- **`WorldSpaceRenderer`**: renders controls in world space (`control:SetSpace(SPACE_WORLD)`).
- **`RenderSpaceRenderer`**: renders via a `3DRenderSpace` (`control:Create3DRenderSpace()`).

## Why renderers are interchangeable

Renderers are intentionally **interchangeable**, because:

- different rendering modes/techniques in ESO require different API calls,
- some techniques (e.g. render space) come with extra features (depth buffer, draw level, local dimensions ...),
- you can experiment/optimize without having to touch the object classes (`Point`, `Line`, `Text`, `Texture3D`, ...).

When creating an object you can pass the renderer in `BaseObject:Initialize(templateControlName, properties, Renderer)`.
If no renderer is provided, `WorldSpaceRenderer` is used by default.

## Renderer interface (required functions)

Every renderer is based on [renderer/RendererClass.lua](RendererClass.lua).
For a renderer to work, it **must** provide these functions (otherwise `RendererClass` will throw an error):

### 1) `ControlFactory(pool) -> control`

Creates a new UI control for the object pool.

- Typically created from an XML template via `ZO_ObjectPool_CreateNamedControl(...)`.
- Must configure the control so it renders correctly in "your space".

### 2) `ControlReset(control)`

Called when a control is returned to the pool.

- Reset everything you initialized in `ControlFactory` & during usage.
- For render space, it’s important to destroy the render space again (`Destroy3DRenderSpace()`), so no resources "stick around".

### 3) `UpdatePosition(object)`

Called each frame (or whenever the object gets updated).

Input:

- `object` is the `BaseObject` instance / subclass instance.

Processing:
To get the 3D Position of an object, use:
- `object:GetFullPosition()` returns the position including offsets/animation offsets.

Output:

- Must set the *control position* so the object is rendered at the correct location.

### 4) `UpdateRotation(object)`

Called each frame (or whenever the object gets updated).

Input:
- `object` is the `BaseObject` instance / subclass instance.

Processing:
To get the 3D Rotation of an object, use:
- `object:GetFullRotation()` returns the rotation including offsets/animation offsets.

Output:

- Must set the *control orientation* so the object is rendered with the correct rotation.

## How the renderer gets "bound" to an object

`RendererClass:InitializeObject(object)` does the wiring:

- gets a control from the `ObjectPoolManager` (pool per `templateControlName` + renderer factory/reset),
- attaches references (`object.Control`, `object.ControlKey`, `object.ObjectPool`),
- sets the methods on the object:
  - `object.UpdatePosition = self.UpdatePosition`
  - `object.UpdateRotation = self.UpdateRotation`
- installs overrides (see below),
- calls `object:UpdatePosition()` once initially.

Important: In the current implementation, `UpdatePosition`/`UpdateRotation` are **functions on the renderer "singleton"** that get copied onto the object as methods.
Therefore the expected signature is `UpdatePosition(object)` (not `UpdatePosition(self)`).

## The override system (`RendererClass.overrides`)

Renderers can provide additional object methods, or replace existing ones.

Mechanics:

- `RendererClass:Initialize()` creates `self.overrides = {}`.
- Subclasses add functions there: `MyRenderer.overrides.<FunctionName> = function(object, ...) ... end`.
- During `InitializeObject`, all overrides are bluntly copied onto the object:

  - `object[funcName] = func`

This means:

- Overrides are renderer-specific and are installed **per object**.
- An override can:
  - add new "feature" methods (e.g. `UseDepthBuffer` in `RenderSpaceRenderer`),
  - replace/optimize existing object logic (e.g. `GetForwardVector` in `WorldSpaceRenderer`).

### Examples from the library

- `RenderSpaceRenderer.overrides.UseDepthBuffer(object, useDepth)`
  - wraps `object.Control:Set3DRenderSpaceUsesDepthBuffer(useDepth)`.

- `WorldSpaceRenderer.overrides.GetForwardVector(object)`
  - uses `object.Control:GetNormal()` instead of the more expensive Euler->matrix math from `BaseObject`.

### Name conflicts / best practices

Because overrides are assigned directly to `object[funcName]`:

- identical names overwrite existing functions on the object,
- for "optional features", prefer clearly named methods (e.g. `UseDepthBuffer`, `SetRenderSpaceDrawLevel`, …),
- if you intentionally override something, document it in your renderer.

## Adding a new renderer (step-by-step)

1) Import `RendererClass` and create an instance:

   - `local RendererClass = Lib3DObjects.renderer.RendererClass`
   - `local MyRenderer = RendererClass:New()`

2) Implement the required functions:

   - `MyRenderer.ControlFactory(pool)`
   - `MyRenderer.ControlReset(control)`
   - `MyRenderer.UpdatePosition(object)`
   - `MyRenderer.UpdateRotation(object)`

3) Optional: populate `MyRenderer.overrides`.
4) Pass the renderer when creating an object:

   - `BaseObject:Initialize(template, props, lib.renderer.MyRenderer)`

## Minimal example (skeleton)

```lua
local RendererClass = Lib3DObjects.renderer.RendererClass

--- @class MyRenderer : RendererClass
local MyRenderer = RendererClass:New()
lib.renderer.MyRenderer = MyRenderer

function MyRenderer.ControlFactory(pool)
    local control = ZO_ObjectPool_CreateNamedControl(pool.name, pool.templateName, pool, pool.parent)
    -- Configure control for your rendering technique here
    return control
end

function MyRenderer.ControlReset(control)
    -- Reset/hide/destroy resources
    control:SetHidden(true)
end

function MyRenderer.UpdatePosition(_)
    -- values: object:GetFullPosition()
    -- Convert and apply to control
end

function MyRenderer.UpdateRotation(_)
    -- values: object:GetFullRotation()
    -- Apply to control
end

-- optional renderer-specific methods (added to the object during InitializeObject)
MyRenderer.overrides.MyFeature = function()
    -- ...
end
```

## Troubleshooting

- if you get the error: **`... must be overridden in subclass`**: you didn’t implement one of the required functions.
- **Object is not visible**:
  - check `object:SetEnabled(true)` and `object:SetHidden(false)`,
  - check draw distance (`SetDrawDistance...`) and fade-out distances,
  - check whether your renderer configured the control correctly (space/anchor/render space created, etc.).
- **Rotation/vectors are "wrong"**:
  - consider whether you need an override like `GetForwardVector` (world space can use `control:GetNormal()`).
