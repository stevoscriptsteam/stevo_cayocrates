fx_version 'cerulean'
game 'gta5'

author 'SSnowly & Steve'
description 'Cayo Crate Resource - Refactored'
version '2.0.0'

ui_page "web/ui.html"

shared_scripts {
  '@ox_lib/init.lua',
}

client_scripts {
  'client.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua'
}

files {
  "web/ui.html",
  "web/app.js",
  "web/style.css",
  "web/laptop.jpg",
  'web/sound.wav',
  'locales/*.json',

  -- shared
  'shared/config.lua',
  'shared/state.lua',

  -- client
  'modules/**/client*.lua',
}

-- initiate locales cuz.. why not?
ox_libs {
  'locale'
}

dependencies {
  'ox_lib',
  'ox_inventory',
  'oxmysql'
}

lua54 'yes'
