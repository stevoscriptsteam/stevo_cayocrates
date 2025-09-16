local config = lib.require('shared.config')
local StateManager = lib.require('shared.state')


local UIManager = {
    is_open = false,
    current_view = nil,
    notifications = {}
}




local function showNotification(message, type)
    SendNUIMessage({
        action = "showNotification",
        message = message,
        type = type or 'inform'
    })


    config.utils.notify(message, type)
end
local function openUI(data)
    if UIManager.is_open then
        return
    end

    UIManager.is_open = true
    StateManager.set('ui.is_open', true)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openLaptop",
        hasUsb = data.hasUsb,
        crateCooldown = data.crateCooldown,
        version = config.version
    })

    config.utils.log(locale('ui.ui_opened'), 'DEBUG')
end


local function closeUI()
    if not UIManager.is_open then
        return
    end

    UIManager.is_open = false
    StateManager.set('ui.is_open', false)
    UIManager.current_view = nil

    SendNUIMessage({
        action = "closeLaptop"
    })

    config.utils.log(locale('ui.ui_closed'), 'DEBUG')
end


local function requestCrateDrop()
    closeUI()
end


local function injectUSB()
    showNotification(locale('ui.usb_injected'), 'success')

    SendNUIMessage({
        action = "usbInjected"
    })

    UIManager.current_view = 'crate_launch'
end


local function ejectUSB()
    showNotification(locale('ui.usb_ejected'), 'inform')

    SendNUIMessage({
        action = "usbEjected"
    })

    UIManager.current_view = 'main'
end

RegisterNUICallback('closeLaptop', function(data, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('crateDrop', function(data, cb)
    requestCrateDrop()
    closeUI()
    cb('ok')
end)

RegisterNUICallback('injectUsb', function(data, cb)
    injectUSB()
    cb('ok')
end)

RegisterNUICallback('ejectUsb', function(data, cb)
    ejectUSB()
    cb('ok')
end)

return {
    openUI = openUI,
    closeUI = closeUI,
    showNotification = showNotification,
    isOpen = function()
        return UIManager.is_open
    end
}
