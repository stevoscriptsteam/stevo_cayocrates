Laptop = {}

let cooldown = false;

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
    $(".laptop-container").fadeIn(100);
    $(".laptop").show();

    $(".applications").empty();
    $(".desktop-apps").empty();
    $(".taskbar-items").empty();
    $('#macos').remove();

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
    $(".laptop-container").fadeOut(100);
    $.post('https://stevo_cayocrates/closeLaptop');
}

Laptop.InjectUSB = function() {
    Laptop.ShowUsbInsertedMessage();

    $('#injectUsb').remove();

    $(".desktop-apps").append(`
        <div class="desktop-app" id="crateApp">
            <i class="fas fa-parachute-box"></i>
            <p>Crate Drop</p>
        </div>
    `);

    $(".taskbar-items").append(`
        <div class="taskbar-item" id="crateTaskbar">
            <i class="fas fa-parachute-box"></i> Crate Drop
        </div>
    `);

    $('#crateApp').on('click', function() {
        Laptop.OpenCrateApp();
    });

    $('#crateTaskbar').on('click', function() {
        Laptop.OpenCrateApp();
    });

    $(".applications").append(`
        <div class="app-icon" id="ejectUsb">
            <p>Eject USB</p>
        </div>
    `);

    $('#ejectUsb').on('click', function() {
        Laptop.EjectUSB();
    });
}

Laptop.OpenCrateApp = function() {
    $('#macos').remove();
    
    $('.taskbar-item').removeClass('active');
    $('#crateTaskbar').addClass('active');

    const currentTime = new Date().toLocaleTimeString();
    const coordinates = "25.7617° N, 80.1918° W";
    const altitude = "2,847 ft";

    $(".laptop").append(`
        <div class="launch-crate" id="macos">
            <div class="macos-box">
                <div class="macos-box-header">
                    <span class="macos-title"><i class="fas fa-parachute-box" style="margin-right: 12px;"></i>Crate Drop Control System v2.1</span>
                    <button id="closeMacosBtn" class="macos-close-btn">CLOSE</button>
                </div>
                <div class="macos-box-content">
                    <div class="crate-info">
                        <h3><i class="fas fa-info-circle"></i> Mission Parameters</h3>
                        <p><strong>Drop Zone:</strong> Cayo Perico Island</p>
                        <p><strong>Coordinates:</strong> ${coordinates}</p>
                        <p><strong>Altitude:</strong> ${altitude}</p>
                        <p><strong>Time:</strong> ${currentTime}</p>
                        
                        <div class="crate-status">
                            <div class="status-item">
                                <div class="status-label">Payload</div>
                                <div class="status-value">READY</div>
                            </div>
                            <div class="status-item">
                                <div class="status-label">Weather</div>
                                <div class="status-value">CLEAR</div>
                            </div>
                            <div class="status-item">
                                <div class="status-label">Security</div>
                                <div class="status-value">${cooldown ? 'HIGH' : 'LOW'}</div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="launch-section">
                        <button id="launchCrateBtn">
                            <span>INITIATE CRATE DROP</span>
                        </button>
                        
                        <div class="progress-container" id="progressContainer">
                            <div class="progress-bar">
                                <div class="progress-fill" id="progressFill"></div>
                            </div>
                            <div class="launch-status" id="launchStatus">Preparing launch sequence...</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `);

    $('#launchCrateBtn').on('click', function() {
        Laptop.LaunchCrateDrop();
    });

    $('#closeMacosBtn').on('click', function() {
        $('#macos').remove();
        $('.taskbar-item').removeClass('active');
    });
}

Laptop.EjectUSB = function() {
    Laptop.ShowNotification("USB has been ejected.");
    
    $('#crateApp').remove();
    $('#crateTaskbar').remove();
    $('#ejectUsb').remove();
    $('#macos').remove();
    
    $(".applications").append(`
        <div class="app-icon" id="injectUsb">
            <p>Inject USB</p>
        </div>
    `);

    $('#injectUsb').on('click', function() {
        Laptop.InjectUSB();
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
    console.log('📦 Launching crate drop, cooldown:', cooldown);
    
    if (cooldown) {
        Laptop.ShowNotification("⚠️ Crate Drop on Cooldown - Access Denied!");
        $('#progressContainer').fadeIn(300);
        $('#launchStatus').text('Launch aborted - Security lockdown active').css('color', '#f44336');
        
        setTimeout(() => {
            $('#progressContainer').fadeOut(300);
        }, 3000);
        return;
    }

    $('#launchCrateBtn').fadeOut(200, function() {
        $('#progressContainer').fadeIn(300);
    });
    
    Laptop.StartLaunchSequence();
}

Laptop.StartLaunchSequence = function() {
    const sequences = [
        { progress: 10, status: 'Initializing launch protocols...', duration: 800 },
        { progress: 25, status: 'Verifying payload integrity...', duration: 1000 },
        { progress: 40, status: 'Calculating drop trajectory...', duration: 900 },
        { progress: 55, status: 'Establishing satellite link...', duration: 1200 },
        { progress: 70, status: 'Authenticating drop coordinates...', duration: 800 },
        { progress: 85, status: 'Engaging launch mechanism...', duration: 1000 },
        { progress: 95, status: 'Final systems check...', duration: 700 },
        { progress: 100, status: 'Crate drop initiated successfully!', duration: 500 }
    ];
    
    let currentStep = 0;
    
    function executeStep() {
        if (currentStep >= sequences.length) {
            setTimeout(() => {
                Laptop.CompleteLaunch();
            }, 1000);
            return;
        }
        
        const step = sequences[currentStep];
        $('#progressFill').css('width', step.progress + '%');
        $('#launchStatus').text(step.status);
        
        if (step.progress >= 85) {
            $('#launchStatus').css('color', '#4caf50');
        } else if (step.progress >= 50) {
            $('#launchStatus').css('color', '#ff9800');
        }
        
        if (step.progress === 25 || step.progress === 70 || step.progress === 100) {
            playSound();
        }
        
        currentStep++;
        setTimeout(executeStep, step.duration);
    }
    
    executeStep();
}

Laptop.CompleteLaunch = function() {
    Laptop.ShowNotification("🚀 Crate Drop Launched Successfully!");
    
    $('#launchStatus').text('Mission accomplished - Crate en route to drop zone').css('color', '#4caf50');
    
    $('#progressFill').css('background', 'linear-gradient(90deg, #4caf50, #8bc34a)');
    
    $.post('https://stevo_cayocrates/crateDrop');
    
    setTimeout(() => {
        $('#macos').fadeOut(300, function() {
            $(this).remove();
            $('.taskbar-item').removeClass('active');
            
            setTimeout(() => {
                Laptop.InitiateCoordinatedClose();
            }, 100);
        });
    }, 1500);
}

Laptop.InitiateCoordinatedClose = function() {
    $.post('https://stevo_cayocrates/closeLaptop');
    
    setTimeout(() => {
        $(".laptop-container").fadeOut(400);
    }, 200);
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
    $(".laptop-container").hide();


}
