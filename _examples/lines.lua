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