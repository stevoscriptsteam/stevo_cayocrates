local config = require('shared.config')
local StateManager = require('shared.state')
local computerCamera = nil


local ComputerZone = {
    view_zone = nil,
    interaction_zone = nil
}


local function validateComputerAccess(player_coords, computer_coords)
    local distance = #(player_coords - computer_coords)

    if distance > config.computer.interaction_distance then
        config.utils.log(locale('computer.player_too_far'), 'WARNING')
        return false
    end

    return true
end


local function checkRateLimit()
    local current_time = GetGameTimer()
    local last_interaction = StateManager.get('player.last_interaction')
    local rate_limit_count = StateManager.get('player.rate_limit_count')


    if current_time - last_interaction > 60000 then
        StateManager.set('player.rate_limit_count', 0)
    end


    if rate_limit_count >= 10 then
        return false
    end


    StateManager.set('player.last_interaction', current_time)
    StateManager.set('player.rate_limit_count', rate_limit_count + 1)

    return true
end


local function closeComputer()
    TriggerEvent('stevo_cayocrates:beginComputerClose')
    
    CreateThread(function()
        local player_ped = cache.ped
        
        if computerCamera then
            SetCamActive(computerCamera, false)
            RenderScriptCams(false, true, 800, true, false) 
        end
    
        Wait(800)
        
        if computerCamera then
            DestroyCam(computerCamera, false)
            computerCamera = nil
        end
        
        FreezeEntityPosition(player_ped, false)
        ClearPedTasks(player_ped)
        
        SetNuiFocus(false, false)
        StateManager.set('ui.is_open', false)
        
        TriggerEvent('stevo_cayocrates:computerCloseComplete')
        
        config.utils.log(locale('computer.computer_interface_closed'), 'DEBUG')
    end)
end


local function requestCrateDrop()
    if StateManager.get('crate.cooldown') then
        config.utils.notify(locale('computer.crate_drop_cooldown'), 'error')
        return
    end

    TriggerServerEvent('stevo_cayocrates:requestCrateDrop')
    closeComputer()
end



local function createComputerCamera()
    local computer_coords = config.computer.coords
    
    local camera_offset = vector3(2.0, -1.5, 1.2) 
    local camera_coords = computer_coords + camera_offset
    
    computerCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 
        camera_coords.x, camera_coords.y, camera_coords.z,
        -10.0, 0.0, 45.0, 
        50.0, false, 0)
    
    PointCamAtCoord(computerCamera, computer_coords.x, computer_coords.y, computer_coords.z + 0.5)
    
    return computerCamera
end

local function startComputerSequence(crate_cooldown, has_usb)
    local player_ped = cache.ped
    

    computerCamera = createComputerCamera()
    SetCamActive(computerCamera, true)
    RenderScriptCams(true, true, 1000, true, false)
    
    FreezeEntityPosition(player_ped, true)

    local typing_dict = "anim@heists@prison_heiststation@cop_reactions"
    local typing_anim = "cop_b_idle"

     
    lib.requestAnimDict(typing_dict)
     
    TaskPlayAnim(player_ped, typing_dict, typing_anim, 2.0, 2.0, -1, 49, 0, false, false, false)

    Wait(1000)

    StateManager.set('player.has_usb', has_usb)
    StateManager.set('crate.cooldown', crate_cooldown)
    StateManager.set('ui.is_open', true)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openLaptop",
        hasUsb = has_usb,
        crateCooldown = crate_cooldown
    })

    config.utils.log(locale('computer.computer_accessed'), 'INFO')
end

local function handleComputerInteraction()
    local player_ped = cache.ped
    local player_coords = GetEntityCoords(player_ped)
    local computer_coords = config.computer.coords

    if not validateComputerAccess(player_coords, computer_coords) then
        return
    end

    if not checkRateLimit() then
        config.utils.notify(locale('computer.too_many_interactions'), 'error')
        return
    end

    if IsEntityDead(player_ped) then
        config.utils.notify(locale('computer.cannot_access_dead'), 'error')
        return
    end

    local crate_cooldown, has_usb = lib.callback.await('stevo_cayocrates:getComputerData', false)

    if not has_usb then
        config.utils.notify(locale('computer.need_usb'), 'error')
        return
    end

    CreateThread(function()
        startComputerSequence(crate_cooldown, has_usb)
    end)
end


local function initializeComputerZones()
    ComputerZone.view_zone = lib.points.new({
        coords = config.computer.coords,
        distance = config.computer.view_distance,
        computer = false
    })

    function ComputerZone.view_zone:onEnter()
        if not StateManager.get('computer.is_visible') then
            lib.requestModel(config.computer.model)
            local computer_object = CreateObject(config.computer.model, config.computer.coords.x,
                config.computer.coords.y, config.computer.coords.z, true)
            FreezeEntityPosition(computer_object, true)

            StateManager.set('computer.object', computer_object)
            StateManager.set('computer.is_visible', true)

            config.utils.log(locale('computer.computer_object_created'), 'DEBUG')
        end
    end

    function ComputerZone.view_zone:onExit()
        local computer_object = StateManager.get('computer.object')
        if computer_object and DoesEntityExist(computer_object) then
            DeleteEntity(computer_object)
            StateManager.set('computer.object', nil)
            StateManager.set('computer.is_visible', false)

            config.utils.log(locale('computer.computer_object_deleted'), 'DEBUG')
        end
    end

    ComputerZone.interaction_zone = lib.points.new({
        coords = config.computer.coords,
        distance = config.computer.interaction_distance
    })

    function ComputerZone.interaction_zone:onEnter()
        if not StateManager.get('ui.is_open') then
            lib.showTextUI(locale('computer.access_computer'))
        end
    end

    function ComputerZone.interaction_zone:onExit()
        lib.hideTextUI()
    end

    function ComputerZone.interaction_zone:nearby()
        if IsControlJustReleased(0, 38) and not StateManager.get('ui.is_open') then
            handleComputerInteraction()
        end
    end
end


RegisterNUICallback('closeLaptop', function(data, cb)
    closeComputer()
    cb('ok')
end)

RegisterNUICallback('crateDrop', function(data, cb)
    requestCrateDrop()
    cb('ok')
end)


CreateThread(function()
    initializeComputerZones()
    config.utils.log(locale('computer.computer_module_initialized'), 'INFO')
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local computer_object = StateManager.get('computer.object')
        if computer_object and DoesEntityExist(computer_object) then
            DeleteEntity(computer_object)
        end

        if ComputerZone.view_zone then
            ComputerZone.view_zone:remove()
        end

        if ComputerZone.interaction_zone then
            ComputerZone.interaction_zone:remove()
        end
    end
end)

RegisterCommand('crate', function()
    TriggerServerEvent('stevo_cayocrates:requestCrateDrop')
end)

RegisterNetEvent('stevo_cayocrates:forceCloseComputer', function()
    if StateManager.get('ui.is_open') then
        closeComputer()
    end
end)
