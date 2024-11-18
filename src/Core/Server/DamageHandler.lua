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

local Assets = ReplicatedStorage.Assets

function DamageHandler:TakeDamage(character, amount, canKill, damageType)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- Check if the victim is blocking
    if character:GetAttribute("IsBlocking") then
        local blockSound = ReplicatedStorage:FindFirstChild("SoundFXs")
            and ReplicatedStorage.SoundFXs:FindFirstChild("FightingStyles")
            and ReplicatedStorage.SoundFXs.FightingStyles:FindFirstChild("Samurai")
            and ReplicatedStorage.SoundFXs.FightingStyles.Samurai:FindFirstChild("BlockNoise")

        if blockSound then
            SoundFX:Play("BlockNoise", character.PrimaryPart)
        else
            warn("BlockNoise sound not found in ReplicatedStorage.SoundFXs.FightingStyles.Samurai")
        end

        -- Optionally, add visual feedback here (e.g., a shield effect)

        return  -- Exit the function without applying damage
    end

    if character:FindFirstChild("iFrame") then return end

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
    Network:Reserve({"DamageEvent", "RemoteEvent"})

    Network:ObserveSignal("DamageEvent", function(request, player, data1, data2, data3, data4)
        if request == "Damage" then
            DamageHandler:TakeDamage(data1, data2, data3, data4)
        end
    end)
end

return DamageHandler