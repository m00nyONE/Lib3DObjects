-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

--[[ doc.lua begin ]]
local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObjectGroup = lib.BaseObjectGroup
--- @class PositionAxis : BaseObjectGroup
local PositionAxis = BaseObjectGroup:Subclass()
lib.PositionAxis = PositionAxis

function PositionAxis:Initialize(object)
    BaseObjectGroup.Initialize(self)
    self.attachedToObject = nil
    self.attachedToUnit = nil

    local x, y, z = 0, 0, 0

    if object then
        self.attachedToObject = object
        x, y, z = object:GetFullPosition()
    else
        self.attachedToUnit = "player"
        local _, pX, pY, pZ = GetUnitRawWorldPosition("player")
        x, y, z = pX, pY, pZ
    end

    self:SetReferencePoint(x, y, z)

    self.arrowSize = 150
    self.arrowWidth = 50
    self.labelOffset = 50

    local xArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", x, y, z, x + self.arrowSize, y, z)
    xArrow:SetColor(1, 0, 0, 1)
    xArrow:SetLineWidth(self.arrowWidth)
    self.xArrow = xArrow
    local xLabel = lib.Text:New("X", x + self.arrowSize + self.labelOffset, y, z)
    xLabel:SetColor(1, 0, 0, 1)
    xLabel:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    self.xLabel = xLabel

    local yArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", x, y, z, x, y + self.arrowSize, z)
    yArrow:SetColor(0, 1, 0, 1)
    yArrow:SetLineWidth(self.arrowWidth)
    self.yArrow = yArrow
    local yLabel = lib.Text:New("Y", x, y + self.arrowSize + self.labelOffset, z)
    yLabel:SetColor(0, 1, 0, 1)
    yLabel:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    self.yLabel = yLabel

    local zArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", x, y, z, x, y, z + self.arrowSize)
    zArrow:SetColor(0, 0, 1, 1)
    zArrow:SetLineWidth(self.arrowWidth)
    self.zArrow = zArrow
    local zLabel = lib.Text:New("Z", x, y, z + self.arrowSize + self.labelOffset)
    zLabel:SetColor(0, 0, 1, 1)
    zLabel:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    self.zLabel = zLabel

    self:Add(self.xArrow, self.yArrow, self.zArrow)
    self:Add(self.xLabel, self.yLabel, self.zLabel)

    self:AddCallback(self._UpdatePosition)
    self:AddCallback(self._UpdateObjects)
end

function PositionAxis:AttachToObject(obj)
    self:DetachFromUnit()
    self.attachedToObject = obj
end
function PositionAxis:DetachFromObject()
    self.attachedToObject = nil
end
function PositionAxis:AttachToUnit(unitTag)
    self:DetachFromObject()
    self.attachedToUnit = unitTag
end
function PositionAxis:DetachFromUnit()
    self.attachedToUnit = nil
end

function PositionAxis:_UpdatePosition()
    if self.attachedToObject then
        local x, y, z = self.attachedToObject:GetPosition()
        self:SetReferencePoint(x, y, z)
        return
    end

    if self.attachedToUnit then
        local _, x, y, z = GetUnitRawWorldPosition(self.attachedToUnit)
        self:SetReferencePoint(x, y, z)
        return
    end
end

function PositionAxis:_UpdateObjects()
    local x, y, z = self:GetReferencePoint()
    local arrowSize = self.arrowSize
    local labelOffset = self.labelOffset

    self.xArrow:SetStartPoint(x, y, z)
    self.xArrow:SetEndPoint(x + arrowSize, y, z)
    self.xLabel:SetPosition(x + arrowSize + labelOffset, y, z)

    self.yArrow:SetStartPoint(x, y, z)
    self.yArrow:SetEndPoint(x, y + arrowSize, z)
    self.yLabel:SetPosition(x, y + arrowSize + labelOffset, z)

    self.zArrow:SetStartPoint(x, y, z)
    self.zArrow:SetEndPoint(x, y, z + arrowSize)
    self.zLabel:SetPosition(x, y, z + arrowSize + labelOffset)
end
--[[ doc.lua end ]]