local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local RendererClass = lib.core.RendererClass

--- Render Space Renderer
--- @class RenderSpaceRenderer : RendererClass
local RenderSpaceRenderer = RendererClass:New()
lib.core.RenderSpaceRenderer = RenderSpaceRenderer

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
    control:Destroy3DRenderSpace()
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

--- Gets the normal vector of the object.
--- @param object table
--- @return number normalX, number normalY, number normalZ
function RenderSpaceRenderer.GetNormalVector(object)
    return object.Control:Get3DRenderSpaceForward()
end

-- overrides

--- Sets whether the 3D render space uses a depth buffer.
--- @param object table
--- @param useDepth boolean
function RenderSpaceRenderer.overrides.UseDepthBuffer(object, useDepth)
    object.Control:Set3DRenderSpaceUsesDepthBuffer(useDepth)
end
