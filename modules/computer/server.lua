local config = require('shared.config')


local ServerState = {
    crate_cooldown = false,
    cooldown_end = 0
}


local PlayerData = {}

local function GetPlayerData(player)
    return PlayerData[player]
end

local function SetPlayerData(player, data)
    PlayerData[player] = data
end


local function validatePlayerAccess(player)
    if not player or player <= 0 then
        config.utils.log(locale('computer.invalid_player_id'), 'WARNING')
        return false
    end

    if not GetPlayerName(player) then
        config.utils.log(locale('computer.player_not_exist'), 'WARNING')
        return false
    end

    return true
end


local function validateCrateDropRequest(player)
    if not validatePlayerAccess(player) then
        return false
    end

    local has_usb = exports.ox_inventory:GetItemCount(player, config.items.usb) >= 1
    if not has_usb then
        config.utils.log(locale('computer.player_no_usb_attempt', player), 'WARNING')
        return false
    end


    local player_data = GetPlayerData(player)
    if player_data and player_data.last_crate_request then
        local time_since_last = os.time() - player_data.last_crate_request
        if time_since_last < 60 then
            config.utils.log(locale('computer.player_rate_limited', player), 'WARNING')
            return false
        end
    end

    if #(GetEntityCoords(GetPlayerPed(player)) - config.computer.coords) > 5 then
        config.utils.log(locale('computer.player_too_far_computer', player, #(GetEntityCoords(GetPlayerPed(player)) - config.computer.coords)), 'WARNING')
        return false
    end

    return true
end


local function startCrateDrop(player)
    ServerState.crate_cooldown = true
    ServerState.cooldown_end = os.time() + (config.crates.drop.cooldown / 1000)


    local player_data = GetPlayerData(player) or {}
    player_data.last_crate_request = os.time()
    SetPlayerData(player, player_data)


    local total_seconds = config.crates.drop.wait_time / 1000
    local minutes = math.floor(total_seconds / 60)
    local seconds = total_seconds % 60

    print(minutes, seconds)
    local message
    if minutes > 0 and seconds > 0 then
        message = locale("computer.crate_drop_incoming_min_sec", minutes, seconds)
    elseif minutes > 0 then
        message = locale("computer.crate_drop_incoming_min", minutes)
    else
        message = locale("computer.crate_drop_incoming_sec", seconds)
    end


    config.utils.global_notify(message)


    CreateThread(function()
        Wait(config.crates.drop.wait_time)


        local random_location = config.crates.locations[math.random(1, #config.crates.locations)]


        TriggerClientEvent('stevo_cayocrates:createCrateBlip', -1, random_location)


        for _, interval in ipairs(config.crates.drop.countdown_intervals) do
            config.utils.global_notify(locale("computer.crate_dropping_seconds", interval))
            Wait(5000)
        end


        local crate_data = {
            coords = random_location,
            owned = false,
            current_owner = nil,
            created_at = os.time()
        }

        TriggerClientEvent('stevo_cayocrates:createCrateDrop', -1, crate_data)
        TriggerEvent("stevo_cayocrates:createCrateDrop", crate_data)
        config.utils.log(locale('computer.crate_drop_created'), 'INFO')
    end)
end


lib.callback.register('stevo_cayocrates:getComputerData', function(source)
    local player = source


    if not validatePlayerAccess(player) then
        return false, false
    end


    local has_usb = exports.ox_inventory:GetItemCount(player, config.items.usb) >= 1


    local current_time = os.time()
    local is_on_cooldown = ServerState.crate_cooldown and current_time < ServerState.cooldown_end

    config.utils.log(
    locale('computer.computer_data_requested', player, has_usb, is_on_cooldown),
    'INFO')

    return is_on_cooldown, has_usb
end)


RegisterNetEvent('stevo_cayocrates:requestCrateDrop', function()
    local player = source

    if not validateCrateDropRequest(player) then
        return
    end


    if ServerState.crate_cooldown then
        local remaining_time = ServerState.cooldown_end - os.time()
        config.utils.notify(player, locale('computer.crate_drop_available_seconds', remaining_time), 'error')
        return
    end


    local removed = exports.ox_inventory:RemoveItem(player, config.items.usb, 1)
    if not removed then
        config.utils.notify(player, locale('computer.failed_remove_usb'), 'error')
        return
    end


    startCrateDrop(player)
end)


AddEventHandler('playerDropped', function()
    local player = source
    PlayerData[player] = nil
end)


CreateThread(function()
    config.utils.log(locale('computer.computer_server_initialized'), 'INFO')
end)
