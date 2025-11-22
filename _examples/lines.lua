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


function lib.examples.createKubeOutOfLines(size)
    local lines = {}
    local halfSize = size / 2
    local _, x, y, z = GetUnitRawWorldPosition("player")
    y = y + halfSize
    local texture = "Lib3DObjects/textures/arrow.dds"
    local corners = {
        {x - halfSize, y - halfSize, z - halfSize},
        {x + halfSize, y - halfSize, z - halfSize},
        {x + halfSize, y + halfSize, z - halfSize},
        {x - halfSize, y + halfSize, z - halfSize},
        {x - halfSize, y - halfSize, z + halfSize},
        {x + halfSize, y - halfSize, z + halfSize},
        {x + halfSize, y + halfSize, z + halfSize},
        {x - halfSize, y + halfSize, z + halfSize},
    }
    local edges = {
        {1, 2}, {2, 3}, {3, 4}, {4, 1},
        {5, 6}, {6, 7}, {7, 8}, {8, 5},
    }
    for _, edge in ipairs(edges) do
        local startCorner = corners[edge[1]]
        local endCorner = corners[edge[2]]
        local line = lib.Line:New(texture,
                startCorner[1], startCorner[2], startCorner[3],
                endCorner[1], endCorner[2], endCorner[3])
        line:SetLineWidth(100)
        line:SetColor(zo_random(), zo_random(), zo_random(), 1)
        table.insert(lines, line)
    end
    for i = 1, 4 do
        local startCorner = corners[i]
        local endCorner = corners[i + 4]
        local line = lib.Line:New(texture,
                startCorner[1], startCorner[2], startCorner[3],
                endCorner[1], endCorner[2], endCorner[3])
        line:SetLineWidth(100)
        line:SetColor(zo_random(), zo_random(), zo_random(), 1)
        table.insert(lines, line)
    end

    -- Set these to control rotation per interval (in radians)
    local intervalMs = 5000
    local rotX = math.pi * 2      -- full rotation around X per interval
    local rotY = math.pi * 2      -- full rotation around Y per interval
    local rotZ = 0 --math.pi * 2      -- full rotation around Z per interval

    local startTime = GetGameTimeMilliseconds()

    local function rotate3D(px, py, pz, cx, cy, cz, ax, ay, az)
        -- Translate to origin
        local x, y, z = px - cx, py - cy, pz - cz

        -- X axis
        local cosX, sinX = math.cos(ax), math.sin(ax)
        local y1 = y * cosX - z * sinX
        local z1 = y * sinX + z * cosX
        y, z = y1, z1

        -- Y axis
        local cosY, sinY = math.cos(ay), math.sin(ay)
        local x1 = x * cosY + z * sinY
        local z2 = -x * sinY + z * cosY
        x, z = x1, z2

        -- Z axis
        local cosZ, sinZ = math.cos(az), math.sin(az)
        local x2 = x * cosZ - y * sinZ
        local y2 = x * sinZ + y * cosZ
        x, y = x2, y2

        -- Translate back
        return x + cx, y + cy, z + cz
    end

    for _, line in ipairs(lines) do
        line.origStartX, line.origStartY, line.origStartZ = line.startX, line.startY, line.startZ
        line.origEndX, line.origEndY, line.origEndZ = line.endX, line.endY, line.endZ

        line:AddCallback(function(self, distanceToPlayer, distanceToCamera)
            local now = GetGameTimeMilliseconds()
            local elapsed = (now - startTime) % intervalMs
            local frac = elapsed / intervalMs
            local angleX = frac * rotX
            local angleY = frac * rotY
            local angleZ = frac * rotZ

            local startX, startY, startZ = rotate3D(self.origStartX, self.origStartY, self.origStartZ, x, y, z, angleX, angleY, angleZ)
            local endX, endY, endZ = rotate3D(self.origEndX, self.origEndY, self.origEndZ, x, y, z, angleX, angleY, angleZ)
            self:SetStartPoint(startX, startY, startZ)
            self:SetEndPoint(endX, endY, endZ)
        end)
    end

    return lines
end

function lib.examples.createPointingArrowLine()
    local _, x, y, z = GetUnitRawWorldPosition("player")
    local line = lib.Line:New("Lib3DObjects/textures/arrow.dds", x, y, z)
    line:SetLineWidth(200)
    line:SetColor(1, 1, 0)
    line:SetAlpha(0.5)

    line:AddCallback(function(self, distanceToPlayer, distanceToCamera)
        local _, px, py, pz = GetUnitRawWorldPosition("player")
        self:SetStartPoint(px, py, pz)

        local pitch = 0
        local yaw = -GetPlayerCameraHeading() - ZO_PI / 2
        self:SetEndpointFromDirectionVector(3000, pitch, yaw)
    end)

    return line
end