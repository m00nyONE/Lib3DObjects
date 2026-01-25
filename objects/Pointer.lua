-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

--- @class Pointer : BaseObject
local Pointer = BaseObject:Subclass()
lib.Pointer = Pointer

--- 3D Pointer Object
--- @param toX number Target X position
--- @param toY number Target Y position
--- @param toZ number Target Z position
--- @param x number X position
--- @param y number Y position
--- @param z number Z position
--- @param radius number Radius around position to pointer
--- @return Pointer
function Pointer:Initialize(toX, toY, toZ, x, y, z, radius)
    BaseObject.Initialize(self, "Lib3DObjects_Pointer", self)

    local _, pX, pY, pZ = GetUnitRawWorldPosition("player")
    x = x or pX
    y = y or pY
    z = z or pZ
    self:SetPosition(x, y, z)

    radius = radius or 200
    self:SetRadius(radius)

    self:SetTargetUnit(nil)
    self:SetTargetPosition(toX, toY, toZ)


    self:SetPointerWidth(50)
    self:SetPointerLength(20)

    self.defaultTexture = "Lib3DObjects/Textures/Pointer.dds"





    self:SetTexture(self.defaultTexture)

    self:SetDrawDistance(math.huge)
    self:SetAlpha(0.4)

    self:CreateUpdatePreHook(self._UpdatePosition)
    self:AddCallback(self._UpdateRotation)
end

function Pointer:Destroy()
    self:SetColor(1, 1, 1, 1)
    self:SetTexture(self.defaultTexture)
    self:SetPointerWidth(100)
    self:SetPointerLength(10000)
    BaseObject.Destroy(self)
end
function Pointer:SetTexture(texturePath, left, right, top, bottom)
    texturePath = texturePath or self.defaultTexture
    self.Control:SetTexture(texturePath)
    self.Control:SetTextureCoords(left or 0, right or 1, top or 0, bottom or 1)
end
function Pointer:SetColor(r, g, b, a)
    self.Control:SetColor(r, g, b, a)
end
function Pointer:GetColor()
    return self.Control:GetColor()
end
function Pointer:SetPointerWidth(width)
    self:SetWidth(width or 100)
end
function Pointer:GetPointerWidth()
    return self:GetWidth()
end
function Pointer:SetPointerLength(height)
    height = height or 10000
    self:SetHeight(height)
    self:SetPositionOffsetY(height / 2)
end
function Pointer:GetPointerLength()
    return self:GetHeight()
end

function Pointer:_UpdatePosition()
    if self.attachedToUnit then
        local _, x, y, z = GetUnitRawWorldPosition(self.attachedToUnit)
        self:SetPosition(x, y, z)
    end
end
function Pointer:_UpdateRotation()
    local fX, _, fZ = GetCameraForward(SPACE_WORLD)
    local yaw = zo_atan2(fX, fZ) - ZO_PI
    self:SetRotation(0, yaw, 0)
end

function Pointer:AttachToUnit(unitTag)
    self.attachedToUnit = unitTag
end
function Pointer:DetachFromUnit()
    self.attachedToUnit = nil
end