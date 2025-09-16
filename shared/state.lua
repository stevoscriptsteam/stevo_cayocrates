
local State = {
    
    computer = {
        is_visible = false,
        object = nil,
        is_interacting = false
    },

    
    crate = {
        current_drop = nil,
        is_active = false,
        cooldown = false,
        cooldown_end = 0,
        point = nil,
        object = nil,
        blip = nil
    },

    
    player = {
        has_usb = false,
        last_interaction = 0,
        rate_limit_count = 0
    },

    
    ui = {
        is_open = false,
        current_view = nil
    }
}


StateManager = {

    get = function(path)
        local keys = {}
        for key in string.gmatch(path, "[^%.]+") do
            table.insert(keys, key)
        end

        local current = State
        for _, key in ipairs(keys) do
            if current[key] then
                current = current[key]
            else
                return nil
            end
        end
        return current
    end,

    
    set = function(path, value)
        local keys = {}
        for key in string.gmatch(path, "[^%.]+") do
            table.insert(keys, key)
        end

        local current = State
        for i, key in ipairs(keys) do
            if i == #keys then
                current[key] = value
            else
                if not current[key] then
                    current[key] = {}
                end
                current = current[key]
            end
        end
    end,

    
    update = function(path, updates)
        local current = StateManager.get(path)
        if type(current) == 'table' and type(updates) == 'table' then
            for key, value in pairs(updates) do
                current[key] = value
            end
        end
    end,

    
    reset = function(path)
        if path then
            StateManager.set(path, nil)
        else
            State = {
                computer = { is_visible = false, object = nil, is_interacting = false },
                crate = { current_drop = nil, is_active = false, cooldown = false, cooldown_end = 0, point = nil, object = nil, blip = nil },
                player = { has_usb = false, last_interaction = 0, rate_limit_count = 0 },
                ui = { is_open = false, current_view = nil }
            }
        end
    end,

    
    getFull = function()
        return State
    end
}


return StateManager
