local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

lib.examples = lib.examples or {}

function lib.examples.createSingleLine()
    local _, x1, y1, z1 = GetUnitRawWorldPosition("player")
    local x2, y2, z2 = x1 + 2500, y1, z1 + 2500

    local line = lib.Line:New(nil, x1, y1, z1, x2, y2, z2)
    line:SetColor(0, 1, 0, 1)
    line:AddCallback(function(self, distanceToPlayer, distanceToCamera)
        local _, x, y, z = GetUnitRawWorldPosition("player")
        self:SetStartPoint(x, y, z)
        local length = self:GetLineLength()
        if length > 2600 then
            self:SetColor(1, 0, 0, 1)
        else
            self:SetColor(0, 1, 0, 1)
        end
        --local directionX = (x2 - x1) / length
        --local directionY = (y2 - y1) / length
        --local directionZ = (z2 - z1) / length
        --self:SetEndPoint(x + directionX * length, y + directionY * length, z + directionZ * length)
    end)

    return line
end

function lib.examples.createLineSphere(count)
    local lines = {}
    local radius = 2000
    local angleStep = (2 * math.pi) / count
    local _, centerX, centerY, centerZ = GetUnitRawWorldPosition("player")

    for i = 0, count - 1 do
        local angle1 = i * angleStep
        local angle2 = ((i + 1) % count) * angleStep

        local x1 = centerX + radius * math.cos(angle1)
        local y1 = centerY
        local z1 = centerZ + radius * math.sin(angle1)

        local x2 = centerX + radius * math.cos(angle2)
        local y2 = centerY
        local z2 = centerZ + radius * math.sin(angle2)

        local line = lib.Line:New(nil, x1, y1, z1, x2, y2, z2)
        line:SetColor(math.random(), math.random(), math.random(), 1)
        table.insert(lines, line)
    end

    return lines
end
