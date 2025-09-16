local config = lib.require('shared.config')


local LootManager = {
    loot_history = {},
    player_stats = {}
}


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

    if #selected_items == 0 then
        table.insert(selected_items, {
            item = "WEAPON_PISTOL",
            count = 1,
            tier = "common"
        })
    end

    return selected_items
end





local function updatePlayerStats(player, loot, success_count)
    if not LootManager.player_stats[player] then
        LootManager.player_stats[player] = {
            total_crates_opened = 0,
            total_items_received = 0,
            items_by_tier = {},
            last_opened = 0
        }
    end

    local stats = LootManager.player_stats[player]
    stats.total_crates_opened = stats.total_crates_opened + 1
    stats.total_items_received = stats.total_items_received + success_count
    stats.last_opened = os.time()


    for _, item_data in ipairs(loot) do
        if not stats.items_by_tier[item_data.tier] then
            stats.items_by_tier[item_data.tier] = 0
        end
        stats.items_by_tier[item_data.tier] = stats.items_by_tier[item_data.tier] + item_data.count
    end

    config.utils.log(locale('loot.updated_player_stats', player, stats.total_crates_opened, stats.total_items_received), 'DEBUG')
end


local function handleFailedItems(player, failed_items)
    config.utils.log(locale('loot.player_failed_items', player, #failed_items), 'WARNING')

end

local function giveLootToPlayer(player, loot)
    local success_count = 0
    local failed_items = {}
    for _, item_data in ipairs(loot) do
        local success = exports.ox_inventory:AddItem(player, item_data.item, item_data.count)
        if success then
            success_count = success_count + 1
            config.utils.log(locale('loot.gave_item_player', item_data.count, item_data.item, player, item_data.tier), 'INFO')
        else
            table.insert(failed_items, item_data)
            config.utils.log(locale('loot.failed_give_item', item_data.count, item_data.item, player), 'WARNING')
        end
    end

    updatePlayerStats(player, loot, success_count)

    if success_count > 0 then
        config.utils.notify(player, locale('loot.received_items', success_count), 'success')

        local loot_message = locale('loot.loot_received') .. "\n"
        for _, item_data in ipairs(loot) do
            if item_data.count > 0 then
                loot_message = loot_message .. locale('loot.loot_item_format', item_data.count, item_data.item, item_data.tier) .. "\n"
            end
        end
        config.utils.notify(player, loot_message, 'inform', 8000)
    else
        config.utils.notify(player, locale('loot.failed_receive_items'), 'error')
    end

    if #failed_items > 0 then
        handleFailedItems(player, failed_items)
    end

    return success_count
end

local function getPlayerStats(player)
    return LootManager.player_stats[player] or {
        total_crates_opened = 0,
        total_items_received = 0,
        items_by_tier = {},
        last_opened = 0
    }
end


local function getLootHistory()
    return LootManager.loot_history
end


local function addToLootHistory(player, loot)
    table.insert(LootManager.loot_history, {
        player = player,
        loot = loot,
        timestamp = os.time()
    })


    if #LootManager.loot_history > 100 then
        table.remove(LootManager.loot_history, 1)
    end
end


AddEventHandler('playerDropped', function()
    local player = source
    LootManager.player_stats[player] = nil
end)


return {
    generateLoot = generateLoot,
    giveLootToPlayer = giveLootToPlayer,
    getPlayerStats = getPlayerStats,
    getLootHistory = getLootHistory,
    addToLootHistory = addToLootHistory
}
