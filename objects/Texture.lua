-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

local Texture = BaseObject:Subclass()
lib.Texture = Texture

function Texture:Initialize(texture, x, y, z)
    BaseObject.Initialize(self, "Lib3DObjects_Texture", self)
    local _, pX, pY, pZ = GetUnitRawWorldPosition("player")
    self:SetPosition(x or pX, y or pY, z or pZ)

    self:SetTexture(texture)

    self:SetDrawDistanceMeters(75)
    self:SetAlpha(1)
end

function Texture:Destroy()
    self:SetTexture(nil)
    self:SetDimensions(100, 100)
    self:SetColor(1, 1, 1, 1)
    self:SetScale(1)

    BaseObject.Destroy(self)
end

function Texture:SetColor(r, g, b, a)
    self.Control:SetColor(r, g, b, a)
end
function Texture:GetColor()
    return self.Control:GetColor()
end
function Texture:SetDimensions(width, height)
    self.Control:SetDimensions(width, height)
end
function Texture:GetDimensions()
    return self.Control:GetDimensions()
end
function Texture:SetHeight(height)
    self.Control:SetHeight(height)
end
function Texture:GetHeight()
    return self.Control:GetHeight()
end
function Texture:SetWidth(width)
    self.Control:SetWidth(width)
end
function Texture:GetWidth()
    return self.Control:GetWidth()
end
function Texture:SetTexture(texturePath, left, right, top, bottom)
    self.Control:SetTexture(texturePath)
    self.Control:SetTextureCoords(left or 0, right or 1, top or 0, bottom or 1)
end
function Texture:GetTexture()
    local texture = self.Control:GetTextureFileName()
    local left, right, top, bottom = self.Control:GetTextureCoords()
    return texture, left, right, top, bottom
end