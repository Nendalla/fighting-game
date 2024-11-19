local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)

Stellar.BulkLoad(ReplicatedStorage.ClientModules, ReplicatedStorage.SharedModules)
Stellar.BulkGet("SoundFX", "SamuraiClient", "PlayerUtil", "BlockingClient")

task.wait(5)
--PikaBeam:Activate()
