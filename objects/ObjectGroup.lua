local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local ObjectGroup = ZO_Object:Subclass()
lib.ObjectGroup = ObjectGroup

function ObjectGroup:Initialize(...)
    self.groupMembers = {}
    for i = 1, select("#", ...) do
        local member = select(i, ...)
        table.insert(self.groupMembers, member)
    end

    local numObjects = #self.groupMembers
    if numObjects > 0 then
        local sumX, sumY, sumZ = 0, 0, 0
        for _, member in ipairs(self.groupMembers) do
            local x, y, z = member:GetFullPosition()
            sumX = sumX + x
            sumY = sumY + y
            sumZ = sumZ + z
        end
        self.x = sumX / numObjects
        self.y = sumY / numObjects
        self.z = sumZ / numObjects
    else
        local _, x, y, z = GetUnitRawWorldPosition("player")
        self.x, self.y, self.z = x, y, z
    end
end
function ObjectGroup:GetMembers()
    return self.groupMembers
end
function ObjectGroup:GetMidpoint()
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
function ObjectGroup:Add(...)
    for i = 1, select("#", ...) do
        local member = select(i, ...)
        table.insert(self.groupMembers, member)
    end
    self.x, self.y, self.z = self:GetMidpoint()
end
function ObjectGroup:Remove(...)
    for i = 1, select("#", ...) do
        local object = select(i, ...)
        for memberIndex, member in ipairs(self.groupMembers) do
            if member == object then
                table.remove(self.groupMembers, memberIndex)
                break
            end
        end
    end
    self.x, self.y, self.z = self:GetMidpoint()
end
function ObjectGroup:Destroy()
    for _, member in ipairs(self.groupMembers) do
        member:Destroy()
    end
    self.groupMembers = nil
    self = nil
end
function ObjectGroup:SetPosition(newX, newY, newZ)
    local deltaX = newX - self.x
    local deltaY = newY - self.y
    local deltaZ = newZ - self.z

    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX + deltaX, memberY + deltaY, memberZ + deltaZ)
    end

    self.x = newX
    self.y = newY
    self.z = newZ
end
function ObjectGroup:GetPosition()
    return self.x, self.y, self.z
end
function ObjectGroup:SetPositionX(newX)
    local deltaX = newX - self.x

    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX + deltaX, memberY, memberZ)
    end

    self.x = newX
end
function ObjectGroup:SetPositionY(newY)
    local deltaY = newY - self.y

    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX, memberY + deltaY, memberZ)
    end

    self.y = newY
end
function ObjectGroup:SetPositionZ(newZ)
    local deltaZ = newZ - self.z

    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX, memberY, memberZ + deltaZ)
    end

    self.z = newZ
end
function ObjectGroup:Move(deltaX, deltaY, deltaZ)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX + deltaX, memberY + deltaY, memberZ + deltaZ)
    end

    self.x = self.x + deltaX
    self.y = self.y + deltaY
    self.z = self.z + deltaZ
end
function ObjectGroup:MoveX(deltaX)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX + deltaX, memberY, memberZ)
    end

    self.x = self.x + deltaX
end
function ObjectGroup:MoveY(deltaY)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX, memberY + deltaY, memberZ)
    end

    self.y = self.y + deltaY
end
function ObjectGroup:MoveZ(deltaZ)
    for _, member in ipairs(self.groupMembers) do
        local memberX, memberY, memberZ = member:GetFullPosition()
        member:SetPosition(memberX, memberY, memberZ + deltaZ)
    end

    self.z = self.z + deltaZ
end
function ObjectGroup:Rotate(deltaPitch, deltaYaw, deltaRoll)
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, deltaPitch, deltaYaw, deltaRoll)
    end

    self.x, self.y, self.z = self:GetMidpoint()
end
function ObjectGroup:RotatePitch(deltaPitch)
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, deltaPitch, 0, 0)
    end
end
function ObjectGroup:RotateYaw(deltaYaw)
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, 0, deltaYaw, 0)
    end
end
function ObjectGroup:RotateRoll(deltaRoll)
    for _, member in ipairs(self.groupMembers) do
        member:RotateAroundPoint(self.x, self.y, self.z, 0, 0, deltaRoll)
    end
end
function ObjectGroup:EnableVisualMidPoint()
    local visualMarker = lib.FloatingMarker:New("EsoUI/Art/Miscellaneous/point_of_interest.dds", self.x, self.y, self.z, 0)
    visualMarker:AddCallback(function(marker, distanceToPlayer, distanceToCamera)
        marker:SetPosition(self.x, self.y, self.z)
    end)
    self.visualMidPointMarker = visualMarker
end
function ObjectGroup:DisableVisualMidPoint()
    if self.visualMidPointMarker then
        self.visualMidPointMarker:Destroy()
        self.visualMidPointMarker = nil
    end
end
