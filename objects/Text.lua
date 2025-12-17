local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

local Text = BaseObject:Subclass()
lib.Text = Text

function Text:Initialize(text, x, y, z)
    BaseObject.Initialize(self, "Lib3DObjects_Text", self)
    local _, pX, pY, pZ = GetUnitRawWorldPosition("player")
    self:SetPosition(x or pX, y or pY, z or pZ)

    self:SetText(text or "")

    self:SetDrawDistanceMeters(75)
    self:SetAlpha(1)

    self.originalFont = self:GetFont()
end

function Text:Destroy()
    self:SetText("")
    self:SetFont(self.originalFont)
    self:SetDimensions(200, 200)
    BaseObject.Destroy(self)
end

function Text:SetText(text)
    self.Control:SetText(text)
end
function Text:GetText()
    return self.Control:GetText()
end
function Text:SetFont(fontString)
    self.Control:SetFont(fontString)
end
function Text:GetFont()
    return self.Control:GetFont()
end

function Text:SetColor(r, g, b, a)
    self.Control:SetColor(r, g, b, a)
end
function Text:GetColor()
    return self.Control:GetColor()
end
function Text:SetDimensions(width, height)
    self.Control:SetDimensions(width, height)
end
function Text:GetDimensions()
    return self.Control:GetDimensions()
end
function Text:SetHeight(height)
    self.Control:SetHeight(height)
end
function Text:GetHeight()
    return self.Control:GetHeight()
end
function Text:SetWidth(width)
    self.Control:SetWidth(width)
end
function Text:GetWidth()
    return self.Control:GetWidth()
end