--[[
    FightingStyleService.lua
    Nendalla
    31/10/2024
--]]

local FightingStyleService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)

function FightingStyleService:SetFightingStyle(player: Player, style: string)
    player:SetAttribute("FightingStyle", style)

    Stellar.Get(style):Equip(player)
end

function FightingStyleService:Init()
    Stellar.BulkGet("Samurai")
end

return FightingStyleService