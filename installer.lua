-- Minit installer
-- Copyright (C) 2023 AlexDevs
-- This software is licensed under the MIT license.

local remote = "https://raw.githubusercontent.com"
local repository = "Ale32bit/Minit"
local branch = "main"

local files = {
    "minit.lua",
}

local modulesPath = "modules"
local modules = {
    { name = "Elytra Flight", file = "flight.lua" },
    { name = "AutoFeed",      file = "autofeed.lua" },
    { name = "ESpeak",        file = "espeak.lua" },
}
local function get(file)
    local url = string.format("%s/%s/%s/%s", remote, repository, branch, file)
    local response, err = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        return content
    else
        return nil, err
    end
end

local function saveFile(path, content)
    local file = fs.open(path, "w")
    file.write(content)
    file.close()
end

print("Minit installer")
print("Copyright (C) 2023 AlexDevs")
print("This software is licensed under the MIT license.")
print("https://github.com/Ale32bit/Minit/blob/main/LICENSE")
print()
print("Select modules to install:")

local tabs = {}
for i, v in ipairs(modules) do
    table.insert(tabs, string.format("[%d] %s", i, v.name))
end
textutils.tabulate(tabs)
print()

print("Separate numbers with spaces")
write("> ")
local input = read()
local selected = {}
for i in input:gmatch("%d+") do
    local n = tonumber(i)
    if n and modules[n] then
        table.insert(selected, n)
    end
end

print("The following modules will be installed: ")
for i, v in ipairs(selected) do
    write(modules[v].name .. "; ")
end

print("Continue? [Y/n]")
local input = read()
if input:lower() ~= "y" and input:lower() ~= "" then
    print("Installation canceled.")
    return
end

print()
print("Installing Minit...")

for i, v in ipairs(files) do
    local content, err = get(v)
    if content then
        saveFile(v, content)
        print("Installed " .. v)
    else
        printError("Could not install " .. v .. ": " .. err)
    end
end

print("Installing modules...")
for i, v in ipairs(selected) do
    local content, err = get(fs.combine(modulesPath, modules[v].file))
    if content then
        saveFile(fs.combine(modulesPath, modules[v].file), content)
        print("Installed " .. modules[v].name)
    else
        printError("Could not install " .. modules[v].name .. ": " .. err)
    end
end