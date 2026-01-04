-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

local Line = BaseObject:Subclass()
lib.Line = Line

--- 3D Line Object
--- @param texture string Path to texture file
--- @param x1 number X coordinate of start point
--- @param y1 number Y coordinate of start point
--- @param z1 number Z coordinate of start point
--- @param x2 number X coordinate of end point (optional, defaults to x1)
--- @param y2 number Y coordinate of end point (optional, defaults to y1)
--- @param z2 number Z coordinate of end point (optional, defaults to z1)
function Line:Initialize(texture, x1, y1, z1, x2, y2, z2)
    BaseObject.Initialize(self, "Lib3DObjects_Line", self)
    x2 = x2 or x1
    y2 = y2 or y1
    z2 = z2 or z1
    local centerX = (x1 + x2) / 2
    local centerY = (y1 + y2) / 2
    local centerZ = (z1 + z2) / 2
    self:SetPosition(centerX, centerY, centerZ)

    self:SetStartPoint(x1, y1, z1)
    self:SetEndPoint(x2, y2, z2)

    self:SetTexture(texture)

    self:SetDrawDistanceMeters(75)
    self:SetAlpha(0.75)
    self:SetLineWidth(5)

    self:AddCallback(self._UpdatePosition)
    self:AddCallback(self._UpdateRotation)
    self:AddCallback(self._ResizeToEndpoints)
end

function Line:Destroy()
    self:SetTexture(nil)
    self:SetColor(1, 1, 1, 1)
    self:SetLineWidth(10)
    BaseObject.Destroy(self)
end

function Line:SetTexture(texturePath, left, right, top, bottom)
    self.Control:SetTexture(texturePath)
    self.Control:SetTextureCoords(left or 0, right or 1, top or 0, bottom or 1)
end
function Line:GetTexture()
    local texture = self.Control:GetTextureFileName()
    local left, right, top, bottom = self.Control:GetTextureCoords()
    return texture, left, right, top, bottom
end
function Line:SetColor(r, g, b, a)
    self.Control:SetColor(r, g, b, a)
end
function Line:GetColor()
    return self.Control:GetColor()
end
function Line:SetLineWidth(width)
    self.lineWidth = width or 10
    self.Control:SetWidth(self.lineWidth)
end
function Line:GetLineWidth()
    return self.lineWidth
end
function Line:GetLineLength()
    local dist = zo_distance3D(self.startX or 0, self.startY or 0, self.startZ or 0, self.endX or 0, self.endY or 0, self.endZ or 0)
    return dist
end

function Line:SetStartPoint(x, y, z)
    self.startX = x or 0
    self.startY = y or 0
    self.startZ = z or 0
end
function Line:GetStartPoint()
    return self.startX, self.startY, self.startZ
end
function Line:SetEndPoint(x, y, z)
    self.endX = x or 0
    self.endY = y or 0
    self.endZ = z or 0
end
function Line:GetEndPoint()
    return self.endX, self.endY, self.endZ
end
-- calculates a new endpoint
function Line:SetEndpointFromDirectionVector(length, pitch, yaw)
    local dx = length * zo_cos(pitch) * zo_cos(yaw)
    local dy = length * zo_sin(pitch)
    local dz = length * zo_cos(pitch) * zo_sin(yaw)
    local endX = self.startX + dx
    local endY = self.startY + dy
    local endZ = self.startZ + dz
    self.endX = endX
    self.endY = endY
    self.endZ = endZ
end

function Line:_ResizeToEndpoints()
    self.Control:SetHeight(self:GetLineLength())
end

function Line:_UpdatePosition()
    -- set position to midpoint between start and end
    self.position.x = (self.startX + self.endX) / 2
    self.position.y = (self.startY + self.endY) / 2
    self.position.z = (self.startZ + self.endZ) / 2
end

function Line:_UpdateRotation()
    -- calculate rotation to face from start to end point
    local dx = self.endX - self.startX
    local dy = self.endY - self.startY
    local dz = self.endZ - self.startZ
    local anglePitch = zo_atan2(dy, zo_sqrt(dx * dx + dz * dz))
    local angleYaw = zo_atan2(dz, dx)
    self.rotation.pitch = -anglePitch + ZO_PI / 2
    self.rotation.yaw = -angleYaw + ZO_PI / 2
    self.rotation.roll = 0
end