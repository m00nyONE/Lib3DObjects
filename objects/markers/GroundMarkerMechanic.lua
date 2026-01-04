-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local GroundMarker = lib.GroundMarker

local GroundMarkerMechanic = GroundMarker:Subclass()
lib.GroundMarkerMechanic = GroundMarkerMechanic

function GroundMarkerMechanic:Initialize(texture, x, y, z, from, to, finishCallback)
    GroundMarker.Initialize(self, texture, x, y, z)

    local function destroySelfWhenCounterEnded()
        self:Destroy()
        if finishCallback then
            finishCallback()
        end
    end
    self:StartCounter(from, to, 1, destroySelfWhenCounterEnded)
end