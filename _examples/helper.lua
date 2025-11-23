local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

lib.examples = lib.examples or {}

function lib.examples.createAxis(length)
    length = length or 500

    local markers = {}

    local _, pX, pY, pZ = GetUnitRawWorldPosition("player")

    local function updatePoints(lengthX, lengthY, lengthZ)
        return function(self, distanceToPlayer, distanceToCamera)
            local _, x, y, z = GetUnitRawWorldPosition("player")
            self:SetStartPoint(x, y, z)
            self:SetEndPoint(x + lengthX or 0, y + lengthY or 0, z + lengthZ or 0)
        end
    end

    -- X axis (red)
    local xArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", pX, pY, pZ, pX + length, pY, pZ)
    xArrow:SetColor(1, 0, 0, 1)
    xArrow:SetLineWidth(100)
    xArrow:AddCallback(updatePoints(length, 0, 0))
    table.insert(markers, xArrow)
    local xArrowText = lib.Text:New("X (ROLL)", pX + length + 50, pY, pZ)
    xArrowText:SetColor(1, 0, 0, 1)
    xArrowText:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    xArrowText:AddCallback(function(self, _, _)
        local _, x, y, z = GetUnitRawWorldPosition("player")
        self:SetPosition(x + length + 50, y, z)
    end)
    table.insert(markers, xArrowText)

    -- Y axis (green)
    local yArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", pX, pY, pZ, pX, pY + length, pZ)
    yArrow:SetLineWidth(100)
    yArrow:SetColor(0, 1, 0, 1)
    yArrow:AddCallback(updatePoints(0, length, 0))
    table.insert(markers, yArrow)
    local yArrowText = lib.Text:New("Y (YAW)", pX, pY + length + 50, pZ)
    yArrowText:SetColor(0, 1, 0, 1)
    yArrowText:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    yArrowText:AddCallback(function(self, _, _)
        local _, x, y, z = GetUnitRawWorldPosition("player")
        self:SetPosition(x, y + length + 50, z)
    end)
    table.insert(markers, yArrowText)

    -- Z axis (blue)
    local zArrow = lib.Line:New("Lib3DObjects/textures/arrow.dds", pX, pY, pZ, pX, pY, pZ + length)
    zArrow:SetLineWidth(100)
    zArrow:SetColor(0, 0, 1, 1)
    zArrow:AddCallback(updatePoints(0, 0, length))
    table.insert(markers, zArrow)
    local zArrowText = lib.Text:New("Z (PITCH)", pX, pY, pZ + length + 50)
    zArrowText:SetColor(0, 0, 1, 1)
    zArrowText:SetAutoRotationMode(lib.AUTOROTATE_CAMERA)
    zArrowText:AddCallback(function(self, _, _)
        local _, x, y, z = GetUnitRawWorldPosition("player")
        self:SetPosition(x, y, z + length + 50)
    end)
    table.insert(markers, zArrowText)


    return markers
end
