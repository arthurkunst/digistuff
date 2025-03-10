digistuff = {
	S = core.get_translator("digistuff"),
	FS = function(...) return core.formspec_escape(digistuff.S(...)) end,
}

local components = {
	"internal",
	"conductors",
	"touchscreen",
	"light",
	"noteblock",
	"camera",
	"switches",
	"panel",
	"piezo",
	"detector",
	"piston",
	"timer",
	"cardreader",
	"channelcopier",
	"controller",
	"memory",
	"gpu",
	"sillystuff",
	"movestone",
	"pressureplate",
}

if minetest.get_modpath("mesecons_luacontroller") then table.insert(components,"ioexpander") end

for _,name in ipairs(components) do
	dofile(string.format("%s%s%s.lua",minetest.get_modpath(minetest.get_current_modname()),DIR_DELIM,name))
end

local http = minetest.request_http_api()
if not http then
	minetest.log("warning","digistuff is not allowed to use the HTTP API - digilines NIC will not be available!")
	minetest.log("warning","If this functionality is desired, please add digistuff to your secure.http_mods setting")
else
	local qos_http = minetest.get_modpath("qos") and QoS(http, 3) or http
	loadfile(string.format("%s%s%s.lua",minetest.get_modpath(minetest.get_current_modname()),DIR_DELIM,"nic"))(qos_http)
end
