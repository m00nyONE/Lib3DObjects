local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

lib.examples = lib.examples or {}

local scaleToFourAnimation = lib.animations.CreateSingleScaleAnimation(500, 4)
local scaleToOneAnimation = lib.animations.CreateSingleScaleAnimation(500, 1)
local function onMouseEnterCallback(self, distanceToPlayer, distanceToCamera)
    self:AddCallback(scaleToFourAnimation())
    self.TextControl:SetHidden(false)
end
local function onMouseLeaveCallback(self, distanceToPlayer, distanceToCamera)
    self:AddCallback(scaleToOneAnimation())
    self.TextControl:SetHidden(true)
end
local function updateDistanceText(self, distanceToPlayer, distanceToCamera)
    self:SetText(string.format("%.1fm", distanceToPlayer / 100))
end
local onMouseOver = lib.animations.CreateMouseOverTrigger(100, onMouseEnterCallback, onMouseLeaveCallback)

function lib.examples.createSingleReactiveFloatingMarker()
    local _, pX, pY, pZ = GetUnitRawWorldPosition("player")
    local marker = lib.FloatingMarker:New(nil, pX, pY, pZ, 0)
    marker:SetDrawDistanceMeters(200)
    marker:SetColor(0, 0, 1, 1)
    marker:AddCallback(updateDistanceText)
    marker:AddCallback(marker.MoveToCursor)
end

function lib.examples.createReactiveFloatingMarkerArray(count)
    local markers = {}
    local radius = 5000
    local angleStep = (2 * math.pi) / count
    local _, centerX, centerY, centerZ = GetUnitRawWorldPosition("player")

    for i = 0, count - 1 do
        local angle = i * angleStep
        local offsetX = radius * math.cos(angle)
        local offsetZ = radius * math.sin(angle)

        local marker = lib.FloatingMarker:New(nil, centerX + offsetX, centerY, centerZ + offsetZ, 1000)
        marker:SetDrawDistanceMeters(200)
        marker:SetColor(math.random(), math.random(), math.random(), 1)
        marker:AddCallback(onMouseOver())
        marker:AddCallback(updateDistanceText)
        marker.TextControl:SetHidden(true)
        table.insert(markers, marker)
    end

    return markers
end