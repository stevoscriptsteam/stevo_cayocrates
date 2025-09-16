return {
    debug = false,

    items = {
        usb = 'crate_usb',
    },

    computer = {
        coords = vec3(-37.975009918213, -2685.2998046875, 5.0002298355103),
        model = 'xm_prop_base_staff_desk_02',
        view_distance = 20,
        interaction_distance = 2,
        animation = {
            dict = 'anim@heists@prison_heiststation@cop_reactions',
            clip = 'cop_b_idle'
        }
    },

    crates = {
        model = 'xm_prop_moderncrate_xplv_01',
        opening_time = 8000,
        explosion_delay = 8000,
        explosion_radius = 0, -- setting this to 0 will disable the explosion
        flare_count = 4,
        flare_offset = 5,

        drop = {
            wait_time = 60000, -- 1 minute
            cooldown = 10000,
            countdown_intervals = { 15, 10, 5 }
        },
        interaction = {
            type = "textui", -- target | drawtext | textui -- target is the default, and it uses ox_target
            distance = 2,
            options = { -- this will be used for the label and icon (if required for that type)
                {
                    name = "open_crate",
                    icon = "fa-solid fa-box-open",
                    label = "Open Crate",
                }
            }
        },
        locations = {
            vec3(4927.8603515625, -4905.9565429688, 2.5298671722412),
            vec3(5322.365234375, -5250.5541992188, 31.581197738647),
            vec3(5476.5571289062, -5834.537109375, 18.372451782227)
        },

        loot = {
            tiers = {
                common = {
                    chance = 60,
                    items = {
                        { item = "WEAPON_PISTOL", min_amt = 1, max_amt = 1, chance = 80 },
                        { item = "WEAPON_KNIFE",  min_amt = 1, max_amt = 2, chance = 90 }
                    }
                },
                rare = {
                    chance = 30,
                    items = {
                        { item = "WEAPON_CARBINERIFLE", min_amt = 1, max_amt = 2, chance = 15 }
                    }
                },
                legendary = {
                    chance = 10,
                    items = {
                        { item = "WEAPON_PISTOL", min_amt = 1, max_amt = 2, chance = 5 }
                    }
                }
            }
        }
    },

    ui = {
        notifications = {
            position = 'top-right',
            duration = 5000,
            icon = 'fa-solid fa-box-open',
            style = {}
        }
    },

    database = {
        enabled = true,
        table_prefix = 'cayo_crates_',
        tables = {
            players = 'players',
            crates = 'crates',
            statistics = 'statistics'
        }
    },

    utils = {

        notify = function(message, type, duration)
            local self = require('shared.config')
            lib.notify({
                title = message,
                type = type or 'inform',
                duration = duration or 5000,
                position = self.ui.notifications.position,
                style = self.ui.notifications.style
            })
        end,


        global_notify = function(message)
            local self = require('shared.config')
            TriggerClientEvent('ox_lib:notify', -1, {
                title = message,
                icon = self.ui.notifications.icon,
                type = 'inform',
                duration = 5000,
                position = 'top'
            })
        end,


        log = function(message, level)
            local self = require('shared.config')
            if self.debug then
                print(string.format('[Stevo Cayo] [%s] %s', level or 'INFO', message))
            end
        end
    }
}
