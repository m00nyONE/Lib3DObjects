local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

lib.examples = lib.examples or {}

function lib.examples.createSingleLine()
    local _, x1, y1, z1 = GetUnitRawWorldPosition("player")
    local x2, y2, z2 = x1 + 1000, y1 + 500, z1 + 1000

    local line = lib.Line:New(nil, x1, y1, z1, x2, y2, z2)
    line:SetColor(0, 1, 0, 1)
    line:AddCallback(function(self, distanceToPlayer, distanceToCamera)
        local _, x, y, z = GetUnitRawWorldPosition("player")
        self:SetStartPoint(x, y, z)
    end)

    return line
end