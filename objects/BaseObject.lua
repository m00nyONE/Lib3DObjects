local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local WorldSpaceRenderer = lib.renderer.WorldSpaceRenderer
local RenderSpaceRenderer = lib.renderer.RenderSpaceRenderer

local BaseObject = ZO_InitializingObject:Subclass()
lib.BaseObject = BaseObject

local AUTOROTATE_NONE = lib.AUTOROTATE_NONE
local AUTOROTATE_CAMERA = lib.AUTOROTATE_CAMERA
local AUTOROTATE_PLAYER_HEADING = lib.AUTOROTATE_PLAYER_HEADING
local AUTOROTATE_PLAYER_POSITION = lib.AUTOROTATE_PLAYER_POSITION
local AUTOROTATE_GROUND = lib.AUTOROTATE_GROUND

local up = { 0, 1, 0 }
local right = { 1, 0, 0 }
local forward = { 0, 0, 1 }
local EulerToMatrix = lib.util.EulerToMatrix
local MatrixToEuler = lib.util.MatrixToEuler
local MultiplyMatrices3x3 = lib.util.MultiplyMatrices3x3
local MultiplyMatrixVector3x3 = lib.util.MultiplyMatrixVector3x3

local EM = GetEventManager()

--- @param templateControlName string
--- @param properties table
--- @param Renderer table optional, defaults to WorldSpaceRenderer
--- @return BaseObject
function BaseObject:Initialize(templateControlName, properties, Renderer)
    Renderer = Renderer or WorldSpaceRenderer

    self.isEnabled = true
    self.isHidden = false
    self.autoRotationMode = AUTOROTATE_NONE
    self.position = {
        x = 0,
        y = 0,
        z = 0,
        offsetX = 0, -- offset for positioning relative to another object
        offsetY = 0, -- offset for positioning relative to another object
        offsetZ = 0, -- offset for positioning relative to another object
        animationOffsetX = 0, -- offset for animations
        animationOffsetY = 0, -- offset for animations
        animationOffsetZ = 0, -- offset for animations
    }
    self.rotation = {
        pitch = 0,
        yaw = 0,
        roll = 0,
        animationOffsetPitch = 0,
        animationOffsetYaw = 0,
        animationOffsetRoll = 0,
    }
    self.alpha = 1
    self.drawDistance = 100 * 100 -- meters to draw distance
    self.fadeOutDistanceFar = 10 * 100 -- meters to fade out after drawDistance is reached
    self.fadeOutDistanceNear = 5 * 100 -- meters to fade out when getting closer to camera

    self.scale = 1.0
    --self.drawLevel = 0
    self.callbacks = {}
    self.onDestroyAnimation = nil
    self._Id = string.match(tostring(self), "0%x+")
    self.creationTimestamp = GetGameTimeMilliseconds()

    for key, value in pairs(properties or {}) do
        self[key] = value
    end

    self.templateControlName = templateControlName
    Renderer:InitializeObject(self)

    self.Initialize = nil -- remove initialization function after first call
end
--- Destroys the object, optionally playing an onDestroyAnimation before actual destruction.
--- @return void
function BaseObject:Destroy()
    -- remove all references to callbacks
    ZO_ClearTable(self.callbacks)

    -- this is the actual destroy function called after the onDestroyAnimation (if any) is finished
    self._onDestroy = function()
        self.Control.obj = nil
        self.ObjectPool:ReleaseObject(self.ControlKey)
        self = nil
    end

    -- if there is an onDestroyAnimation, add it to the callbacks list
    if self.onDestroyAnimation then
        table.insert(self.callbacks, self.onDestroyAnimation)
    else
        -- destroy instantly if there is no animation
        self._onDestroy()
        return
    end

    -- check when all callbacks are done
    local eventName = string.format("%s_OnDestroy_%s", lib_name, self._Id)
    EM:RegisterForUpdate(eventName, 10 , function()
        -- call the actual destroy function after the animation has finished
        if #self.callbacks == 0 then
            EM:UnregisterForUpdate(eventName)
            self._onDestroy()
        end
    end)
end
--- set onDestroy animation callback
--- @param callback function
--- @return void
function BaseObject:SetOnDestroyAnimation(callback)
    self.onDestroyAnimation = callback
end
--- clear onDestroy animation callback
--- @return void
function BaseObject:ClearOnDestroyAnimation()
    self.onDestroyAnimation = nil
end
--- update position of the object - to be implemented by RendererClass
--- @return void
function BaseObject:UpdatePosition()
    error("UpdatePosition needs to be implemented by a RendererClass")
end
--- update rotation of the object - to be implemented by RendererClass
--- @return void
function BaseObject:UpdateRotation()
    error("UpdateRotation needs to be implemented by a RendererClass")
end
--- update function called every frame by the ObjectPoolManager
--- @return boolean isRendered
function BaseObject:Update()
    if not self:IsEnabled() then
        self.Control:SetHidden(true)
        return false
    end

    local drawDistance = self.drawDistance
    local fadeOutDistanceFar = self.fadeOutDistanceFar

    local distance = self:GetDistanceToPlayer()
    if distance > (drawDistance + fadeOutDistanceFar) then
        self.Control:SetHidden(true)
        return false
    end
    local distanceToCamera = self:GetDistanceToCamera()

    for _, callback in ipairs(self.callbacks) do
        local finished = callback(self, distance, distanceToCamera)
        if finished then self:RemoveCallback(callback) end
    end

    if distance > drawDistance then
        local alpha = self.alpha * (1.0 - ((distance - drawDistance) / fadeOutDistanceFar))
        self.Control:SetAlpha(alpha)
    else
        self.Control:SetAlpha(self.alpha)
    end

    if distanceToCamera < self.fadeOutDistanceNear then
        -- fade out when getting closer based on distance. never go over the current max alpha
        self.Control:SetAlpha(math.min(self.alpha, self.alpha * (distanceToCamera / self.fadeOutDistanceNear)))
    end

    if self.autoRotationMode == AUTOROTATE_CAMERA then
        self:RotateToCamera()
    elseif self.autoRotationMode == AUTOROTATE_PLAYER_HEADING then
        self:RotateToPlayerHeading()
    elseif self.autoRotationMode == AUTOROTATE_PLAYER_POSITION then
        self:RotateToPlayerPosition()
    elseif self.autoRotationMode == AUTOROTATE_GROUND then
        self:RotateToGroundNormal()
    end

    self:UpdatePosition()
    self:UpdateRotation()

    if self.isHidden then
        self.Control:SetHidden(true)
        return false
    end

    self.Control:SetHidden(false)
    return true
end
--- creates a pre hook for the update function. WARNING! This will always be executed before every update call! It does not check if the object is enabled or not or if it should even be rendered!
--- @param preHookFunction function
--- @return void
function BaseObject:CreateUpdatePreHook(preHookFunction)
    if not self._updatePreHooks then
        self._updatePreHooks = {}
    end

    table.insert(self._updatePreHooks, preHookFunction)
end
--- removes a pre hook for the update function
--- @param preHookFunction function
--- @return void
function BaseObject:RemoveUpdatePreHook(preHookFunction)
    if not self._updatePreHooks then return end

    for i, hook in ipairs(self._updatePreHooks) do
        if hook == preHookFunction then
            table.remove(self._updatePreHooks, i)
            break
        end
    end

    if #self._updatePreHooks == 0 then
        self._updatePreHooks = nil
    end
end
--- creates a post hook for the update function. WARNING! This will always be executed after every update call! It does not check if the object is enabled or not or if it should even be rendered!
--- @param postHookFunction function
--- @return void
function BaseObject:CreateUpdatePostHook(postHookFunction)
    if not self._updatePostHooks then
        self._updatePostHooks = {}
    end

    table.insert(self._updatePostHooks, postHookFunction)
end
--- removes a post hook for the update function
--- @param postHookFunction function
--- @return void
function BaseObject:RemoveUpdatePostHook(postHookFunction)
    if not self._updatePostHooks then return end

    for i, hook in ipairs(self._updatePostHooks) do
        if hook == postHookFunction then
            table.remove(self._updatePostHooks, i)
            break
        end
    end

    if #self._updatePostHooks == 0 then
        self._updatePostHooks = nil
    end
end

--- set enabled/disabled - This will completely skip the update function when disabled
--- @param enabled boolean
--- @return void
function BaseObject:SetEnabled(enabled)
    self.isEnabled = enabled or true
end
--- check if enabled
--- @return boolean
function BaseObject:IsEnabled()
    return self.isEnabled
end
--- set hidden/shown - This will only hide the object but still run the update function
--- @param hidden boolean
--- @return void
function BaseObject:SetHidden(hidden)
    self.isHidden = hidden or false
end
--- check if hidden
--- @return boolean
function BaseObject:IsHidden()
    return self.isHidden
end
--- get distance to camera
--- @return number distance
function BaseObject:GetDistanceToCamera()
    local camX, camY, camZ = lib.GetCameraWorldPosition()
    local distance = zo_distance3D(camX, camY, camZ, self:GetFullPosition())
    return distance
end
--- get distance to unit
--- @param unitTag string
--- @return number distance
function BaseObject:GetDistanceToUnit(unitTag)
    local _, playerX, PlayerY, playerZ = GetUnitRawWorldPosition(unitTag)
    local distance = zo_distance3D(playerX, PlayerY, playerZ, self:GetFullPosition())
    return distance
end
--- get distance to local player
--- @return number distance
function BaseObject:GetDistanceToPlayer()
    return self:GetDistanceToUnit('player')
end
--- get scale of the object
--- @return number scale
function BaseObject:GetScale()
    return self.scale
end
--- set scale of the object
--- @param scale number
--- @return void
function BaseObject:SetScale(scale)
    self.scale = scale
    self.Control:SetScale(self.scale)
end
--- get alpha of the object
--- @return number alpha
function BaseObject:GetAlpha()
    return self.alpha
end
--- get scale of the object
--- @return number scale
function BaseObject:SetAlpha(alpha)
    self.alpha = alpha
    self.Control:SetAlpha(self.alpha)
end
--- set draw distance in centimeters
--- @param distance number
--- @return void
function BaseObject:SetDrawDistance(distance)
    self.drawDistance = distance
end
--- get draw distance in centimeters
--- @return number distance
function BaseObject:GetDrawDistance()
    return self.drawDistance
end
--- set draw distance in meters
--- @param distance number
--- @return void
function BaseObject:SetDrawDistanceMeters(distance)
    self.drawDistance = distance * 100 -- meters to centimeters
end
--- get draw distance in meters
--- @return number distance
function BaseObject:GetDrawDistanceMeters()
    return self.drawDistance / 100
end

-- positions
--- get main position
--- @return number, number, number x, y, z
function BaseObject:GetPosition()
    return self.position.x, self.position.y, self.position.z
end
--- get full position (including offsets)
--- @return number, number, number x, y, z
function BaseObject:GetFullPosition()
    return self.position.x + self.position.offsetX + self.position.animationOffsetX,
           self.position.y + self.position.offsetY + self.position.animationOffsetY,
           self.position.z + self.position.offsetZ + self.position.animationOffsetZ
end
--- set main position
--- @param x number
--- @param y number
--- @param z number
--- @return void
function BaseObject:SetPosition(x, y, z)
    self.position.x = x or self.position.x
    self.position.y = y or self.position.y
    self.position.z = z or self.position.z
end
--- set X position
--- @param x number
--- @return void
function BaseObject:SetPositionX(x)
    self.position.x = x or self.position.x
end
--- set Y position
--- @param y number
--- @return void
function BaseObject:SetPositionY(y)
    self.position.y = y or self.position.y
end
--- set Z position
--- @param z number
--- @return void
function BaseObject:SetPositionZ(z)
    self.position.z = z or self.position.z
end
--- get position offsets
--- @return number, number, number offsetX, offsetY, offsetZ
function BaseObject:GetPositionOffset()
    return self.position.offsetX, self.position.offsetY, self.position.offsetZ
end
--- set position offsets
--- @param offsetX number
--- @param offsetY number
--- @param offsetZ number
--- @return void
function BaseObject:SetPositionOffset(offsetX, offsetY, offsetZ)
    self.position.offsetX = offsetX or self.position.offsetX
    self.position.offsetY = offsetY or self.position.offsetY
    self.position.offsetZ = offsetZ or self.position.offsetZ
end
--- set position offset X
--- @param offsetX number
--- @return void
function BaseObject:SetPositionOffsetX(offsetX)
    self.position.offsetX = offsetX or self.position.offsetX
end
--- set position offset Y
--- @param offsetY number
--- @return void
function BaseObject:SetPositionOffsetY(offsetY)
    self.position.offsetY = offsetY or self.position.offsetY
end
--- set position offset Z
--- @param offsetZ number
--- @return void
function BaseObject:SetPositionOffsetZ(offsetZ)
    self.position.offsetZ = offsetZ or self.position.offsetZ
end
--- get animation position offsets
--- @return number, number, number offsetX, offsetY, offsetZ
function BaseObject:GetAnimationOffset()
    return self.position.animationOffsetX, self.position.animationOffsetY, self.position.animationOffsetZ
end
--- set animation position offsets
--- @param offsetX number
--- @param offsetY number
--- @param offsetZ number
--- @return void
function BaseObject:SetAnimationOffset(offsetX, offsetY, offsetZ)
    self.position.animationOffsetX = offsetX or self.position.animationOffsetX
    self.position.animationOffsetY = offsetY or self.position.animationOffsetY
    self.position.animationOffsetZ = offsetZ or self.position.animationOffsetZ
end
--- set animation position offset X
--- @param offsetX number
--- @return void
function BaseObject:SetAnimationOffsetX(offsetX)
    self.position.animationOffsetX = offsetX
end
--- set animation position offset Y
--- @param offsetY number
--- @return void
function BaseObject:SetAnimationOffsetY(offsetY)
    self.position.animationOffsetY = offsetY
end
--- set animation position offset Z
--- @param offsetZ number
--- @return void
function BaseObject:SetAnimationOffsetZ(offsetZ)
    self.position.animationOffsetZ = offsetZ
end

-- move position
--- move object by given x, y, z offsets. The offsets are added to the current position and are absolute in the end.
--- @param offsetX number
--- @param offsetY number
--- @param offsetZ number
--- @return void
function BaseObject:Move(offsetX, offsetY, offsetZ)
    self.position.x = (self.position.x or 0) + (offsetX or 0)
    self.position.y = (self.position.y or 0) + (offsetY or 0)
    self.position.z = (self.position.z or 0) + (offsetZ or 0)
end
--- move object by given x offset. The offset is added to the current position and is absolute in the end.
--- @param offsetX number
--- @return void
function BaseObject:MoveX(offsetX)
    self.position.x = (self.position.x or 0) + (offsetX or 0)
end
--- move object by given y offset. The offset is added to the current position and is absolute in the end.
--- @param offsetY number
--- @return void
function BaseObject:MoveY(offsetY)
    self.position.y = (self.position.y or 0) + (offsetY or 0)
end
--- move object by given z offset. The offset is added to the current position and is absolute in the end.
--- @param offsetZ number
--- @return void
function BaseObject:MoveZ(offsetZ)
    self.position.z = (self.position.z or 0) + (offsetZ or 0)
end
--- move object by given x, y, z animation offsets. The offsets are added to the current animation offsets and are absolute in the end.
--- @param offsetX number
--- @param offsetY number
--- @param offsetZ number
--- @return void
function BaseObject:MoveOffset(offsetX, offsetY, offsetZ)
    self.position.offsetX = (self.position.offsetX or 0) + (offsetX or 0)
    self.position.offsetY = (self.position.offsetY or 0) + (offsetY or 0)
    self.position.offsetZ = (self.position.offsetZ or 0) + (offsetZ or 0)
end
--- move object by given x animation offset. The offset is added to the current animation offset and is absolute in the end.
--- @param offsetX number
--- @return void
function BaseObject:MoveOffsetX(offsetX)
    self.position.offsetX = (self.position.offsetX or 0) + (offsetX or 0)
end
--- move object by given y animation offset. The offset is added to the current animation offset and is absolute in the end.
--- @param offsetY number
--- @return void
function BaseObject:MoveOffsetY(offsetY)
    self.position.offsetY = (self.position.offsetY or 0) + (offsetY or 0)
end
--- move object by given z animation offset. The offset is added to the current animation offset and is absolute in the end.
--- @param offsetZ number
--- @return void
function BaseObject:MoveOffsetZ(offsetZ)
    self.position.offsetZ = (self.position.offsetZ or 0) + (offsetZ or 0)
end
--- move object by given x, y, z animation offsets. The offsets are added to the current animation offsets and are absolute in the end.
--- @param offsetX number
--- @param offsetY number
--- @param offsetZ number
--- @return void
function BaseObject:MoveAnimationOffset(offsetX, offsetY, offsetZ)
    self.position.animationOffsetX = (self.position.animationOffsetX or 0) + (offsetX or 0)
    self.position.animationOffsetY = (self.position.animationOffsetY or 0) + (offsetY or 0)
    self.position.animationOffsetZ = (self.position.animationOffsetZ or 0) + (offsetZ or 0)
end
--- move object by given x animation offset. The offset is added to the current animation offset and is absolute in the end.
--- @param offsetX number
--- @return void
function BaseObject:MoveAnimationOffsetX(offsetX)
    self.position.animationOffsetX = (self.position.animationOffsetX or 0) + (offsetX or 0)
end
--- move object by given y animation offset. The offset is added to the current animation offset and is absolute in the end.
--- @param offsetY number
--- @return void
function BaseObject:MoveAnimationOffsetY(offsetY)
    self.position.animationOffsetY = (self.position.animationOffsetY or 0) + (offsetY or 0)
end
--- move object by given z animation offset. The offset is added to the current animation offset and is absolute in the end.
--- @param offsetZ number
--- @return void
function BaseObject:MoveAnimationOffsetZ(offsetZ)
    self.position.animationOffsetZ = (self.position.animationOffsetZ or 0) + (offsetZ or 0)
end

-- rotation
--- get main rotation
--- @return number, number, number pitch, yaw, roll
function BaseObject:GetRotation()
    return self.rotation.pitch, self.rotation.yaw, self.rotation.roll
end
--- get full rotation (including animation offsets)
--- @return number, number, number pitch, yaw, roll
function BaseObject:GetFullRotation()
    return self.rotation.pitch + self.rotation.animationOffsetPitch,
           self.rotation.yaw + self.rotation.animationOffsetYaw,
           self.rotation.roll + self.rotation.animationOffsetRoll
end
--- set main rotation
--- @param pitch number
--- @param yaw number
--- @param roll number
--- @return void
function BaseObject:SetRotation(pitch, yaw, roll)
    self.rotation.pitch = pitch
    self.rotation.yaw = yaw
    self.rotation.roll = roll
end
--- set rotation pitch
--- @param pitch number
--- @return void
function BaseObject:SetRotationPitch(pitch)
    self.rotation.pitch = pitch
end
--- set rotation yaw
--- @param yaw number
--- @return void
function BaseObject:SetRotationYaw(yaw)
    self.rotation.yaw = yaw
end
--- set rotation roll
--- @param roll number
--- @return void
function BaseObject:SetRotationRoll(roll)
    self.rotation.roll = roll
end
--- rotate object by given pitch, yaw, roll offsets. The offsets are added to the current rotation and are absolute in the end. This does not rotate the object locally.
--- @param offsetPitch number
--- @param offsetYaw number
--- @param offsetRoll number
--- @return void
function BaseObject:Rotate(offsetPitch, offsetYaw, offsetRoll)
    self.rotation.pitch = (self.rotation.pitch or 0) + offsetPitch
    self.rotation.yaw = (self.rotation.yaw or 0) + offsetYaw
    self.rotation.roll = (self.rotation.roll or 0) + offsetRoll
end
--- rotate object by given pitch offsets. The offsets are added to the current rotation and are absolute in the end. This does not rotate the object locally.
--- @param offsetPitch number
--- @return void
function BaseObject:RotatePitch(offsetPitch)
    self.rotation.pitch = (self.rotation.pitch or 0) + offsetPitch
end
--- rotate object by given yaw offsets. The offsets are added to the current rotation and are absolute in the end. This does not rotate the object locally.
--- @param offsetYaw number
--- @return void
function BaseObject:RotateYaw(offsetYaw)
    self.rotation.yaw = (self.rotation.yaw or 0) + offsetYaw
end
--- rotate object by given roll offsets. The offsets are added to the current rotation and are absolute in the end. This does not rotate the object locally.
--- @param offsetRoll number
--- @return void
function BaseObject:RotateRoll(offsetRoll)
    self.rotation.roll = (self.rotation.roll or 0) + offsetRoll
end
--- get animation rotation offsets
--- @return number, number, number offsetPitch, offsetYaw, offsetRoll
function BaseObject:GetAnimationRotationOffset()
    return self.rotation.animationOffsetPitch, self.rotation.animationOffsetYaw, self.rotation.animationOffsetRoll
end
--- set animation rotation offsets
--- @param offsetPitch number
--- @param offsetYaw number
--- @param offsetRoll number
--- @return void
function BaseObject:SetAnimationRotationOffset(offsetPitch, offsetYaw, offsetRoll)
    self.rotation.animationOffsetPitch = offsetPitch or self.rotation.animationOffsetPitch
    self.rotation.animationOffsetYaw = offsetYaw or self.rotation.animationOffsetYaw
    self.rotation.animationOffsetRoll = offsetRoll or self.rotation.animationOffsetRoll
end
--- set animation rotation offset pitch
--- @param offsetPitch number
--- @return void
function BaseObject:SetAnimationRotationOffsetPitch(offsetPitch)
    self.rotation.animationOffsetPitch = offsetPitch or self.rotation.animationOffsetPitch
end
--- set animation rotation offset yaw
--- @param offsetYaw number
--- @return void
function BaseObject:SetAnimationRotationOffsetYaw(offsetYaw)
    self.rotation.animationOffsetYaw = offsetYaw or self.rotation.animationOffsetYaw
end
--- set animation rotation offset roll
--- @param offsetRoll number
--- @return void
function BaseObject:SetAnimationRotationOffsetRoll(offsetRoll)
    self.rotation.animationOffsetRoll = offsetRoll or self.rotation.animationOffsetRoll
end

--- get normal vector (facing direction)
--- @return number normalX, number normalY, number normalZ
function BaseObject:GetNormalVector()
    error("GetNormalVector needs to be implemented by a RendererClass")
end

--- get creation timestamp in milliseconds
--- @return number creationTimestamp
function BaseObject:GetCreationTimestamp()
    return self.creationTimestamp
end
--- get livetime of the object in milliseconds
--- @return number livetimeMS
function BaseObject:GetLivetimeMS()
    return GetGameTimeMilliseconds() - self.creationTimestamp
end
--- rotate object around a point by given pitch, yaw, roll offsets (WARNING: this is costly in terms of performance!)
--- @param x number pivot x
--- @param y number pivot y
--- @param z number pivot z
--- @param pitchOffset number pitch offset in radians
--- @param yawOffset number yaw offset in radians
--- @param rollOffset number roll offset in radians
--- @return void
function BaseObject:RotateAroundPoint(x, y, z, pitchOffset, yawOffset, rollOffset)
    -- get current position and rotation
    local pX, pY, pZ = self:GetFullPosition()
    local pitch, yaw, roll = self:GetRotation()

    -- build rotation matrix from offsets
    local offsetMatrix = EulerToMatrix(yawOffset, pitchOffset, rollOffset)

    -- transform position relative to pivot
    local relPos = {pX - x, pY - y, pZ - z}
    local newRelPos = MultiplyMatrixVector3x3(offsetMatrix, relPos)
    local newX, newY, newZ = x + newRelPos[1], y + newRelPos[2], z + newRelPos[3]

    -- combine rotations
    local currentMatrix = EulerToMatrix(yaw, pitch, roll)
    local newMatrix = MultiplyMatrices3x3(offsetMatrix, currentMatrix)
    local newPitch, newYaw, newRoll = MatrixToEuler(newMatrix)

    -- set new position and rotation
    self:SetPosition(
            newX - self.position.offsetX - self.position.animationOffsetX,
            newY - self.position.offsetY - self.position.animationOffsetY,
            newZ - self.position.offsetZ - self.position.animationOffsetZ
    )
    self:SetRotation(-newPitch, -newYaw, -newRoll)
end

--- rotate object to face camera
--- @return void
function BaseObject:RotateToCamera()
    local fX, fY, fZ = GetCameraForward(SPACE_WORLD)
    self.rotation.pitch = zo_atan2(fY, zo_sqrt(fX * fX + fZ * fZ))
    self.rotation.yaw = zo_atan2(fX, fZ) - ZO_PI
    self.rotation.roll = 0
end
--- rotate object to face player heading
--- @return void
function BaseObject:RotateToPlayerHeading()
    local _, _, heading = GetMapPlayerPosition("player")
    self.rotation.yaw = heading + ZO_PI
end
--- rotate to face the player
--- @return void
function BaseObject:RotateToPlayerPosition()
    local _, playerX, playerY, playerZ = GetUnitRawWorldPosition("player")
    local objX, objY, objZ = self:GetFullPosition()
    local dirX = playerX - objX
    local dirY = playerY - objY
    local dirZ = playerZ - objZ

    self.rotation.yaw = zo_atan2(dirX, dirZ) + ZO_PI
    self.rotation.pitch = zo_atan2(dirY, zo_sqrt(dirX * dirX + dirZ * dirZ))
end

--- rotate object to be aligned with ground normal (facing up from the ground)
--- @return void
function BaseObject:RotateToGroundNormal()
    local cP, cY, cR = self:GetRotation()
    self:SetRotation(-ZO_PI/2, cY, cR)
end
--- set auto rotation mode
--- @param mode number one of AUTOROTATE_NONE, AUTOROTATE_CAMERA, AUTOROTATE_PLAYER_HEADING, AUTOROTATE_PLAYER_POSITION, AUTOROTATE_GROUND
--- @return void
function BaseObject:SetAutoRotationMode(mode)
    self.autoRotationMode = mode
end

--- move object to unit position
--- @param unitTag string
--- @return void
function BaseObject:MoveToUnit(unitTag)
    local _, unitX, unitY, unitZ = GetUnitRawWorldPosition(unitTag)
    self:SetPosition(unitX, unitY, unitZ)
end
--- move object to cursor position
--- @return void
function BaseObject:MoveToCursor()
    -- this code is inspired by M0RMarkers
    local camX, camY, camZ = lib.GetCameraWorldPosition()
    local fwX, fwY, fwZ = GetCameraForward(SPACE_WORLD)
    local yaw = zo_atan2(fwX, fwZ) - ZO_PI
    local pitch = zo_atan2(fwY, zo_sqrt(fwX * fwX + fwZ * fwZ))

    if pitch > zo_rad(-2) then return end -- just not too far off the screen

    local _, _, y, _ = GetUnitRawWorldPosition("player") --feet position
    local r = (camY-y)/(zo_tan(pitch))
    local x = r*zo_sin(yaw) + camX
    local z = r*zo_cos(yaw) + camZ

    self:SetPosition(x, y, z)
end

--- add a callback function
--- @param callback function the callback function to add
--- @return boolean true if the callback was added, false if it was already present
function BaseObject:AddCallback(callback)
    for _, cb in ipairs(self.callbacks) do
        if cb == callback then
            return false
        end
    end

    table.insert(self.callbacks, callback)
    return true
end
--- remove a callback function
--- @param callback function the callback function to remove
--- @return boolean true if the callback was found and removed, false otherwise
function BaseObject:RemoveCallback(callback)
    for i, cb in ipairs(self.callbacks) do
        if cb == callback then
            table.remove(self.callbacks, i)
            return true
        end
    end

    return false
end
--- remove all callback functions
--- @return void
function BaseObject:RemoveAllCallbacks()
    ZO_ClearTable(self.callbacks)
end

-- TODO: replace with quaternion math for better performance
--- Gets the forward vector of the object.
--- @return number, number, number forwardX, forwardY, forwardZ
function BaseObject:GetForwardVector()
    local pitch, yaw, roll = self:GetFullRotation()
    local m = EulerToMatrix(yaw, pitch, roll)
    local nv = MultiplyMatrixVector3x3(m, forward)

    return nv[1], nv[2], nv[3]
end
--- Gets the right vector of the object.
--- @return number, number, number rightX, rightY, rightZ
function BaseObject:GetRightVector()
    local pitch, yaw, roll = self:GetFullRotation()
    local m = EulerToMatrix(yaw, pitch, roll)
    local nv = MultiplyMatrixVector3x3(m, right)

    return nv[1], nv[2], nv[3]
end
--- Gets the up vector of the object.
--- @return number, number, number upX, upY, upZ
function BaseObject:GetUpVector()
    local pitch, yaw, roll = self:GetFullRotation()
    local m = EulerToMatrix(yaw, pitch, roll)
    local nv = MultiplyMatrixVector3x3(m, up)
    return nv[1], nv[2], nv[3]
end
--- Gets the normal vector of the object.
--- @return number, number, number normalX, normalY, normalZ
function BaseObject:GetNormalVector()
    return self:GetForwardVector()
end