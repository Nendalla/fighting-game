--[[
    PikaBeam.lua
    Nendalla
    30/10/2024
--]]

local PikaBeam = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")
local CameraShaker = Stellar.Library("CameraShaker")

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local config = Stellar.Get(script.Name .. "Config")

local function ShakeCamera(shakeCf)
    camera.CFrame = camera.CFrame * shakeCf
end

local renderPriority = Enum.RenderPriority.Camera.Value + 1
local camShake = CameraShaker.new(renderPriority, ShakeCamera)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = { workspace.Debris, workspace.Alive }

local function updateRaycastFilter()
    local filterList = { workspace.Debris, workspace.Alive }

    for _, p in Players:GetPlayers() do
        if p.Character then
            table.insert(filterList, p.Character)
        end
    end

    raycastParams.FilterDescendantsInstances = filterList
end

function PikaBeam:_updateBeam()
    local origin = camera.CFrame.Position
    local direction = (mouse.Hit.Position - origin).Unit * 100
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)

    if raycastResult and raycastResult.Instance and raycastResult.Instance.CanCollide then
        local targetPosition = raycastResult.Position + Vector3.new(0, 1, 0)
        Network:Signal("PikaBeam", false, targetPosition)
    end
end

function PikaBeam:Activate()
    camShake:Start()
    Network:Signal("PikaBeam", true)
    local active = true
    updateRaycastFilter()

    task.spawn(function()
        local startTime = tick()
        while active and tick() - startTime < config.Length and player.Character do
            PikaBeam:_updateBeam()
            task.wait()
        end
    end)

    task.delay(1, function()
        camShake:ShakeOnce(
            1,    -- Magnitude
            10,     -- Roughness
            0.1,    -- Fade-in time
            0.5,    -- Fade-out time
            Vector3.new(1, 1, 1),
            Vector3.new(1, 1, 1)
        )
    end)

    task.delay(config.Length, function()
        active = false
    end)
end

return PikaBeam
