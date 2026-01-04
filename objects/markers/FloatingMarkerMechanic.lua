local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local FloatingMarker = lib.FloatingMarker

local FloatingMarkerMechanic = FloatingMarker:Subclass()
lib.FloatingMarkerMechanic = FloatingMarkerMechanic

function FloatingMarkerMechanic:Initialize(texture, x, y, z, offsetY, from, to, finishCallback)
    FloatingMarker.Initialize(self, texture, x, y, z, offsetY)

    local function destroySelfWhenCounterEnded()
        self:Destroy()
        if finishCallback then
            finishCallback()
        end
    end
    self:StartCounter(from, to, 1, destroySelfWhenCounterEnded)
end