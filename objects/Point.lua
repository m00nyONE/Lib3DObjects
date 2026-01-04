-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

local Point = BaseObject:Subclass()
lib.Point = Point

function Point:Initialize(x, y, z)
    BaseObject.Initialize(self, "Lib3DObjects_Point", self)
    local _, pX, pY, pZ = GetUnitRawWorldPosition("player")
    self:SetPosition(x or pX, y or pY, z or pZ)

    self.PointControl = self.Control:GetNamedChild("_Point")
    self.LabelControl = self.Control:GetNamedChild("_Label")
    self.PositionControl = self.Control:GetNamedChild("_Position")

    self:SetTexture("Lib3DObjects/textures/plus.dds")
    self.PositionControl:SetHidden(true)

    self:AddCallback(function(obj, distanceToPlayer, distanceToCamera)
        obj.Control:GetNamedChild("_Position"):SetText(string.format("X: %d Y: %d Z: %d", self:GetFullPosition()))
    end)

    self:RotateToCamera()
    self:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)

    self:SetDrawDistanceMeters(100)
    self:SetAlpha(0.75)
end

function Point:Destroy()
    self.PointControl:SetHidden(false)
    self:SetTexture(nil)
    self.LabelControl:SetHidden(false)
    self:SetLabel("")
    self.PositionControl:SetHidden(false)

    BaseObject.Destroy(self)
end

function Point:SetTexture(texturePath, left, right, top, bottom)
    self.PointControl:SetTexture(texturePath)
    self.PointControl:SetTextureCoords(left or 0, right or 1, top or 0, bottom or 1)
end
function Point:GetTexture()
    local texture = self.PointControl:GetTextureFileName()
    local left, right, top, bottom = self.PointControl:GetTextureCoords()
    return texture, left, right, top, bottom
end
function Point:SetLabel(text)
    self.LabelControl:SetText(text)
end
function Point:GetLabel()
    return self.LabelControl:GetText()
end

function Point:SetColor(r, g, b, a)
    self.PointControl:SetColor(r, g, b, a)
    self.LabelControl:SetColor(r, g, b, a)
    self.PositionControl:SetColor(r, g, b, a)
end
function Point:GetColor()
    return self.PointControl:GetColor()
end
function Point:ShowPosition(show)
    self.PositionControl:SetHidden(not show)
end
function Point:IsPositionShown()
    return not self.PositionControl:IsHidden()
end