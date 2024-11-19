--[[
    PikaBeam.lua
    Nendalla
    29/10/2024
--]]

local PikaBeam = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local DamagePart = Stellar.Get("DamagePart")
local Network = Stellar.Get("Network")
local TweenService = game:GetService("TweenService")
local Config = Stellar.Get(script.Name .. "Config")
local SoundFX = Stellar.Get("SoundFX")

local beam = ReplicatedStorage.Assets.Abilities.PikaBeam
local playerBeams = {} -- Table to store each player's beam instance

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)

local tweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true)

function PikaBeam:_StartAbility(player)
    -- If a beam already exists for the player, clean it up first
    if playerBeams[player] then
        playerBeams[player].Beam:Destroy()
    end

    local clone = beam:Clone()
    clone.Parent = workspace.Debris
    local part2 = clone.Part2
    local part1 = clone.Part1

    -- Store the player's beam instance
    playerBeams[player] = {
        Beam = clone,
        Part1 = part1,
        Part2 = part2,
    }

    task.spawn(function()
        while task.wait() do
            if player.Character then
                local targetPosition = player.Character.PrimaryPart.CFrame.Position + Vector3.new(0, 15, 0)
                local goal = { CFrame = CFrame.new(targetPosition) }
                local tween = TweenService:Create(part1, tweenInfo2, goal)
                tween:Play()
            else
                break
            end
        end
    end)

    task.wait()
    part1.Attachment.One.Enabled = true
    part1.Attachment.Two.Enabled = true
    task.wait(1)
    SoundFX:Play("BeamStart", part1, true)
    part1.Beam.Enabled = true

    for _, v in part2:GetDescendants() do
        if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("Trail") then
            v.Enabled = true
        end
    end

    DamagePart.new(clone.DamagePart, Config.Damage, Config.damageOverTime, Config.debounce, {player.Character}, "PikaBeam", true)

    task.delay(Config.Length, function()
        self:_EndAbility(player)
    end)
end

function PikaBeam:_EndAbility(player)
    local playerBeam = playerBeams[player]
    if playerBeam then
        local part1 = playerBeam.Part1
        local part2 = playerBeam.Part2

        part1.Beam.Enabled = false

        for _, v in part2:GetDescendants() do
            if v:IsA("ParticleEmitter") or v:IsA("PointLight") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
        task.wait(1)
        part1.Attachment.One.Enabled = false
        part1.Attachment.Two.Enabled = false

        playerBeam.Beam:Destroy()
        playerBeams[player] = nil
    end
end

function PikaBeam:_Update(player, targetPos)
    local playerBeam = playerBeams[player]
    if playerBeam then
        local part2 = playerBeam.Part2
        local tweenGoals = { Position = targetPos }
        local tweenPart2 = TweenService:Create(part2, tweenInfo, tweenGoals)
        local tweenDamagePart = TweenService:Create(part2.Parent.DamagePart, tweenInfo, tweenGoals)
        tweenPart2:Play()
        tweenDamagePart:Play()
    end
end

function PikaBeam:Init()
    Network:Reserve({ "PikaBeam", "RemoteEvent" })
    Network:ObserveSignal("PikaBeam", function(player: Player, startAbility: boolean, targetPos: Vector3)
        if startAbility then
            PikaBeam:_StartAbility(player)
        else
            PikaBeam:_Update(player, targetPos)
        end
    end)
end

return PikaBeam
