--[[ 
    DamagePart.lua 
    Nendalla 
    30/10/2024 
    Handles damaging players when they touch a specified part in Roblox, 
    with optional damage-over-time functionality and debounce control. 
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local Maid = Stellar.Get("Maid")

local DamagePart = {}
DamagePart.__index = DamagePart

--- Initializes a new DamagePart instance.
-- @param part Instance The part that will damage players
-- @param damageAmount number The amount of damage dealt to each player
-- @param damageOverTime boolean Optional; toggles continuous damage while player is in part
-- @param debounce number Delay between each damage tick for damageOverTime
-- @param exclude table Table of character instances to exclude from damage
-- @return table A DamagePart instance
function DamagePart.new(part: Instance, damageAmount: number, damageOverTime: boolean, debounce: number, exclude: table)
    local self = setmetatable({}, DamagePart)
    self.part = part
    self.damageAmount = damageAmount
    self.damageOverTime = damageOverTime or false
    self.debounce = debounce
    self.exclude = exclude or {}
    self.maid = Maid.new()
    self.lastTouch = {} -- Track last touch times for each humanoid
    self.touchCount = {} -- Track number of touching parts per humanoid

    self:_setup()
    return self
end

--- Sets up touch connections and part cleanup for damage logic.
function DamagePart:_setup()
    self.maid:GiveTask(self.part.Touched:Connect(function(hit: Instance)
        local character = hit.Parent
        local humanoid = character:FindFirstChild("Humanoid")

        -- Check if character is in the exclude list
        if humanoid and humanoid:IsA("Humanoid") and not table.find(self.exclude, character) then
            local currentTime = tick()
            -- Use humanoid instance as the key for tracking last touch time
            if not self.lastTouch[humanoid] or (currentTime - self.lastTouch[humanoid] >= 0.1) then
                self.lastTouch[humanoid] = currentTime -- Update last touch time
                -- Increment touch count
                self.touchCount[humanoid] = (self.touchCount[humanoid] or 0) + 1

                if self.damageOverTime then
                    self:_damageOverTime(humanoid)
                else
                    self:_applyDamage(humanoid)
                end
            end
        end
    end))

    self.maid:GiveTask(self.part.TouchEnded:Connect(function(endedHit: Instance)
        local character = endedHit.Parent
        local humanoid = character:FindFirstChild("Humanoid")

        if humanoid and humanoid:IsA("Humanoid") then
            -- Decrement touch count
            if self.touchCount[humanoid] then
                self.touchCount[humanoid] = self.touchCount[humanoid] - 1
                if self.touchCount[humanoid] <= 0 then
                    self.touchCount[humanoid] = nil
                    if self.damageOverTime and self.maid[humanoid] then
                        local humanoidMaid = self.maid[humanoid]
                        humanoidMaid:DoCleaning()
                        self.maid[humanoid] = nil
                    end
                end
            end
        end
    end))

    self.maid:GiveTask(self.part.Destroying:Connect(function()
        self.maid:DoCleaning()
    end))
end

--- Immediately applies damage to a humanoid based on specified damage amount.
-- @param humanoid Humanoid The humanoid instance to damage
function DamagePart:_applyDamage(humanoid: Humanoid)
    humanoid:TakeDamage(self.damageAmount)
end

--- Continuously applies damage over time to a humanoid while they remain in the part.
-- Prevents multiple damage loops per humanoid.
-- @param humanoid Humanoid The humanoid instance to apply damage over time
function DamagePart:_damageOverTime(humanoid: Humanoid)
    if self.maid[humanoid] then
        return
    end

    local humanoidMaid = Maid.new()
    self.maid[humanoid] = humanoidMaid

    local function damageLoop()
        while
            self.touchCount[humanoid]
            and self.touchCount[humanoid] > 0
            and humanoid
            and humanoid.Health > 0
            and self.part:IsDescendantOf(workspace)
        do
            humanoid:TakeDamage(self.damageAmount)
            task.wait(self.debounce)
        end
        -- Cleanup after loop ends
        if self.maid[humanoid] then
            humanoidMaid:DoCleaning()
            self.maid[humanoid] = nil
        end
    end

    task.spawn(damageLoop)
end

return DamagePart
