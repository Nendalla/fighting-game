--[[
    PlayerUtilServer.lua
    Nendalla
    17/11/2024
--]]

local PlayerUtilServer = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)

local iFramedPlayers = {}

function PlayerUtilServer:iFrame(player, duration)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end

    local currentTime = tick()

    if iFramedPlayers[player] then
        iFramedPlayers[player].endTime = iFramedPlayers[player].endTime + duration
    else
        iFramedPlayers[player] = {
            endTime = currentTime + duration,
        }

        character:SetAttribute("iFrame", true)

        task.spawn(function()
            while iFramedPlayers[player] do
                local remainingTime = iFramedPlayers[player].endTime - tick()

                if remainingTime <= 0 then
                    character:SetAttribute("iFrame", false)

                    iFramedPlayers[player] = nil
                else
                    task.wait(math.min(remainingTime, 0.5))
                end
            end
        end)
    end
end

return PlayerUtilServer
