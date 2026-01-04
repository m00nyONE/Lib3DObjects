local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local Marker = lib.Marker
local AUTOROTATE_CAMERA = lib.AUTOROTATE_CAMERA

local FloatingMarker = Marker:Subclass()
lib.FloatingMarker = FloatingMarker

function FloatingMarker:Initialize(texture, x, y, z, offsetY)
    Marker.Initialize(self, texture)
    self:SetPosition(x, y, z)
    self:SetPositionOffsetY(offsetY or 50)
    self:SetAutoRotationMode(AUTOROTATE_CAMERA)
end