local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local UnitMarker = lib.UnitMarker

local UnitMarkerMechanic = UnitMarker:Subclass()
lib.UnitMarkerMechanic = UnitMarkerMechanic

function UnitMarkerMechanic:Initialize(texture, unitTag, offsetY, from, to, finishCallback)
    UnitMarker.Initialize(self, texture, unitTag, offsetY, lib.UNITMARKER_PRIORITY_MECHANIC)

    local function destroySelfWhenCounterEnded()
        self:Destroy()
        if finishCallback then
            finishCallback()
        end
    end
    self:StartCounter(from, to, 1, destroySelfWhenCounterEnded)
end