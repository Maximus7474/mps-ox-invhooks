fx_version "cerulean"
game "gta5"
server_only "yes"
description "ox inventory hooks"
repository 'https://github.com/Maximus7474/mps-ox-invhooks'

version "1.0.0"

server_scripts {
	"@ox_lib/init.lua",
	"server/utils.lua",
	"server/hooks/*.lua",
	"server/init.lua",
}
