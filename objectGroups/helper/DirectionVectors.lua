-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

--[[ doc.lua begin ]]
local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObjectGroup = lib.BaseObjectGroup
--- @class DirectionVectors : BaseObjectGroup
local DirectionVectors = BaseObjectGroup:Subclass()
lib.DirectionVectors = DirectionVectors

--- @param object BaseObject The object to which the direction vectors will be attached
--- 3D Direction Vectors Object Group
function DirectionVectors:Initialize(object)
    BaseObjectGroup.Initialize(self)

    self.attachedToObject = object

    self:SetReferencePoint(object:GetFullPosition())

    self.arrowSize = 100
    self.arrowWidth = 50
    self.labelOffset = 100

    local colorForward = {0, 0, 1, 1}
    local colorUp = {0, 1, 0, 1}
    local colorRight = {1, 0, 0, 1}
    local drawDistance = math.huge

    local forwardArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", self:GetPosition())
    forwardArrow:SetDrawDistance(drawDistance)
    forwardArrow:SetColor(unpack(colorForward))
    forwardArrow:SetLineWidth(self.arrowWidth)
    self.forwardArrow = forwardArrow
    local forwardLabel = lib.Text:New("Forward Vector", self:GetPosition())
    forwardLabel:SetDrawDistance(drawDistance)
    forwardLabel:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    self.forwardLabel = forwardLabel

    local upArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", self:GetPosition())
    upArrow:SetDrawDistance(drawDistance)
    upArrow:SetColor(unpack(colorUp))
    upArrow:SetLineWidth(self.arrowWidth)
    self.upArrow = upArrow
    local upLabel = lib.Text:New("Up Vector", self:GetPosition())
    upLabel:SetDrawDistance(drawDistance)
    upLabel:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    self.upLabel = upLabel

    local rightArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", self:GetPosition())
    rightArrow:SetDrawDistance(drawDistance)
    rightArrow:SetColor(unpack(colorRight))
    rightArrow:SetLineWidth(self.arrowWidth)
    self.rightArrow = rightArrow
    local rightLabel = lib.Text:New("Right Vector", self:GetPosition())
    rightLabel:SetDrawDistance(drawDistance)
    rightLabel:SetAutoRotationMode(l3do.AUTOROTATE_CAMERA)
    self.rightLabel = rightLabel


    self:Add(self.forwardArrow, self.upArrow, self.rightArrow)
    self:Add(self.forwardLabel, self.upLabel, self.rightLabel)

    self:AddCallback(self._UpdatePosition)
    self:AddCallback(self._UpdateObjects)
end

function DirectionVectors:AttachToObject(obj)
    self.attachedToObject = obj
end

function DirectionVectors:_UpdatePosition()
    local x, y, z = self.attachedToObject:GetFullPosition()
    self:SetReferencePoint(x, y, z)
end

function DirectionVectors:_UpdateObjects()
    local posX, posY, posZ = self:GetReferencePoint()
    local fX, fY, fZ = self.attachedToObject:GetForwardVector()
    local uX, uY, uZ = self.attachedToObject:GetUpVector()
    local rX, rY, rZ = self.attachedToObject:GetRightVector()
    local fEndX, fEndY, fEndZ = posX + fX * self.arrowSize, posY + fY * self.arrowSize, posZ + fZ * self.arrowSize
    local uEndX, uEndY, uEndZ = posX + uX * self.arrowSize, posY + uY * self.arrowSize, posZ + uZ * self.arrowSize
    local rEndX, rEndY, rEndZ = posX + rX * self.arrowSize, posY + rY * self.arrowSize, posZ + rZ * self.arrowSize

    self.forwardArrow:SetStartPoint(posX, posY, posZ)
    self.forwardArrow:SetEndPoint(fEndX, fEndY, fEndZ)
    self.forwardLabel:SetPosition(fEndX, fEndY, fEndZ)
    self.forwardLabel:SetText(string.format("F (%.2f, %.2f, %.2f)", fX, fY, fZ))
    self.upArrow:SetStartPoint(posX, posY, posZ)
    self.upArrow:SetEndPoint(uEndX, uEndY, uEndZ)
    self.upLabel:SetPosition(uEndX, uEndY, uEndZ)
    self.upLabel:SetText(string.format("U (%.2f, %.2f, %.2f)", uX, uY, uZ))
    self.rightArrow:SetStartPoint(posX, posY, posZ)
    self.rightArrow:SetEndPoint(rEndX, rEndY, rEndZ)
    self.rightLabel:SetPosition(rEndX, rEndY, rEndZ)
    self.rightLabel:SetText(string.format("R (%.2f, %.2f, %.2f)", rX, rY, rZ))
end