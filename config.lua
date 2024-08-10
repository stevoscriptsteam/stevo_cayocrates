return {
    usb_item = 'stevo_usb',
    spawnAggressivePeds = true,
    explosion = true,
    crate_order_wait = 5000, -- Time after crate is launched until crate spawns on cayo.
    crate_order_cooldown = 10000,

    computer = {
        coords = vec3(-37.975009918213, -2685.2998046875, 5.0002298355103),
        model = 'xm_prop_base_staff_desk_02',
        viewdistance = 20
    },

    crates = {
        model = 'xm_prop_moderncrate_xplv_01', 
        opening_time = 8000, 
        locations = {
            vec3(4927.8603515625, -4905.9565429688, 2.5298671722412),
            vec3(5322.365234375, -5250.5541992188, 31.581197738647),
            vec3(5476.5571289062, -5834.537109375, 18.372451782227)
        },
        loot = {
            {item = "WEAPON_PISTOL", min_amt = 1, max_amt = 1, chance = 80}, 
            {item = "WEAPON_KNIFE", min_amt = 1, max_amt = 2, chance = 90}, 
            {item = "WEAPON_CARBINERIFLE", min_amt = 1, max_amt = 2, chance = 15},
            {item = "WEAPON_PISTOL", min_amt = 1, max_amt = 2, chance = 5}
        }
    },

    globalNotify = function(message)

        -- TriggerClientEvent('chat:addMessage', -1, {
        --     color = { 34, 139, 230 },
        --     multiline = true,
        --     args = { message }
        -- }) 

        lib.notify( -1, {
            title = message,
            duration = 5000,
            showDuration = false,
            position = 'top',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                  color = '#909296'
                }
            },
            icon = 'parachute-box',
            iconColor = '#C53030'
        })
    end,
    
    -- LOCALES

    locales = {
        open_crate = 'PRESS [~b~E~w~] TO OPEN ~b~CRATE',
        opening_crate = 'Opening Crate'
    },
}

