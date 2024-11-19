local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)

local function onDescendantAdded(descendant)
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = "Players"
	end
end

local function onCharacterAdded(character)
	for _, descendant in character:GetDescendants() do
		onDescendantAdded(descendant)
	end
	character.DescendantAdded:Connect(onDescendantAdded)

end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)

Stellar.BulkLoad(ServerStorage.ServerModules, ReplicatedStorage.SharedModules)
local Network = Stellar.Get("Network")
Network:Reserve({"PlayerUtil", "RemoteEvent"})

Stellar.BulkGet("AbilityServer", "SoundFX", "DamageHandler", "BlockingServer", "FightingStyleService")

