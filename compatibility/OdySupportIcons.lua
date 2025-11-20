-- this is a stub for OSI's mechanic and ground icons
-- TODO: create a translator for callbacks between OSI and Lib3DObjects
local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local EM = GetEventManager()

local OSI = OSI or {}

-- cache of unit names to unit tags
local unitCache = {}
EM:RegisterForEvent(lib_name .. "_UnitCache", EVENT_GROUP_UPDATE, function()
    ZO_ClearTable(unitCache)

    local groupSize = GetGroupSize()
    for i = 1, groupSize do
        local unitTag = GetGroupUnitTagByIndex(i)
        local name = GetUnitName(unitTag)
        if name and name ~= "" then
            unitCache[string.lower(name)] = unitTag
        end
    end
end)

function OSI.CreatePositionIcon( x, y, z, texture, size, color, offset, callback )
    local marker = lib.FloatingMarker:New(texture, x, y, z, offset)
    marker:SetColor( unpack(color) )
    marker:AddCallback(callback)

    return marker
end

function OSI.DiscardPositionIcon( icon )
    icon:Destroy()
end

-- exposed function to assign mechanic icon
function OSI.SetMechanicIconForUnit( displayName, texture, size, color, offset, callback )
    local unitTag = unitCache[string.lower( displayName )]
    if not unitTag then return end

    local marker = lib.UnitMarker:New(texture, unitTag, offset)
    marker:SetColor(unpack(color))
    marker:AddCallback(callback)
end

-- exposed function to remove mechanic icon
function OSI.RemoveMechanicIconForUnit( displayName )
    if not OSI.mechanic then
        return
    end
    OSI.mechanic[string.lower( displayName )] = nil
end