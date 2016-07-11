-- digiterm/nodes.lua

digiterm.register_terminal("basic", {
	description = "Basic Digiterm",
	off_tiles = {
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_front_off.png"
	},
	bios_tiles = {
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"bios.png^digiterm_front_off.png"
	},
	on_tiles = {
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_side.png",
		"digiterm_front.png"
	}
})
