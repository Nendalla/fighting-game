--[=[
    @class SoundFX
    A simplistic way to store and play sound effects
    Sounds must be stored in ReplicatedStorage inside a folder called "SoundFXs"
    You can (and advised) to store sounds in subfolders if you have a large amount
]=]

local SoundFX = {}
local Stellar = require(game.ReplicatedStorage.SharedModules.Stellar)

local Network = Stellar.Get("Network")
local Maid = Stellar.Get("Maid")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local IsServer = game:GetService("RunService"):IsServer()

local SoundPlayed

local SoundFolder = ReplicatedStorage:WaitForChild("SoundFXs")
local Sounds = {}
local Volumes = {}
local Muted = false
local DEBUG_SOUND = false

function SoundFX:Play(name, part, duration, dupe, ignoreIfNotLoaded)
    local sound = Sounds[name] :: Sound

    if sound then
        -- One of the weirdest bugs I've encountered, sometimes the sound is
        -- loaded (and has a correct TimeLength, but .IsLoaded is still false)
        -- We account for this in the next few lines of code
        local soundStillLoading = (not sound.IsLoaded) and sound.TimeLength == 0
        if soundStillLoading then
            if ignoreIfNotLoaded then
                return
            else
                local start = tick()
                repeat
                    task.wait()
                    local durationSoFar = tick() - start
                    if durationSoFar >= 10 and DEBUG_SOUND then
                        warn(`[SoundFX] {name} is taking a long time to load!`)
                    elseif durationSoFar >= 15 then
                        warn(`[SoundFX] {name} took too long, overriding and not playing!`)
                        return
                    end
                until sound.IsLoaded or sound.TimeLength ~= 0
            end
        end

        if dupe then -- Duplicate RQ of sound (for multiple noises played at once)
            local newSound = sound:Clone()
            newSound.Parent = part or workspace
            local soundMaid = Maid.new()
            newSound:Play()

            if part and IsServer then
                SoundPlayed:Fire(part.Position, name, newSound.Looped)
            end

            if newSound.Looped then
                CollectionService:AddTag(newSound, "SoundFX")
            end
            soundMaid:GiveTask(newSound)
            soundMaid:GiveTask(newSound.Ended:Connect(function()
                soundMaid:DoCleaning()
            end))
            return
        end
        if sound.Looped and not dupe then
            if not SoundFX:GetLoopedSoundFromName(name) then
                local newSound = sound:Clone()
                local actualVolume = newSound.Volume

                if duration or Muted then
                    newSound.Volume = 0
                end

                newSound.Parent = part or workspace
                newSound:Play()

                if part and IsServer then
                    SoundPlayed:Fire(part.Position, name, true)
                end

                CollectionService:AddTag(newSound, "SoundFX")

                if duration and not Muted then
                    TweenService:Create(newSound, TweenInfo.new(duration), { Volume = actualVolume }):Play()
                end
            end
        elseif part or IsServer then
            local newSound = sound:Clone()
            newSound.Parent = part or workspace

            if part and IsServer then
                SoundPlayed:Fire(part.Position, name)
            end

            newSound.Ended:Connect(function()
                newSound:Destroy()
            end)
            newSound:Play()
        else
            sound:Play()
        end
    end
end

function SoundFX:GetLoopedSoundFromName(name)
    for _, sound in CollectionService:GetTagged("SoundFX") do
        if sound.Name == name then
            return sound
        end
    end
end

function SoundFX:StopLoop(name, duration)
    local objs = CollectionService:GetTagged("SoundFX")
    if objs then
        for _, obj in objs do
            if obj.Name == name then
                if duration then
                    TweenService:Create(obj, TweenInfo.new(duration), { Volume = 0 }):Play()
                end

                task.delay(duration or 0, function()
                    obj:Destroy()
                    obj = nil
                end)
            end
        end
    end
end

function SoundFX:Get(name)
    if Sounds[name] then
        return Sounds[name]
    end
end

function SoundFX:PlayAsync(name, part)
    local sound = SoundFX:Get(name)

    if sound then
        SoundFX:Play(name, part)
        task.wait(sound.TimeLength)
    end
end

function SoundFX:Mute()
    if Muted then
        return
    end

    for name, sound in pairs(Sounds) do
        if not CollectionService:HasTag(sound, "ImportantSound") then
            Volumes[name] = sound.Volume
            sound.Volume = 0
        end
    end

    for _, obj in pairs(CollectionService:GetTagged("SoundFX")) do
        if not CollectionService:HasTag(obj, "ImportantSound") then
            Volumes[obj.Name] = obj.Volume
            obj.Volume = 0
        end
    end

    Muted = true
end

function SoundFX:Unmute()
    for name, sound in pairs(Sounds) do
        if Volumes[name] then
            sound.Volume = Volumes[name]
        end
    end

    for _, sound in pairs(CollectionService:GetTagged("SoundFX")) do
        if Volumes[sound.Name] then
            sound.Volume = Volumes[sound.Name]
        end
    end

    Muted = false
end

function SoundFX:PlayClient(player: Player, name, part: Part)
    Network:Signal("SoundFX", player, name, part)
end

function SoundFX:StopClient(player: Player, name: string, duration: number)
    Network:Signal("SoundFX", player, name, nil, true, duration)
end

function SoundFX:Init()
    for _, asset in SoundFolder:GetDescendants() do
        if asset:IsA("Sound") then
            Sounds[asset.Name] = asset
        end
    end

    if IsServer then
        Network:Reserve({ "SoundFX", "RemoteEvent" })
        SoundPlayed = Stellar.Get("SignalProvider"):Get("SoundPlayed")
    else
        Network:ObserveSignal("SoundFX", function(name, part, stopLoop, duration)
            if not stopLoop then
                SoundFX:Play(name, part)
            elseif stopLoop then
                SoundFX:StopLoop(name, duration)
            end
        end)
    end

    CollectionService:GetInstanceAddedSignal("SoundFX"):Connect(function(asset)
        if Muted and asset.Volume ~= 0 then
            Volumes[asset.Name] = asset.Volume
            asset.Volume = 0
        end
    end)
end

return SoundFX
