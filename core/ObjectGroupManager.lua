-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local EM = GetEventManager()

local ObjectGroupManager = ZO_Object:New()
lib.core.ObjectGroupManager = ObjectGroupManager

ObjectGroupManager.groups = {}
function ObjectGroupManager:UpdateGroups()
    for _, group in pairs(self.groups) do
        group:Update()
    end
end
function ObjectGroupManager:Add(group)
    table.insert(self.groups, group)

    self:StartUpdateLoop()
end
function ObjectGroupManager:Remove(group)
    for i, g in ipairs(self.groups) do
        if g == group then
            table.remove(self.groups, i)

            -- Stop update loop if no groups are left
            if #self.groups == 0 then
                self:StopUpdateLoop()
            end
            return
        end
    end
end

--- Starts the update loop for updating active groups.
--- @return void
function ObjectGroupManager:StartUpdateLoop()
    if self.isUpdating then return end

    EM:RegisterForUpdate(lib_name .. "_UpdateGroupObjects", lib.core.sw.updateInterval , function()
        self:UpdateGroups()
    end)
    self.isUpdating = true
end

--- Stops the update loop for updating active controls.
--- @return void
function ObjectGroupManager:StopUpdateLoop()
    EM:UnregisterForUpdate(lib_name .. "_UpdateGroupObjects")
    self.isUpdating = false
end