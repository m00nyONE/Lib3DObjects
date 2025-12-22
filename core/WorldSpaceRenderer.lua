local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local ObjectPoolManager = lib.core.ObjectPoolManager

local WorldSpaceRenderer = ZO_Object:New()
lib.core.WorldSpaceRenderer = WorldSpaceRenderer

-- this is almost an exact copy of ZO_ControlPool but adapted for 3D world space controls
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

function WorldSpaceRenderer.ControlReset(control)
    control:SetHidden(true)
end

function WorldSpaceRenderer.UpdatePosition(object)
    local sx, sy ,sz = GuiRender3DPositionToWorldPosition(0,0,0)
    local posX, posY, posZ = object:GetFullPosition()
    local x = (posX - sx) / 100
    local y = (posY - sy) / 100
    local z = (posZ - sz) / 100
    object.Control:SetTransformOffset(x, y, z)
end

function WorldSpaceRenderer.UpdateRotation(object)
    local pitch, yaw, roll = object:GetFullRotation()
    object.Control:SetTransformRotation(pitch, yaw, roll)
end

function WorldSpaceRenderer:InitializeObject(object)
    object.ObjectPool = ObjectPoolManager:Get(object.templateControlName, self.ControlFactory, self.ControlReset)
    object.Control, object.ControlKey = object.ObjectPool:AcquireObject()
    local x, y, z = WorldPositionToGuiRender3DPosition(object.position.x, object.position.y, object.position.z)
    object.Control:SetTransformOffset(x,y,z)
    object.Control.obj = object

    object.UpdatePosition = self.UpdatePosition
    object.UpdateRotation = self.UpdateRotation
end