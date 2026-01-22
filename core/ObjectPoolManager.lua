-- SPDX-FileCopyrightText: 2025 m00nyONE
-- SPDX-License-Identifier: Artistic-2.0

local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local WM = GetWindowManager()
local EM = GetEventManager()

local async = LibAsync

--- @class ObjectPoolManager : ZO_Object
--- @field pools table<string, ZO_ObjectPool>
--- @field metrics table
--- @field isUpdating boolean
local ObjectPoolManager = ZO_Object:New()
lib.core.ObjectPoolManager = ObjectPoolManager
ObjectPoolManager.activeObjects = {}
ObjectPoolManager.activeObjectsCount = 0
ObjectPoolManager.pools = {}
ObjectPoolManager.metrics = {
    totalCreatedObjects = 0,
    totalUpdates = 0,
    totalUpdateTime = 0,
    currentUpdateTime = 0,
    peakUpdateTime = 0,
    averageUpdateTime = 0,
    currentRegisteredObjects = 0,
    peakRegisteredObjects = 0,
    currentVisibleObjects = 0,
    peakVisibleObjects = 0,
}
ObjectPoolManager.isUpdating = false

--- Creates or retrieves a control pool for 3D world space controls.
--- @param templateName string The control template to use for the controls in this pool.
--- @param ControlFactory function The factory function to create new controls.
--- @param ControlReset function The reset function to reset controls when they are released back to the pool.
--- @return ZO_ObjectPool The created or retrieved control pool.
function ObjectPoolManager:Get(templateName, ControlFactory, ControlReset)
    if self.pools[templateName] then
        return self.pools[templateName]
    end

    -- create tlw for this pool and attach a fragment to HUD scenes
    local window = WM:CreateTopLevelWindow(string.format("%s_%s", lib_name, templateName))
    window:SetDrawLayer(0) -- draw at the very back
    --local windowFragment = ZO_HUDFadeSceneFragment:New(window, DEFAULT_SCENE_TRANSITION_TIME, 0)
    --HUD_SCENE:AddFragment(windowFragment)
    --HUD_UI_SCENE:AddFragment(windowFragment)

    local pool = ZO_ObjectPool:New(ControlFactory, ControlReset)
    pool.parent = window
    pool.name = window:GetName()
    pool.templateName = templateName
    pool.AcquireObject = function(selfself, objectKey)
        local control, key = ZO_ObjectPool.AcquireObject(selfself, objectKey)
        control:SetHidden(false)
        self:StartUpdateLoop()

        self.metrics.totalCreatedObjects = self.metrics.totalCreatedObjects + 1

        return control, key
    end
    self.pools[templateName] = pool

    return pool
end

--- Begins the metrics timing for an update cycle.
--- @return number beginTime The start time in milliseconds.
function ObjectPoolManager:BeginMetrics()
    return GetGameTimeMilliseconds()
end
--- Ends the metrics timing for an update cycle and updates the metrics.
--- @param beginTime number The start time in milliseconds.
--- @param updatedControls number The number of updated controls.
--- @param renderedControls number The number of rendered controls.
--- @return void
function ObjectPoolManager:EndMetrics(beginTime, updatedControls, renderedControls)
    local endTime = GetGameTimeMilliseconds()
    local diffTime = endTime - beginTime

    local metrics = self.metrics
    metrics.totalUpdates = metrics.totalUpdates + 1
    metrics.totalUpdateTime = metrics.totalUpdateTime + diffTime
    metrics.averageUpdateTime = metrics.totalUpdateTime / metrics.totalUpdates
    metrics.currentUpdateTime = diffTime
    metrics.peakUpdateTime = zo_max(metrics.peakUpdateTime, diffTime)
    metrics.currentRegisteredObjects = updatedControls
    metrics.peakRegisteredObjects = zo_max(metrics.peakRegisteredObjects, updatedControls)
    metrics.currentVisibleObjects = renderedControls
    metrics.peakVisibleObjects = zo_max(metrics.peakVisibleObjects, renderedControls)
    --d(string.format("ObjectPools Updated: %d/%d controls in average: %.2f ms over %d updates", renderedControls, updatedControls, updateTime / updateCount, updateCount))
    --d(string.format("ObjectPools Updated: %d/%d controls in: %.2f ms", renderedControls, updatedControls, (endTime - beginTime)))
end

function ObjectPoolManager:Noop()
    -- no operation
end

--- Starts the update loop for updating active controls.
--- @return void
function ObjectPoolManager:StartUpdateLoop()
    if self.isUpdating then return end

    --- Wrapper function to include metrics around the update call
    local function _updateControlsWrapper()
        local beginTime = self:BeginMetrics()
        local updatedControls, renderedControls = self:UpdateControls()
        self:EndMetrics(beginTime, updatedControls, renderedControls)
    end

    EM:RegisterForUpdate(lib_name .. "_Update", lib.core.sw.updateInterval , _updateControlsWrapper)
    self.isUpdating = true
end

--- Stops the update loop for updating active controls.
--- @return void
function ObjectPoolManager:StopUpdateLoop()
    EM:UnregisterForUpdate(lib_name .. "_Update")
    self.isUpdating = false
end

function ObjectPoolManager:UpdateObject(object)
    if object._updatePreHooks then
        for _, hook in ipairs(object._updatePreHooks) do
            hook(object)
        end
    end

    local isRendered = object:Update()

    if object._updatePostHooks then
        for _, hook in ipairs(object._updatePostHooks) do
            hook(object)
        end
    end

    return isRendered
end

--- Internal function to update all active controls in all pools.
--- @return void
local function _UpdateControlsSync(self)
    local _updatedControls = 0
    local _renderedControls = 0
    for _, pool in pairs(self.pools) do
        for _, object in ipairs(pool:GetActiveObjects()) do -- we can also use the pool:ActiveObjectIterator(filterFunctions) here if we need it later
            local isRendered = self:UpdateObject(object.obj)
            if isRendered then _renderedControls = _renderedControls + 1 end
            _updatedControls = _updatedControls + 1
        end
    end
    return _updatedControls, _renderedControls
end
--- Internal function to update all active controls in all pools. (uses LibAsync)
--- @return void
local function _UpdateControlsAsync(self)
    local _updatedControls = 0
    local _renderedControls = 0
    for _, pool in pairs(self.pools) do
        local task = async:Create(pool.name)
        task:For(ipairs(pool:GetActiveObjects())):Do(function(_, object)
            local isRendered = self:UpdateObject(object.obj)
            if isRendered then _renderedControls = _renderedControls + 1 end
            _updatedControls = _updatedControls + 1
        end)
    end
    return _updatedControls, _renderedControls
end

--- Sets the update mode for the ObjectPoolManager.
--- @param mode number The update mode to set (UPDATE_MODE_SYNC or UPDATE_MODE_ASYNC).
--- @return void
function ObjectPoolManager:SetUpdateMode(mode)
    if mode == lib.UPDATE_MODE_SYNC then
        self.UpdateControls = _UpdateControlsSync
    elseif mode == lib.UPDATE_MODE_ASYNC then
        if not async then
            df("[%s] Warning: LibAsync not found, cannot set update mode to ASYNC. Defaulting to SYNC mode.", lib_name)
            lib.core.sw.updateMode = lib.UPDATE_MODE_SYNC
            self.UpdateControls = _UpdateControlsSync
            return
        end
        self.UpdateControls = _UpdateControlsAsync
    else
        df("[%s] Warning: Unknown update mode %s, defaulting to SYNC mode.", lib_name, tostring(mode))
        self.UpdateControls = _UpdateControlsSync
    end
end