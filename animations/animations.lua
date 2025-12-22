local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local animations = {}
lib.animations = animations

--- Calculates the progress of an animation based on the current game time.
--- @param beginTime number The time the animation started (in milliseconds).
--- @param endTime number The time the animation is scheduled to end (in milliseconds).
--- @return number A number between 0 and 1 representing the progress of the animation.
local function getProgress(beginTime, endTime)
    local currentTime = GetGameTimeMilliseconds()
    if currentTime <= beginTime then
        return 0
    elseif currentTime >= endTime then
        return 1
    else
        return (currentTime - beginTime) / (endTime - beginTime)
    end
end

-- animation factory functions

function animations.CreateSingleRotationAnimation(durationMS, pitchDegrees, yawDegrees, rollDegrees)
    return function()
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + durationMS or 1000 -- default to 1 second if not provided

        -- convert degrees to radians
        local pitchRadians = (pitchDegrees or 0) * (ZO_PI / 180)
        local yawRadians = (yawDegrees or 0) * (ZO_PI / 180)
        local rollRadians = (rollDegrees or 0) * (ZO_PI / 180)

        local callbackFunc = function(self, distanceToPlayer, distanceToCamera)
            local progress = getProgress(beginTime, endTime) -- value between 0 and 1
            if progress >= 1 then return true end
            -- set rotation of yaw axis based on progress in radian
            self.rotation.animationOffsetPitch = progress * pitchRadians
            self.rotation.animationOffsetYaw = progress * yawRadians
            self.rotation.animationOffsetRoll = progress * rollRadians
        end

        return callbackFunc
    end
end
function animations.CreateSingleFadeAnimation(durationMS, fromAlpha, toAlpha)
    return function()
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + durationMS or 1000 -- default to 1 second if not provided

        fromAlpha = fromAlpha or 1.0
        toAlpha = toAlpha or 0.2

        local callbackFunc = function(self, distanceToPlayer, distanceToCamera)
            local progress = getProgress(beginTime, endTime) -- value between 0 and 1
            if progress >= 1 then return true end
            local currentAlpha = fromAlpha + (toAlpha - fromAlpha) * progress
            self.Control:SetAlpha(currentAlpha)
        end

        return callbackFunc
    end
end
function animations.CreateSingleScaleAnimation(durationMS, toScale)
    return function()
        durationMS = durationMS or 1000 -- default to 1 second
        toScale = toScale or 1.0 -- default to 1.0
        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + durationMS
        local initialScale = nil

        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            local progress = getProgress(beginTime, endTime) -- value between 0 and 1
            if progress >= 1 then return true end
            if initialScale == nil then initialScale = self.scale end
            local currentScale = initialScale + (toScale - initialScale) * progress
            self:SetScale(currentScale)
        end

        return callbackFunc
    end
end

function animations.CreateSingleBounceAnimation(durationMS, frequency, amplitude)
    return function()
        durationMS = durationMS or 1000 -- default to 1 second
        frequency = frequency or 2 -- default to 2 bounces per second
        amplitude = amplitude or 50 -- default to 0.5m

        local beginTime = GetGameTimeMilliseconds()
        local endTime = beginTime + durationMS

        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            local progress = getProgress(beginTime, endTime) -- value between 0 and 1
            if progress >= 1 then return true end
            local elapsedTime = progress * (durationMS / 1000) -- convert to seconds
            local offsetY = amplitude * math.abs(math.sin(2 * ZO_PI * frequency * elapsedTime))
            self.position.animationOffsetY = offsetY
        end

        return callbackFunc
    end
end

function animations.CreateContinuesBounceAnimation(conditionFunc, frequency, amplitude)
    return function()
        if not conditionFunc then conditionFunc=function() return true end end
        frequency = frequency or 2 -- default to 2 bounces per second
        amplitude = amplitude or 50 -- default to 0.5m

        local beginTime = GetGameTimeMilliseconds()

        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            if not conditionFunc() then return end

            local currentTime = GetGameTimeMilliseconds()
            local elapsedTime = (currentTime - beginTime) / 1000 -- convert to seconds
            local offsetY = amplitude * math.abs(math.sin(2 * ZO_PI * frequency * elapsedTime))
            self.position.animationOffsetY = offsetY

        end

        return callbackFunc
    end
end
function animations.CreateContinuesRotationAnimation(conditionFunc, frequency, pitchDegreesPerCycle, yawDegreesPerCycle, rollDegreesPerCycle)
    return function()
        if not conditionFunc then conditionFunc=function() return true end end
        frequency = frequency or 1 -- default to 1 cycle per second

        local pitchRadiansPerCycle = (pitchDegreesPerCycle or 0) * (ZO_PI / 180)
        local yawRadiansPerCycle = (yawDegreesPerCycle or 0) * (ZO_PI / 180)
        local rollRadiansPerCycle = (rollDegreesPerCycle or 0) * (ZO_PI / 180)
        local beginTime = GetGameTimeMilliseconds()
        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            if not conditionFunc() then return end

            local currentTime = GetGameTimeMilliseconds()
            local elapsedTime = (currentTime - beginTime) / 1000 -- convert to seconds
            local cyclesCompleted = frequency * elapsedTime

            self.rotation.animationOffsetPitch = cyclesCompleted * pitchRadiansPerCycle
            self.rotation.animationOffsetYaw = cyclesCompleted * yawRadiansPerCycle
            self.rotation.animationOffsetRoll = cyclesCompleted * rollRadiansPerCycle
        end

        return callbackFunc
    end
end
function animations.CreateContinuesPulseAnimation(conditionFunc, minAlpha, maxAlpha)
    return function()
        if not conditionFunc then conditionFunc=function() return true end end
        minAlpha = minAlpha or 0.2
        maxAlpha = maxAlpha or 1.0

        local beginTime = GetGameTimeMilliseconds()

        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            if not conditionFunc() then return end
            local currentTime = GetGameTimeMilliseconds()
            local elapsedTime = (currentTime - beginTime) / 1000 -- convert to seconds
            local alphaRange = maxAlpha - minAlpha
            self.Control:SetAlpha(minAlpha + (alphaRange / 2) * (1 + math.sin(2 * ZO_PI * elapsedTime)))
        end

        return callbackFunc
    end
end
function animations.CreateContinuesFlashAnimation(conditionFunc, offDuration, onDuration)
    return function()
        if not conditionFunc then conditionFunc=function() return true end end
        offDuration = offDuration or 500 -- default to 0.5 second
        onDuration = onDuration or 500 -- default to 0.5 second

        local cycleDuration = offDuration + onDuration
        local beginTime = GetGameTimeMilliseconds()

        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            if not conditionFunc() then return end
            local currentTime = GetGameTimeMilliseconds()
            local elapsedTime = currentTime - beginTime
            local timeInCycle = elapsedTime % cycleDuration

            if timeInCycle < offDuration then
                self.alpha = 0
                self.Control:SetAlpha(0)
            else
                self.Control:SetAlpha(1)
            end
        end

        return callbackFunc
    end
end

-- callback creation functions
function animations.CreateRadiusTrigger(activationRadius, enterCallback, leaveCallback)
    return function()
        local fired = false
        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            if distanceToPlayer > activationRadius then
                if fired and leaveCallback then
                    leaveCallback(self, distanceToPlayer, distanceToCamera)
                end
                fired = false
            elseif not fired and distanceToPlayer <= activationRadius then
                if enterCallback then
                    enterCallback(self, distanceToPlayer, distanceToCamera)
                end
                fired = true
            end
        end

        return callbackFunc
    end
end


function animations.CreateRadiusTriggerForUnit(unitTag, activationRadius, enterCallback, leaveCallback)
    return function()
        local fired = false
        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            local unitDistance = self:GetDistanceToUnit(unitTag)
            if unitDistance > activationRadius then
                if fired and leaveCallback then
                    leaveCallback(self, distanceToPlayer, distanceToCamera)
                end
                fired = false
            elseif not fired and unitDistance <= activationRadius then
                if enterCallback then
                    enterCallback(self, distanceToPlayer, distanceToCamera)
                end
                fired = true
            end
        end

        return callbackFunc
    end
end

function animations.CreateMouseOverTrigger(activationRadius, enterCallback, leaveCallback)
    return function()
        local fired = false
        local function callbackFunc(self, distanceToPlayer, distanceToCamera)
            local cX, cY, cZ = lib.GetCameraWorldPosition()
            local fX, fY, fZ = GetCameraForward(SPACE_WORLD)

            local mX, mY, mZ = self:GetFullPosition()

            -- Vector from camera to object
            local toObjX = mX - cX
            local toObjY = mY - cY
            local toObjZ = mZ - cZ

            -- Distance to object
            local dist = zo_distance3D(0, 0, 0, toObjX, toObjY, toObjZ)
            if dist == 0 then return end

            -- Normalize vectors
            local toObjNormX, toObjNormY, toObjNormZ = toObjX / dist, toObjY / dist, toObjZ / dist
            local fLen = zo_sqrt(fX * fX + fY * fY + fZ * fZ)
            local fNormX, fNormY, fNormZ = fX / fLen, fY / fLen, fZ / fLen

            -- Dot product gives cos(angle)
            local dot = toObjNormX * fNormX + toObjNormY * fNormY + toObjNormZ * fNormZ
            -- Clamp dot to [-1, 1] to avoid math domain errors
            dot = zo_max(-1, zo_min(1, dot))
            local angle = math.acos(dot)

            -- Calculate the allowed angle based on activationRadius and distance
            local allowedAngle = zo_atan2(activationRadius, dist)

            if angle > allowedAngle then
                if fired and leaveCallback then
                    leaveCallback(self, distanceToPlayer, distanceToCamera)
                end
                fired = false
            elseif not fired and angle <= allowedAngle then
                if enterCallback then
                    enterCallback(self, distanceToPlayer, distanceToCamera)
                end
                fired = true
            end
        end

        return callbackFunc
    end
end

-- TODO:
--if MouseIsOver(object) then
--    d("Mouse Over Object: " .. tostring(object.obj))
--end