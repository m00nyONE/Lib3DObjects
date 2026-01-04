local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject
local RenderSpaceRenderer = lib.renderer.RenderSpaceRenderer

local Texture3D = BaseObject:Subclass()
lib.Texture3D = Texture3D

function Texture3D:Initialize(texture)
    BaseObject.Initialize(self, "Lib3DObjects_Texture3D", self, RenderSpaceRenderer)
    local _, pX, pY, pZ = GetUnitRawWorldPosition("player")
    self:SetPosition(pX, pY, pZ)

    self:SetTexture(texture)

    self:SetDrawDistanceMeters(75)
    self:SetAlpha(1)


    --TEX_BLEND_MODE_ADD = 1
    --TEX_BLEND_MODE_ALPHA = 0
    --TEX_BLEND_MODE_COLOR_DODGE = 2
    --self.Control:SetBlendMode(TEX_BLEND_MODE_ADD)
    --zo_callLater(function()
    --    self.Control:SetBlendMode(TEX_BLEND_MODE_ALPHA)
    --end, 2000)
    --zo_callLater(function()
    --    self.Control:SetBlendMode(TEX_BLEND_MODE_COLOR_DODGE)
    --end, 4000)
end

function Texture3D:Destroy()
    self:SetTexture(nil)
    self:SetHeight(100)
    self:SetWidth(100)
    self:SetScale(1)

    BaseObject.Destroy(self)
end

function Texture3D:SetColor(r, g, b, a)
    self.Control:SetColor(r, g, b, a)
end
function Texture3D:GetColor()
    return self.Control:GetColor()
end
function Texture3D:SetDimensions(width, height)
    self.Control:SetDimensions(width, height)
end
function Texture3D:GetDimensions()
    return self.Control:GetDimensions()
end
function Texture3D:SetHeight(height)
    self.Control:SetHeight(height)
end
function Texture3D:GetHeight()
    return self.Control:GetHeight()
end
function Texture3D:SetWidth(width)
    self.Control:SetWidth(width)
end
function Texture3D:GetWidth()
    return self.Control:GetWidth()
end
function Texture3D:SetTexture(texturePath, left, right, top, bottom)
    self.Control:SetTexture(texturePath)
    self.Control:SetTextureCoords(left or 0, right or 1, top or 0, bottom or 1)
end
function Texture3D:GetTexture()
    local texture = self.Control:GetTextureFileName()
    local left, right, top, bottom = self.Control:GetTextureCoords()
    return texture, left, right, top, bottom
end





