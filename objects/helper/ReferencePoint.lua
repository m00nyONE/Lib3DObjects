-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

--[[ doc.lua begin ]]
local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local Point = lib.Point
local ReferencePoint = Point:Subclass()
lib.ReferencePoint = ReferencePoint

function ReferencePoint:Initialize(object)
    local x, y, z = object:GetFullPosition()
    Point.Initialize(self, x, y, z)

    self.attachedToObject = object

    self:SetLabel("RefPoint")
    self:ShowPosition(true)
    self:SetColor(1, 1, 0, 1) -- yellow
end

function ReferencePoint:AttachToObject(obj)
    self.attachedToObject = obj
end

function ReferencePoint:_UpdatePosition()
    local x, y, z = self.attachedToObject:GetFullPosition()
    self:SetPosition(x, y, z)
end
--[[ doc.lua end ]]