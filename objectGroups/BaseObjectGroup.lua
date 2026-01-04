local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local ObjectGroupManager = lib.core.ObjectGroupManager

local BaseObjectGroup = ZO_InitializingObject:Subclass()
lib.BaseObjectGroup = BaseObjectGroup

function BaseObjectGroup:Initialize(...)
    self.groupMembers = {}
    self.callbacks = {}
    self.x = 0
    self.y = 0
    self.z = 0
    self.pitch = 0
    self.yaw = 0
    self.roll = 0
    self.isEnabled = true
    self.isHidden = false
    self.scale = 1

    -- Add initial members
    for i = 1, select("#", ...) do
        local member = select(i, ...)
        table.insert(self.groupMembers, member)
    end

    local numObjects = #self.groupMembers
    if numObjects > 0 then
        self.x, self.y, self.z = self:GetMidpoint()
    else
        local _, x, y, z = GetUnitRawWorldPosition("player")
        self.x, self.y, self.z = x, y, z
    end

    ObjectGroupManager:Add(self)
    return self
end
function BaseObjectGroup:Destroy()
    for _, member in ipairs(self.groupMembers) do
        member:Destroy()
    end

    ObjectGroupManager:Remove(self)
    self = nil
end
function BaseObjectGroup:Update()
    if not self.isEnabled then
        return false
    end
    local distanceToPlayer = self:GetDistanceToPlayer()
    local distanceToCamera = self:GetDistanceToCamera()

    for _, callback in ipairs(self.callbacks) do
        local finished = callback(self, distanceToPlayer, distanceToCamera)
        if finished then self:RemoveCallback(callback) end
    end
end
function BaseObjectGroup:IsEnabled()
    return self.isEnabled
end
function BaseObjectGroup:SetEnabled(enabled)
    for _, member in ipairs(self.groupMembers) do
        member:SetEnabled(enabled)
    end
    self.isEnabled = enabled
end
function BaseObjectGroup:IsHidden()
    return self.isHidden
end
function BaseObjectGroup:SetHidden(hidden)
    for _, member in ipairs(self.groupMembers) do
        member:SetHidden(hidden)
    end
    self.isHidden = not hidden
end
function BaseObjectGroup:SetScale(scale)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        local dirX = memberX - self.x
        local dirY = memberY - self.y
        local dirZ = memberZ - self.z
        member:SetPosition(self.x + dirX * scale, self.y + dirY * scale, self.z + dirZ * scale)
        member:SetScale(scale)
    end
    self.scale = scale
end
function BaseObjectGroup:GetScale()
    return self.scale
end

function BaseObjectGroup:GetMemberCount()
    return #self.groupMembers
end
function BaseObjectGroup:GetMembers()
    return self.groupMembers
end
function BaseObjectGroup:GetMidpoint()
    local numObjects = #self.groupMembers
    if numObjects == 0 then
        return self.x, self.y, self.z
    end

    local sumX, sumY, sumZ = 0, 0, 0
    for _, member in ipairs(self.groupMembers) do
        local x, y, z = member:GetFullPosition()
        sumX = sumX + x
        sumY = sumY + y
        sumZ = sumZ + z
    end
    local x = sumX / numObjects
    local y = sumY / numObjects
    local z = sumZ / numObjects

    return x, y, z
end
function BaseObjectGroup:Add(...)
    for i = 1, select("#", ...) do
        local member = select(i, ...)
        table.insert(self.groupMembers, member)
    end
end
function BaseObjectGroup:Remove(...)
    for i = 1, select("#", ...) do
        local object = select(i, ...)
        for memberIndex, member in ipairs(self.groupMembers) do
            if member == object then
                table.remove(self.groupMembers, memberIndex)
                break
            end
        end
    end
end
function BaseObjectGroup:GetDistanceToCamera()
    local camX, camY, camZ = lib.GetCameraWorldPosition()
    local distance = zo_distance3D(camX, camY, camZ, self.x, self.y, self.z)
    return distance
end
function BaseObjectGroup:GetDistanceToUnit(unitTag)
    local _, playerX, PlayerY, playerZ = GetUnitRawWorldPosition(unitTag)
    local distance = zo_distance3D(playerX, PlayerY, playerZ, self.x, self.y, self.z)
    return distance
end
function BaseObjectGroup:GetDistanceToPlayer()
    return self:GetDistanceToUnit('player')
end
function BaseObjectGroup:GetRotation()
    return self.pitch, self.yaw, self.roll
end
function BaseObjectGroup:SetRotation(newPitch, newYaw, newRoll)
    local deltaPitch = newPitch - self.pitch
    local deltaYaw = newYaw - self.yaw
    local deltaRoll = newRoll - self.roll

    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, deltaPitch, deltaYaw, deltaRoll)
    end

    self.pitch = newPitch
    self.yaw = newYaw
    self.roll = newRoll
end
function BaseObjectGroup:SetRotationPitch(newPitch)
    local deltaPitch = newPitch - self.pitch
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, deltaPitch, 0, 0)
    end
    self.pitch = newPitch
end
function BaseObjectGroup:SetRotationYaw(newYaw)
    local deltaYaw = newYaw - self.yaw
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, 0, deltaYaw, 0)
    end
    self.yaw = newYaw
end
function BaseObjectGroup:SetRotationRoll(newRoll)
    local deltaRoll = newRoll - self.roll
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, 0, 0, deltaRoll)
    end
    self.roll = newRoll
end

function BaseObjectGroup:Rotate(deltaPitch, deltaYaw, deltaRoll)
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, deltaPitch, deltaYaw, deltaRoll)
    end
    self.pitch = (self.pitch + (deltaPitch or 0))
    self.yaw = (self.yaw + (deltaYaw or 0))
    self.roll = (self.roll + (deltaRoll or 0))
end
function BaseObjectGroup:RotatePitch(deltaPitch)
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, deltaPitch, 0, 0)
    end
end
function BaseObjectGroup:RotateYaw(deltaYaw)
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, 0, deltaYaw, 0)
    end
end
function BaseObjectGroup:RotateRoll(deltaRoll)
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, 0, 0, deltaRoll)
    end
end
function BaseObjectGroup:GetNormalVector()
    local x = zo_cos(self.pitch) * zo_sin(self.yaw)
    local y = zo_sin(self.pitch)
    local z = zo_cos(self.pitch) * zo_cos(self.yaw)
    return x, y, z
end
function BaseObjectGroup:RotateToCamera()
    return nil
end

function BaseObjectGroup:RotateToPlayerHeading()
    return nil
end

function BaseObjectGroup:RotateToGroundNormal()
    return nil
end

-- TODO: this should work differently. it should rotate the whole group to face the camera/player/ground normal instead of setting each member individually. Or am i wrong here?
function BaseObjectGroup:SetAutoRotationMode(mode)
    for _, member in ipairs(self.groupMembers) do
        member:SetAutoRotationMode(mode)
    end
end
function BaseObjectGroup:MoveToUnit(unitTag)
    local _, unitX, unitY, unitZ = GetUnitRawWorldPosition(unitTag)
    self:SetPosition(unitX, unitY, unitZ)
end
function BaseObjectGroup:MoveToCursor()
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
function BaseObjectGroup:AddCallback(callback)
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
function BaseObjectGroup:RemoveCallback(callback)
    for i, cb in ipairs(self.callbacks) do
        if cb == callback then
            table.remove(self.callbacks, i)
            return true
        end
    end

    return false
end
function BaseObjectGroup:RemoveAllCallbacks()
    ZO_ClearTable(self.callbacks)
end
function BaseObjectGroup:SetPosition(newX, newY, newZ)
    local deltaX = newX - self.x
    local deltaY = newY - self.y
    local deltaZ = newZ - self.z

    for _, member in ipairs(self.groupMembers) do
        member:Move(deltaX, deltaY, deltaZ)
    end

    self.x = newX
    self.y = newY
    self.z = newZ
end
function BaseObjectGroup:GetPosition()
    return self.x, self.y, self.z
end
function BaseObjectGroup:SetPositionX(newX)
    newX = newX or 0
    local deltaX = newX - self.x

    for _, member in ipairs(self.groupMembers) do
        member:MoveX(deltaX)
    end

    self.x = newX
end
function BaseObjectGroup:SetPositionY(newY)
    newY = newY or 0
    local deltaY = newY - self.y
    for _, member in ipairs(self.groupMembers) do
        member:MoveY(deltaY)
    end

    self.y = newY
end
function BaseObjectGroup:SetPositionZ(newZ)
    newZ = newZ or 0
    local deltaZ = newZ - self.z
    for _, member in ipairs(self.groupMembers) do
        member:MoveZ(deltaZ)
    end

    self.z = newZ
end
function BaseObjectGroup:Move(deltaX, deltaY, deltaZ)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX + deltaX, memberY + deltaY, memberZ + deltaZ)
    end

    self.x = self.x + deltaX
    self.y = self.y + deltaY
    self.z = self.z + deltaZ
end
function BaseObjectGroup:MoveX(deltaX)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX + deltaX, memberY, memberZ)
    end

    self.x = self.x + deltaX
end
function BaseObjectGroup:MoveY(deltaY)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX, memberY + deltaY, memberZ)
    end

    self.y = self.y + deltaY
end
function BaseObjectGroup:MoveZ(deltaZ)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX, memberY, memberZ + deltaZ)
    end

    self.z = self.z + deltaZ
end
--- Set the reference point of the object group
--- @param x number x coordinate of the reference point
--- @param y number y coordinate of the reference point
--- @param z number z coordinate of the reference point
function BaseObjectGroup:SetReferencePoint(x, y, z)
    self.x, self.y, self.z = x, y, z
end
--- Get the reference point of the object group
--- @return number, number, number x, y, z of the reference point
function BaseObjectGroup:GetReferencePoint()
    return self.x, self.y, self.z
end
