local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local ObjectPoolManager = lib.core.ObjectPoolManager


local BaseObject = ZO_InitializingObject:Subclass()
lib.BaseObject = BaseObject

local AUTOROTATE_NONE = lib.AUTOROTATE_NONE
local AUTOROTATE_CAMERA = lib.AUTOROTATE_CAMERA
local AUTOROTATE_PLAYER = lib.AUTOROTATE_PLAYER

local EM = GetEventManager()

function BaseObject:Initialize(templateControlName, properties)
    self.autoRotationMode = AUTOROTATE_NONE
    self.visible = true
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
    self.ObjectPool = ObjectPoolManager:Get(self.templateControlName)
    self.Control = self.ObjectPool:AcquireObject()
    local x, y, z = WorldPositionToGuiRender3DPosition(self.position.x + self.position.offsetX, self.position.y + self.position.offsetY, self.position.z + self.position.offsetZ)
    self.Control:SetTransformOffset(x,y,z)
    self.Control.obj = self

    self.Initialize = nil -- remove initialization function after first call
end

function BaseObject:SetOnDestroyAnimation(callback)
    self.onDestroyAnimation = callback
end
function BaseObject:ClearOnDestroyAnimation()
    self.onDestroyAnimation = nil
end

function BaseObject:Destroy()
    -- remove all references to callbacks
    ZO_ClearTable(self.callbacks)

    -- this is the actual destroy function called after the onDestroyAnimation (if any) is finished
    self._onDestroy = function()
        self.Control.obj = nil
        self.ObjectPool:ReleaseObject(self.Control)
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

function BaseObject:Update()
    if not self.visible then
        self.Control:SetHidden(true)
        return false
    end

    local distance = self:GetDistanceToPlayer()
    if distance > (self.drawDistance + self.fadeOutDistanceFar) then
        self.Control:SetHidden(true)
        return false
    end

    if distance > self.drawDistance then
        local alpha = self.alpha * (1.0 - ((distance - self.drawDistance) / self.fadeOutDistanceFar))
        self.Control:SetAlpha(alpha)
    else
        self.Control:SetAlpha(self.alpha)
    end

    local distanceToCamera = self:GetDistanceToCamera()
    if distanceToCamera < self.fadeOutDistanceNear then
        -- fade out when getting closer based on distance. never go over the current max alpha
        self.Control:SetAlpha(math.min(self.alpha, self.alpha * (distanceToCamera / 500)))
    end

    for _, callback in ipairs(self.callbacks) do
        local finished = callback(self, distance, distanceToCamera)
        if finished then self:RemoveCallback(callback) end
    end

    if self.autoRotationMode == AUTOROTATE_CAMERA then
        self:RotateToCamera()
    elseif self.autoRotationMode == AUTOROTATE_PLAYER then
        self:RotateToPlayerHeading()
    end

    self:_UpdatePosition()
    self:_UpdateRotation()

    self.Control:SetHidden(false)

    return true
end

function BaseObject:_UpdatePosition()
    local sx, sy ,sz = GuiRender3DPositionToWorldPosition(0,0,0)
    local x = ((self.position.x + self.position.offsetX + self.position.animationOffsetX) - sx) / 100
    local y = ((self.position.y + self.position.offsetY + self.position.animationOffsetY) - sy) / 100
    local z = ((self.position.z + self.position.offsetZ + self.position.animationOffsetZ) - sz) / 100
    self.Control:SetTransformOffset(x, y, z)
end

function BaseObject:_UpdateRotation()
    local pitch = self.rotation.pitch + self.rotation.animationOffsetPitch
    local yaw = self.rotation.yaw + self.rotation.animationOffsetYaw
    local roll = self.rotation.roll + self.rotation.animationOffsetRoll
    self.Control:SetTransformRotation(pitch, yaw, roll)
end

function BaseObject:GetDistanceToCamera()
    local camX, camY, camZ = lib.GetCameraWorldPosition()
    local distance = zo_distance3D(camX, camY, camZ,
            self.position.x + self.position.offsetX + self.position.animationOffsetX,
            self.position.y + self.position.offsetY + self.position.animationOffsetY,
            self.position.z + self.position.offsetZ + self.position.animationOffsetZ)
    return distance
end
function BaseObject:GetDistanceToUnit(unitTag)
    local _, playerX, PlayerY, playerZ = GetUnitRawWorldPosition(unitTag)
    local distance = zo_distance3D(playerX, PlayerY, playerZ, self.position.x + self.position.animationOffsetX, self.position.y + self.position.animationOffsetY, self.position.z + self.position.animationOffsetZ)
    return distance
end
function BaseObject:GetDistanceToPlayer()
    return self:GetDistanceToUnit('player')
end
function BaseObject:SetScale(scale)
    self.scale = scale
    self.Control:SetScale(self.scale)
end
function BaseObject:SetAlpha(alpha)
    self.alpha = alpha
    self.Control:SetAlpha(self.alpha)
end
function BaseObject:SetDrawDistanceMeters(distance)
    self.drawDistance = distance * 100 -- meters to centimeters
end
function BaseObject:SetVisible(visible)
    self.visible = visible
end
-- position
function BaseObject:GetPosition()
    return self.position.x, self.position.y, self.position.z
end
function BaseObject:SetPosition(x, y, z)
    self.position.x = x
    self.position.y = y
    self.position.z = z
end
function BaseObject:SetPositionAnimated(x, y, z, durationMS)
    local beginTime = GetGameTimeMilliseconds()
    local endTime = beginTime + durationMS or 1000 -- default to 1 second if not provided

    local startX = self.position.x
    local startY = self.position.y
    local startZ = self.position.z

    local callbackFunc = function(self)
        local progress = (GetGameTimeMilliseconds() - beginTime) / (endTime - beginTime) -- value between 0 and 1
        if progress >= 1 then return true end
        -- Ease out: fast start, slow end (using quadratic ease out)
        local eased = 1 - (1 - progress) * (1 - progress)
        self.position.x = startX + (x - startX) * eased
        self.position.y = startY + (y - startY) * eased
        self.position.z = startZ + (z - startZ) * eased
    end

    self:AddCallback(callbackFunc)
end


function BaseObject:SetPositionX(x)
    self.position.x = x
end
function BaseObject:SetPositionY(y)
    self.position.y = y
end
function BaseObject:SetPositionZ(z)
    self.position.z = z
end

function BaseObject:GetPositionOffset()
    return self.position.offsetX, self.position.offsetY, self.position.offsetZ
end
function BaseObject:SetPositionOffset(offsetX, offsetY, offsetZ)
    self.position.offsetX = offsetX
    self.position.offsetY = offsetY
    self.position.offsetZ = offsetZ
end
function BaseObject:SetPositionOffsetX(offsetX)
    self.position.offsetX = offsetX
end
function BaseObject:SetPositionOffsetY(offsetY)
    self.position.offsetY = offsetY
end
function BaseObject:SetPositionOffsetZ(offsetZ)
    self.position.offsetZ = offsetZ
end

function BaseObject:Move(offsetX, offsetY, offsetZ)
    self.position.x = (self.position.x or 0) + offsetX
    self.position.y = (self.position.y or 0) + offsetY
    self.position.z = (self.position.z or 0) + offsetZ
end
function BaseObject:MoveX(offsetX)
    self.position.x = (self.position.x or 0) + offsetX
end
function BaseObject:MoveY(offsetY)
    self.position.y = (self.position.y or 0) + offsetY
end
function BaseObject:MoveZ(offsetZ)
    self.position.z = (self.position.z or 0) + offsetZ
end
function BaseObject:MoveOffset(offsetX, offsetY, offsetZ)
    self.position.offsetX = (self.position.offsetX or 0) + offsetX
    self.position.offsetY = (self.position.offsetY or 0) + offsetY
    self.position.offsetZ = (self.position.offsetZ or 0) + offsetZ
end
function BaseObject:MoveOffsetX(offsetX)
    self.position.offsetX = (self.position.offsetX or 0) + offsetX
end
function BaseObject:MoveOffsetY(offsetY)
    self.position.offsetY = (self.position.offsetY or 0) + offsetY
end
function BaseObject:MoveOffsetZ(offsetZ)
    self.position.offsetZ = (self.position.offsetZ or 0) + offsetZ
end

-- rotation
function BaseObject:GetRotation()
    return self.rotation.pitch, self.rotation.yaw, self.rotation.roll
end
function BaseObject:SetRotation(pitch, yaw, roll)
    self.rotation.pitch = pitch
    self.rotation.yaw = yaw
    self.rotation.roll = roll
end
function BaseObject:SetRotationPitch(pitch)
    self.rotation.pitch = pitch
end
function BaseObject:SetRotationYaw(yaw)
    self.rotation.yaw = yaw
end
function BaseObject:SetRotationRoll(roll)
    self.rotation.roll = roll
end
function BaseObject:Rotate(offsetPitch, offsetYaw, offsetRoll)
    self.rotation.pitch = (self.rotation.pitch or 0) + offsetPitch
    self.rotation.yaw = (self.rotation.yaw or 0) + offsetYaw
    self.rotation.roll = (self.rotation.roll or 0) + offsetRoll
end
function BaseObject:RotatePitch(offsetPitch)
    self.rotation.pitch = (self.rotation.pitch or 0) + offsetPitch
end
function BaseObject:RotateYaw(offsetYaw)
    self.rotation.yaw = (self.rotation.yaw or 0) + offsetYaw
end
function BaseObject:RotateRoll(offsetRoll)
    self.rotation.roll = (self.rotation.roll or 0) + offsetRoll
end

function BaseObject:GetNormalVector()
    local fX = -math.sin(self.rotation.yaw) * math.cos(self.rotation.pitch)
    local fY = math.sin(self.rotation.pitch)
    local fZ = -math.cos(self.rotation.yaw) * math.cos(self.rotation.pitch)
    return fX, fY, fZ
end

function BaseObject:GetCreationTimestamp()
    return self.creationTimestamp
end
function BaseObject:GetLivetimeMS()
    return GetGameTimeMilliseconds() - self.creationTimestamp
end

function BaseObject:RotateToCamera()
    local fX, fY, fZ = GetCameraForward(SPACE_WORLD)
    self.rotation.pitch = zo_atan2(fY, zo_sqrt(fX * fX + fZ * fZ))
    self.rotation.yaw = zo_atan2(fX, fZ) - ZO_PI
    self.rotation.roll = 0
end

function BaseObject:RotateToPlayerHeading()
    local _, _, heading = GetMapPlayerPosition("player")
    self.rotation.yaw = heading + ZO_PI
end

function BaseObject:SetAutoRotationMode(mode)
    self.autoRotationMode = mode
end

function BaseObject:MoveToUnit(unitTag)
    local _, unitX, unitY, unitZ = GetUnitRawWorldPosition(unitTag)
    self.position.x = unitX
    self.position.y = unitY
    self.position.z = unitZ
end

function BaseObject:MoveToCursor()
    -- this code is inspired by M0RMarkers
    local camX, camY, camZ = lib.GetCameraWorldPosition()
    local fwX, fwY, fwZ = GetCameraForward(SPACE_WORLD)
    local yaw = zo_atan2(fwX, fwZ) - ZO_PI
    local pitch = zo_atan2(fwY, zo_sqrt(fwX * fwX + fwZ * fwZ))

    if pitch > zo_rad(-2) then return end -- just not too far off the screen

    local _, _, y, _ = GetUnitRawWorldPosition('player') --feet position
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

function BaseObject:RemoveAllCallback()
    ZO_ClearTable(self.callbacks)
end