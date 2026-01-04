-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

--[[ doc.lua begin ]]
local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObjectGroup = lib.BaseObjectGroup
--- @class NormalVector : BaseObjectGroup
local NormalVector = BaseObjectGroup:Subclass()
lib.NormalVector = NormalVector

function NormalVector:Initialize(object)
    BaseObjectGroup.Initialize(self)

    self.attachedToObject = object

    self:SetReferencePoint(object:GetFullPosition())

    self.arrowSize = 100
    self.arrowWidth = 100

    local arrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", self:GetPosition())
    arrow:SetDrawDistance(math.huge)
    arrow:SetColor(1, 1, 1, 1)
    arrow:SetLineWidth(self.arrowWidth)
    self.arrow = arrow

    local label = lib.Text:New("Normal Vector", self:GetPosition())
    label:SetDrawDistance(math.huge)
    label:SetColor(1, 1, 1, 1)
    label:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    self.label = label

    self:Add(self.arrow)
    self:Add(self.label)

    self:AddCallback(self._UpdatePosition)
    self:AddCallback(self._UpdateObjects)
end

function NormalVector:AttachToObject(obj)
    self.attachedToObject = obj
end

function NormalVector:_UpdatePosition()
    local x, y, z = self.attachedToObject:GetFullPosition()
    self:SetReferencePoint(x, y, z)
end

function NormalVector:_UpdateObjects()
    local fX, fY, fZ = self.attachedToObject:GetNormalVector()
    local posX, posY, posZ = self:GetReferencePoint()
    local endX, endY, endZ = posX + fX * self.arrowSize, posY + fY * self.arrowSize, posZ + fZ * self.arrowSize
    self.arrow:SetStartPoint(posX, posY, posZ)
    self.arrow:SetEndPoint(endX, endY, endZ)
    self.label:SetPosition(endX, endY, endZ)
    self.label:SetText(string.format("(%.2f, %.2f, %.2f)", fX, fY, fZ))
end