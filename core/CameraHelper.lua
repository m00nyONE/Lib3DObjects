-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local WM = GetWindowManager()

local cameraControlName = lib_name .. "_CameraHelperControl"
local cameraControl = nil

function lib.core.createCameraHelperControl()
    if cameraControl then return end -- Already created

    cameraControl = WM:CreateControl(cameraControlName, GuiRoot, CT_CONTROL)
    cameraControl:SetMouseEnabled(false)
    cameraControl:Create3DRenderSpace()
    cameraControl:SetHidden(true)
end

--- Returns the world position of the current camera.
--- @return number, number, number x,y,z - The world position of the camera.
function lib.GetCameraWorldPosition()
    Set3DRenderSpaceToCurrentCamera(cameraControlName)
    return GuiRender3DPositionToWorldPosition(cameraControl:Get3DRenderSpaceOrigin())
end

--function lib.GetDistanceToCamera(x, y, z)
--    local cX, cY, cZ = lib.GetCameraWorldPosition()
--    return zo_distance3D(cX, cY, cZ, x, y, z)
--end