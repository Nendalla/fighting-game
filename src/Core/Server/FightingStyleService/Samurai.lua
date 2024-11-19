--[[
    Samurai.lua
    Nendalla
    31/10/2024
--]]

local Samurai = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")

local Hitbox = Stellar.Get("Hitbox")
local SoundFX = Stellar.Get("SoundFX")
local DamageHandler = Stellar.Get("DamageHandler")
local Config = Stellar.Get("SamuraiConfig")
local PlayerUtilServer = Stellar.Get("PlayerUtilServer")

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
local swordHitbox
local lasthit
local sounds = ReplicatedStorage.SoundFXs.FightingStyles.Samurai.Slashes:GetChildren()
local lastPlayedSound = nil

local animations = {}

function Samurai:Swing(player, length, finalhit)
    local soundToPlay = nil

    lasthit = finalhit
    if swordHitbox then
        swordHitbox:HitStart()
    end

    repeat
        soundToPlay = sounds[math.random(1, #sounds)]
    until soundToPlay ~= lastPlayedSound

    SoundFX:Play(soundToPlay.Name, player.Character.PrimaryPart)
    lastPlayedSound = soundToPlay

    task.wait(length * 0.9)
    if swordHitbox then
        swordHitbox:HitStop()
    end
end

function Samurai:Equip(player)
    if not player.Character or not player.Character:FindFirstChild("PrimaryPart") then return end

    SoundFX:Play("Unsheath", player.Character.PrimaryPart)

    swordHitbox = Hitbox.new(player.Character:FindFirstChild("Katana").Handle)
    raycastParams.FilterDescendantsInstances = { player.Character }
    swordHitbox.RaycastParams = raycastParams

    swordHitbox.OnHit:Connect(function(_, humanoid)
        if humanoid.Parent:FindFirstChild("iFrame") then return end

        PlayerUtilServer:iFrame(player, 0.5)
        local animator = humanoid:WaitForChild("Animator")
        local Assets = ReplicatedStorage.Assets.Combat

        if animator then
            for _, v in Assets:GetChildren() do
                if v:IsA("Animation") then
                    local anim = animator:LoadAnimation(v)
                    animations[v.Name] = anim
                end
            end
        end
        if not lasthit then
            animations["TakeDamage" .. math.random(1, 4)]:Play()
        end

        if lasthit and humanoid.Parent.IsRagdoll then
            Network:Signal("PlayerUtil", Players:GetPlayerFromCharacter(humanoid.Parent), "ApplyForce", 750, player)
            task.spawn(function()
                local active = true
                task.wait(0.25)
                while task.wait() and active do
                    if math.abs(humanoid.Parent.PrimaryPart.AssemblyLinearVelocity.Y) < 1.5 then
                        local position = humanoid.Parent.PrimaryPart.Position - Vector3.new(0, 3, 0) -- Adjust y-offset as needed
                        local normal = Vector3.new(0, 1, 0) -- Normal facing up
                        local distance = 4 -- Reduced distance for placement adjustment
                        local size = Vector3.new(1, 1, 1) -- Smaller size of rocks
                        local maxRocks = 8 -- Fewer rocks for a smaller crater
                        local ice = false -- Set to true for icy rocks
                        local despawnTime = 2 -- Time in seconds before rocks disappear
                        local bigExplosion = false -- Big Explosion?
                        Network:SignalAll("PlayerUtil", "Impact", position, normal, distance, size, humanoid.Parent, maxRocks, ice, despawnTime, bigExplosion)
                        active = false
                    end
                end
            end)
            humanoid.Parent.IsRagdoll.Value = true
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            task.delay(1.5, function()
                humanoid.Parent.IsRagdoll.Value = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end

        DamageHandler:TakeDamage(humanoid.Parent, Config.m1Damage, true, "slashm1")
    end)
end

function Samurai:Unequip(player)
    swordHitbox = nil
    SoundFX:Play("Sheath", player.Character.PrimaryPart)
end

function Samurai:Init()
    Network:Reserve({"Samurai", "RemoteEvent"})

    -- Listen for network signals related to Samurai
    Network:ObserveSignal("Samurai", function(player, request, data1, data2)
        if request == "Swing" then
            Samurai:Swing(player, data1, data2)
        else
            print(player, request, data1)
        end
    end)

    -- Monitor players for changes in their fightingStyle attribute
    Players.PlayerAdded:Connect(function(player)
        player:GetAttributeChangedSignal("fightingStyle"):Connect(function()
            local style = player:GetAttribute("fightingStyle")
            if style == "Samurai" then
                Samurai:Equip(player)
            else
                Samurai:Unequip(player)
            end
        end)

        -- Initial check in case the attribute is already set
        local initialStyle = player:GetAttribute("fightingStyle")
        if initialStyle == "Samurai" then
            Samurai:Equip(player)
        end
    end)

    -- Also handle existing players if the script runs after some players are already in the game
    for _, player in ipairs(Players:GetPlayers()) do
        player:GetAttributeChangedSignal("fightingStyle"):Connect(function()
            local style = player:GetAttribute("fightingStyle")
            if style == "Samurai" then
                Samurai:Equip(player)
            else
                Samurai:Unequip(player)
            end
        end)

        -- Initial check
        local initialStyle = player:GetAttribute("fightingStyle")
        if initialStyle == "Samurai" then
            Samurai:Equip(player)
        end
    end
end

return Samurai
