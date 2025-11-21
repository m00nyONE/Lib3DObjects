local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

lib.examples = lib.examples or {}

local continuousRotation = lib.animations.CreateContinuesRotationAnimation(function() return true  end, 2, 0, 90, 0)
local bounceAnimation = lib.animations.CreateSingleBounceAnimation(500, 1, 100)
local scaleToTwoAnimation = lib.animations.CreateSingleScaleAnimation(500, 2)
local scaleToOneAnimation = lib.animations.CreateSingleScaleAnimation(500, 1)
local enterRadiusCallback = function(self, distanceToPlayer, distanceToCamera)
    self:AddCallback(bounceAnimation())
    self:AddCallback(scaleToOneAnimation())
end
local leaveRadiusCallback = function(self, distanceToPlayer, distanceToCamera)
    self:AddCallback(scaleToTwoAnimation())
end
local radiusTrigger = lib.animations.CreateRadiusTrigger(500, enterRadiusCallback, leaveRadiusCallback)

--- creates a single reactive ground marker at player's position
function lib.examples.createSingleReactiveGroundMarker()
    local _, x, y, z = GetUnitRawWorldPosition("player")
    local reactiveMarker = lib.GroundMarker:New("/art/fx/texture/arcanist_support03_wardring.dds", x, y, z)
    reactiveMarker:AddCallback(radiusTrigger())
    reactiveMarker:AddCallback(continuousRotation())

    reactiveMarker:SetAlpha(1)
    reactiveMarker:SetColor(0, 1, 0)
end

--- Create an array of reactive ground markers around you.
--- @param count number Number of markers to create.
--- @return table Table of created reactive ground markers.
function lib.examples.createReactiveGroundMarkerArray(count)
    local markers = {}
    local radius = 1000
    local angleStep = (2 * math.pi) / count
    local _, centerX, centerY, centerZ = GetUnitRawWorldPosition("player")

    for i = 0, count - 1 do
        local angle = i * angleStep
        local offsetX = radius * math.cos(angle)
        local offsetY = 0
        local offsetZ = radius * math.sin(angle)

        local reactiveMarker = lib.GroundMarker:New(nil, centerX + offsetX, centerY + offsetY, centerZ + offsetZ)
        reactiveMarker:AddCallback(radiusTrigger())
        reactiveMarker:AddCallback(continuousRotation())

        reactiveMarker:SetTexture("/art/fx/texture/arcanist_support03_wardring.dds")
        reactiveMarker:SetAlpha(1)
        reactiveMarker:SetColor(math.random(), math.random(), math.random())
        table.insert(markers, reactiveMarker)
    end

    return markers
end

--- Create a concentric array of reactive ground markers.
--- @param ringCount number Number of rings to create.
--- @param markersStart number Number of markers in the first ring.
--- @param radiusStart number Radius of the first ring.
--- @param radiusStep number Increase in radius for each subsequent ring.
--- @return table Table of created reactive ground markers.
function lib.examples.createReactiveGroundMarkerConcentricArray(ringCount, markersStart, radiusStart, radiusStep)
    local markers = {}
    local _, centerX, centerY, centerZ = GetUnitRawWorldPosition("player")

    for ring = 1, ringCount do
        local radius = radiusStart + (ring - 1) * radiusStep
        local markerCount = markersStart + (ring - 1) * markersStart -- Increase marker count per ring
        local angleStep = (2 * math.pi) / markerCount

        for i = 0, markerCount - 1 do
            local angle = i * angleStep
            local offsetX = radius * math.cos(angle)
            local offsetY = 0
            local offsetZ = radius * math.sin(angle)

            local reactiveMarker = lib.GroundMarker:New(nil, centerX + offsetX, centerY + offsetY, centerZ + offsetZ)
            reactiveMarker:AddCallback(radiusTrigger())
            reactiveMarker:AddCallback(continuousRotation())

            reactiveMarker:SetTexture("/art/fx/texture/arcanist_support03_wardring.dds")
            reactiveMarker:SetAlpha(1)
            reactiveMarker:SetColor(math.random(), math.random(), math.random())
            table.insert(markers, reactiveMarker)
        end
    end

    return markers
end