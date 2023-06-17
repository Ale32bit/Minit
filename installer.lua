-- Minit installer
-- Copyrigth (C) 2023 AlexDevs
-- This software is licensed under the MIT license.

local remote = "https://raw.githubusercontent.com"
local repository = "Ale32bit/Minit"
local branch = "main"

local files = {
    "minit.lua",
    "modules/autofeed.lua",
    "modules/flight.lua",
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
print("This software is licensed under the MIT license.")
print("https://github.com/Ale32bit/Minit/blob/main/LICENSE")
print("Continue? [Y/n]")
local input = read()
if input:lower() ~= "y" and input:lower() ~= "" then
    print("Installation canceled.")
    return
end

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