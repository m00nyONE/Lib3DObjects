local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local AUTOROTATE_CAMERA = lib.AUTOROTATE_CAMERA
local Marker = lib.Marker

local UnitMarker = Marker:Subclass()
lib.UnitMarker = UnitMarker

function UnitMarker:Initialize(texture, unitTag, offsetY)
    Marker.Initialize(self, texture)

    unitTag = unitTag or "player"
    offsetY = offsetY or 300

    self:AttachToUnit(unitTag)
    self:SetPositionOffsetY(offsetY)
    self:SetAutoRotationMode(AUTOROTATE_CAMERA)

    local function moveToUnitWrapper(object, distanceToPlayer, distanceToCamera)
        object:MoveToUnit(object.unitTag)
    end

    self:AddCallback(moveToUnitWrapper)
end

function UnitMarker:AttachToUnit(unitTag)
    self.unitTag = unitTag
    self:MoveToUnit(unitTag)
end