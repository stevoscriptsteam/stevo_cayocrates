Laptop = {}

cooldown: false;

$(document).on('keydown', function(event) {
    switch(event.keyCode) {
        case 27:
            $('#macos').remove();
            Laptop.Close();
            break;
    }
});

$(document).ready(function() {
    window.addEventListener('message', function(event) {
        var action = event.data.action;
        switch(action) {
            case "openLaptop":
                Laptop.Open(event.data);
                break;
            case "closeLaptop":
                Laptop.Close();
                break;
        }
    });

    $('#injectUsb').on('click', function() {
        Laptop.InjectUSB();
    });
});

Laptop.Open = function(data) {
    $(".laptop").fadeIn(100);

    $(".applications").empty();

    if (data.hasUsb) {
        cooldown = data.crateCooldown
        $(".applications").append(`
            <div class="app-icon" id="injectUsb">
                <p>Inject USB</p>
            </div>
        `);

        $('#injectUsb').on('click', function() {
            Laptop.InjectUSB();
        });

        setTimeout(() => {
            Laptop.ShowNotification("USB Detected, you can inject now.");
        }, 200);
    }
}

Laptop.Close = function() {
    $(".laptop").fadeOut(100);
    $.post('https://stevo_cayocrates/closeLaptop');
}

Laptop.InjectUSB = function() {
    Laptop.ShowUsbInsertedMessage();


    $('#injectUsb').remove();


    $(".laptop").append(`
        <div class="launch-crate" id="macos">
            <div class="macos-box">
                <div class="macos-box-header">
                    <span class="macos-title">crate.exe</span>
                    <button id="closeMacosBtn" class="macos-close-btn">EJECT USB</button>
                </div>
                <div class="macos-box-content">
                    <button id="launchCrateBtn">LAUNCH CRATE DROP</button>
                </div>
            </div>
        </div>

    `);

    $('#launchCrateBtn').on('click', function() {
        Laptop.LaunchCrateDrop();
    });

    $('#closeMacosBtn').on('click', function() {
        Laptop.ShowNotification("USB has been ejected.");
        $('#macos').remove();
        $(".applications").append(`
            <div class="app-icon" id="injectUsb">
                <p>Inject USB</p>
            </div>
        `);

        $('#injectUsb').on('click', function() {
            Laptop.InjectUSB();
        });
    });
}

Laptop.ShowUsbInsertedMessage = function() {
    Laptop.ShowNotification("USB has been injected.");
}

Laptop.ShowNotification = function(message) {
    if ($('.notifications').length === 0) {
        $('.laptop').append('<div class="notifications"></div>');
    }

    const notification = $(`<div class="notification">${message}</div>`);
    $('.notifications').append(notification);
    playSound()
    notification.fadeIn(100).delay(2000).fadeOut(100, function() {
        $(this).remove();
    });
}


Laptop.LaunchCrateDrop = function(data) {
    $('#macos').remove();

    if (cooldown) {
        Laptop.ShowNotification("Crate Cooldown active, Cannot drop!");
    } else {
        Laptop.ShowNotification("Crate Drop Launched!");
        $.post('https://stevo_cayocrates/crateDrop');
    }
    
}

function playSound() {
    var audio = document.getElementById('soundEffect');
    audio.volume = 0.2;
    audio.play();
}


$(document).on('click', '#closelaptop', function(e) {
    e.preventDefault();
    $('#macos').remove();
    Laptop.Close();
});


window.onload = function() {
    $(".laptop").hide();

}
