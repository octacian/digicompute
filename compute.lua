-- GENERATED CODE
-- Node Box Editor, version 0.9.0
-- Namespace: test

minetest.register_node("test:node_1", {
	tiles = {
		"updown.png",
		"updown.png",
		"right.png",
		"left.png",
		"back_off.png",
		"front_off.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, 0.5, 0.5, 0.5}, -- computer
		}
	}
})

