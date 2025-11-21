local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

lib.examples = lib.examples or {}

local AUTOROTATE_NONE = lib.AUTOROTATE_NONE
local AUTOROTATE_CAMERA = lib.AUTOROTATE_CAMERA
local AUTOROTATE_PLAYER = lib.AUTOROTATE_PLAYER

function lib.examples.createSingleUnitMarker()
    local marker = lib.UnitMarker:New(nil, "player", nil)
    marker.Control:SetColor(0,1,0,1)

    return marker
end

function lib.examples.createUnitMarkerArray(count)
    local markers = {}
    local radius = 1000
    local angleStep = (2 * math.pi) / count

    for i = 0, count - 1 do
        local angle = i * angleStep
        local offsetX = radius * math.cos(angle)
        local offsetZ = radius * math.sin(angle)

        local marker = lib.UnitMarker:New(nil, "player", nil)
        marker:SetColor(math.random(), math.random(), math.random(), 1)
        marker:SetPositionOffsetX(offsetX)
        marker:SetPositionOffsetZ(offsetZ)
        marker:SetAutoRotationMode(AUTOROTATE_PLAYER)
        table.insert(markers, marker)
    end

    return markers
end