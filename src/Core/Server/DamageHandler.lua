--[[
    DamageHandler.lua
    Nendalla
    02/11/2024
--]]

local DamageHandler = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")
local SoundFX = Stellar.Get("SoundFX")

local blockableHits = Stellar.Get("BlockableMoves")

local Assets = ReplicatedStorage.Assets

function DamageHandler:TakeDamage(character, amount, canKill, damageType)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end

    if character:GetAttribute("iFrame") then
        return
    end

    if character:GetAttribute("IsBlocking") and blockableHits[damageType] then
        SoundFX:Play("BlockNoise", character.PrimaryPart)
        return
    end

    local function damage()
        if amount >= humanoid.Health then
            if canKill then
                humanoid:TakeDamage(amount)
            else
                humanoid.Health = 1
            end
        else
            humanoid:TakeDamage(amount)
        end
    end

    if damageType == "slashm1" then
        local clone = Assets.Combat.damage:WaitForChild("Slash1"):Clone()
        clone.Parent = character.Torso
        for _, v in clone:GetChildren() do
            if v:IsA("ParticleEmitter") then
                v:Emit(v:GetAttribute("EmitCount") or 1)
                if v.Name == "HeavySlash" then
                    v.Rotation = NumberRange.new(math.random(20, 180))
                end
            end
        end
        SoundFX:Play("KatanaHitSound", character.PrimaryPart)
        damage()
    end
end

function DamageHandler:Init()
    Network:Reserve({ "DamageEvent", "RemoteEvent" })

    Network:ObserveSignal("DamageEvent", function(request, player, data1, data2, data3, data4)
        if request == "Damage" then
            DamageHandler:TakeDamage(player.character, data1, data2, data3)
        end
    end)
end

return DamageHandler
