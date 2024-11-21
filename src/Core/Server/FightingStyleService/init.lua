--[[
    FightingStyleService.lua
    Nendalla
    31/10/2024
--]]

local FightingStyleService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stellar = require(ReplicatedStorage.SharedModules.Stellar)

local Initialised = {}

local Assets = {}
local LoadedAssets = {}

function FightingStyleService._Initialise(name: string, module: any)
    if module.Init ~= nil and Initialised[name] == nil then
        local success: boolean, result: any = nil, nil
        local hasWarned: boolean = false
        local start: number = tick()

        task.spawn(function()
            success, result = pcall(module.Init, module)
        end)

        while success == nil do
            if tick() - start > 15 and not hasWarned then
                warn(`[FightingStyleService::Danger] '{name}' is taking a long time to initialise!`)
                hasWarned = true
            end
            task.wait()
        end

        if hasWarned then
            warn(
                string.format(
                    "[FightingStyleService::Resolved] '%s' has finished initialising. Took %.2fs!",
                    name,
                    tick() - start
                )
            )
        end

        if not success then
            warn(`[FightingStyleService] Failed to initialise '{name}' due to: {result}`)
        end

        Initialised[name] = true
    end
end

function FightingStyleService.Get(name: string, dontInit: boolean?): any
    assert(
        typeof(name) == "string",
        `[FightingStyleService] Attempted to get module with type '{typeof(name)}', string expected!`
    )

    if LoadedAssets[name] ~= nil then
        return LoadedAssets[name]
    end

    if Assets[name] == nil then
        local yieldDuration: number = tick()
        warn(`[FightingStyleService] Yielding for unimported module '{name}'`)
        repeat
            task.wait()
        until Assets[name] or tick() >= yieldDuration + 5
    end

    if Assets[name] ~= nil then
        local start: number = tick()
        local success: boolean, result: any = FightingStyleService._Import(Assets[name])
        local duration: string = string.format("%.2f", tick() - start)

        if tick() - start > 1 then
            warn(`[FightingStyleService] '{name}' has finished requiring. Took {duration}s!`)
        end

        if success then
            LoadedAssets[name] = result
            print(`[FightingStyleService] '{name}' successfully imported [{duration}s]`)

            if not dontInit then
                FightingStyleService._Initialise(name, LoadedAssets[name])
            end

            return result
        else
            warn(`[FightingStyleService] Failed to import module '{name}' due to: {result}`)
        end
    end
end

function FightingStyleService.Load(module: ModuleScript)
    assert(
        typeof(module) == "Instance" and module:IsA("ModuleScript"),
        `[FightingStyleService] Attempted to load a '{typeof(module)}', ModuleScript expected!`
    )
    assert(Assets[module.Name] == nil, `[FightingStyleService] Attempted to load duplicate named module '{module.Name}'`)

    if module ~= script then
        Assets[module.Name] = module
    end
end

function FightingStyleService._Import(module: ModuleScript): (boolean, any)
    if module:IsA("ModuleScript") then
        local start: number = tick()
        local result: {} = nil
        local hasLogged: boolean = false

        task.spawn(function()
            result = table.pack(pcall(require, module))
        end)

        while result == nil do
            if tick() - start > 15 and not hasLogged then
                warn(`[FightingStyleService::Danger] '{module.Name}' is taking a long time to require!`)
                hasLogged = true
            end
            task.wait()
        end

        if hasLogged then
            warn(
                string.format(
                    "[FightingStyleService::Resolved] '%s' has finished requiring. Took %.2fs!",
                    module.Name,
                    tick() - start
                )
            )
        end

        return table.unpack(result)
    end
end

function FightingStyleService:SetFightingStyle(player: Player, style: string)
    player:SetAttribute("FightingStyle", style)

    FightingStyleService.Get(style):Equip(player)
end

function FightingStyleService:Init()
    for _, v in script:GetChildren() do
        if v:IsA("ModuleScript") then
            FightingStyleService.Load(v)
        end
    end
    for _, v in script:GetChildren() do
        if v:IsA("ModuleScript") then
            FightingStyleService.Get(v.Name)
        end
    end

    task.delay(10, function()
        print("Setting")
        FightingStyleService:SetFightingStyle(game.Players.Nendalla, "Samurai")
    end)
end

return FightingStyleService
