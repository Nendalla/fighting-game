local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)

Stellar.BulkLoad(ReplicatedStorage.ClientModules, ReplicatedStorage.SharedModules)
Stellar.BulkGet("SoundFX", "SamuraiClient", "PlayerUtil", "BlockingClient")

task.spawn(function()
    Players.LocalPlayer.CharacterAppearanceLoaded:Wait()
    local character = Players.LocalPlayer.Character
    local hum = character:WaitForChild("Humanoid")

    local RunService = game:GetService("RunService")
    local NormalJump = hum.JumpHeight
    local lastWalkSpeed, lastJumpHeight

    RunService.Heartbeat:Connect(function()
        local newWalkSpeed, newJumpHeight

        if character:FindFirstChild("Stun") then
            newWalkSpeed, newJumpHeight = 1, 0
        elseif character:FindFirstChild("Freeze") then
            newWalkSpeed, newJumpHeight = 0, 0
        elseif character:FindFirstChild("DoingCombat") then
            newWalkSpeed, newJumpHeight = 3, 0
        elseif character:FindFirstChild("Blocking") then
            newWalkSpeed, newJumpHeight = 6, 0
        elseif character:FindFirstChild("Sliding") then
            newWalkSpeed, newJumpHeight = hum.WalkSpeed, 0
        elseif character:FindFirstChild("Running") then
            newWalkSpeed, newJumpHeight = 34, 5
        elseif character:FindFirstChild("DoingMove") then
            newWalkSpeed, newJumpHeight = 0, 0
        else
            newWalkSpeed, newJumpHeight = 16, NormalJump
        end

        if newWalkSpeed ~= lastWalkSpeed then
            hum.WalkSpeed = newWalkSpeed
            lastWalkSpeed = newWalkSpeed
        end

        if newJumpHeight ~= lastJumpHeight then
            hum.JumpHeight = newJumpHeight
            lastJumpHeight = newJumpHeight
        end
    end)
end)

task.wait(5)
--PikaBeam:Activate()
