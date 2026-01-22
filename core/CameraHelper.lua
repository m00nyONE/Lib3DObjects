-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local EM = GetEventManager()
local WM = GetWindowManager()

local cameraControlName = lib_name .. "_CameraHelperControl"
local cameraControl = nil

-- Camera properties
local cameraWorldPositionX = 0
local cameraWorldPositionY = 0
local cameraWorldPositionZ = 0
local cameraWorldRotationPitch = 0
local cameraWorldRotationYaw = 0
local cameraWorldRotationRoll = 0

--- Updates the camera properties by querying the current camera position and rotation.
--- we do this here in a loop to avoid doing it multiple times per frame when multiple objects request it.
--- @private
local function updateCameraProperties()
    Set3DRenderSpaceToCurrentCamera(cameraControlName)
    cameraWorldPositionX, cameraWorldPositionY, cameraWorldPositionZ = GuiRender3DPositionToWorldPosition(cameraControl:Get3DRenderSpaceOrigin())

    local fX, fY, fZ = GetCameraForward(SPACE_WORLD)
    cameraWorldRotationPitch = zo_atan2(fY, zo_sqrt(fX * fX + fZ * fZ)) + 0.017 -- this small offset seems to stop ESO from going completely nuts and dropping FPS like crazy. Seems like when something is facing the camera directly, it causes a lot of internal issues.
    cameraWorldRotationYaw = zo_atan2(fX, fZ) - ZO_PI
    cameraWorldRotationRoll = 0
end

--- Creates a hidden 3D render space control to help with camera position calculations.
--- This function should be called once during the library initialization.
--- @private
function lib.core.InitializeCameraHelper()
    if cameraControl then return end -- Already created

    cameraControl = WM:CreateControl(cameraControlName, GuiRoot, CT_CONTROL)
    cameraControl:SetMouseEnabled(false)
    cameraControl:Create3DRenderSpace()
    cameraControl:SetHidden(true)

    EM:RegisterForUpdate(lib_name .. "_CameraHelperUpdate", 0, updateCameraProperties)

    lib.core.InitializeCameraHelper = nil -- prevent re-initialization
end

--- Returns the world position of the current camera.
--- @return number, number, number x,y,z - The world position of the camera.
function lib.GetCameraWorldPosition()
    return cameraWorldPositionX, cameraWorldPositionY, cameraWorldPositionZ
end

--- Returns the world rotation of the current camera.
--- @return number, number, number pitch,yaw,roll - The world rotation of the camera.
function lib.GetCameraWorldRotation()
    return cameraWorldRotationPitch, cameraWorldRotationYaw, cameraWorldRotationRoll
end