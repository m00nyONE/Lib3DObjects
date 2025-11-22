local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

local Line = BaseObject:Subclass()
lib.Line = Line

function Line:Initialize(texture, x1, y1, z1, x2, y2, z2)
    BaseObject.Initialize(self, "Lib3DObjects_Line", self)
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

    self:AddCallback(self._ResizeToEndpoints)
end

function Line:Destroy()
    self:SetTexture(nil)
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
function Line:_ResizeToEndpoints()
    self.Control:SetHeight(self:GetLineLength())
end

function Line:_UpdatePosition()
    -- set position to midpoint between start and end
    self.position.x = (self.startX + self.endX) / 2
    self.position.y = (self.startY + self.endY) / 2
    self.position.z = (self.startZ + self.endZ) / 2

    local sx, sy ,sz = GuiRender3DPositionToWorldPosition(0,0,0)
    local x = ((self.position.x + self.position.offsetX + self.position.animationOffsetX) - sx) / 100
    local y = ((self.position.y + self.position.offsetY + self.position.animationOffsetY) - sy) / 100
    local z = ((self.position.z + self.position.offsetZ + self.position.animationOffsetZ) - sz) / 100
    self.Control:SetTransformOffset(x, y, z)
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

    local pitch = self.rotation.pitch + self.rotation.animationOffsetPitch
    local yaw = self.rotation.yaw + self.rotation.animationOffsetYaw
    local roll = self.rotation.roll + self.rotation.animationOffsetRoll
    self.Control:SetTransformRotation(pitch, yaw, roll)
end