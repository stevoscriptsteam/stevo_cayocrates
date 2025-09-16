local config = lib.require('shared.config')
local StateManager = lib.require('shared.state')


local CrateManager = {
    current_crate = nil,
    crate_point = nil,
    crate_object = nil,
    radius_blip = nil
}


local function createFlareEffects(coords)
    local offsets = {
        vec3(coords.x + config.crates.flare_offset, coords.y, coords.z),
        vec3(coords.x - config.crates.flare_offset, coords.y, coords.z),
        vec3(coords.x, coords.y - config.crates.flare_offset, coords.z),
        vec3(coords.x, coords.y + config.crates.flare_offset, coords.z)
    }

    lib.requestWeaponAsset(GetHashKey("weapon_flare"))

    for i = 1, config.crates.flare_count do
        ShootSingleBulletBetweenCoords(
            vec3(coords.x, coords.y, coords.z + 10),
            offsets[i],
            0,
            false,
            GetHashKey("weapon_flare"),
            0,
            true,
            true,
            -1.0
        )
    end
end

local function startCrateOpening()
    local success = lib.progressBar({
        duration = config.crates.opening_time,
        label = locale('crate.opening_crate'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        },
        anim = {
            dict = 'anim@gangops@facility@servers@bodysearch@',
            clip = 'player_search'
        }
    })

    if success then
        config.utils.notify(locale('crate.crate_opened_success'), 'success')
        TriggerServerEvent('stevo_cayocrates:finishCrateOpening')
    else
        config.utils.notify(locale('crate.crate_opening_cancelled'), 'error')
        TriggerServerEvent('stevo_cayocrates:cancelCrateOpening')
    end
end

local function handleCrateInteraction()
    local player_ped = cache.ped

    if IsEntityDead(player_ped) then
        config.utils.notify(locale('crate.cannot_open_dead'), 'error')
        return
    end

    local player_coords = GetEntityCoords(player_ped)
    local crate_coords = StateManager.get('crate.current_drop').coords
    local distance = #(player_coords - crate_coords)

    if distance > 3 then
        config.utils.notify(locale('crate.too_far_from_crate'), 'error')
        return
    end

    TriggerServerEvent('stevo_cayocrates:startCrateOpening')
    startCrateOpening()
end

local function createCratePoint(coords)
    CrateManager.crate_point = lib.points.new({
        coords = coords,
        distance = 50,
        crate = false
    })

    function CrateManager.crate_point:onEnter()
        lib.requestModel(config.crates.model)
        local crate_object = CreateObject(config.crates.model, coords.x, coords.y, coords.z, true)
        FreezeEntityPosition(crate_object, true)
        if config.crates.interaction.type == "target" then
            exports.ox_target:addLocalEntity(crate_object, {
                label = config.crates.interaction.options[1].label,
                icon = config.crates.interaction.options[1].icon,
                onSelect = function()
                    handleCrateInteraction()
                end
            })
        end
        CrateManager.crate_object = crate_object
        StateManager.set('crate.object', crate_object)

        createFlareEffects(coords)

        config.utils.log(locale('crate.crate_object_created'), 'DEBUG')
    end

    function CrateManager.crate_point:onExit()
        if CrateManager.crate_object and DoesEntityExist(CrateManager.crate_object) then
            DeleteEntity(CrateManager.crate_object)
            CrateManager.crate_object = nil
            StateManager.set('crate.object', nil)
            if config.crates.interaction.type == "target" then
                exports.ox_target:removeLocalEntity(CrateManager.crate_object)
            end
        end
    end

    function CrateManager.crate_point:nearby()
        local crate_data = StateManager.get('crate.current_drop')
        if not crate_data then return end


        if config.crates.interaction.type == "drawtext" then
            if self.currentDistance < 3 and not crate_data.owned then
                local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 1)
    
                if onScreen then
                    SetTextScale(0.4, 0.4)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 255, 255, 255)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    SetTextCentre(true)
                    AddTextComponentString(locale('crate.press_e_open_crate'))
                    DrawText(_x, _y)
                end
            end
    
    
            if self.currentDistance < 3 and IsControlJustReleased(0, 38) and not crate_data.owned then
                handleCrateInteraction()
            end
        elseif config.crates.interaction.type == "textui" then
            if not lib.isTextUIOpen() and self.currentDistance < 3 and not crate_data.owned then
                lib.showTextUI(locale('crate.press_e_open_crate'), {
                    icon = config.crates.interaction.options[1].icon,
                    duration = 5000
                })
            elseif self.currentDistance > 3 then
                if lib.isTextUIOpen() then
                    lib.hideTextUI()
                end
            end
            if self.currentDistance < 3 and IsControlJustReleased(0, 38) and not crate_data.owned then
                handleCrateInteraction()
            end
        end
    end
end

RegisterNetEvent('stevo_cayocrates:createCrateBlip', function(coords)
    CrateManager.radius_blip = AddBlipForRadius(coords, 100.0)
    SetBlipColour(CrateManager.radius_blip, 1)
    SetBlipAlpha(CrateManager.radius_blip, 128)
    
    CrateManager.crate_blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipAlpha(CrateManager.crate_blip, 128)
    SetBlipSprite(CrateManager.crate_blip, 568)
end)

local function cleanupCrate()

    if CrateManager.crate_object and DoesEntityExist(CrateManager.crate_object) then
        DeleteEntity(CrateManager.crate_object)
        CrateManager.crate_object = nil
    end

    if CrateManager.crate_point then
        CrateManager.crate_point:remove()
        CrateManager.crate_point = nil
    end

    if config.crates.interaction.type == "textui" then
        if lib.isTextUIOpen() then
            lib.hideTextUI()
        end
    end

    StateManager.set('crate.current_drop', nil)
    StateManager.set('crate.is_active', false)
    StateManager.set('crate.object', nil)
    CrateManager.current_crate = nil

    config.utils.log(locale('crate.crate_cleaned_up'), 'DEBUG')
end

RegisterNetEvent('stevo_cayocrates:createCrateDrop', function(crate_data)
    cleanupCrate()

    StateManager.set('crate.current_drop', crate_data)
    StateManager.set('crate.is_active', true)
    CrateManager.current_crate = crate_data

    createCratePoint(crate_data.coords)

    config.utils.log(locale('crate.crate_drop_created_client'), 'INFO')
end)

RegisterNetEvent('stevo_cayocrates:crateOpened', function(crate_data)
    local player_coords = GetEntityCoords(cache.ped)
    local crate_coords = crate_data.coords
    local distance = #(player_coords - crate_coords)

    if CrateManager.radius_blip then
        RemoveBlip(CrateManager.radius_blip)
        CrateManager.radius_blip = nil
    end

    if CrateManager.crate_blip then
        RemoveBlip(CrateManager.crate_blip)
        CrateManager.crate_blip = nil
    end

    if distance <= config.crates.explosion_radius then
        cleanupCrate()

        config.utils.notify(locale('crate.get_away_crate'), 'error', 5000)

        if config.crates.explosion then
            CreateThread(function()
                Wait(config.crates.explosion_delay)

                local current_distance = #(GetEntityCoords(cache.ped) - crate_coords)
                if current_distance <= config.crates.explosion_radius then
                    AddExplosion(crate_coords, 9, 0.9, 1, 0, 1065353216, 0)
                    Wait(1000)
                end
            end)
        end
    else
        cleanupCrate()
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        cleanupCrate()
    end
end)


CreateThread(function()
    config.utils.log(locale('crate.crate_client_initialized'), 'INFO')
end)
