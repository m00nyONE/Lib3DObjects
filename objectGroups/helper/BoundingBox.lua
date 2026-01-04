-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

--[[ doc.lua begin ]]
local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local BaseObjectGroup = lib.BaseObjectGroup
--- @class BoundingBox : BaseObjectGroup
local BoundingBox = BaseObjectGroup:Subclass()
lib.BoundingBox = BoundingBox

--- Create a bounding box around the given ObjectGroup
--- @param ObjectGroup BaseObjectGroup The object group to create the bounding box for
--- @return BoundingBox
function BoundingBox:Initialize(ObjectGroup)
    BaseObjectGroup.Initialize(self)

    self.ObjectGroup = ObjectGroup
    self:_UpdateReferencePoint()

    self.corners = {}
    for i = 1, 8 do
        self.corners[i] = {}
    end
    self:_UpdateBoundingBoxPoints()

    -- generate points
    self.points = {}
    for i = 1, 8 do
        local corner = self.corners[i]
        local point = lib.Point:New(corner[1], corner[2], corner[3])
        point:SetLabel(i)
        point:SetScale(0.75)
        point:ShowPosition(true)
        self:Add(point)
        table.insert(self.points, point)
    end
    self:ShowPoints(false)

    -- generate lines
    self.lines = {}
    self.lineIndices = {
        {1, 2}, {2, 4}, {4, 3}, {3, 1}, -- bottom face
        {5, 6}, {6, 8}, {8, 7}, {7, 5}, -- top face
        {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- vertical edges
    }
    for _, indices in ipairs(self.lineIndices) do
        local startCorner = self.corners[indices[1]]
        local endCorner = self.corners[indices[2]]
        local line = lib.Line:New(nil, startCorner[1], startCorner[2], startCorner[3], endCorner[1], endCorner[2], endCorner[3])
        self:Add(line)
        table.insert(self.lines, line)
    end
    self:ShowLines(true)

    self:AddCallback(self._UpdateReferencePoint)
    self:AddCallback(self._UpdateBoundingBoxPoints)
    self:AddCallback(self._UpdatePoints)
    self:AddCallback(self._UpdateLines)
end

function BoundingBox:Destroy()
    self.ObjectGroup = nil
    self.corners = nil
    self.points = nil
    self.lines = nil
    BaseObjectGroup.Destroy(self)
end

function BoundingBox:AttachToObjectGroup(ObjectGroup)
    self.ObjectGroup = ObjectGroup
    self:SetReferencePoint(ObjectGroup:GetMidpoint())
end

function BoundingBox:ShowPoints(show)
    for _, point in ipairs(self.points) do
        point:SetHidden(not show)
    end
end
function BoundingBox:ShowLines(show)
    for _, line in ipairs(self.lines) do
        line:SetHidden(not show)
    end
end


function BoundingBox:_UpdateReferencePoint()
    self:SetReferencePoint(self.ObjectGroup:GetMidpoint())
end

-- Update the bounding box corner points based on attached object's positions
function BoundingBox:_UpdateBoundingBoxPoints()
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

    for _, member in ipairs(self.ObjectGroup:GetMembers()) do
        local x, y, z = member:GetFullPosition()
        if x < minX then minX = x end
        if y < minY then minY = y end
        if z < minZ then minZ = z end
        if x > maxX then maxX = x end
        if y > maxY then maxY = y end
        if z > maxZ then maxZ = z end
    end

    local corner1 = self.corners[1]
    local corner2 = self.corners[2]
    local corner3 = self.corners[3]
    local corner4 = self.corners[4]
    local corner5 = self.corners[5]
    local corner6 = self.corners[6]
    local corner7 = self.corners[7]
    local corner8 = self.corners[8]

    corner1[1], corner1[2], corner1[3] = minX, minY, minZ
    corner2[1], corner2[2], corner2[3] = maxX, minY, minZ
    corner3[1], corner3[2], corner3[3] = minX, maxY, minZ
    corner4[1], corner4[2], corner4[3] = maxX, maxY, minZ
    corner5[1], corner5[2], corner5[3] = minX, minY, maxZ
    corner6[1], corner6[2], corner6[3] = maxX, minY, maxZ
    corner7[1], corner7[2], corner7[3] = minX, maxY, maxZ
    corner8[1], corner8[2], corner8[3] = maxX, maxY, maxZ
end
-- Update the point objects to match the bounding box corners
function BoundingBox:_UpdatePoints()
    for i, point in ipairs(self.points) do
        local corner = self.corners[i]
        point:SetPosition(corner[1], corner[2], corner[3])
    end
end
-- Update the lines to match the bounding box edges
function BoundingBox:_UpdateLines()
    for i, indices in ipairs(self.lineIndices) do
        local startCorner = self.corners[indices[1]]
        local endCorner = self.corners[indices[2]]
        local line = self.lines[i]
        line:SetStartPoint(startCorner[1], startCorner[2], startCorner[3])
        line:SetEndPoint(endCorner[1], endCorner[2], endCorner[3])
    end
end

--[[ doc.lua end ]]

