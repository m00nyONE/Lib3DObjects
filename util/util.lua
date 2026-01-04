local lib_name = "Lib3DObjects"
local lib = _G[lib_name]

local util = lib.util

-- calculates the cross product of two vectors in 3D space
function util.CrossProduct3D(ax, ay, az, bx, by, bz)
    local cx = ay * bz - az * by
    local cy = az * bx - ax * bz
    local cz = ax * by - ay * bx
    return cx, cy, cz
end
-- calculates the dot product of two vectors in 3D space
function util.DotProduct3D(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz
end
-- normalizes a vector in 3D space
function util.Normalize3D(x, y, z)
    local length = zo_sqrt(x * x + y * y + z * z)
    if length == 0 then
        return 0, 0, 0
    end
    return x / length, y / length, z / length
end

-- Yaw (around Y axis)
local function RotationMatrixYaw(yaw)
    local cosYaw, sinYaw = zo_cos(yaw), zo_sin(yaw)
    return {
        { cosYaw,  0, sinYaw },
        { 0,  1, 0 },
        { -sinYaw, 0, cosYaw }
    }
end
util.RotationMatrixYaw = RotationMatrixYaw

-- Pitch (around X axis)
local function RotationMatrixPitch(pitch)
    local cosPitch, sinPitch = zo_cos(pitch), zo_sin(pitch)
    return {
        { 1, 0,  0 },
        { 0, cosPitch, -sinPitch },
        { 0, sinPitch,  cosPitch }
    }
end
util.RotationMatrixPitch = RotationMatrixPitch

-- Roll (around Z axis)
local function RotationMatrixRoll(roll)
    local cosRoll, sinRoll = zo_cos(roll), zo_sin(roll)
    return {
        { cosRoll, -sinRoll, 0 },
        { sinRoll,  cosRoll, 0 },
        { 0,  0, 1 }
    }
end
util.RotationMatrixRoll = RotationMatrixRoll

-- Multiplies two 3x3 matrices
local function MultiplyMatrices3x3(a, b)
    local result = {}
    for i = 1, 3 do
        result[i] = {}
        for j = 1, 3 do
            result[i][j] = 0
            for k = 1, 3 do
                result[i][j] = result[i][j] + a[i][k] * b[k][j]
            end
        end
    end
    return result
end
util.MultiplyMatrices3x3 = MultiplyMatrices3x3

-- Multiplies a 3x3 matrix by a 3D vector
local function MultiplyMatrixVector3x3(m, v)
    return {
        m[1][1] * v[1] + m[1][2] * v[2] + m[1][3] * v[3],
        m[2][1] * v[1] + m[2][2] * v[2] + m[2][3] * v[3],
        m[3][1] * v[1] + m[3][2] * v[2] + m[3][3] * v[3],
    }
end
util.MultiplyMatrixVector3x3 = MultiplyMatrixVector3x3

-- Returns a 3x3 rotation matrix from Euler angles (yaw, pitch, roll)
local function EulerToMatrix(yaw, pitch, roll)
    local R_yaw = RotationMatrixYaw(yaw)
    local R_pitch = RotationMatrixPitch(pitch)
    local R_roll = RotationMatrixRoll(roll)
    -- Order: pitch, then yaw, then roll (R = R_roll * R_yaw * R_pitch)
    return MultiplyMatrices3x3(R_roll, MultiplyMatrices3x3(R_yaw, R_pitch))
end
util.EulerToMatrix = EulerToMatrix

-- Extracts Euler angles (yaw, pitch, roll) from a 3x3 rotation matrix
local function MatrixToEuler(R)
    local yaw, pitch, roll

    if zo_abs(R[3][1]) < 1 - 1e-6 then
        pitch = math.asin(R[3][1])
        yaw = zo_atan2(-R[3][2], R[3][3])
        roll = zo_atan2(-R[2][1], R[1][1])
    else
        -- Gimbal lock
        pitch = (R[3][1] > 0) and (ZO_PI / 2) or (-ZO_PI / 2)
        yaw = zo_atan2(R[1][2], R[2][2])
        roll = 0
    end

    return yaw, pitch, roll
end
util.MatrixToEuler = MatrixToEuler

function util.GetRotationFromVector(fX, fY, fZ)
    local pitch = zo_atan2(fY, zo_sqrt(fX * fX + fZ * fZ))
    local yaw = zo_atan2(fX, fZ)
    return pitch, yaw
end