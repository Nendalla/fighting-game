--[[
    SamuraiClient.lua
    Nendalla
    31/10/2024
    Improved and Fixed Version
--]]

local SamuraiClient = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Require Stellar modules
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")
local CombatConfig = Stellar.Get("CombatConfig")
local PlayerUtil = Stellar.Get("PlayerUtil")

local Player = Players.LocalPlayer
local Assets = ReplicatedStorage.Assets.FightingStyles:WaitForChild("Samurai")

local animations = {}
local attacking = false
local inputConnection = nil

-- Variables for Combo Reset Mechanism
local comboResetId = 0  -- Unique identifier for each combo reset timer
local currentComboNumber = 1  -- Tracks the current attack in the combo
local maxCombo = 5  -- Maximum number of combos before reset
local comboResetTime = 2  -- Time in seconds to reset combo

-- Load animations for the character
local function loadAnimations(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        warn("Humanoid not found in character.")
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    for _, animAsset in ipairs(Assets:GetChildren()) do
        if animAsset:IsA("Animation") then
            local loadedAnim = animator:LoadAnimation(animAsset)
            animations[animAsset.Name] = loadedAnim
        end
    end
end

-- Register character and load animations
local function registerCharacter(character)
    loadAnimations(character)
end

-- Handle input for attacking
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local character = Player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        if character:GetAttribute("Stunned") then return end
        if character:GetAttribute("IsBlocking") then return end
        if attacking then return end

        local fightingStyle = Player:GetAttribute("FightingStyle")
        if fightingStyle ~= "Samurai" then return end

        attacking = true
        comboResetId = comboResetId + 1
        local currentId = comboResetId

        local animName = "Slash" .. currentComboNumber
        local animation = animations[animName]

        if not animation then
            warn("Animation " .. animName .. " not found.")
            attacking = false
            return
        end

        -- Determine if it's the final combo attack
        local isFinalCombo = currentComboNumber == maxCombo

        -- Signal the network with appropriate parameters
        if isFinalCombo then
            Network:Signal("Samurai", "Swing", animation.Length, true)
            PlayerUtil:Stun(CombatConfig.Endlag)
        else
            Network:Signal("Samurai", "Swing", animation.Length)
            PlayerUtil:Stun(CombatConfig.AttackStun)  -- Use a configurable stun duration
        end

        animation:Play()

        task.delay(comboResetTime, function()
            if currentId == comboResetId then
                currentComboNumber = 1
            end
        end)

        task.spawn(function()
            task.wait(animation.Length * 0.95)

            if isFinalCombo then
                currentComboNumber = 1
                task.wait(CombatConfig.SamuraiAttackDebounce)
            else
                currentComboNumber = currentComboNumber + 1
            end

            attacking = false
        end)
    end
end

function SamuraiClient:Init()
    if Player.Character then
        registerCharacter(Player.Character)
    end

    Player.CharacterAdded:Connect(registerCharacter)

    local initialStyle = Player:GetAttribute("FightingStyle")
    if initialStyle == "Samurai" then
        inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
    end

    Player:GetAttributeChangedSignal("FightingStyle"):Connect(function(newStyle)
        if newStyle == "Samurai" then
            if not inputConnection then
                inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
            end
        else
            if inputConnection then
                inputConnection:Disconnect()
                inputConnection = nil
            end
        end
    end)
end

return SamuraiClient