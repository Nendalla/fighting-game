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

local DamageHandler = Stellar.Get("DamageHandler")

local DamagePart = {}
DamagePart.__index = DamagePart

--- Initializes a new DamagePart instance.
-- @param part Instance The part that will damage players
-- @param damageAmount number The amount of damage dealt to each player
-- @param damageOverTime boolean Optional; toggles continuous damage while player is in part
-- @param debounce number Delay between each damage tick for damageOverTime
-- @param exclude table Optional; Table of character instances to exclude from damage
-- @param damageType string Optional; The type/category of damage
-- @param canKill boolean Optional; Determines if damage can reduce health to zero
-- @return table A DamagePart instance
function DamagePart.new(
    part: Instance, 
    damageAmount: number, 
    damageOverTime: boolean, 
    debounce: number, 
    exclude: table, 
    damageType: string,
    canKill: boolean
)
    local self = setmetatable({}, DamagePart)
    self.part = part
    self.damageAmount = damageAmount
    self.damageOverTime = damageOverTime or false
    self.debounce = debounce or 1
    self.exclude = exclude or {}
    self.damageType = damageType or "generic"
    self.canKill = canKill or false
    self.maid = Maid.new()
    self.lastTouch = {} -- Track last touch times for each humanoid
    self.touchCount = {} -- Track number of touching parts per humanoid
    self.activeDamageLoops = {} -- Track active damage loops for each humanoid

    self:_setup()
    return self
end

--- Sets up touch connections and part cleanup for damage logic.
function DamagePart:_setup()
    -- Handle when a part is touched
    self.maid:GiveTask(self.part.Touched:Connect(function(hit: Instance)
        local character = hit.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        -- Check if character is valid and not excluded
        if humanoid and humanoid:IsA("Humanoid") and not table.find(self.exclude, character) then
            local currentTime = tick()
            -- Use humanoid instance as the key for tracking last touch time
            if not self.lastTouch[humanoid] or (currentTime - self.lastTouch[humanoid] >= 0.1) then
                self.lastTouch[humanoid] = currentTime -- Update last touch time
                -- Increment touch count
                self.touchCount[humanoid] = (self.touchCount[humanoid] or 0) + 1

                if self.damageOverTime then
                    self:_damageOverTime(character, humanoid)
                else
                    self:_applyDamage(character)
                end
            end
        end
    end))

    -- Handle when a part touch ends
    self.maid:GiveTask(self.part.TouchEnded:Connect(function(endedHit: Instance)
        local character = endedHit.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid:IsA("Humanoid") then
            -- Decrement touch count
            if self.touchCount[humanoid] then
                self.touchCount[humanoid] = self.touchCount[humanoid] - 1
                if self.touchCount[humanoid] <= 0 then
                    self.touchCount[humanoid] = nil
                    if self.damageOverTime and self.activeDamageLoops[humanoid] then
                        local humanoidMaid = self.activeDamageLoops[humanoid]
                        humanoidMaid:DoCleaning()
                        self.activeDamageLoops[humanoid] = nil
                    end
                end
            end
        end
    end))

    -- Cleanup when the part is destroyed
    self.maid:GiveTask(self.part.Destroying:Connect(function()
        self.maid:DoCleaning()
    end))
end

--- Applies damage to a humanoid using DamageHandler.
-- @param character Instance The character model to damage
-- @param humanoid Humanoid The humanoid instance within the character
function DamagePart:_applyDamage(character: Instance)
    -- Validate parameters
    if not character or not character.Parent then return end
    if not self.damageAmount or typeof(self.damageAmount) ~= "number" then return end
    if not self.damageType or typeof(self.damageType) ~= "string" then
        self.damageType = "generic"
    end

    -- Call DamageHandler:TakeDamage with the character
    DamageHandler:TakeDamage(
        character, 
        self.damageAmount, 
        self.canKill, 
        self.damageType
    )
end

--- Continuously applies damage over time to a humanoid while they remain in the part.
-- Prevents multiple damage loops per humanoid.
-- @param character Instance The character model to damage
-- @param humanoid Humanoid The humanoid instance within the character
function DamagePart:_damageOverTime(character: Instance, humanoid: Humanoid)
    if self.activeDamageLoops[humanoid] then
        return -- Damage loop already active for this humanoid
    end

    local humanoidMaid = Maid.new()
    self.activeDamageLoops[humanoid] = humanoidMaid

    local function damageLoop()
        while
            self.touchCount[humanoid]
            and self.touchCount[humanoid] > 0
            and humanoid
            and humanoid.Health > 0
            and self.part:IsDescendantOf(workspace)
        do
            -- Apply damage using DamageHandler
            DamageHandler:TakeDamage(
                character,
                self.damageAmount,
                self.canKill,
                self.damageType
            )
            task.wait(self.debounce)
        end
        -- Cleanup after loop ends
        if self.activeDamageLoops[humanoid] then
            humanoidMaid:DoCleaning()
            self.activeDamageLoops[humanoid] = nil
        end
    end

    task.spawn(damageLoop)
end

--- Cleans up the DamagePart instance, disconnecting all events and loops.
function DamagePart:Destroy()
    self.maid:DoCleaning()
    -- Additionally, clean up any active damage loops
    for humanoid, maid in pairs(self.activeDamageLoops) do
        maid:DoCleaning()
        self.activeDamageLoops[humanoid] = nil
    end
end

return DamagePart