-- Elytra Flight module for Minit
-- Copyright (C) 2023 AlexDevs
-- This software is licensed under the MIT license.

local module = {
    name = "flight",
}

local locale = {
    direction = "%s : %d", -- windrose : pitch
    altitude = "Y: %d",
    yMotion = "Y: %.2f",
    speed = "%.2f m/s",
}

local icons = {
    empty = "air",
    fly = "elytra",
    launch = "firework_rocket",
    slow = "feather",
    disabled = "barrier",
    propelling = "blaze_powder"
}

-- Default variables. Use settings file to change values.
settings.define("elytra.power", {
    description = "Propeller power",
    type = "number",
    default = 2,
})

settings.define("elytra.pitch", {
    description = "Propeller pitch treshold",
    type = "number",
    default = 0,
})

settings.define("elytra.scale", {
    description = "Scale of UI",
    type = "number",
    default = 0.6,
})

settings.define("elytra.sounds", {
    description = "Enable sound effects",
    type = "boolean",
    default = true,
})

settings.define("elytra.manual", {
    description = "Invert the SHIFT function to propel on press",
    type = "boolean",
    default = false,
})

local neural, speaker
local canvas, container
local screen = {}
local currentY = 0

local function getRoseWind(degrees)
    degrees = degrees + 180
    local directions = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    local index = math.floor((degrees / 45) + 0.5) % 8
    return directions[index + 1]
end

local function createScreen()
    canvas = neural.canvas()
    screen = {}

    if container then
        pcall(container.clear)
    end

    container = canvas.addGroup({ 1, 1 })

    local scale = settings.get("elytra.scale")
    local x, y = 25, math.ceil(9 * scale)

    screen.icon = container.addItem({ 0, 1 }, "elytra")
    screen.speed = container.addText({ x, y * 1 }, "")
    screen.speed.setScale(scale)

    screen.altitude = container.addText({ x, y * 2 }, "")
    screen.altitude.setScale(scale)

    screen.direction = container.addText({ x, y * 3 }, "")
    screen.direction.setScale(scale)
end

local function updateScreen(meta)
    if not canvas or not container then
        createScreen()
    end

    local mVector = vector.new(meta.deltaPosX, meta.deltaPosY, meta.deltaPosZ)
    local speed = mVector:length() * 20
    screen.speed.setText(string.format(locale.speed, speed))
    screen.direction.setText(string.format(locale.direction, getRoseWind(meta.yaw), meta.pitch))
    screen.altitude.setText(string.format(locale.altitude, currentY))
end

local icon = icons.empty
local function toggleScreen(show)
    local alpha = show and 0xff or 0
    screen.icon.setItem(show and icon or icons.empty)
    screen.speed.setAlpha(alpha)
    screen.altitude.setAlpha(alpha)
    screen.direction.setAlpha(alpha)
end

local function setIcon(newIcon)
    icon = newIcon
    screen.icon.setItem(newIcon)
end

local function playSound(sound, volume, pitch)
    if speaker and settings.get("elytra.sounds") then
        speaker.playSound(sound, volume, pitch)
    end
end

local function launch(yaw, pitch, power)
    power = power or settings.get("elytra.power")
    neural.launch(yaw, pitch, math.min(power, 4))
end

local function launchUp(power)
    launch(0, -90, power)
end

local function softFall(motionY)
    motionY = motionY or 0
    launchUp(-motionY + 0.75)
    playSound("minecraft:entity.phantom.flap", 1, 1)
end

local function canPropel(meta)
    return settings.get("elytra.manual") and meta.isSneaking or not meta.isSneaking
end

local function propel(meta, icon)
    neural.launch(meta.yaw, meta.pitch, settings.get("elytra.power"))
    playSound("minecraft:entity.fishing_bobber.throw", 0.4, 1)

    if icon then
        setIcon(icon)
    end
end

local function gpsLocate()
    while true do
        local x, y, z = gps.locate()
        if x then
            currentY = y
        end
        sleep(0.5)
    end
end

function module.init(init)
    init.addTask(gpsLocate)
end

function module.setup(ni)
    neural = ni
    speaker = peripheral.find("speaker")

    createScreen()
    toggleScreen(false)
end

function module.update(meta)
    if not meta.isElytraFlying then
        if meta.isSneaking then
            if meta.pitch == -90 then
                setIcon(icons.launch)
                launchUp(2)
            else
                setIcon(icons.disabled)
            end
            return
        end

        if meta.deltaPosY < -1 then
            softFall(meta.motionY)
            setIcon(icons.slow)
            return
        end

        toggleScreen(false)
        return
    end

    toggleScreen(true)
    updateScreen(meta)

    local pitch = meta.pitch
    local yaw = meta.yaw

    if not canPropel(meta) then
        setIcon(icons.disabled)
        return
    end

    if settings.get("elytra.manual") then
        if meta.isSneaking then
            propel(meta, icons.propelling)
        else
            if meta.deltaPosY < -1 then
                softFall(meta.motionY)
                setIcon(icons.slow)
            else
                setIcon(icons.fly)
            end
        end
    else
        if pitch > settings.get("elytra.pitch") then
            if meta.deltaPosY < -1 then
                softFall(meta.motionY)
                setIcon(icons.slow)
            end
            return
        end

        setIcon(icons.fly)
        propel(meta, false)
    end
end

return module