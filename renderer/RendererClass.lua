-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local ObjectPoolManager = lib.core.ObjectPoolManager

--- 3D Renderer base class. Implements the interface required by 3D objects to render themselves.
--- additional functions can be added via the .overrides table.
--- @class RendererClass
local RendererClass = ZO_InitializingObject:Subclass()
lib.renderer.RendererClass = RendererClass

--- Initializes the RendererClass instance by creating an empty .overrides table.
--- @return void
function RendererClass:Initialize()
    self.overrides = {}
end

--- Creates a new control for the render space. MUST be overridden in subclass.
--- @param pool table
--- @return table control
function RendererClass.ControlFactory(pool)
    error("ControlFactory must be overridden in subclass")
end

--- Resets the control when released back to the pool. MUST be overridden in subclass.
--- @param control table
--- @return void
function RendererClass.ControlReset(control)
    error("ControlReset must be overridden in subclass")
end

--- Updates the position of the given object. MUST be overridden in subclass.
--- @param object table
--- @return void
function RendererClass.UpdatePosition(object)
    error("UpdatePosition must be overridden in subclass")
end
--- Updates the rotation of the given object. MUST be overridden in subclass.
--- @param object table
--- @return void
function RendererClass.UpdateRotation(object)
    error("UpdateRotation must be overridden in subclass")
end

--- Initializes the renderer for the given object.
--- @param object table
--- @return void
function RendererClass:InitializeObject(object)
    object.ObjectPool = ObjectPoolManager:Get(object.templateControlName, self.ControlFactory, self.ControlReset)
    object.Control, object.ControlKey = object.ObjectPool:AcquireObject()
    object.Control.obj = object

    object.UpdatePosition = self.UpdatePosition
    object.UpdateRotation = self.UpdateRotation

    for funcName, func in pairs(self.overrides) do
        object[funcName] = func
    end

    object:UpdatePosition()
end