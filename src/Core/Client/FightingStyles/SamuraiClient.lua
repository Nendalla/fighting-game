--[[
    SamuraiClient.lua
    Nendalla
    31/10/2024
--]]

local SamuraiClient = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")
local UserInputService = game:GetService("UserInputService")
local CombatConfig = Stellar.Get("CombatConfig")
local PlayerUtil = Stellar.Get("PlayerUtil")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Assets = ReplicatedStorage.Assets.FightingStyles:WaitForChild("Samurai")

local animations = {}
local attacking = false

-- Variables for Combo Reset Mechanism
local comboResetId = 0  -- Unique identifier for each combo reset timer
local number = 1        -- Tracks the current attack in the combo

local function registerCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 5)

    if humanoid then
        local animator = humanoid:WaitForChild("Animator")

        if animator then
            for _, v in Assets:GetChildren() do
                if v:IsA("Animation") then
                    local anim = animator:LoadAnimation(v)
                    animations[v.Name] = anim
                end
            end
        end
    end

    character.ChildAdded:Connect(function(child)
        if child and child:IsA("Tool") and child.Name == "Katana" then
            child.Equipped:Connect(function()
                animations["Unsheath"]:Play()
                character.HumanoidRootPart.Anchored = true
                Network:Signal("Samurai", "Equip")
                task.delay(1, function()
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.Anchored = false
                    end
                end)
                task.wait(animations["Unsheath"].Length * 0.95)
            end)

            child.Unequipped:Connect(function()
                Network:Signal("Samurai", "Unequip")
                animations["Sheath"]:Play()
                character.HumanoidRootPart.Anchored = true
                task.delay(1, function()
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.Anchored = false
                    end
                end)
            end)
        end
    end)
end

function SamuraiClient:Init()
    if Player.Character ~= nil then
        registerCharacter(Player.Character)
    end

    Player.CharacterAdded:Connect(registerCharacter)

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local character = Player.Character
            if not character then return end
            if not character:FindFirstChild("Katana") then return end
            if character.Humanoid.Health <= 0 then return end
            if character:GetAttribute("Stunned") then return end
            if character:GetAttribute("IsBlocking") then return end
            if attacking then return end

            attacking = true

            comboResetId = comboResetId + 1
            local currentComboResetId = comboResetId

            if number == 5 then
                Network:Signal("Samurai", "Swing", animations["Slash" .. number].Length, true)
                PlayerUtil:Stun(CombatConfig.Endlag)
            else
                Network:Signal("Samurai", "Swing", animations["Slash" .. number].Length)
                PlayerUtil:Stun(0.55)
            end
            animations["Slash" .. number]:Play()

            task.delay(2, function()
                if currentComboResetId == comboResetId then
                    number = 1
                end
            end)

            task.wait(animations["Slash" .. number].Length * 0.95)

            if number == 5 then
                number = 1
                task.wait(CombatConfig.SamuraiAttackDebounce)
            else
                number = number + 1
            end

            attacking = false
        end
    end

    UserInputService.InputBegan:Connect(onInputBegan)
end

return SamuraiClient