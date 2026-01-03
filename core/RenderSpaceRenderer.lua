local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local ObjectPoolManager = lib.core.ObjectPoolManager

local RenderSpaceRenderer = ZO_Object:New()
lib.core.RenderSpaceRenderer = RenderSpaceRenderer

-- this is almost an exact copy of ZO_ControlPool but adapted for 3D world space controls
function RenderSpaceRenderer.ControlFactory(pool)
    local control = ZO_ObjectPool_CreateNamedControl(pool.name, pool.templateName, pool, pool.parent)
    control:SetHidden(false)
    control:Create3DRenderSpace()
    control:Set3DLocalDimensions(1, 1)
    control:Set3DRenderSpaceUsesDepthBuffer(true)
    control:SetDrawLevel(0) -- draw at the very back

    return control
end

function RenderSpaceRenderer.ControlReset(control)
    control:Destroy3DRenderSpace()
    control:SetHidden(true)
end

function RenderSpaceRenderer.UpdatePosition(object)
    local sX, sY, sZ = WorldPositionToGuiRender3DPosition(object:GetFullPosition())
    object.Control:Set3DRenderSpaceOrigin(sX, sY, sZ)
end

function RenderSpaceRenderer.UpdateRotation(object)
    local pitch, yaw, roll = object:GetFullRotation()
    object.Control:Set3DRenderSpaceOrientation(pitch, yaw, roll)
end

function RenderSpaceRenderer.GetNormalVector(object)
    return object.Control:Get3DRenderSpaceForward()
end
function RenderSpaceRenderer.UseDepthBuffer(object, useDepth)
    object.Control:Set3DRenderSpaceUsesDepthBuffer(useDepth)
end

function RenderSpaceRenderer:InitializeObject(object)
    object.ObjectPool = ObjectPoolManager:Get(object.templateControlName, self.ControlFactory, self.ControlReset)
    object.Control, object.ControlKey = object.ObjectPool:AcquireObject()
    local x, y, z = WorldPositionToGuiRender3DPosition(object:GetFullPosition())
    object.Control:Set3DRenderSpaceOrigin(x,y,z)
    object.Control.obj = object

    object.UpdatePosition = self.UpdatePosition
    object.UpdateRotation = self.UpdateRotation

    object.GetNormalVector = self.GetNormalVector
    object.UseDepthBuffer = self.UseDepthBuffer
end