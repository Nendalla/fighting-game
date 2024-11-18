--[[
    AbilityServer.lua
    Nendalla
    30/10/2024
--]]

local AbilityServer = {}
local Initialised = {}

local Assets = {}
local LoadedAssets = {}

function AbilityServer._Initialise(name: string, module: any)
    if module.Init ~= nil and Initialised[name] == nil then
        local success: boolean, result: any = nil, nil
        local hasWarned: boolean = false
        local start: number = tick()

        task.spawn(function()
            success, result = pcall(module.Init, module)
        end)

        while success == nil do
            if tick() - start > 15 and not hasWarned then
                warn(`[AbilityServer::Danger] '{name}' is taking a long time to initialise!`)
                hasWarned = true
            end
            task.wait()
        end

        if hasWarned then
            warn(
                string.format(
                    "[AbilityServer::Resolved] '%s' has finished initialising. Took %.2fs!",
                    name,
                    tick() - start
                )
            )
        end

        if not success then
            warn(`[AbilityServer] Failed to initialise '{name}' due to: {result}`)
        end

        Initialised[name] = true
    end
end

function AbilityServer.Get(name: string, dontInit: boolean?): any
    assert(
        typeof(name) == "string",
        `[AbilityServer] Attempted to get module with type '{typeof(name)}', string expected!`
    )

    if LoadedAssets[name] ~= nil then
        return LoadedAssets[name]
    end

    if Assets[name] == nil then
        local yieldDuration: number = tick()
        warn(`[AbilityServer] Yielding for unimported module '{name}'`)
        repeat
            task.wait()
        until Assets[name] or tick() >= yieldDuration + 5
    end

    if Assets[name] ~= nil then
        local start: number = tick()
        local success: boolean, result: any = AbilityServer._Import(Assets[name])
        local duration: string = string.format("%.2f", tick() - start)

        if tick() - start > 1 then
            warn(`[AbilityServer] '{name}' has finished requiring. Took {duration}s!`)
        end

        if success then
            LoadedAssets[name] = result
            print(`[AbilityServer] '{name}' successfully imported [{duration}s]`)

            if not dontInit then
                AbilityServer._Initialise(name, LoadedAssets[name])
            end

            return result
        else
            warn(`[AbilityServer] Failed to import module '{name}' due to: {result}`)
        end
    end
end

function AbilityServer.Load(module: ModuleScript)
    assert(
        typeof(module) == "Instance" and module:IsA("ModuleScript"),
        `[AbilityServer] Attempted to load a '{typeof(module)}', ModuleScript expected!`
    )
    assert(Assets[module.Name] == nil, `[AbilityServer] Attempted to load duplicate named module '{module.Name}'`)

    if module ~= script then
        Assets[module.Name] = module
    end
end

function AbilityServer._Import(module: ModuleScript): (boolean, any)
    if module:IsA("ModuleScript") then
        local start: number = tick()
        local result: {} = nil
        local hasLogged: boolean = false

        task.spawn(function()
            result = table.pack(pcall(require, module))
        end)

        while result == nil do
            if tick() - start > 15 and not hasLogged then
                warn(`[AbilityServer::Danger] '{module.Name}' is taking a long time to require!`)
                hasLogged = true
            end
            task.wait()
        end

        if hasLogged then
            warn(
                string.format(
                    "[AbilityServer::Resolved] '%s' has finished requiring. Took %.2fs!",
                    module.Name,
                    tick() - start
                )
            )
        end

        return table.unpack(result)
    end
end

function AbilityServer:Init()
    print("Running")
    for _, v in script:GetChildren() do
        if v:IsA("ModuleScript") then
            AbilityServer.Load(v)
        end
    end
    for _, v in script:GetChildren() do
        if v:IsA("ModuleScript") then
            AbilityServer.Get(v.Name)
        end
    end
end

return AbilityServer
