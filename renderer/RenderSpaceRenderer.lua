-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local RendererClass = lib.renderer.RendererClass

--- Render Space Renderer
--- @class RenderSpaceRenderer : RendererClass
local RenderSpaceRenderer = RendererClass:New()
lib.renderer.RenderSpaceRenderer = RenderSpaceRenderer

--- Factory function to create a new control.
--- @param pool table
--- @return table control
function RenderSpaceRenderer.ControlFactory(pool)
    local control = ZO_ObjectPool_CreateNamedControl(pool.name, pool.templateName, pool, pool.parent)
    control:SetHidden(false)
    control:Create3DRenderSpace()
    control:Set3DLocalDimensions(1, 1)
    control:Set3DRenderSpaceUsesDepthBuffer(true)
    control:SetDrawLevel(0) -- draw at the very back

    return control
end

--- Resets the control when released back to the pool.
--- @param control table
--- @return void
function RenderSpaceRenderer.ControlReset(control)
    --control:Destroy3DRenderSpace() -- keep the render space for reuse - once it get's destroyed on an control, it can not be created again
    control:SetHidden(true)
end

--- Updates the position of the object.
--- @param object table
--- @return void
function RenderSpaceRenderer.UpdatePosition(object)
    local sX, sY, sZ = WorldPositionToGuiRender3DPosition(object:GetFullPosition())
    object.Control:Set3DRenderSpaceOrigin(sX, sY, sZ)
end

--- Updates the rotation of the object.
--- @param object table
--- @return void
function RenderSpaceRenderer.UpdateRotation(object)
    local pitch, yaw, roll = object:GetFullRotation()
    object.Control:Set3DRenderSpaceOrientation(pitch, yaw, roll)
end
--- Sets the height of the object.
--- @param object table
--- @param height number
--- @return void
function RenderSpaceRenderer.SetHeight(object, height)
    local w, _ = object.Control:Get3DLocalDimensions()
    object.Control:Set3DLocalDimensions(w, height / 100)
end
--- Gets the height of the object.
--- @param object table
--- @return number height
function RenderSpaceRenderer.GetHeight(object)
    local _, h = object.Control:Get3DLocalDimensions()
    return h * 100
end
--- Sets the width of the object.
--- @param object table
--- @param width number
--- @return void
function RenderSpaceRenderer.SetWidth(object, width)
    local _, h = object.Control:Get3DLocalDimensions()
    object.Control:Set3DLocalDimensions(width / 100, h)
end
--- Gets the width of the object.
--- @param object table
--- @return number width
function RenderSpaceRenderer.GetWidth(object)
    local w, _ = object.Control:Get3DLocalDimensions()
    return w * 100
end
--- Sets the dimensions of the object.
--- @param object table
--- @param width number
--- @param height number
--- @return void
function RenderSpaceRenderer.SetDimensions(object, width, height)
    object.Control:Set3DLocalDimensions(width / 100, height / 100)
end
--- Gets the dimensions of the object.
--- @param object table
--- @return number, number width, height
function RenderSpaceRenderer.GetDimensions(object)
    return object.Control:Get3DLocalDimensions() * 100
end

-- overrides

--- Sets whether the 3D render space uses a depth buffer.
--- @param object table
--- @param useDepth boolean
function RenderSpaceRenderer.overrides.UseDepthBuffer(object, useDepth)
    object.Control:Set3DRenderSpaceUsesDepthBuffer(useDepth)
end
