-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

--- @class Beam : BaseObject
local Beam = BaseObject:Subclass()
lib.Beam = Beam

--- 3D Beam Object
--- @param x number X position
--- @param y number Y position
--- @param z number Z position
--- @return Beam
function Beam:Initialize(x, y, z, drawThroughObjects)
    local renderer = lib.renderer.RenderSpaceRenderer
    local template = "Lib3DObjects_Beam_Render"
    if drawThroughObjects == true then
        renderer = lib.renderer.WorldSpaceRenderer
        template = "Lib3DObjects_Beam_World"
    end
    BaseObject.Initialize(self, template, self, renderer)

    self.defaultTexture = "Lib3DObjects/Textures/beam.dds"

    self:SetPosition(x, y, z)

    self:SetBeamWidth(100)
    self:SetBeamHeight(10000)

    self:SetTexture(self.defaultTexture)

    self:SetDrawDistance(math.huge)
    self:SetAlpha(0.4)

    self:CreateUpdatePreHook(self._UpdatePosition)
    self:AddCallback(self._UpdateRotation)
end

function Beam:Destroy()
    self:SetColor(1, 1, 1, 1)
    self:SetTexture(self.defaultTexture)
    self:SetBeamWidth(100)
    self:SetBeamHeight(10000)
    BaseObject.Destroy(self)
end
function Beam:SetTexture(texturePath, left, right, top, bottom)
    texturePath = texturePath or self.defaultTexture
    self.Control:SetTexture(texturePath)
    self.Control:SetTextureCoords(left or 0, right or 1, top or 0, bottom or 1)
end
function Beam:SetColor(r, g, b, a)
    self.Control:SetColor(r, g, b, a)
end
function Beam:GetColor()
    return self.Control:GetColor()
end
function Beam:SetBeamWidth(width)
    self:SetWidth(width or 100)
end
function Beam:GetBeamWidth()
    return self:GetWidth()
end
function Beam:SetBeamHeight(height)
    height = height or 10000
    self:SetHeight(height)
    self:SetPositionOffsetY(height / 2)
end
function Beam:GetBeamHeight()
    return self:GetHeight()
end

function Beam:_UpdatePosition()
    if self.attachedToUnit then
        local _, x, y, z = GetUnitRawWorldPosition(self.attachedToUnit)
        self:SetPosition(x, y, z)
    end
end
function Beam:_UpdateRotation()
    local fX, _, fZ = GetCameraForward(SPACE_WORLD)
    local yaw = zo_atan2(fX, fZ) - ZO_PI
    self:SetRotation(0, yaw, 0)
end

function Beam:AttachToUnit(unitTag)
    self.attachedToUnit = unitTag
end
function Beam:DetachFromUnit()
    self.attachedToUnit = nil
end