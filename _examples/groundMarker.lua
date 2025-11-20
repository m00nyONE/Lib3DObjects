local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

lib.examples = lib.examples or {}

local AUTOROTATE_NONE = lib.AUTOROTATE_NONE
local AUTOROTATE_CAMERA = lib.AUTOROTATE_CAMERA
local AUTOROTATE_PLAYER = lib.AUTOROTATE_PLAYER

function lib.examples.createSingleGroundMarker()
    local _, x, y, z = GetUnitRawWorldPosition("player")
    local marker = lib.GroundMarker:New(nil, x, y, z)
    marker:SetColor(1,0,0,1)

    return marker
end

function lib.examples.createGroundMarkerArray(count)
    local markers = {}
    local radius = 1000
    local angleStep = (2 * math.pi) / count
    local _, centerX, centerY, centerZ = GetUnitRawWorldPosition("player")

    for i = 0, count - 1 do
        local angle = i * angleStep
        local offsetX = radius * math.cos(angle)
        local offsetY = 0
        local offsetZ = radius * math.sin(angle)

        local marker = lib.GroundMarker:New(nil, centerX + offsetX, centerY + offsetY, centerZ + offsetZ)
        marker:SetColor(math.random(), math.random(), math.random(), 1)
        table.insert(markers, marker)
    end

    return markers
end

