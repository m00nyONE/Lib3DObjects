--- you should ABSOLUTELY NOT be using this compatibility layer for new development
--- this is ONLY for compatibility with addons that used the OSI icon system

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local EM = GetEventManager()

local AUTOROTATE_CAMERA = lib.AUTOROTATE_CAMERA
local BaseObject = lib.BaseObject

local OSICompatibleIcon = BaseObject:Subclass()
lib.OSICompatibleIcon = OSICompatibleIcon

local baseColor = {1, 1, 1}
local unitCache = {}
EM:RegisterForEvent(lib_name .. "_UnitCache", EVENT_GROUP_UPDATE, function()
    ZO_ClearTable(unitCache)

    for i = 1, GetGroupSize() do
        local unitTag = GetGroupUnitTagByIndex(i)
        local name = GetUnitName(unitTag)
        if name and name ~= "" then
            unitCache[string.lower(name)] = unitTag
        end
    end
end)
-- static method to get unit tag from display name
local function GetUnitTagFromDisplayName(displayName)
    return unitCache[string.lower(displayName)]
end

--- @class OSICompatibleIcon : BaseObject
function OSICompatibleIcon:Initialize(texture, size, color, offset, callback)
    BaseObject.Initialize(self, "Lib3DObjects_OSICompatibleIcon", self)
    local _, x, y, z = GetUnitRawWorldPosition("player")
    self:SetPosition(x, y, z)

    self.use = true
    self.ctrl = self.Control
    self:SetTexture(texture)
    self.callback = callback
    self.data = {
        texture     = texture,
        size        = size or 100,
        color       = color or baseColor,
        offset      = offset or 0,
        displayName = nil,
    }

    self:SetAutoRotationMode(AUTOROTATE_CAMERA)

    -- hook Update method to apply custom properties
    self.BaseObjectUpdate = self.Update
    self.Update = function()
        self:UpdatePreHook()
        self:BaseObjectUpdate()
    end
end

function OSICompatibleIcon:Destroy()
    self.ctrl:SetTexture(nil)
    self.ctrl:SetTextureCoords(0, 1, 0, 1)
    self.ctrl:SetColor(1, 1, 1, 1)
    self.data.color = nil
    self.data = nil
    BaseObject.Destroy(self)
end

function OSICompatibleIcon:UpdatePreHook()
    self.visible = self.use
    if not self.visible then return end

    local data = self.data
    if data.texture then self:SetTexture(data.texture) end
    if data.color then self:SetColor(data.color) end
    if data.size then self:SetSize(data.size, data.size) end
    if data.offset then self:SetPositionOffsetY(data.offset) end
    if data.displayName then self:MoveToUnitWithDisplayName(data.displayName) end

    if self.callback then
        self.callback(self.data)
    end

    if self.x or self.y or self.z then
        self:SetPosition(self.x, self.y, self.z)
    end
end

function OSICompatibleIcon:MoveToUnitWithDisplayName(displayName)
    local unitTag = GetUnitTagFromDisplayName(displayName)
    if not unitTag then return end

    local _, x, y, z = GetUnitRawWorldPosition(unitTag)
    self.x, self.y, self.z = x, y, z
    self:SetPosition(x, y, z)
end

function OSICompatibleIcon:SetTexture(texture)
    texture = string.gsub(string.lower(texture), "odysupporticons/icons/", "Lib3DObjects/compatibility/OSI/icons/")
    self.ctrl:SetTexture(texture)
    self.ctrl:SetTextureCoords(0, 1, 0, 1)
end
function OSICompatibleIcon:SetColor(color)
    self.ctrl:SetColor(color)
end

function OSICompatibleIcon:SetSize(size)
    self.ctrl:SetDimensions(size, size)
end