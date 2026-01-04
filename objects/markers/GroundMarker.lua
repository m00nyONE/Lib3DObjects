-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local Marker = lib.Marker

local AUTOROTATE_NONE = lib.AUTOROTATE_NONE

local GroundMarker = Marker:Subclass()
lib.GroundMarker = GroundMarker

function GroundMarker:Initialize(texture, x, y, z)
    Marker.Initialize(self, texture)
    self:SetPosition(x, y, z)

    self:SetRotation(-ZO_PI/2, 0, 0) -- lay flat on ground
    self:SetAutoRotationMode(AUTOROTATE_NONE)
end