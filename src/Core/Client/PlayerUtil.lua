--[[
    PlayerUtil.lua
    Nendalla
    01/11/2024
--]]

local PlayerUtil = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")
local Players = game:GetService("Players")

local DebrisMaker = Stellar.Get("DebrisMaker")

local Player = Players.LocalPlayer
local Stunned = false
local originalWalkSpeed
local originalJumpHeight

local StunTimer = nil

function PlayerUtil:ApplyForce(strength, attacker)
    if not attacker or not attacker.Character then
        warn("ApplyForce: Invalid attacker")
        return
    end

    local victimCharacter = Player.Character
    local attackerCharacter = attacker.Character

    if not (victimCharacter and attackerCharacter) then
        warn("ApplyForce: Missing character references")
        return
    end

    local victimHRP = victimCharacter:FindFirstChild("HumanoidRootPart")
    local attackerHRP = attackerCharacter:FindFirstChild("HumanoidRootPart")

    if not (victimHRP and attackerHRP) then
        warn("ApplyForce: Missing HumanoidRootPart")
        return
    end

    local attackerLookVector = attackerHRP.CFrame.LookVector
    local knockbackDirection = Vector3.new(attackerLookVector.X, (strength / 1000), attackerLookVector.Z).Unit

    if knockbackDirection.Magnitude == 0 then
        knockbackDirection = Vector3.new(0, 0, 1)
    end

    local impulse = knockbackDirection * strength

    victimHRP:ApplyImpulse(impulse)
end

function PlayerUtil:Impact(position, normal, distance, size, character, maxRocks, ice, despawnTime)
    DebrisMaker:Ground(position, normal, distance, size, {character}, maxRocks, ice, despawnTime)
end

function PlayerUtil:Stun(duration)
    if Stunned then
        if StunTimer then
            task.cancel(StunTimer)
        end
    else
        local character = Player.Character
        if not character then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        originalWalkSpeed = humanoid.WalkSpeed
        originalJumpHeight = humanoid.JumpHeight

        character:SetAttribute("Stunned", true)

        humanoid.WalkSpeed = 1
        humanoid.JumpHeight = 0
        Stunned = true
    end

    StunTimer = task.delay(duration, function()
        if Stunned then
            local character = Player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = originalWalkSpeed
                    humanoid.JumpHeight = originalJumpHeight
                    character:SetAttribute("Stunned", false)
                end
            end
            Stunned = false
            StunTimer = nil
        end
    end)
end

function PlayerUtil:Init()
    Network:ObserveSignal("PlayerUtil", function(request, data, data2, data3, data4, data5, data6, data7, data8)
        if request == "ApplyForce" then
            PlayerUtil:ApplyForce(data, data2)
        elseif request == "Impact" then
            PlayerUtil:Impact(data, data2, data3, data4, data5, data6, data7, data8)
        elseif request == "Stun" then
            PlayerUtil:Stun(data)
        end
    end)
end

return PlayerUtil