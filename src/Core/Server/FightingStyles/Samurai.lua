--[[
    Samurai.lua
    Nendalla
    31/10/2024
--]]

local Samurai = {}
local Debris = game:GetService("Debris")
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
    swordHitbox:HitStart()

    repeat
        soundToPlay = sounds[math.random(1, #sounds)]
    until soundToPlay ~= lastPlayedSound

    SoundFX:Play(soundToPlay.Name, player.Character.PrimaryPart)

    task.wait(length * 0.9)
    swordHitbox:HitStop()
end

function Samurai:Equip(player)

    SoundFX:Play("Unsheath", player.Character.PrimaryPart)
    swordHitbox = Hitbox.new(player.Character:FindFirstChild("Katana").Handle)
    raycastParams.FilterDescendantsInstances = { player.Character }
    swordHitbox.RaycastParams = raycastParams

    swordHitbox.OnHit:Connect(function(hit, humanoid)
        if humanoid.Parent:FindFirstChild("iFrame") then return end
        
        PlayerUtilServer:iFrame(player, 0.25)
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

function Samurai:Unequip(player, tool)
    swordHitbox = nil
    SoundFX:Play("Sheath", player.Character.PrimaryPart)
end

function Samurai:Init()
    Network:Reserve({"Samurai", "RemoteEvent"})

    Network:ObserveSignal("Samurai", function(player, request, data1, data2)
        if request == "Equip" then
            Samurai:Equip(player)
        elseif request == "Unequip" then
            Samurai:Unequip(player)
        elseif request == "Swing" then
            Samurai:Swing(player, data1, data2)
        else
            print(player, request, data1)
        end
    end)
end

return Samurai