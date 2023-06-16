-- Minit Beta 1.0.0
-- Copyright (C) 2023 AlexDevs
-- This software is licensed under the MIT license.

settings.define("minit.cycleSleep", {
    description = "Sleep time between cycles",
    type = "number",
    default = 0.1,
})

settings.define("minit.cycleTimeout", {
    description = "Cycles timeout",
    type = "number",
    default = 1,
})

settings.define("minit.modulesPath", {
    description = "Path to modules",
    type = "string",
    default = "modules",
})

local modulesPath = settings.get("minit.modulesPath")
local neuralInterface

local expect = require("cc.expect").expect

local logPrefix = "%s %s:"
local function getTime()
    return os.date("%H:%M:%S")
end
local function log(label, ...)
    local time = getTime()
    print(string.format(logPrefix, time, label), ...)
end

local function logError(label, ...)
    local time = getTime()
    printError(string.format(logPrefix, time, label), ...)
end

local modules = {}
local function loadModules()
    log("Minit", "Loading modules from /" .. modulesPath)
    local files = fs.list(modulesPath)
    for i = 1, #files do
        local ok, par = pcall(require, fs.combine(modulesPath, files[i])
            :gsub("/", ".")
            :gsub("%.lua$", ""))
        if ok then
            par.name = par.name or files[i]:gsub("%.lua$", "")
            table.insert(modules, par)
            log("Minit", "Loaded module " .. par.name)
        else
            logError("Minit", "Could not load module " .. files[i] .. ": " .. par)
        end
    end
end

local function getCallbacks(name, ...)
    local args = table.pack(...)
    local callbacks = {}
    for i = 1, #modules do
        local module = modules[i]
        if type(module[name]) == "function" then
            table.insert(callbacks, function()
                module[name](table.unpack(args))
            end)
        end
    end
    return table.unpack(callbacks)
end

local tasks = {}
local function addTask(task)
    expect(1, task, "function")
    table.insert(tasks, coroutine.create(task))
end

local function initModules()
    for i = 1, #modules do
        local module = modules[i]
        if type(module.init) == "function" then
            module.init({
                addTask = addTask,
                log = function(...)
                    log(module.name, ...)
                end,
                logError = function(...)
                    logError(module.name, ...)
                end,
            })
        end
    end
end

local function setupNeuralInterface()
    neuralInterface = peripheral.wrap("back")

    if not neuralInterface then
        error("No neural interface found")
    end

    -- Wait for owner to be alive
    local function getOwner()
        local meta
        parallel.waitForAny(function()
            meta = neuralInterface.getMetaOwner()
        end, function()
            sleep(1)
        end)

        return meta
    end

    local meta = getOwner()
    if not meta or not meta.isAlive then
        log("Minit", "Waiting for respawn...")
    end
    while not meta or not meta.isAlive do
        sleep(0.2)
        meta = getOwner()
    end

    parallel.waitForAll(getCallbacks("setup", neuralInterface))
end

local function cycleUpdate()
    local metaOwner = neuralInterface.getMetaOwner()

    parallel.waitForAll(getCallbacks("update", metaOwner))

    sleep(settings.get("minit.cycleSleep"))
end

local function tasksHandler()
    local ev = { n = 0 }
    local filters = {}

    while true do
        for i, thread in pairs(tasks) do
            if coroutine.status(thread) == "dead" then
                tasks[i] = nil
                filters[i] = nil
            else
                if filters[i] == nil or filters[i] == ev[1] or ev[1] == "terminate" then
                    local ok, param = coroutine.resume(thread, table.unpack(ev, 1, ev.n))
                    if not ok then
                        logError("Task", param)
                    else
                        filters[i] = param
                    end
                end
            end
        end
        ev = table.pack(coroutine.yield())
    end
end

local function main()
    setupNeuralInterface()
    while true do
        parallel.waitForAny(
            cycleUpdate,
            function()
                sleep(settings.get("minit.cycleTimeout"))
            end
        )
    end
end

loadModules()
initModules()

parallel.waitForAny(
    function()
        while true do
            local ok, err = pcall(main)
            if not ok then
                if err == "Terminated" then
                    break
                end
                logError("Minit", err)
                sleep(1)
            end
        end
    end,
    tasksHandler
)
