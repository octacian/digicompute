-- computers/nodes.lua

digicompute.register_computer("default", {
	description = "digicomputer",
	off_tiles = {
		"top.png",
		"bottom.png",
		"right.png",
		"left.png",
		"back_off.png",
		"front_off.png",
	},
	bios_tiles = {
		"top.png",
		"bottom.png",
		"right.png",
		"left.png",
		"back_off.png",
		"front_off.png^bios.png",
	},
	on_tiles = {
		"top.png",
		"bottom.png",
		"right.png",
		"left.png",
		"back.png",
		"front.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, 0.5, 0.5, 0.5}, -- computer
		}
	},
})
