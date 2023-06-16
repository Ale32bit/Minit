-- AutoFeed module for Minit
-- Copyright (C) 2023 AlexDevs
-- This software is licensed under the MIT license.

local module = {
    name = "autofeed",
}

local saturation = 7
local foods = {
    "golden_carrot",
    "popcorn",
    "cooked_beef",
    "cooked_pork",
    "cooked_chicken",
    "baked_potato",
    "cooked_cod",
    "cooked_salmon",
    "bread",
    "melon_slice",
    "cooked_rabbit",
    "cooked_mutton",
}

local neural

local function has(arr, val)
    for k, v in ipairs(arr) do
        if val:find(v) then
            return true
        end
    end
    return false
end

local function findSlot(inventory)
    local list = inventory.list()
    for k, v in pairs(list) do
        if has(foods, v.name) then
            return k
        end
    end
    
    return -1
end

local function feed()
    local inventory = neural.getInventory()
    local foodSlot = findSlot(inventory)
    if foodSlot == -1 then
        return
    end
    inventory.consume(foodSlot)
end

function module.setup(ni)
    neural = ni
end

function module.update(meta)
    if meta.food.saturation < saturation then
        feed()
    end
end

return module