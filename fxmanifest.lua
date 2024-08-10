fx_version 'cerulean'
game 'gta5'


author 'StevoScripts | steve'
description 'Cayo Crate Resource'
version '1.0.0'

ui_page "web/ui.html"

shared_scripts {
  'config.lua',
  '@ox_lib/init.lua'
}

client_scripts {
  'resource/client.lua',

}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
	'resource/server.lua'
}

files {
  "web/ui.html",
  "web/app.js",
  "web/style.css",
  "web/laptop.jpg",
  'web/sound.wav',
  'locales/*.json'
}


dependencies {
  'ox_lib',
  'oxmysql',
  'stevo_lib'
}

lua54 'yes'
