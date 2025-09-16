local config = lib.require('shared.config')


local CrateState = {
    current_crate = nil,
    opening_players = {}
}


local function validateCrateOpening(player)
    if not player or player <= 0 then
        config.utils.log(locale('crate.invalid_player_crate'), 'WARNING')
        return false
    end

    if not CrateState.current_crate then
        config.utils.log(locale('crate.non_existent_crate', player), 'WARNING')
        return false
    end
    if #(CrateState.current_crate.coords - GetEntityCoords(GetPlayerPed(player))) > 5 then
        config.utils.log(locale('crate.player_too_far_crate', player, #(CrateState.current_crate.coords - GetEntityCoords(GetPlayerPed(player)))), 'WARNING')
        return false
    end

    if CrateState.current_crate.owned and CrateState.current_crate.current_owner ~= player then
        config.utils.log(locale('crate.already_owned_crate', player), 'WARNING')
        return false
    end

    local player_coords = GetEntityCoords(GetPlayerPed(player))
    local crate_coords = CrateState.current_crate.coords
    local distance = #(player_coords - crate_coords)

    if distance > 5 then
        config.utils.log(locale('crate.player_too_far_crate', player, distance), 'WARNING')
        return false
    end

    return true
end

local function validateCrateCompletion(player)
    local opening_data = CrateState.opening_players[player]
    if not opening_data then
        config.utils.log(locale('crate.player_no_start_crate', player), 'WARNING')
        return false
    end

    if not CrateState.current_crate or CrateState.current_crate.current_owner ~= player then
        config.utils.log(locale('crate.player_no_ownership', player), 'WARNING')
        return false
    end

    local opening_time = os.time() - opening_data.start_time
    local min_opening_time = (config.crates.opening_time / 1000) * 0.8

    if opening_time < min_opening_time then
        config.utils.log(locale('crate.opening_too_quick', player, opening_time, min_opening_time), 'WARNING')
        return false
    end

    return true
end

local function generateLoot()
    local selected_items = {}

    for tier_name, tier_data in pairs(config.crates.loot.tiers) do
        local random_chance = math.random(1, 100)
        if random_chance <= tier_data.chance then
            for _, item_data in ipairs(tier_data.items) do
                local item_chance = math.random(1, 100)
                if item_chance <= item_data.chance then
                    local amount = math.random(item_data.min_amt, item_data.max_amt)
                    table.insert(selected_items, {
                        item = item_data.item,
                        count = amount,
                        tier = tier_name
                    })
                end
            end
        end
    end

    return selected_items
end


local function giveLootToPlayer(player, loot)
    local success_count = 0

    for _, item_data in ipairs(loot) do
        local success = exports.ox_inventory:AddItem(player, item_data.item, item_data.count)
        if success then
            success_count = success_count + 1
            config.utils.log(locale('loot.gave_item_player', item_data.count, item_data.item, player, item_data.tier), 'INFO')
        else
            config.utils.log(locale('loot.failed_give_item', item_data.count, item_data.item, player), 'WARNING')
        end
    end


    if success_count > 0 then
        config.utils.notify(player, locale('loot.received_items', success_count), 'success')
    else
        config.utils.notify(player, locale('loot.failed_receive_items'), 'error')
    end
end

local function cleanupCrate()
    TriggerClientEvent('stevo_cayocrates:crateOpened', -1, CrateState.current_crate)

    CrateState.current_crate = nil
    CrateState.opening_players = {}

    config.utils.log(locale('crate.crate_cleaned_up_server'), 'INFO')
end

RegisterNetEvent('stevo_cayocrates:createCrateDrop', function(crate_data)
    CrateState.current_crate = crate_data
    config.utils.log(locale('crate.crate_drop_created_server'), 'INFO')
end)

RegisterNetEvent('stevo_cayocrates:startCrateOpening', function()
    local player = source

    if not validateCrateOpening(player) then
        return
    end

    CrateState.opening_players[player] = {
        start_time = os.time(),
        crate_data = CrateState.current_crate
    }

    if CrateState.current_crate then
        CrateState.current_crate.owned = true
        CrateState.current_crate.current_owner = player
    end

    config.utils.log(locale('crate.player_started_opening', player), 'INFO')
end)

RegisterNetEvent('stevo_cayocrates:finishCrateOpening', function()
    local player = source

    if not validateCrateCompletion(player) then
        return
    end

    local loot = generateLoot()
    giveLootToPlayer(player, loot)

    config.utils.global_notify(locale('crate_opened'))

    cleanupCrate()

    config.utils.log(locale('crate.player_completed_opening', player), 'INFO')
end)

RegisterNetEvent('stevo_cayocrates:cancelCrateOpening', function()
    local player = source

    if CrateState.current_crate then
        CrateState.current_crate.owned = false
        CrateState.current_crate.current_owner = nil
    end

    CrateState.opening_players[player] = nil

    config.utils.log(locale('crate.player_cancelled_opening', player), 'INFO')
end)

AddEventHandler('playerDropped', function()
    local player = source

    CrateState.opening_players[player] = nil

    if CrateState.current_crate and CrateState.current_crate.current_owner == player then
        CrateState.current_crate.owned = false
        CrateState.current_crate.current_owner = nil
    end
end)

CreateThread(function()
    config.utils.log(locale('crate.crate_server_initialized'), 'INFO')
end)
