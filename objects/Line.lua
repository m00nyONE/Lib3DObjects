local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

local Line = BaseObject:Subclass()
lib.Line = Line

function Line:Initialize(texture, x1, y1, z1, x2, y2, z2)
    BaseObject.Initialize(self, "Lib3DObjects_Line", self)
    self:SetStartPoint(x1, y1, z1)
    self:SetEndPoint(x2, y2, z2)
    self:ResizeToEndpoints()
    self:SetPositionToCenter()

    self:SetTexture(texture)

    --self:RotateToCamera()
    --self:SetRotation(-ZO_PI/2, 0, 0)

    self:SetDrawDistanceMeters(75)
    self:SetAlpha(0.75)
    self:SetLineWidth(20)

    self:AddCallback(function(object, distanceToPlayer, distanceToCamera)
        object:_drawLine()
    end)
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
function Line:SetPositionToCenter()
    local centerX = (self.startX + self.endX) / 2
    local centerY = (self.startY + self.endY) / 2
    local centerZ = (self.startZ + self.endZ) / 2
    self:SetPosition(centerX, centerY, centerZ)
end
function Line:ResizeToEndpoints()
    local dist = zo_distance3D(self.startX or 0, self.startY or 0, self.startZ or 0, self.endX or 0, self.endY or 0, self.endZ or 0)
    self.Control:SetHeight(dist / 100) -- Scale factor to convert world units to control width
end

function Line:_drawLine()
    -- set position to center between endpoints
    local centerX = (self.startX + self.endX) / 2
    local centerY = (self.startY + self.endY) / 2
    local centerZ = (self.startZ + self.endZ) / 2
    self:SetPosition(centerX, centerY, centerZ)

    -- resize to match distance between endpoints
    local dx = self.endX - self.startX
    local dy = self.endY - self.startY
    local dz = self.endZ - self.startZ
    local dist = zo_sqrt(dx * dx + dy * dy + dz * dz)
    self.Control:SetHeight(dist) -- Scale factor to convert world units to control width

    --local angle = math.atan(dy/dx)
    --self.Control:SetTransformRotationZ(-angle)

    -- TODO: fix rotation

    ---- set rotation to match direction between endpoints
    ---- the top should face the same direction as the vector from p1 to p2
    self.rotation.yaw = zo_atan2(dz, dx)
    self.rotation.pitch = zo_atan2(dy, zo_sqrt(dx * dx + dz * dz))
    self.rotation.roll = 0

end