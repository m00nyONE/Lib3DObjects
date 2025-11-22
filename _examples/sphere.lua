local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

lib.examples = lib.examples or {}


local function discoLightColor(t)
    t = t / 500 -- Slow down the color cycling
    local r = (math.sin(t) + 1) / 2
    local g = (math.sin(t + 2 * ZO_PI / 3) + 1) / 2
    local b = (math.sin(t + 4 * ZO_PI / 3) + 1) / 2
    return r, g, b
end

function lib.examples.create3DSphereMarker(radius, count)
    radius = radius or 2500
    count = count or 100
    local markers = {}
    local phi = ZO_PI * (3 - zo_sqrt(5)) -- golden angle in radians
    local _, centerX, centerY, centerZ = GetUnitRawWorldPosition("player")
    for i = 0, count - 1 do
        local y = 1 - (i / (count - 1)) * 2 -- y goes from 1 to -1
        local radiusAtY = zo_sqrt(1 - y * y) -- radius at y
        local theta = phi * i -- golden angle increment
        local x = zo_cos(theta) * radiusAtY
        local z = zo_sin(theta) * radiusAtY
        local offsetX, offsetY, offsetZ = x * radius, y * radius, z * radius
        local marker = lib.Marker:New(nil)
        marker:SetPosition(centerX, centerY + radius, centerZ)
        marker:SetPositionOffset(offsetX, offsetY, offsetZ)

        -- rotate the control away from the center point
        local dx, dy, dz = offsetX, offsetY, offsetZ
        local distance = zo_distance3D(0, 0, 0, dx, dy, dz)
        local pitch = -math.asin(dy / distance)
        local yaw = zo_atan2(dx, dz)
        marker:SetRotation(pitch, yaw, 0)

        marker:SetColor(zo_random(), zo_random(), zo_random(), 1)
        marker:EnableVisualNormalVector()

        marker:AddCallback(function(object, distanceToPlayer, distanceToCamera)
            local r, g, b = discoLightColor(GetGameTimeMilliseconds() + (100 * i))
            object:SetColor(r, g, b, 1)
        end)
        table.insert(markers, marker)
    end

    return markers
end