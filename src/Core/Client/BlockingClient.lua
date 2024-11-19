--[[
    BlockingClient.lua
    Nendalla
    17/11/2024
--]]

local BlockingClient = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Network = Stellar.Get("Network")

local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")

local blockingAnim
local isBlocking = false
local isFPressed = false
local blockingTask = nil

function BlockingClient:StartBlocking()
    if isBlocking or blockingTask then
        return
    end

    isFPressed = true

    blockingTask = task.spawn(function()
        while Player.Character and Player.Character:GetAttribute("Stunned") do
            Player.Character:GetAttributeChangedSignal("Stunned"):Wait()
        end

        if not Player.Character or Player.Character:GetAttribute("Stunned") then
            isFPressed = false
            blockingTask = nil
            return
        end

        if not isFPressed then
            blockingTask = nil
            return
        end

        isBlocking = true
        blockingTask = nil

        Network:Signal("Block", "StartBlocking")

        local animator = Player.Character:WaitForChild("Humanoid"):WaitForChild("Animator")
        local STYLE = Player:GetAttribute("FightingStyle")

        local blockingAsset = ReplicatedStorage.Assets.FightingStyles[STYLE]:FindFirstChild("Blocking")
            or ReplicatedStorage.Assets.Combat.Blocking
        if blockingAsset then
            blockingAnim = animator:LoadAnimation(blockingAsset)
            blockingAnim:Play()
        else
            warn("Blocking animation not found for style:", STYLE)
        end
    end)
end

function BlockingClient:StopBlocking()
    isFPressed = false

    if blockingTask then
        blockingTask = nil
    end

    if isBlocking then
        isBlocking = false

        Network:Signal("Block", "StopBlocking")

        if blockingAnim and blockingAnim.IsPlaying then
            blockingAnim:Stop()
            blockingAnim = nil
        end
    end
end

function BlockingClient:Init()
    local function onInputBegan(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.F and not gameProcessed then
            self:StartBlocking()
        end
    end

    local function onInputEnded(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.F and not gameProcessed then
            self:StopBlocking()
        end
    end

    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputEnded:Connect(onInputEnded)

    Player.CharacterAdded:Connect(function(character)
        isBlocking = false
        isFPressed = false
        blockingTask = nil
        if blockingAnim then
            blockingAnim:Stop()
            blockingAnim = nil
        end
    end)
end

return BlockingClient
