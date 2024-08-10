local config = lib.require('config')
local stevo_lib = exports['stevo_lib']:import()
local CRATE_COOLDOWN = false
local CURRENT_CRATE_DATA = {}
lib.locale()



---@param loot_table table Loot table
---@return table full Random Loot
function GenerateRandomLoot(loot_table)
    math.randomseed(os.time())
    local selected_items = {}

    for _, loot in ipairs(loot_table) do
        local randomChance = math.random(1, 100)
        if randomChance <= loot.chance then
            local randomAmount = math.random(loot.min_amt, loot.max_amt)
            table.insert(selected_items, {item = loot.item, count = randomAmount})
            
        end
    end

    return selected_items
end

RegisterNetEvent('stevo_cayocrates:createdrop', function()

    if stevo_lib.HasItem(source, config.usb_item) < 1 then 
        return 
    end

    stevo_lib.RemoveItem(source, config.usb_item, 1)

    local totalSeconds = config.crate_order_wait / 1000
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60

    local message
    if seconds > 0 then
        message = string.format("Drop incoming in %d minutes %d seconds", minutes, seconds)
    else
        message = string.format("Drop incoming in %d minutes", minutes)
    end

    config.globalNotify(message)
    
    Wait(config.crate_order_wait)

    local randomLocation = config.crates.locations[math.random(1, #config.crates.locations)]

    TriggerClientEvent('stevo_cayocrates:createblip', -1, randomLocation)

    config.globalNotify(locale('crate_dropping_15'))

    Wait(5000)

    config.globalNotify(locale('crate_dropping_10'))

    Wait(5000)

    config.globalNotify(locale('crate_dropping_5'))

    Wait(5000)

    CURRENT_CRATE_DATA = {
        coords = randomLocation,
        owned = false,
        current_owner = false,        
    }

    TriggerClientEvent('stevo_cayocrates:createdrop', -1, CURRENT_CRATE_DATA)
end)

RegisterNetEvent('stevo_cayocrates:networksync', function(action)


    if action == 'open' then 
        CURRENT_CRATE_DATA.current_owner = source
        CURRENT_CRATE_DATA.owned = true
        TriggerClientEvent('stevo_cayocrates:networksync', -1, 'open', CURRENT_CRATE_DATA)
    end

    if action == 'crateopen' then
        local loot = GenerateRandomLoot(config.crates.loot)
        for i, item in pairs(loot) do
            stevo_lib.AddItem(source, item.item, item.count)
        end

        local coords = CURRENT_CRATE_DATA.coords
        CURRENT_CRATE_DATA = {}
        TriggerClientEvent('stevo_cayocrates:networksync', -1, 'crateopen', CURRENT_CRATE_DATA, coords)

        config.globalNotify(locale('crate_opened'))

        CRATE_COOLDOWN = true
        SetTimeout(config.crate_order_cooldown, function()
            CRATE_COOLDOWN = false
        end)
    
    end

    if action == 'cancelopen' then
        CURRENT_CRATE_DATA.current_owner = false
        CURRENT_CRATE_DATA.owned = false
        TriggerClientEvent('stevo_cayocrates:networksync', -1, 'crateclose', CURRENT_CRATE_DATA)
    end

end)


lib.callback.register('stevo_cayocrates:data', function(source)
    return CRATE_COOLDOWN, stevo_lib.HasItem(source, config.usb_item) >= 1
end)