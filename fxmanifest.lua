fx_version 'cerulean'
game 'gta5'

name 'Pulsar Finance'
description 'Banking with accounts, ATM, loan payments, and crypto trading'
author 'Artmines - maintained for Pulsar Framework'
url 'https://pulsarframe.work'
version 'v1.0.3'

version_check 'yes'
github 'https://github.com/PulsarFW/pulsar_finance'

client_script '@pulsar_core/components/cl_error.lua'
shared_script '@pulsar_core/core/sh_pulsar.lua'
client_script '@pulsar_pwnzor/client/check.lua'
server_script '@oxmysql/lib/MySQL.lua'

client_scripts({
	'data/**/*.lua',
	'client/**/*.lua',
})

server_scripts({
	'data/**/*.lua',
	'server/**/*.lua',
})

files({ 
	'ui/dist/index.html',
	'ui/dist/assets/*', 
	'config/shared.lua' 
})

ui_page 'ui/dist/index.html'
lua54 'yes'
