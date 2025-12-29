local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObject = lib.BaseObject

local EM = GetEventManager()

local Marker = BaseObject:Subclass()
lib.Marker = Marker

function Marker:Initialize(texture)
    BaseObject.Initialize(self, "Lib3DObjects_Marker", self)
    local _, x, y, z = GetUnitRawWorldPosition("player")
    self:SetPosition(x, y, z)

    self.BackgroundControl = self.Control:GetNamedChild("_Background")
    self.TextControl = self.Control:GetNamedChild("_Text")

    self.AnimationControl = self.Control:GetNamedChild("_Animation")
    self.AnimationControl:SetTexture("esoui/art/actionBar/abilityHighlightAnimation.dds") --self:SetAnimationTexture("esoui/art/actionBar/abilityHighlightAnimation.dds", 0, 1, 0, 1)
    self.AnimationControl:SetTextureCoords(0, 1, 0, 1)
    if not self.AnimationControl.animation then
        self.AnimationControl.animation = CreateSimpleAnimation(ANIMATION_TEXTURE, self.AnimationControl)
    end
    self.Animation = self.AnimationControl.animation
    self.Animation:SetImageData(64, 1) --self:SetAnimationImageData(64, 1)
    self.Animation:SetFramerate(30) --self:SetAnimationFramerate(30)
    self.Animation:GetTimeline():SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
    self.Animation:SetHandler("OnStop", function() self.AnimationControl:SetTextureCoords(0, 1, 0, 1) end)

    self:SetTexture(texture)

    self:RotateToCamera()

    self:SetDrawDistanceMeters(75)
    self:SetAlpha(0.75)
end

-- TODO: implement
function Marker:Import(properties)

end
-- TODO: implement
function Marker:Export()
    local data = {}

    return data
end

function Marker:Destroy()
    self.BackgroundControl:SetHidden(false)
    self:SetTexture(nil)

    self.TextControl:SetHidden(false)
    self:SetText("")

    -- TODO: use animation pool
    self.Animation:GetTimeline():Stop()
    self.AnimationControl:SetHidden(true)
    BaseObject.Destroy(self)
end

function Marker:SetTexture(texturePath, left, right, top, bottom)
    self.BackgroundControl:SetTexture(texturePath)
    self.BackgroundControl:SetTextureCoords(left or 0, right or 1, top or 0, bottom or 1)
end
function Marker:GetTexture()
    local texture = self.BackgroundControl:GetTextureFileName()
    local left, right, top, bottom = self.BackgroundControl:GetTextureCoords()
    return texture, left, right, top, bottom
end
function Marker:SetText(text)
    self.TextControl:SetText(text)
end
function Marker:GetText()
    return self.TextControl:GetText()
end
function Marker:SetFont(fontString)
    self.TextControl:SetFont(fontString)
end
function Marker:GetFont()
    return self.TextControl:GetFont()
end

function Marker:SetColor(r, g, b, a)
    self.BackgroundControl:SetColor(r, g, b, a)
end
function Marker:GetColor()
    return self.BackgroundControl:GetColor()
end

--- Starts a counter on the marker's text.
--- @param from number starting number
--- @param to number ending number
--- @param tickSeconds number|nil seconds between each tick
--- @param finishCallback function|nil function to call when the counter finishes
--- @return void
function Marker:StartCounter(from, to, tickSeconds, finishCallback)
    local eventName = self.Control:GetName() .. "_Counter"
    local savedText = self.TextControl:GetText()
    local current = from
    self:SetText(tostring(current))
    local function tickUp()
        current = current + 1
        if current > to then
            self:SetText(savedText)
            return false
        else
            self:SetText(tostring(current))
            return true
        end
    end
    local function tickDown()
        current = current - 1
        if current < to then
            self:SetText(savedText)
            return false
        else
            self:SetText(tostring(current))
            return true
        end
    end

    EM:RegisterForUpdate(eventName, (tickSeconds or 1) * 1000, function()
        local continue
        if from < to then
            continue = tickUp()
        else
            continue = tickDown()
        end
        if not continue then
            EM:UnregisterForUpdate(eventName)
            if finishCallback then
                finishCallback()
            end
        end
    end)

end

function Marker:GetAnimation()
    return self.Animation
end

function Marker:SetAnimationTexture(texturePath, left, right, top, bottom)
    self.AnimationControl:SetTexture(texturePath)
    self.AnimationControl:SetTextureCoords(left or 0, right or 1, top or 0, bottom or 1)
end
function Marker:GetAnimationTexture()
    local texture = self.AnimationControl:GetTextureFileName()
    local left, right, top, bottom = self.AnimationControl:GetTextureCoords()
    return texture, left, right, top, bottom
end

function Marker:SetAnimationImageData(columns, rows)
    self.Animation:SetImageData(columns, rows)
end
function Marker:SetAnimationFramerate(framerate)
    self.Animation:SetFramerate(framerate)
end

--- Runs the highlight animation.
--- @return void
function Marker:RunAnimation()
    self.AnimationControl:SetHidden(false)
    if self.Animation:GetTimeline():IsPlaying() then return end

    self.Animation:GetTimeline():PlayFromStart()
end
--- Stops the highlight animation.
--- @return void
function Marker:StopAnimation()
    self.AnimationControl:SetHidden(true)
    self.Animation:GetTimeline():Stop()
end