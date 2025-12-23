local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local AUTOROTATE_CAMERA = lib.AUTOROTATE_CAMERA
local Marker = lib.Marker

local UnitMarker = Marker:Subclass()
lib.UnitMarker = UnitMarker

local UNITMARKER_PRIORITY_MECHANIC = 999
local UNITMARKER_PRIORITY_IGNORE = -1
local UNITMARKER_PRIORITY_DEFAULT = 0

lib.UNITMARKER_PRIORITY_DEFAULT = UNITMARKER_PRIORITY_DEFAULT
lib.UNITMARKER_PRIORITY_IGNORE = UNITMARKER_PRIORITY_IGNORE
lib.UNITMARKER_PRIORITY_MECHANIC = UNITMARKER_PRIORITY_MECHANIC

local emptyTable = {}
local unitCache = {}


function UnitMarker:Initialize(texture, unitTag, offsetY, priority)
    Marker.Initialize(self, texture)
    priority = priority or 0
    self:SetPriority(priority)

    unitTag = unitTag or "player"
    offsetY = offsetY or 300

    self.unitTag = unitTag
    self:AttachToUnit(unitTag)
    self:SetPositionOffsetY(offsetY)
    self:SetAutoRotationMode(AUTOROTATE_CAMERA)

    self:AddCallback(self._hideConditionCallback)
    self:AddCallback(self._moveToUnitCallback)

    self:_AddToCache()
end

function UnitMarker:Destroy()
    UnitMarker:_RemoveFromCache()
    Marker.Destroy(self)
end

function UnitMarker:SetPriority(priority)
    self.priority = priority or 0
end

function UnitMarker:AttachToUnit(unitTag)
    -- Remove from old unit cache
    self:_RemoveFromCache()

    -- Attach to new unit
    self.unitTag = unitTag
    self:_AddToCache()

    self:MoveToUnit(unitTag)
end

function UnitMarker:_hasHighestPriorityOnUnit()
    if self.priority == -1 then
        return true
    end
    local unitMarkers = unitCache[self.unitTag]
    for _, marker in ipairs(unitMarkers) do
        if marker.priority > self.priority then
            return false
        end
    end
    return true
end

function UnitMarker:_RemoveFromCache()
    local unitMarkers = unitCache[self.unitTag] or emptyTable
    for i, marker in ipairs(unitMarkers) do
        if marker == self then
            table.remove(unitMarkers, i)
            return
        end
    end
end
function UnitMarker:_AddToCache()
    unitCache[self.unitTag] = unitCache[self.unitTag] or {}
    -- check if not already in cache
    for _, marker in ipairs(unitCache[self.unitTag]) do
        if marker == self then
            return
        end
    end

    table.insert(unitCache[self.unitTag], self)
end

function UnitMarker._moveToUnitCallback(object, distanceToPlayer, distanceToCamera)
    object:MoveToUnit(object.unitTag)
end

function UnitMarker._hideConditionCallback(object, distanceToPlayer, distanceToCamera)
    if not IsUnitOnline(object.unitTag) then
        object:SetHidden(true)
        return
    end
    if not object:_hasHighestPriorityOnUnit() then
        object:SetHidden(true)
        return
    end

    object:SetHidden(false)
end

