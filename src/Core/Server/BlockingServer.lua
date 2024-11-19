--[[
    BlockingServer.lua
    Nendalla
    17/11/2024
--]]

local BlockingServer = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")

local CombatConfig = Stellar.Get("CombatConfig")

function BlockingServer:StartBlocking(player)
    local character = player.Character
    if not character then
        return
    end

    player.Character:SetAttribute("IsBlocking", true)

    character.Humanoid.WalkSpeed = CombatConfig.BlockWalkSpeed
end

function BlockingServer:StopBlocking(player)
    local character = player.Character
    if not character then
        return
    end

    player.Character:SetAttribute("IsBlocking", false)

    character.Humanoid.WalkSpeed = CombatConfig.WalkSpeed
end

function BlockingServer:Init()
    Network:Reserve({ "Block", "RemoteEvent" })
    Network:ObserveSignal("Block", function(player, request)
        print(request)
        if request == "StartBlocking" then
            print("hi")
            BlockingServer:StartBlocking(player)
        elseif request == "StopBlocking" then
            BlockingServer:StopBlocking(player)
        end
    end)
end

return BlockingServer
