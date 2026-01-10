-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local RendererClass = lib.renderer.RendererClass

--- World Space Renderer
--- @class WorldSpaceRenderer : RendererClass
local WorldSpaceRenderer = RendererClass:New()
lib.renderer.WorldSpaceRenderer = WorldSpaceRenderer

--- Factory function to create a new control.
--- @param pool table The object pool.
--- @return table The created control.
function WorldSpaceRenderer.ControlFactory(pool)
    local control = ZO_ObjectPool_CreateNamedControl(pool.name, pool.templateName, pool, pool.parent)
    control:SetHidden(false)
    control:SetSpace(SPACE_WORLD)
    control:SetAnchor(CENTER, GuiRoot, CENTER)
    control:SetScale(1)
    control:SetTransformScale(0.01)  -- default scale to 1% to represent 1m in the world
    control:SetTransformNormalizedOriginPoint(0.5,0.5)

    return control
end

--- Resets the control when released back to the pool.
--- @param control table
--- @return void
function WorldSpaceRenderer.ControlReset(control)
    control:SetHidden(true)
end

--- Updates the position of the object.
--- @param object table
--- @return void
function WorldSpaceRenderer.UpdatePosition(object)
    local sx, sy ,sz = GuiRender3DPositionToWorldPosition(0,0,0)
    local posX, posY, posZ = object:GetFullPosition()
    local x = (posX - sx) / 100
    local y = (posY - sy) / 100
    local z = (posZ - sz) / 100
    object.Control:SetTransformOffset(x, y, z)
end
--- Updates the rotation of the object.
--- @param object table
--- @return void
function WorldSpaceRenderer.UpdateRotation(object)
    local pitch, yaw, roll = object:GetFullRotation()
    object.Control:SetTransformRotation(pitch, yaw, roll)
end
--- Sets the height of the object.
--- @param object table
--- @param height number
--- @return void
function WorldSpaceRenderer.SetHeight(object, height)
    object.Control:SetHeight(height)
end
--- Gets the height of the object.
--- @param object table
--- @return number height
function WorldSpaceRenderer.GetHeight(object)
    return object.Control:GetHeight()
end
--- Sets the width of the object.
--- @param object table
--- @param width number
--- @return void
function WorldSpaceRenderer.SetWidth(object, width)
    object.Control:SetWidth(width)
end
--- Gets the width of the object.
--- @param object table
--- @return number width
function WorldSpaceRenderer.GetWidth(object)
    return object.Control:GetWidth()
end
--- Sets the dimensions of the object.
--- @param object table
--- @param width number
--- @param height number
--- @return void
function WorldSpaceRenderer.SetDimensions(object, width, height)
    object.Control:SetDimensions(width, height)
end
--- Gets the dimensions of the object.
--- @param object table
--- @return number, number width, height
function WorldSpaceRenderer.GetDimensions(object)
    return object.Control:GetDimensions()
end

-- overrides

--- Gets the forward vector of the object.
--- @param object table
--- @return number, number, number x,y,z - The forward vector of the object.
function WorldSpaceRenderer.overrides.GetForwardVector(object)
    return object.Control:GetNormal()
end