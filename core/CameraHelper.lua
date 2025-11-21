local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local WM = GetWindowManager()

function lib.core.createCameraHelperControl()
    local name = lib_name .. "_CameraHelperControl"
    local ctrl = WM:CreateControl(name, GuiRoot, CT_CONTROL)
    ctrl:SetMouseEnabled(false)
    ctrl:Create3DRenderSpace()
    ctrl:SetHidden(true)

    lib.core.cameraControlName = name
    lib.core.cameraControl = ctrl

    lib.core.createCameraHelperControl = nil
end

--- Returns the world position of the current camera.
--- @return number, number, number x,y,z - The world position of the camera.
function lib.GetCameraWorldPosition()
    Set3DRenderSpaceToCurrentCamera(lib.core.cameraControlName)
    return GuiRender3DPositionToWorldPosition(lib.core.cameraControl:Get3DRenderSpaceOrigin())
end

--function lib.GetDistanceToCamera(x, y, z)
--    local cX, cY, cZ = lib.GetCameraWorldPosition()
--    return zo_distance3D(cX, cY, cZ, x, y, z)
--end